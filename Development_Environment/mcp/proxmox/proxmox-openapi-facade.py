import http.server
import json
import os
import re
import ssl
import socketserver
import urllib.error
import urllib.parse
import urllib.request

UPSTREAM = os.environ.get('PROXMOX_UPSTREAM_URL', 'http://fortisai-mcp-openapi-proxmox-upstream.fortisai.local:8811').rstrip('/')
API_KEY = os.environ.get('PROXMOX_API_KEY', '')
UPDATE_API_KEY = os.environ.get('PROXMOX_UPDATE_API_KEY', '').strip()
PORT = int(os.environ.get('PROXMOX_PROXY_PORT', '8095'))
PROXMOX_HOST = os.environ.get('PROXMOX_HOST', '').strip()
PROXMOX_PORT = os.environ.get('PROXMOX_PORT', '8006').strip() or '8006'
PROXMOX_USER = os.environ.get('PROXMOX_USER', '').strip()
PROXMOX_TOKEN_NAME = os.environ.get('PROXMOX_TOKEN_NAME', '').strip()
PROXMOX_TOKEN_VALUE = os.environ.get('PROXMOX_TOKEN_VALUE', '').strip()
PROXMOX_VERIFY_SSL = os.environ.get('PROXMOX_VERIFY_SSL', 'true').strip().lower()
PROXMOX_CONFIG_PATH = os.environ.get('PROXMOX_MCP_CONFIG', '').strip()
PROXMOX_DEFAULT_ENVIRONMENT = os.environ.get('PROXMOX_DEFAULT_ENVIRONMENT', '').strip()
HOP_BY_HOP = {'connection', 'host', 'keep-alive', 'proxy-authenticate', 'proxy-authorization', 'te', 'trailer', 'transfer-encoding', 'upgrade'}
UPDATE_PATHS = {'/update_vm_resources', '/update_container_resources', '/create_vm_disk'}
STATISTICS_PATHS = {'/get_vm_statistics', '/get_container_statistics'}
MUTATING_PROXY_KEYWORDS = {
    'cancel', 'clone', 'create', 'delete', 'download', 'execute', 'reset',
    'restart', 'restore', 'retry', 'rollback', 'shutdown', 'start', 'stop',
    'update',
}
MUTATING_PROXY_JOB_RE = re.compile(r'/jobs/[^/]+/(cancel|retry)')
ENVIRONMENT_HEADER_NAMES = ('X-FortisAI-Proxmox-Environment', 'X-Proxmox-Environment')

def load_proxmox_config():
    if not PROXMOX_CONFIG_PATH:
        return {}
    try:
        with open(PROXMOX_CONFIG_PATH, 'r', encoding='utf-8') as handle:
            return json.load(handle)
    except Exception:
        return {}

PROXMOX_CONFIG = load_proxmox_config()

def bool_from_config(value, default=True):
    if value in (None, ''):
        return default
    if isinstance(value, bool):
        return value
    return str(value).strip().lower() not in {'0', 'false', 'no', 'off'}

def configured_environments():
    environments = {}
    if isinstance(PROXMOX_CONFIG, dict):
        raw_envs = PROXMOX_CONFIG.get('environments')
        if isinstance(raw_envs, dict):
            for name, env_config in raw_envs.items():
                env_name = str(name).strip()
                if env_name and isinstance(env_config, dict):
                    environments[env_name] = env_config

        if isinstance(PROXMOX_CONFIG.get('proxmox'), dict) or isinstance(PROXMOX_CONFIG.get('auth'), dict):
            default_name = str(
                PROXMOX_CONFIG.get('default_environment')
                or PROXMOX_DEFAULT_ENVIRONMENT
                or 'default'
            ).strip() or 'default'
            environments.setdefault(default_name, {
                'proxmox': PROXMOX_CONFIG.get('proxmox', {}),
                'auth': PROXMOX_CONFIG.get('auth', {}),
                'logging': PROXMOX_CONFIG.get('logging', {}),
                'security': PROXMOX_CONFIG.get('security', {}),
            })

    if not environments and (PROXMOX_HOST or PROXMOX_USER or PROXMOX_TOKEN_NAME or PROXMOX_TOKEN_VALUE):
        default_name = PROXMOX_DEFAULT_ENVIRONMENT or 'default'
        environments[default_name] = {
            'proxmox': {
                'host': PROXMOX_HOST,
                'port': PROXMOX_PORT,
                'verify_ssl': PROXMOX_VERIFY_SSL,
            },
            'auth': {
                'user': PROXMOX_USER,
                'token_name': PROXMOX_TOKEN_NAME,
                'token_value': PROXMOX_TOKEN_VALUE,
            },
        }
    return environments

PROXMOX_ENVIRONMENTS = configured_environments()
DEFAULT_ENVIRONMENT = str(
    (PROXMOX_CONFIG.get('default_environment') if isinstance(PROXMOX_CONFIG, dict) else '')
    or PROXMOX_DEFAULT_ENVIRONMENT
    or next(iter(PROXMOX_ENVIRONMENTS), 'default')
).strip() or 'default'

def environment_schema_properties():
    return {
        'environment': {
            'type': 'string',
            'description': 'Optional runtime Proxmox environment name from proxmox-config.json. Defaults to default_environment.',
        },
        'proxmox_environment': {
            'type': 'string',
            'description': 'FortisAI alias for environment. Forwarded upstream as environment.',
        },
    }

def add_environment_to_schema(schema):
    if not isinstance(schema, dict):
        return
    if schema.get('type') == 'object':
        properties = schema.setdefault('properties', {})
        if isinstance(properties, dict):
            properties.update({k: v for k, v in environment_schema_properties().items() if k not in properties})
    for key in ('allOf', 'anyOf', 'oneOf'):
        items = schema.get(key)
        if isinstance(items, list):
            for item in items:
                add_environment_to_schema(item)

def add_environment_parameters(operation):
    parameters = operation.setdefault('parameters', [])
    if not isinstance(parameters, list):
        return
    existing = {(item.get('name'), item.get('in')) for item in parameters if isinstance(item, dict)}
    if ('environment', 'query') not in existing:
        parameters.append({
            'name': 'environment',
            'in': 'query',
            'required': False,
            'schema': {'type': 'string'},
            'description': 'Optional runtime Proxmox environment name.',
        })
    if ('X-FortisAI-Proxmox-Environment', 'header') not in existing:
        parameters.append({
            'name': 'X-FortisAI-Proxmox-Environment',
            'in': 'header',
            'required': False,
            'schema': {'type': 'string'},
            'description': 'Optional runtime Proxmox environment header.',
        })

def is_mutating_proxy_path(path):
    normalized = path.split('?', 1)[0].rstrip('/') or '/'
    if normalized in UPDATE_PATHS:
        return True
    if normalized in STATISTICS_PATHS:
        return False
    if MUTATING_PROXY_JOB_RE.fullmatch(normalized):
        return True
    leaf = normalized.rsplit('/', 1)[-1]
    return any(leaf == keyword or leaf.startswith(keyword + '_') for keyword in MUTATING_PROXY_KEYWORDS)

def json_bytes(payload):
    return json.dumps(payload, separators=(',', ':')).encode('utf-8')

def env_section(env_config, name):
    value = env_config.get(name, {}) if isinstance(env_config, dict) else {}
    return value if isinstance(value, dict) else {}

def proxmox_auth(env_config):
    auth = env_section(env_config, 'auth')
    return {
        'user': str(auth.get('user') or PROXMOX_USER).strip(),
        'token_name': str(auth.get('token_name') or PROXMOX_TOKEN_NAME).strip(),
        'token_value': str(auth.get('token_value') or PROXMOX_TOKEN_VALUE).strip(),
    }

def proxmox_verify_ssl(env_config):
    proxmox = env_section(env_config, 'proxmox')
    return bool_from_config(proxmox.get('verify_ssl', PROXMOX_VERIFY_SSL), True)

def proxmox_base_url(env_config):
    proxmox = env_section(env_config, 'proxmox')
    raw = str(proxmox.get('host') or PROXMOX_HOST).strip()
    if not raw:
        return ''
    if '://' not in raw:
        raw = 'https://' + raw
    parsed = urllib.parse.urlparse(raw)
    scheme = parsed.scheme or 'https'
    host = parsed.hostname or parsed.netloc or parsed.path
    port = parsed.port or int(str(proxmox.get('port') or PROXMOX_PORT or '8006'))
    if ':' in host and not host.startswith('['):
        host = '[' + host + ']'
    return scheme + '://' + host + ':' + str(port)

def create_vm_disk_endpoint_schema():
    return {
        'post': {
            'summary': 'Create VM Disk',
            'description': 'Allocate and attach a new disk to a Proxmox QEMU VM. Uses the Proxmox POST config API so storage allocation and hotplug are supported. Returns before and after VM config.',
            'operationId': 'tool_create_vm_disk_post',
            'security': [{'FortisAIProxmoxUpdateKey': []}],
            'requestBody': {
                'required': True,
                'content': {
                    'application/json': {
                        'schema': {
                            'type': 'object',
                            'required': ['node', 'vmid', 'disk', 'storage', 'size_gib'],
                            'properties': {
                                **environment_schema_properties(),
                                'node': {'type': 'string', 'description': 'Proxmox node name, for example pve2'},
                                'vmid': {'type': 'string', 'description': 'QEMU VM ID, for example 124'},
                                'disk': {'type': 'string', 'description': 'Target disk slot, for example scsi1, virtio1, sata1, or ide1'},
                                'storage': {'type': 'string', 'description': 'Proxmox storage ID to allocate from, for example BootVolume'},
                                'size_gib': {'type': 'integer', 'minimum': 1, 'maximum': 1048576, 'description': 'New disk size in GiB. 1024 equals 1 TiB.'},
                                'cache': {'type': 'string', 'description': 'Optional Proxmox disk cache mode, for example writethrough or writeback'},
                                'iothread': {'type': 'boolean', 'description': 'Enable iothread=1 on supported disk buses'},
                                'discard': {'type': 'string', 'enum': ['ignore', 'on'], 'description': 'Optional discard mode'},
                                'ssd': {'type': 'boolean', 'description': 'Set ssd=1'},
                                'backup': {'type': 'boolean', 'description': 'Set backup=1 or backup=0'},
                                'replicate': {'type': 'boolean', 'description': 'Set replicate=1 or replicate=0'},
                                'digest': {'type': 'string', 'description': 'Optional Proxmox config digest for optimistic concurrency'},
                                'overwrite': {'type': 'boolean', 'description': 'Allow replacing an existing disk slot. Defaults to false.'},
                            },
                        }
                    }
                },
            },
            'responses': {
                '200': {'description': 'Disk created and attached'},
                '400': {'description': 'Invalid request'},
                '401': {'description': 'Missing or invalid FortisAI Proxmox update key'},
                '409': {'description': 'Disk slot already exists'},
                '503': {'description': 'Update endpoint authentication is not configured'},
            },
        }
    }

def update_endpoint_schema(kind):
    if kind == 'vm':
        properties = {
            **environment_schema_properties(),
            'node': {'type': 'string', 'description': 'Proxmox node name, for example pve2'},
            'vmid': {'type': 'string', 'description': 'QEMU VM ID, for example 124'},
            'sockets': {'type': 'integer', 'minimum': 1, 'maximum': 16, 'description': 'CPU socket count'},
            'cores': {'type': 'integer', 'minimum': 1, 'maximum': 256, 'description': 'CPU cores per socket'},
            'memory': {'type': 'integer', 'minimum': 256, 'maximum': 1048576, 'description': 'Memory in MiB'},
            'digest': {'type': 'string', 'description': 'Optional Proxmox config digest for optimistic concurrency'},
        }
        required = ['node', 'vmid']
        description = 'Update permanent CPU socket/core and memory settings for a Proxmox QEMU VM. Returns before and after VM config.'
    else:
        properties = {
            **environment_schema_properties(),
            'selector': {'type': 'string', 'description': 'Container selector: vmid, node:vmid, name, node/name, or comma list'},
            'node': {'type': 'string', 'description': 'Optional Proxmox node name when vmid is supplied directly'},
            'vmid': {'type': 'string', 'description': 'Optional LXC container ID when node is supplied directly'},
            'cores': {'type': 'integer', 'minimum': 1, 'maximum': 256, 'description': 'CPU core count'},
            'memory': {'type': 'integer', 'minimum': 16, 'maximum': 1048576, 'description': 'Memory in MiB'},
            'swap': {'type': 'integer', 'minimum': 0, 'maximum': 1048576, 'description': 'Swap in MiB'},
            'disk_gb': {'type': 'integer', 'minimum': 1, 'maximum': 1048576, 'description': 'Additional disk size in GiB'},
            'disk': {'type': 'string', 'description': 'Disk identifier to resize, default rootfs'},
            'digest': {'type': 'string', 'description': 'Optional Proxmox config digest for optimistic concurrency'},
        }
        required = []
        description = 'Update permanent CPU, memory, swap, or disk settings for Proxmox LXC containers. Returns before and after container config.'
    return {
        'post': {
            'summary': 'Update ' + ('VM' if kind == 'vm' else 'Container') + ' Resources',
            'description': description,
            'operationId': 'tool_update_' + kind + '_resources_post',
            'security': [{'FortisAIProxmoxUpdateKey': []}],
            'requestBody': {
                'required': True,
                'content': {'application/json': {'schema': {'type': 'object', 'required': required, 'properties': properties}}},
            },
            'responses': {
                '200': {'description': 'Resources updated'},
                '400': {'description': 'Invalid request'},
                '401': {'description': 'Missing or invalid FortisAI Proxmox update key'},
                '503': {'description': 'Update endpoint authentication is not configured'},
            },
        }
    }

def statistics_endpoint_schema(kind):
    is_vm = kind == 'vm'
    properties = {
        **environment_schema_properties(),
        'node': {'type': 'string', 'description': 'Proxmox node name, for example pve2'},
        'vmid': {'type': 'string', 'description': ('QEMU VM ID' if is_vm else 'LXC container ID')},
        'timeframe': {'type': 'string', 'enum': ['hour', 'day', 'week', 'month', 'year'], 'default': 'hour', 'description': 'RRD timeframe to include'},
        'cf': {'type': 'string', 'enum': ['AVERAGE', 'MAX'], 'default': 'AVERAGE', 'description': 'RRD consolidation function'},
        'include_config': {'type': 'boolean', 'default': True, 'description': 'Include permanent guest config'},
        'include_rrd': {'type': 'boolean', 'default': True, 'description': 'Include Proxmox RRD datapoints'},
    }
    required = ['node', 'vmid']
    if not is_vm:
        properties.update({
            'selector': {'type': 'string', 'description': 'Container selector: vmid, node:vmid, name, node/name, or comma list. Overrides node/vmid when supplied.'},
        })
        required = []
    return {
        'post': {
            'summary': 'Get ' + ('VM' if is_vm else 'Container') + ' Statistics',
            'description': 'Return current Proxmox status/current statistics, optional config, and optional rrddata for individual ' + ('QEMU VMs.' if is_vm else 'LXC containers.'),
            'operationId': 'tool_get_' + kind + '_statistics_post',
            'requestBody': {
                'required': True,
                'content': {'application/json': {'schema': {'type': 'object', 'required': required, 'properties': properties}}},
            },
            'responses': {
                '200': {'description': 'Statistics returned'},
                '400': {'description': 'Invalid request'},
                '502': {'description': 'Unable to query Proxmox'},
            },
        }
    }

def add_fortisai_endpoints_openapi(spec):
    components = spec.setdefault('components', {})
    schemes = components.setdefault('securitySchemes', {})
    schemes['FortisAIProxmoxUpdateKey'] = {
        'type': 'apiKey',
        'in': 'header',
        'name': 'X-FortisAI-Proxmox-Update-Key',
        'description': 'Vault-managed FortisAI key required for Proxmox update endpoints.',
    }
    paths = spec.setdefault('paths', {})
    paths['/get_vm_statistics'] = statistics_endpoint_schema('vm')
    paths['/get_container_statistics'] = statistics_endpoint_schema('container')
    paths['/update_vm_resources'] = update_endpoint_schema('vm')
    paths['/update_container_resources'] = update_endpoint_schema('container')
    paths['/create_vm_disk'] = create_vm_disk_endpoint_schema()

    for path_name, path_item in paths.items():
        if not isinstance(path_item, dict):
            continue
        for method, operation in path_item.items():
            if not isinstance(operation, dict):
                continue
            if method.lower() not in {'head', 'options'}:
                add_environment_parameters(operation)
            request_body = operation.get('requestBody')
            if isinstance(request_body, dict):
                content = request_body.get('content')
                if isinstance(content, dict):
                    for media in content.values():
                        if isinstance(media, dict):
                            add_environment_to_schema(media.get('schema'))
            if method.lower() in {'get', 'head', 'options'}:
                continue
            if is_mutating_proxy_path(path_name):
                operation['security'] = [{'FortisAIProxmoxUpdateKey': []}]
                responses = operation.setdefault('responses', {})
                responses.setdefault('401', {'description': 'Missing or invalid FortisAI Proxmox update key'})
                responses.setdefault('503', {'description': 'Update endpoint authentication is not configured'})

def public_openapi(payload):
    try:
        spec = json.loads(payload.decode('utf-8'))
    except Exception:
        return payload, 'application/json'

    spec.pop('security', None)
    components = spec.get('components')
    if isinstance(components, dict):
        components.pop('securitySchemes', None)

    paths = spec.get('paths')
    if isinstance(paths, dict):
        for path_item in paths.values():
            if not isinstance(path_item, dict):
                continue
            for operation in path_item.values():
                if isinstance(operation, dict):
                    operation.pop('security', None)

    add_fortisai_endpoints_openapi(spec)
    return (json.dumps(spec, separators=(',', ':')).encode('utf-8'), 'application/json')

class Handler(http.server.BaseHTTPRequestHandler):
    protocol_version = 'HTTP/1.1'

    def log_message(self, fmt, *args):
        return

    def _send_json(self, status, payload):
        body = json_bytes(payload)
        self.send_response(status)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _read_json(self):
        length = int(self.headers.get('Content-Length', '0') or '0')
        if not length:
            return {}
        return json.loads(self.rfile.read(length).decode('utf-8'))

    def _query_params(self):
        parsed = urllib.parse.urlparse(self.path)
        return urllib.parse.parse_qs(parsed.query, keep_blank_values=True)

    def _environment_name_from_request(self, payload=None):
        candidates = []
        if isinstance(payload, dict):
            candidates.extend([payload.get('environment'), payload.get('proxmox_environment')])
        query = self._query_params()
        candidates.extend([
            (query.get('environment') or [''])[0],
            (query.get('proxmox_environment') or [''])[0],
        ])
        for header_name in ENVIRONMENT_HEADER_NAMES:
            candidates.append(self.headers.get(header_name, ''))
        for candidate in candidates:
            value = str(candidate or '').strip()
            if value:
                return value
        return DEFAULT_ENVIRONMENT

    def _resolve_environment(self, payload=None):
        env_name = self._environment_name_from_request(payload)
        if not PROXMOX_ENVIRONMENTS:
            return env_name, {}, {'error': 'No Proxmox environments are configured'}
        env_config = PROXMOX_ENVIRONMENTS.get(env_name)
        if env_config is None:
            return env_name, None, {
                'error': 'Unknown Proxmox environment',
                'environment': env_name,
                'available_environments': sorted(PROXMOX_ENVIRONMENTS),
            }
        return env_name, env_config, None

    def _path_with_environment(self, env_name):
        parsed = urllib.parse.urlparse(self.path)
        query = urllib.parse.parse_qs(parsed.query, keep_blank_values=True)
        query.pop('proxmox_environment', None)
        query['environment'] = [env_name]
        encoded = urllib.parse.urlencode(query, doseq=True)
        return urllib.parse.urlunparse(('', '', parsed.path, parsed.params, encoded, parsed.fragment))

    def _update_auth_status(self):
        if not UPDATE_API_KEY:
            return 503, {'error': 'Proxmox update key is not configured'}
        header_key = self.headers.get('X-FortisAI-Proxmox-Update-Key', '').strip()
        auth = self.headers.get('Authorization', '').strip()
        bearer = ''
        if auth.lower().startswith('bearer '):
            bearer = auth.split(None, 1)[1].strip()
        if header_key == UPDATE_API_KEY or bearer == UPDATE_API_KEY:
            return 200, {}
        return 401, {'error': 'Missing or invalid Proxmox update key'}

    def _require_update_auth(self):
        status, payload = self._update_auth_status()
        if status != 200:
            self._send_json(status, payload)
            return False
        return True

    def _positive_int(self, payload, key, minimum, maximum):
        if key not in payload or payload[key] in (None, ''):
            return None
        try:
            value = int(payload[key])
        except Exception:
            raise ValueError(key + ' must be an integer')
        if value < minimum or value > maximum:
            raise ValueError(key + ' must be between ' + str(minimum) + ' and ' + str(maximum))
        return value

    def _proxmox_request(self, method, path, form=None, environment_config=None):
        environment_config = environment_config or {}
        auth_config = proxmox_auth(environment_config)
        missing = []
        for name, value in {
            'PROXMOX_HOST': env_section(environment_config, 'proxmox').get('host') or PROXMOX_HOST,
            'PROXMOX_USER': auth_config['user'],
            'PROXMOX_TOKEN_NAME': auth_config['token_name'],
            'PROXMOX_TOKEN_VALUE': auth_config['token_value'],
        }.items():
            if not value:
                missing.append(name)
        if missing:
            return 500, {'error': 'Proxmox API configuration missing', 'missing': missing}

        data = None
        headers = {
            'Authorization': 'PVEAPIToken=' + auth_config['user'] + '!' + auth_config['token_name'] + '=' + auth_config['token_value'],
            'Accept': 'application/json',
        }
        if form is not None:
            data = urllib.parse.urlencode(form).encode('utf-8')
            headers['Content-Type'] = 'application/x-www-form-urlencoded'
        base_url = proxmox_base_url(environment_config)
        if not base_url:
            return 500, {'error': 'Proxmox API host is not configured'}
        url = base_url + '/api2/json' + path
        context = None if proxmox_verify_ssl(environment_config) else ssl._create_unverified_context()
        request = urllib.request.Request(url, data=data, headers=headers, method=method)
        try:
            with urllib.request.urlopen(request, timeout=30, context=context) as response:
                raw = response.read()
                return getattr(response, 'status', 200), json.loads(raw.decode('utf-8') or '{}')
        except urllib.error.HTTPError as exc:
            raw = exc.read()
            try:
                payload = json.loads(raw.decode('utf-8') or '{}')
            except Exception:
                payload = {'error': raw.decode('utf-8', errors='replace')}
            return exc.code, payload
        except Exception as exc:
            return 502, {'error': type(exc).__name__}

    def _guest_path(self, vm_type, node, vmid, suffix):
        node_q = urllib.parse.quote(str(node), safe='')
        vmid_q = urllib.parse.quote(str(vmid), safe='')
        return '/nodes/' + node_q + '/' + vm_type + '/' + vmid_q + '/' + suffix.lstrip('/')

    def _config_path(self, vm_type, node, vmid):
        return self._guest_path(vm_type, node, vmid, 'config')

    def _statistics_paths(self, vm_type, node, vmid, timeframe, cf):
        query = urllib.parse.urlencode({'timeframe': timeframe, 'cf': cf})
        return (
            self._guest_path(vm_type, node, vmid, 'status/current'),
            self._guest_path(vm_type, node, vmid, 'config'),
            self._guest_path(vm_type, node, vmid, 'rrddata') + '?' + query,
        )

    def _rrd_options(self, payload):
        timeframe = str(payload.get('timeframe') or 'hour').strip().lower()
        if timeframe not in {'hour', 'day', 'week', 'month', 'year'}:
            raise ValueError('timeframe must be one of hour, day, week, month, or year')
        cf = str(payload.get('cf') or 'AVERAGE').strip().upper()
        if cf not in {'AVERAGE', 'MAX'}:
            raise ValueError('cf must be AVERAGE or MAX')
        return timeframe, cf

    def _resolve_lxc_selectors(self, payload, environment_config):
        node = str(payload.get('node') or '').strip()
        vmid = str(payload.get('vmid') or '').strip()
        if node and vmid:
            return [{'node': node, 'vmid': vmid, 'selector': node + ':' + vmid}]
        selector_text = str(payload.get('selector') or '').strip()
        if not selector_text:
            raise ValueError('selector or node plus vmid is required')
        selectors = [item.strip() for item in selector_text.split(',') if item.strip()]
        status, resources = self._proxmox_request('GET', '/cluster/resources?type=vm', environment_config=environment_config)
        if status >= 400:
            raise RuntimeError('Unable to query Proxmox cluster resources')
        lxcs = [item for item in resources.get('data', []) if item.get('type') == 'lxc']
        resolved = []
        for selector in selectors:
            matches = []
            if ':' in selector and selector.rsplit(':', 1)[1].isdigit():
                sel_node, sel_vmid = selector.rsplit(':', 1)
                matches = [item for item in lxcs if str(item.get('node')) == sel_node and str(item.get('vmid')) == sel_vmid]
            elif '/' in selector:
                sel_node, sel_name = selector.split('/', 1)
                matches = [item for item in lxcs if str(item.get('node')) == sel_node and str(item.get('name')) == sel_name]
            elif selector.isdigit():
                matches = [item for item in lxcs if str(item.get('vmid')) == selector]
            else:
                matches = [item for item in lxcs if str(item.get('name')) == selector]
            if not matches:
                raise ValueError('No LXC container matched selector ' + selector)
            if len(matches) > 1:
                raise ValueError('Selector matched multiple LXC containers: ' + selector)
            item = matches[0]
            resolved.append({'node': str(item.get('node')), 'vmid': str(item.get('vmid')), 'selector': selector})
        return resolved

    def _bool_param(self, payload, key):
        if key not in payload or payload[key] in (None, ''):
            return None
        value = payload[key]
        if isinstance(value, bool):
            return value
        if isinstance(value, int) and value in (0, 1):
            return bool(value)
        text = str(value).strip().lower()
        if text in {'1', 'true', 'yes', 'on'}:
            return True
        if text in {'0', 'false', 'no', 'off'}:
            return False
        raise ValueError(key + ' must be a boolean')

    def _include_flag(self, payload, key, default):
        value = self._bool_param(payload, key)
        return default if value is None else value

    def _guest_statistics(self, vm_type, node, vmid, timeframe, cf, include_config=True, include_rrd=True, environment_name=None, environment_config=None):
        status_path, config_path, rrd_path = self._statistics_paths(vm_type, node, vmid, timeframe, cf)
        current_status, current = self._proxmox_request('GET', status_path, environment_config=environment_config)
        if current_status >= 400:
            return {
                'success': False,
                'environment': environment_name,
                'type': vm_type,
                'node': node,
                'vmid': vmid,
                'error': 'Unable to read current guest statistics',
                'status': current_status,
                'upstream': current,
            }
        result = {
            'success': True,
            'environment': environment_name,
            'type': vm_type,
            'node': node,
            'vmid': vmid,
            'timeframe': timeframe,
            'cf': cf,
            'current': current.get('data', current),
        }
        if include_config:
            config_status, config = self._proxmox_request('GET', config_path, environment_config=environment_config)
            result['config'] = config.get('data', config) if config_status < 400 else {'status': config_status, 'upstream': config}
        if include_rrd:
            rrd_status, rrd = self._proxmox_request('GET', rrd_path, environment_config=environment_config)
            result['rrddata'] = rrd.get('data', rrd) if rrd_status < 400 else {'status': rrd_status, 'upstream': rrd}
        return result

    def _handle_get_vm_statistics(self):
        try:
            payload = self._read_json()
            env_name, env_config, env_error = self._resolve_environment(payload)
            if env_error:
                self._send_json(400, env_error)
                return
            node = str(payload.get('node') or '').strip()
            vmid = str(payload.get('vmid') or '').strip()
            if not node or not vmid:
                self._send_json(400, {'error': 'node and vmid are required'})
                return
            if not vmid.isdigit():
                self._send_json(400, {'error': 'vmid must be numeric'})
                return
            timeframe, cf = self._rrd_options(payload)
            include_config = self._include_flag(payload, 'include_config', True)
            include_rrd = self._include_flag(payload, 'include_rrd', True)
        except ValueError as exc:
            self._send_json(400, {'error': str(exc)})
            return
        except Exception:
            self._send_json(400, {'error': 'Invalid JSON request body'})
            return
        result = self._guest_statistics('qemu', node, vmid, timeframe, cf, include_config, include_rrd, env_name, env_config)
        self._send_json(200 if result.get('success') else 502, result)

    def _handle_get_container_statistics(self):
        try:
            payload = self._read_json()
            env_name, env_config, env_error = self._resolve_environment(payload)
            if env_error:
                self._send_json(400, env_error)
                return
            targets = self._resolve_lxc_selectors(payload, env_config)
            timeframe, cf = self._rrd_options(payload)
            include_config = self._include_flag(payload, 'include_config', True)
            include_rrd = self._include_flag(payload, 'include_rrd', True)
        except ValueError as exc:
            self._send_json(400, {'error': str(exc)})
            return
        except Exception as exc:
            self._send_json(502, {'error': str(exc)})
            return
        results = []
        for target in targets:
            item = self._guest_statistics('lxc', target['node'], target['vmid'], timeframe, cf, include_config, include_rrd, env_name, env_config)
            item['selector'] = target.get('selector')
            results.append(item)
        self._send_json(200 if all(item.get('success') for item in results) else 207, {'environment': env_name, 'results': results})

    def _handle_create_vm_disk(self):
        if not self._require_update_auth():
            return
        try:
            payload = self._read_json()
            env_name, env_config, env_error = self._resolve_environment(payload)
            if env_error:
                self._send_json(400, env_error)
                return
        except Exception:
            self._send_json(400, {'error': 'Invalid JSON request body'})
            return
        node = str(payload.get('node') or '').strip()
        vmid = str(payload.get('vmid') or '').strip()
        disk = str(payload.get('disk') or '').strip()
        storage = str(payload.get('storage') or '').strip()
        if not node or not vmid or not disk or not storage:
            self._send_json(400, {'error': 'node, vmid, disk, and storage are required'})
            return
        if not vmid.isdigit():
            self._send_json(400, {'error': 'vmid must be numeric'})
            return
        if not re.fullmatch(r'(ide|sata|scsi|virtio)\d+', disk):
            self._send_json(400, {'error': 'disk must look like scsi1, virtio1, sata1, or ide1'})
            return
        if not re.fullmatch(r'[A-Za-z0-9_.-]+', storage):
            self._send_json(400, {'error': 'storage contains unsupported characters'})
            return
        try:
            size_gib = self._positive_int(payload, 'size_gib', 1, 1048576)
            iothread = self._bool_param(payload, 'iothread')
            ssd = self._bool_param(payload, 'ssd')
            backup = self._bool_param(payload, 'backup')
            replicate = self._bool_param(payload, 'replicate')
            overwrite = self._bool_param(payload, 'overwrite') or False
        except ValueError as exc:
            self._send_json(400, {'error': str(exc)})
            return
        if size_gib is None:
            self._send_json(400, {'error': 'size_gib is required'})
            return

        path = self._config_path('qemu', node, vmid)
        before_status, before = self._proxmox_request('GET', path, environment_config=env_config)
        if before_status >= 400:
            self._send_json(502, {'error': 'Unable to read current VM config', 'status': before_status, 'upstream': before})
            return
        before_config = before.get('data', before)
        if disk in before_config and not overwrite:
            self._send_json(409, {'error': 'Disk slot already exists', 'disk': disk, 'current': before_config.get(disk)})
            return

        disk_parts = [storage + ':' + str(size_gib)]
        for key in ['cache', 'discard']:
            value = str(payload.get(key) or '').strip()
            if value:
                if not re.fullmatch(r'[A-Za-z0-9_.-]+', value):
                    self._send_json(400, {'error': key + ' contains unsupported characters'})
                    return
                disk_parts.append(key + '=' + value)
        for key, value in [('iothread', iothread), ('ssd', ssd), ('backup', backup), ('replicate', replicate)]:
            if value is not None:
                disk_parts.append(key + '=' + ('1' if value else '0'))
        update = {disk: ','.join(disk_parts)}
        digest = str(payload.get('digest') or '').strip()
        if digest:
            update['digest'] = digest

        update_status, update_response = self._proxmox_request('POST', path, update, environment_config=env_config)
        if update_status >= 400:
            self._send_json(502, {'error': 'Unable to create VM disk', 'status': update_status, 'upstream': update_response, 'requested': update})
            return
        after_status, after = self._proxmox_request('GET', path, environment_config=env_config)
        self._send_json(200, {
            'success': True,
            'environment': env_name,
            'type': 'qemu',
            'node': node,
            'vmid': vmid,
            'disk': disk,
            'requested': {k: v for k, v in update.items() if k != 'digest'},
            'before': before_config,
            'after': after.get('data', after) if after_status < 400 else {'status': after_status, 'upstream': after},
            'upstream': update_response,
            'restart_note': 'Disk hotplug is expected when VM hotplug includes disk; otherwise restart the VM before the guest sees the new disk.',
        })

    def _handle_update_vm_resources(self):
        if not self._require_update_auth():
            return
        try:
            payload = self._read_json()
            env_name, env_config, env_error = self._resolve_environment(payload)
            if env_error:
                self._send_json(400, env_error)
                return
        except Exception:
            self._send_json(400, {'error': 'Invalid JSON request body'})
            return
        node = str(payload.get('node') or '').strip()
        vmid = str(payload.get('vmid') or '').strip()
        if not node or not vmid:
            self._send_json(400, {'error': 'node and vmid are required'})
            return
        if not vmid.isdigit():
            self._send_json(400, {'error': 'vmid must be numeric'})
            return
        try:
            update = {}
            for key, minimum, maximum in [('sockets', 1, 16), ('cores', 1, 256), ('memory', 256, 1048576)]:
                value = self._positive_int(payload, key, minimum, maximum)
                if value is not None:
                    update[key] = value
        except ValueError as exc:
            self._send_json(400, {'error': str(exc)})
            return
        digest = str(payload.get('digest') or '').strip()
        if digest:
            update['digest'] = digest
        if not update or set(update) == {'digest'}:
            self._send_json(400, {'error': 'At least one of sockets, cores, or memory is required'})
            return
        path = self._config_path('qemu', node, vmid)
        before_status, before = self._proxmox_request('GET', path, environment_config=env_config)
        if before_status >= 400:
            self._send_json(502, {'error': 'Unable to read current VM config', 'status': before_status, 'upstream': before})
            return
        update_status, update_response = self._proxmox_request('PUT', path, update, environment_config=env_config)
        if update_status >= 400:
            self._send_json(502, {'error': 'Unable to update VM resources', 'status': update_status, 'upstream': update_response})
            return
        after_status, after = self._proxmox_request('GET', path, environment_config=env_config)
        self._send_json(200, {
            'success': True,
            'environment': env_name,
            'type': 'qemu',
            'node': node,
            'vmid': vmid,
            'requested': {k: v for k, v in update.items() if k != 'digest'},
            'before': before.get('data', before),
            'after': after.get('data', after) if after_status < 400 else {'status': after_status, 'upstream': after},
            'restart_note': 'A guest reboot or VM restart may be required before changed CPU and memory resources are active.',
        })

    def _handle_update_container_resources(self):
        if not self._require_update_auth():
            return
        try:
            payload = self._read_json()
            env_name, env_config, env_error = self._resolve_environment(payload)
            if env_error:
                self._send_json(400, env_error)
                return
            targets = self._resolve_lxc_selectors(payload, env_config)
        except ValueError as exc:
            self._send_json(400, {'error': str(exc)})
            return
        except Exception as exc:
            self._send_json(502, {'error': str(exc)})
            return
        try:
            config_update = {}
            for key, minimum, maximum in [('cores', 1, 256), ('memory', 16, 1048576), ('swap', 0, 1048576)]:
                value = self._positive_int(payload, key, minimum, maximum)
                if value is not None:
                    config_update[key] = value
            disk_gb = self._positive_int(payload, 'disk_gb', 1, 1048576)
        except ValueError as exc:
            self._send_json(400, {'error': str(exc)})
            return
        digest = str(payload.get('digest') or '').strip()
        if digest:
            config_update['digest'] = digest
        if not config_update and disk_gb is None:
            self._send_json(400, {'error': 'At least one of cores, memory, swap, or disk_gb is required'})
            return
        disk = str(payload.get('disk') or 'rootfs').strip() or 'rootfs'
        results = []
        for target in targets:
            node = target['node']
            vmid = target['vmid']
            path = self._config_path('lxc', node, vmid)
            before_status, before = self._proxmox_request('GET', path, environment_config=env_config)
            if before_status >= 400:
                results.append({'success': False, 'node': node, 'vmid': vmid, 'error': 'Unable to read current container config', 'status': before_status, 'upstream': before})
                continue
            update_status = 200
            update_response = {'data': None}
            if config_update:
                update_status, update_response = self._proxmox_request('PUT', path, config_update, environment_config=env_config)
            resize_status = 200
            resize_response = {'data': None}
            if update_status < 400 and disk_gb is not None:
                resize_path = '/nodes/' + urllib.parse.quote(node, safe='') + '/lxc/' + urllib.parse.quote(vmid, safe='') + '/resize'
                resize_status, resize_response = self._proxmox_request('PUT', resize_path, {'disk': disk, 'size': '+' + str(disk_gb) + 'G'}, environment_config=env_config)
            after_status, after = self._proxmox_request('GET', path, environment_config=env_config)
            success = update_status < 400 and resize_status < 400
            requested = {k: v for k, v in config_update.items() if k != 'digest'}
            if disk_gb is not None:
                requested.update({'disk': disk, 'disk_gb': disk_gb})
            results.append({
                'success': success,
                'environment': env_name,
                'type': 'lxc',
                'selector': target.get('selector'),
                'node': node,
                'vmid': vmid,
                'requested': requested,
                'before': before.get('data', before),
                'after': after.get('data', after) if after_status < 400 else {'status': after_status, 'upstream': after},
                'update_status': update_status,
                'resize_status': resize_status,
                'upstream': {'config': update_response, 'resize': resize_response},
                'restart_note': 'A container restart may be required before changed resources are active.',
            })
        self._send_json(200 if all(item.get('success') for item in results) else 207, {'environment': env_name, 'results': results})

    def _proxy(self):
        path = self.path.split('?', 1)[0]
        if is_mutating_proxy_path(path) and not self._require_update_auth():
            return
        body = None
        upstream_path = self.path
        env_name = DEFAULT_ENVIRONMENT
        request_payload = None
        if self.command in {'POST', 'PUT', 'PATCH', 'DELETE'}:
            length = int(self.headers.get('Content-Length', '0') or '0')
            body = self.rfile.read(length) if length else b''
            content_type = self.headers.get('Content-Type', '')
            if body and 'json' in content_type.lower():
                try:
                    payload = json.loads(body.decode('utf-8'))
                    if isinstance(payload, dict):
                        request_payload = payload
                except Exception:
                    pass

        env_name, env_config, env_error = self._resolve_environment(request_payload)
        if env_error and path not in {'/openapi.json', '/livez', '/healthz'}:
            self._send_json(400, env_error)
            return

        if isinstance(request_payload, dict):
            request_payload.pop('proxmox_environment', None)
            request_payload['environment'] = env_name
            body = json.dumps(request_payload, separators=(',', ':')).encode('utf-8')
        elif path not in {'/openapi.json', '/livez', '/healthz'}:
            upstream_path = self._path_with_environment(env_name)

        headers = {
            key: value
            for key, value in self.headers.items()
            if key.lower() not in HOP_BY_HOP and key.lower() not in {'authorization', 'content-length'}
        }
        if API_KEY:
            headers['Authorization'] = 'Bearer ' + API_KEY

        request = urllib.request.Request(UPSTREAM + upstream_path, data=body, headers=headers, method=self.command)
        try:
            with urllib.request.urlopen(request, timeout=30) as response:
                payload = response.read()
                status = getattr(response, 'status', 200)
                content_type = response.headers.get('Content-Type', 'application/json')
        except urllib.error.HTTPError as exc:
            payload = exc.read()
            status = exc.code
            content_type = exc.headers.get('Content-Type', 'application/json')
        except Exception as exc:
            payload = json.dumps({'detail': 'Proxmox upstream unavailable', 'error': type(exc).__name__}).encode('utf-8')
            status = 502
            content_type = 'application/json'

        if self.command == 'GET' and self.path.split('?', 1)[0] == '/openapi.json' and status == 200:
            payload, content_type = public_openapi(payload)

        self.send_response(status)
        self.send_header('Content-Type', content_type)
        self.send_header('Content-Length', str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def do_GET(self):
        self._proxy()

    def do_POST(self):
        path = self.path.split('?', 1)[0]
        if path == '/get_vm_statistics':
            self._handle_get_vm_statistics()
            return
        if path == '/get_container_statistics':
            self._handle_get_container_statistics()
            return
        if path == '/update_vm_resources':
            self._handle_update_vm_resources()
            return
        if path == '/update_container_resources':
            self._handle_update_container_resources()
            return
        if path == '/create_vm_disk':
            self._handle_create_vm_disk()
            return
        self._proxy()

    def do_PUT(self):
        self._proxy()

    def do_PATCH(self):
        self._proxy()

    def do_DELETE(self):
        self._proxy()

class ReusableTCPServer(socketserver.TCPServer):
    allow_reuse_address = True

with ReusableTCPServer(('0.0.0.0', PORT), Handler) as server:
    server.serve_forever()
