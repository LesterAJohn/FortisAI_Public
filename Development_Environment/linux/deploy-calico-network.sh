#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEV_ENV_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
FORTISAI_DEV_HOME="${FORTISAI_DEV_HOME:-$HOME/fortisai-dev}"
WATCHDOG_DIR="${FORTISAI_WATCHDOG_DIR:-$FORTISAI_DEV_HOME/watchdog}"
ACTIVE_HOSTS_SEED_FILE="${FORTISAI_ACTIVE_HOSTS_SEED_FILE:-$SCRIPT_DIR/active_host.json}"
ACTIVE_HOSTS_FILE="${ACTIVE_HOSTS_FILE:-${FORTISAI_ACTIVE_HOSTS_FILE:-$WATCHDOG_DIR/active_host.json}}"

CALICO_NETWORK_NAME="${FORTISAI_CALICO_NETWORK_NAME:-fortisai-calico-net}"
CALICO_DNS_ZONE="${FORTISAI_CALICO_DNS_ZONE:-fortisai.local}"
COREDNS_CONTAINER_NAME="${FORTISAI_COREDNS_CONTAINER_NAME:-fortisai-coredns}"
COREDNS_IMAGE="${FORTISAI_COREDNS_IMAGE:-docker.io/coredns/coredns:latest}"
COREDNS_PORT="${FORTISAI_COREDNS_PORT:-1053}"
CALICO_MODE="${FORTISAI_CALICO_MODE:-netavark-compatible}"
RUN_TEST="true"
LOCAL_ONLY="false"
ONLY_HOST=""
SYNC_CLUSTER_DNS="true"
SYNC_DNS_ONLY="false"

log() {
  printf '%s\n' "[fortisai-calico] $*"
}

err() {
  printf '%s\n' "[fortisai-calico] ERROR: $*" >&2
}

usage() {
  cat <<EOF
FortisAI Calico/CoreDNS deployment helper

Usage:
  $(basename "$0") [--host HOST] [--local-only] [--test|--no-test]
  $(basename "$0") --sync-dns-only

Options:
  --host HOST      Deploy only the matching host from the runtime active_host.json.
  --local-only     Deploy only on the current host.
  --test           Run container registration/deregistration smoke tests (default).
  --no-test        Install/start only; used by the main FortisAI helper.
  --sync-dns-only  Refresh and redistribute the shared CoreDNS records only.
  --no-sync-dns    Skip shared CoreDNS redistribution after deploy.

Environment:
  ACTIVE_HOSTS_FILE                 Default: ~/fortisai-dev/watchdog/active_host.json
  FORTISAI_ACTIVE_HOSTS_FILE        Alternate runtime active_host.json override
  FORTISAI_WATCHDOG_DIR             Default: ~/fortisai-dev/watchdog
  FORTISAI_CALICO_NETWORK_NAME      Default: fortisai-calico-net
  FORTISAI_CALICO_DNS_ZONE          Default: fortisai.local
  FORTISAI_COREDNS_CONTAINER_NAME   Default: fortisai-coredns
  FORTISAI_COREDNS_IMAGE            Default: docker.io/coredns/coredns:latest
  FORTISAI_COREDNS_PORT             Default: 1053
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)
      ONLY_HOST="${2:-}"
      [[ -n "$ONLY_HOST" ]] || { err "--host requires a value"; exit 1; }
      shift 2
      ;;
    --local-only)
      LOCAL_ONLY="true"
      shift
      ;;
    --test)
      RUN_TEST="true"
      shift
      ;;
    --no-test)
      RUN_TEST="false"
      shift
      ;;
    --sync-dns-only)
      SYNC_DNS_ONLY="true"
      RUN_TEST="false"
      shift
      ;;
    --no-sync-dns)
      SYNC_CLUSTER_DNS="false"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      err "Unknown option: $1"
      usage >&2
      exit 1
      ;;
  esac
done

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    err "Required command not found: $1"
    exit 1
  fi
}

ensure_active_hosts_file() {
  mkdir -p "$(dirname "$ACTIVE_HOSTS_FILE")"
  if [[ -f "$ACTIVE_HOSTS_FILE" ]]; then
    return 0
  fi
  if [[ ! -f "$ACTIVE_HOSTS_SEED_FILE" ]]; then
    err "Active host seed file is missing: $ACTIVE_HOSTS_SEED_FILE"
    exit 1
  fi
  cp "$ACTIVE_HOSTS_SEED_FILE" "$ACTIVE_HOSTS_FILE"
}

short_name() {
  printf '%s\n' "$1" | awk -F. '{print tolower($1)}'
}

shell_quote() {
  local value="$1"
  printf "'%s'" "${value//\'/\'\\\'\'}"
}

local_short_hostname() {
  local host
  host="$(hostname -s 2>/dev/null || hostname 2>/dev/null || true)"
  short_name "$host"
}

host_is_local() {
  local candidate
  candidate="$(short_name "$1")"
  case "$candidate" in
    ""|localhost|127|127.0.0.1)
      return 0
      ;;
  esac
  [[ "$candidate" == "$(local_short_hostname)" ]]
}

host_ssh_args() {
  local identity="$1"
  printf '%s\n' "-o"
  printf '%s\n' "BatchMode=yes"
  printf '%s\n' "-o"
  printf '%s\n' "ConnectTimeout=15"
  if [[ -n "$identity" && -f "$identity" ]]; then
    printf '%s\n' "-i"
    printf '%s\n' "$identity"
  fi
}

host_run() {
  local hostname="$1"
  local userid="$2"
  local identity="$3"
  local command="$4"
  local target="$userid@$hostname"

  if host_is_local "$hostname"; then
    bash -lc "$command"
  else
    local -a ssh_args
    mapfile -t ssh_args < <(host_ssh_args "$identity")
    ssh "${ssh_args[@]}" "$target" "$command"
  fi
}

host_rows() {
  require_cmd python3
  ensure_active_hosts_file
  python3 - "$ACTIVE_HOSTS_FILE" "$ONLY_HOST" "$LOCAL_ONLY" "$(local_short_hostname)" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
only_host = sys.argv[2].strip().lower()
local_only = sys.argv[3].lower() == "true"
local_short = sys.argv[4].lower()

if not path.exists():
    if local_only or not only_host:
        print(f"{local_short}\t{local_short}\t{__import__('getpass').getuser()}\t")
    raise SystemExit(0)

payload = json.loads(path.read_text())
hosts = payload.get("hosts", {})
for key in sorted(hosts):
    entry = hosts[key] or {}
    hostname = str(entry.get("hostname") or key)
    short = hostname.split(".", 1)[0].lower()
    key_short = str(key).split(".", 1)[0].lower()
    if only_host and only_host not in {key.lower(), key_short, hostname.lower(), short}:
        continue
    if local_only and local_short not in {key_short, short}:
        continue
    userid = str(entry.get("userid") or entry.get("user") or "aiuser")
    connectivity = entry.get("connectivity") or {}
    identity = str(connectivity.get("ssh_identity") or entry.get("ssh_identity") or "")
    print(f"{key}\t{hostname}\t{userid}\t{identity}")
PY
}

remote_payload() {
  cat <<'REMOTE'
set -euo pipefail

log() {
  printf '%s\n' "[fortisai-calico:${HOSTNAME:-host}] $*"
}

err() {
  printf '%s\n' "[fortisai-calico:${HOSTNAME:-host}] ERROR: $*" >&2
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    err "Required command not found: $1"
    exit 1
  fi
}

sudo_run() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
    return $?
  fi
  if sudo -n true >/dev/null 2>&1; then
    sudo "$@"
    return $?
  fi
  if [[ -n "${FORTISAI_SUDO_PASSWORD:-}" ]]; then
    printf '%s\n' "$FORTISAI_SUDO_PASSWORD" | sudo -S -p '' "$@"
    return $?
  fi
  return 1
}

register_dns_records() {
  local network_name="$1"
  local zone="$2"
  local local_hosts_file="$3"

  mkdir -p "$(dirname "$local_hosts_file")"
  python3 - "$network_name" "$zone" "$local_hosts_file" <<'PY'
import json
import re
import subprocess
import sys
from pathlib import Path

network_name, zone, hosts_file = sys.argv[1:4]
zone = zone.strip(".")
path = Path(hosts_file)

def clean_name(value):
    value = str(value or "").strip().strip("/")
    value = re.sub(r"[^A-Za-z0-9_.-]+", "-", value)
    value = value.strip(".-")
    if not value:
        return ""
    return value[:63] if "." not in value else value[:253]

try:
    ids = subprocess.check_output(
        ["podman", "ps", "--format", "{{.ID}}"],
        text=True,
        stderr=subprocess.DEVNULL,
    ).splitlines()
except Exception:
    ids = []

records = {}
if ids:
    try:
        inspected = json.loads(subprocess.check_output(["podman", "inspect", *ids], text=True))
    except Exception:
        inspected = []

    for item in inspected:
        networks = ((item.get("NetworkSettings") or {}).get("Networks") or {})
        net = networks.get(network_name)
        if not isinstance(net, dict):
            continue
        ip = net.get("IPAddress") or net.get("GlobalIPv6Address") or ""
        if not ip:
            continue
        names = set()
        names.add(item.get("Name", ""))
        labels = ((item.get("Config") or {}).get("Labels") or {})
        names.add(labels.get("io.podman.pod.name", ""))
        for alias in net.get("Aliases") or []:
            names.add(alias)
        cleaned = []
        for name in names:
            name = clean_name(name)
            if not name:
                continue
            cleaned.append(name)
            if zone and not name.endswith("." + zone):
                cleaned.append(f"{name}.{zone}")
        if cleaned:
            records.setdefault(ip, set()).update(cleaned)

lines = [
    "# Generated by FortisAI Podman/CoreDNS registration.",
    "# Edits are replaced automatically.",
]
for ip in sorted(records):
    names = sorted(records[ip])
    lines.append(f"{ip} {' '.join(names)}")

path.write_text("\n".join(lines) + "\n")
PY
}

merge_dns_records() {
  local local_hosts_file="$1"
  local cluster_hosts_file="$2"
  local merged_hosts_file="$3"

  mkdir -p "$(dirname "$merged_hosts_file")"
  python3 - "$local_hosts_file" "$cluster_hosts_file" "$merged_hosts_file" <<'PY'
import sys
from pathlib import Path

local_hosts, cluster_hosts, merged_hosts = (Path(item) for item in sys.argv[1:4])
seen = set()
records = []
for path in (local_hosts, cluster_hosts):
    if not path.exists():
        continue
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if line in seen:
            continue
        seen.add(line)
        records.append(line)

lines = [
    "# Generated by FortisAI multi-host Podman/CoreDNS registration.",
    "# Edits are replaced automatically.",
    *sorted(records),
]
merged_hosts.parent.mkdir(parents=True, exist_ok=True)
merged_hosts.write_text("\n".join(lines) + "\n", encoding="utf-8")
PY
}

network_subnet() {
  local network_name="$1"
  local inspect_json
  inspect_json="$(podman network inspect "$network_name" --format '{{json .}}' 2>/dev/null || true)"
  python3 - "$inspect_json" <<'PY'
import json
import sys

try:
    payload = json.loads(sys.argv[1] or "{}")
except Exception:
    payload = {}
if isinstance(payload, list):
    payload = payload[0] if payload else {}
for item in payload.get("subnets") or []:
    subnet = item.get("subnet")
    if subnet and "." in subnet:
        print(subnet)
        raise SystemExit(0)
PY
}

coredns_ip_for_subnet() {
  local subnet="$1"
  [[ -n "$subnet" ]] || return 0
  python3 - "$subnet" "${FORTISAI_COREDNS_IP_OFFSET:-53}" <<'PY'
import ipaddress
import sys

network = ipaddress.ip_network(sys.argv[1], strict=False)
offset = int(sys.argv[2])
candidate = network.network_address + offset
if candidate not in network:
    candidate = network.network_address + 10
print(candidate)
PY
}

update_network_dns() {
  local network_name="$1"
  local coredns_ip="$2"
  if [[ -z "$coredns_ip" ]]; then
    return 0
  fi
  podman network update --dns-add "$coredns_ip" "$network_name" >/dev/null 2>&1 || true
}

wait_for_coredns() {
  local network_name="$1"
  local coredns_ip="$2"
  local coredns_container="$3"
  local zone="$4"
  local lookup_name="$coredns_container"
  local attempt

  if [[ -n "$zone" ]]; then
    lookup_name="$lookup_name.$zone"
  fi
  if [[ -z "$coredns_ip" ]]; then
    sleep 2
    return 0
  fi

  for attempt in $(seq 1 60); do
    if podman run --rm --network "$network_name" docker.io/library/alpine:latest \
        sh -lc "nslookup '$lookup_name' >/dev/null 2>&1 && nslookup '$lookup_name' '$coredns_ip' >/dev/null 2>&1" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done

  err "CoreDNS did not become queryable through $network_name within the readiness window"
  return 1
}

write_runtime_files() {
  local runtime_dir="$1"
  local network_name="$2"
  local zone="$3"
  local coredns_port="$4"
  local coredns_container="$5"
  local coredns_image="$6"
  local calico_mode="$7"
  local cluster_routes_json="$8"

  local calico_dir="$runtime_dir/calico"
  local coredns_dir="$runtime_dir/coredns"
  mkdir -p "$calico_dir" "$coredns_dir"

  cat > "$calico_dir/calico-network.env" <<EOF
FORTISAI_CALICO_ENABLED=true
FORTISAI_CALICO_MODE=$calico_mode
FORTISAI_CALICO_NETWORK_NAME=$network_name
FORTISAI_CALICO_DNS_ZONE=$zone
FORTISAI_COREDNS_CONTAINER_NAME=$coredns_container
FORTISAI_COREDNS_IMAGE=$coredns_image
FORTISAI_COREDNS_PORT=$coredns_port
EOF

  cat > "$coredns_dir/Corefile" <<EOF
.:53 {
    errors
    health :18054
    ready :18055
    hosts /etc/coredns/fortisai.hosts {
        ttl 5
        reload 2s
        fallthrough
    }
    forward . 1.1.1.1 8.8.8.8
    cache 5
    reload 2s
}
EOF

  touch "$coredns_dir/fortisai.local.hosts" "$coredns_dir/fortisai.cluster.hosts" "$coredns_dir/fortisai.hosts"
  if [[ -n "$cluster_routes_json" && "$cluster_routes_json" != "[]" ]]; then
    printf '%s\n' "$cluster_routes_json" > "$calico_dir/cluster-routes.json"
  elif [[ ! -f "$calico_dir/cluster-routes.json" ]]; then
    printf '[]\n' > "$calico_dir/cluster-routes.json"
  fi

  cat > "$coredns_dir/register-podman-dns.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

NETWORK_NAME="${FORTISAI_CALICO_NETWORK_NAME:-fortisai-calico-net}"
DNS_ZONE="${FORTISAI_CALICO_DNS_ZONE:-fortisai.local}"
LOCAL_HOSTS_FILE="${FORTISAI_COREDNS_LOCAL_HOSTS_FILE:-$HOME/fortisai-dev/coredns/fortisai.local.hosts}"

python3 - "$NETWORK_NAME" "$DNS_ZONE" "$LOCAL_HOSTS_FILE" <<'PY'
import json
import re
import subprocess
import sys
from pathlib import Path

network_name, zone, hosts_file = sys.argv[1:4]
zone = zone.strip(".")
path = Path(hosts_file)

def clean_name(value):
    value = str(value or "").strip().strip("/")
    value = re.sub(r"[^A-Za-z0-9_.-]+", "-", value)
    value = value.strip(".-")
    if not value:
        return ""
    return value[:63] if "." not in value else value[:253]

try:
    ids = subprocess.check_output(["podman", "ps", "--format", "{{.ID}}"], text=True, stderr=subprocess.DEVNULL).splitlines()
except Exception:
    ids = []

records = {}
if ids:
    try:
        inspected = json.loads(subprocess.check_output(["podman", "inspect", *ids], text=True))
    except Exception:
        inspected = []
    for item in inspected:
        networks = ((item.get("NetworkSettings") or {}).get("Networks") or {})
        net = networks.get(network_name)
        if not isinstance(net, dict):
            continue
        ip = net.get("IPAddress") or net.get("GlobalIPv6Address") or ""
        if not ip:
            continue
        names = set()
        names.add(item.get("Name", ""))
        labels = ((item.get("Config") or {}).get("Labels") or {})
        names.add(labels.get("io.podman.pod.name", ""))
        for alias in net.get("Aliases") or []:
            names.add(alias)
        cleaned = []
        for name in names:
            name = clean_name(name)
            if not name:
                continue
            cleaned.append(name)
            if zone and not name.endswith("." + zone):
                cleaned.append(f"{name}.{zone}")
        if cleaned:
            records.setdefault(ip, set()).update(cleaned)

lines = [
    "# Generated by FortisAI Podman/CoreDNS registration.",
    "# Edits are replaced automatically.",
]
for ip in sorted(records):
    lines.append(f"{ip} {' '.join(sorted(records[ip]))}")
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text("\n".join(lines) + "\n")
PY
EOF
  chmod +x "$coredns_dir/register-podman-dns.sh"

  cat > "$coredns_dir/merge-coredns-hosts.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

LOCAL_HOSTS_FILE="${FORTISAI_COREDNS_LOCAL_HOSTS_FILE:-$HOME/fortisai-dev/coredns/fortisai.local.hosts}"
CLUSTER_HOSTS_FILE="${FORTISAI_COREDNS_CLUSTER_HOSTS_FILE:-$HOME/fortisai-dev/coredns/fortisai.cluster.hosts}"
HOSTS_FILE="${FORTISAI_COREDNS_HOSTS_FILE:-$HOME/fortisai-dev/coredns/fortisai.hosts}"

python3 - "$LOCAL_HOSTS_FILE" "$CLUSTER_HOSTS_FILE" "$HOSTS_FILE" <<'PY'
import sys
from pathlib import Path

local_hosts, cluster_hosts, merged_hosts = (Path(item) for item in sys.argv[1:4])
seen = set()
records = []
for path in (local_hosts, cluster_hosts):
    if not path.exists():
        continue
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if line in seen:
            continue
        seen.add(line)
        records.append(line)

lines = [
    "# Generated by FortisAI multi-host Podman/CoreDNS registration.",
    "# Edits are replaced automatically.",
    *sorted(records),
]
merged_hosts.parent.mkdir(parents=True, exist_ok=True)
merged_hosts.write_text("\n".join(lines) + "\n", encoding="utf-8")
PY
EOF
  chmod +x "$coredns_dir/merge-coredns-hosts.sh"

  cat > "$coredns_dir/watch-podman-dns.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

REGISTER_SCRIPT="${FORTISAI_COREDNS_REGISTER_SCRIPT:-$HOME/fortisai-dev/coredns/register-podman-dns.sh}"
MERGE_SCRIPT="${FORTISAI_COREDNS_MERGE_SCRIPT:-$HOME/fortisai-dev/coredns/merge-coredns-hosts.sh}"

while true; do
  "$REGISTER_SCRIPT" || true
  "$MERGE_SCRIPT" || true
  podman events \
    --filter type=container \
    --filter event=start \
    --filter event=stop \
    --filter event=die \
    --filter event=remove \
    --stream \
    --format '{{.Status}}' 2>/dev/null | while IFS= read -r _event; do
      "$REGISTER_SCRIPT" || true
      "$MERGE_SCRIPT" || true
    done
  sleep 2
done
EOF
  chmod +x "$coredns_dir/watch-podman-dns.sh"

  cat > "$calico_dir/apply-routes.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail

ROUTES_JSON="\${FORTISAI_CALICO_CLUSTER_ROUTES_JSON:-$calico_dir/cluster-routes.json}"

if [[ -f "\$ROUTES_JSON" ]]; then
  ROUTES_PAYLOAD="\$(cat "\$ROUTES_JSON")"
else
  ROUTES_PAYLOAD="\$ROUTES_JSON"
fi

sysctl -w net.ipv4.ip_forward=1 >/dev/null

python3 - "\$ROUTES_PAYLOAD" <<'PY' | while IFS=\$'\t' read -r subnet via; do
import json
import sys

try:
    routes = json.loads(sys.argv[1] or "[]")
except Exception:
    routes = []

for route in routes:
    subnet = str(route.get("subnet") or "").strip()
    via = str(route.get("via") or "").strip()
    if subnet and via:
        print(f"{subnet}\t{via}")
PY
  [[ -n "\$subnet" && -n "\$via" ]] || continue
  ip route replace "\$subnet" via "\$via"
done
EOF
  chmod +x "$calico_dir/apply-routes.sh"

  cat > "$calico_dir/install-route-service.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail

SERVICE_FILE="/etc/systemd/system/fortisai-calico-routes.service"
SYSCTL_FILE="/etc/sysctl.d/99-fortisai-calico.conf"
ROUTE_SCRIPT="$calico_dir/apply-routes.sh"

sudo_run() {
  if [[ "\$(id -u)" -eq 0 ]]; then
    "\$@"
    return \$?
  fi
  if sudo -n true >/dev/null 2>&1; then
    sudo "\$@"
    return \$?
  fi
  if [[ -n "\${FORTISAI_SUDO_PASSWORD:-}" ]]; then
    printf '%s\n' "\$FORTISAI_SUDO_PASSWORD" | sudo -S -p '' "\$@"
    return \$?
  fi
  return 1
}

tmp_service="\$(mktemp)"
tmp_sysctl="\$(mktemp)"
cat > "\$tmp_service" <<SERVICE
[Unit]
Description=FortisAI routed Calico-compatible Podman network routes
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
ExecStart=\$ROUTE_SCRIPT
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
SERVICE
cat > "\$tmp_sysctl" <<SYSCTL
net.ipv4.ip_forward = 1
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.rp_filter = 0
SYSCTL

sudo_run install -m 0644 "\$tmp_service" "\$SERVICE_FILE"
sudo_run install -m 0644 "\$tmp_sysctl" "\$SYSCTL_FILE"
sudo_run "\$ROUTE_SCRIPT"
sudo_run systemctl daemon-reload
sudo_run systemctl enable --now fortisai-calico-routes.service >/dev/null
rm -f "\$tmp_service" "\$tmp_sysctl"
EOF
  chmod +x "$calico_dir/install-route-service.sh"
}

ensure_network() {
  local network_name="$1"
  local calico_mode="$2"

  if podman network exists "$network_name" >/dev/null 2>&1; then
    log "Network already exists: $network_name"
    return 0
  fi

  log "Creating Calico network: $network_name ($calico_mode)"
  if ! podman network create \
      --label io.fortisai.network.role=calico \
      --label io.fortisai.calico.mode="$calico_mode" \
      "$network_name" >/dev/null 2>&1; then
    podman network create "$network_name" >/dev/null
  fi
}

start_coredns() {
  local runtime_dir="$1"
  local network_name="$2"
  local coredns_container="$3"
  local coredns_image="$4"
  local coredns_port="$5"

  local coredns_dir="$runtime_dir/coredns"
  local subnet coredns_ip
  local -a run_cmd

  subnet="$(network_subnet "$network_name" || true)"
  coredns_ip="$(coredns_ip_for_subnet "$subnet" || true)"

  register_dns_records "$network_name" "${FORTISAI_CALICO_DNS_ZONE:-fortisai.local}" "$coredns_dir/fortisai.local.hosts"
  merge_dns_records "$coredns_dir/fortisai.local.hosts" "$coredns_dir/fortisai.cluster.hosts" "$coredns_dir/fortisai.hosts"

  log "Starting CoreDNS container: $coredns_container"
  podman rm -f "$coredns_container" >/dev/null 2>&1 || true
  run_cmd=(
    podman run -d
    --name "$coredns_container" \
    --network "$network_name" \
  )
  if [[ -n "$coredns_ip" ]]; then
    run_cmd+=(--ip "$coredns_ip")
  fi
  run_cmd+=(
    --network-alias "$coredns_container" \
    -p "127.0.0.1:$coredns_port:53/udp" \
    -p "127.0.0.1:$coredns_port:53/tcp" \
    -v "$coredns_dir/Corefile:/Corefile:ro" \
    -v "$coredns_dir/fortisai.hosts:/etc/coredns/fortisai.hosts:ro" \
    "$coredns_image" -conf /Corefile
  )
  "${run_cmd[@]}" >/dev/null

  update_network_dns "$network_name" "$coredns_ip"

  register_dns_records "$network_name" "${FORTISAI_CALICO_DNS_ZONE:-fortisai.local}" "$coredns_dir/fortisai.local.hosts"
  merge_dns_records "$coredns_dir/fortisai.local.hosts" "$coredns_dir/fortisai.cluster.hosts" "$coredns_dir/fortisai.hosts"
  wait_for_coredns "$network_name" "$coredns_ip" "$coredns_container" "${FORTISAI_CALICO_DNS_ZONE:-fortisai.local}"
}

install_route_service() {
  local runtime_dir="$1"
  local cluster_routes_json="$2"
  local calico_dir="$runtime_dir/calico"

  if [[ -z "$cluster_routes_json" || "$cluster_routes_json" == "[]" ]]; then
    log "No peer Calico routes to install on this host"
    return 0
  fi

  printf '%s\n' "$cluster_routes_json" > "$calico_dir/cluster-routes.json"
  if "$calico_dir/install-route-service.sh"; then
    log "Installed persistent routed Calico routes"
  else
    log "Warning: could not install persistent routed Calico routes; run $calico_dir/install-route-service.sh with sudo access"
  fi
}

start_registration_watcher() {
  local runtime_dir="$1"
  local network_name="$2"
  local zone="$3"
  local coredns_dir="$runtime_dir/coredns"
  local service_dir="$HOME/.config/systemd/user"
  local service_file="$service_dir/fortisai-coredns-register.service"

  if command -v systemctl >/dev/null 2>&1 && systemctl --user status >/dev/null 2>&1; then
    mkdir -p "$service_dir"
    cat > "$service_file" <<EOF
[Unit]
Description=FortisAI CoreDNS Podman auto-registration
After=podman.socket

[Service]
Type=simple
Environment=FORTISAI_CALICO_NETWORK_NAME=$network_name
Environment=FORTISAI_CALICO_DNS_ZONE=$zone
Environment=FORTISAI_COREDNS_HOSTS_FILE=$coredns_dir/fortisai.hosts
Environment=FORTISAI_COREDNS_LOCAL_HOSTS_FILE=$coredns_dir/fortisai.local.hosts
Environment=FORTISAI_COREDNS_CLUSTER_HOSTS_FILE=$coredns_dir/fortisai.cluster.hosts
Environment=FORTISAI_COREDNS_REGISTER_SCRIPT=$coredns_dir/register-podman-dns.sh
Environment=FORTISAI_COREDNS_MERGE_SCRIPT=$coredns_dir/merge-coredns-hosts.sh
ExecStart=$coredns_dir/watch-podman-dns.sh
Restart=always
RestartSec=2

[Install]
WantedBy=default.target
EOF
    systemctl --user daemon-reload
    systemctl --user enable --now fortisai-coredns-register.service >/dev/null
    log "CoreDNS registration watcher active through user systemd"
  else
    local pid_file="$coredns_dir/watch-podman-dns.pid"
    if [[ -f "$pid_file" ]] && kill -0 "$(cat "$pid_file")" >/dev/null 2>&1; then
      log "CoreDNS registration watcher already active"
      return 0
    fi
    FORTISAI_CALICO_NETWORK_NAME="$network_name" \
      FORTISAI_CALICO_DNS_ZONE="$zone" \
      FORTISAI_COREDNS_HOSTS_FILE="$coredns_dir/fortisai.hosts" \
      FORTISAI_COREDNS_LOCAL_HOSTS_FILE="$coredns_dir/fortisai.local.hosts" \
      FORTISAI_COREDNS_CLUSTER_HOSTS_FILE="$coredns_dir/fortisai.cluster.hosts" \
      FORTISAI_COREDNS_REGISTER_SCRIPT="$coredns_dir/register-podman-dns.sh" \
      FORTISAI_COREDNS_MERGE_SCRIPT="$coredns_dir/merge-coredns-hosts.sh" \
      nohup "$coredns_dir/watch-podman-dns.sh" > "$coredns_dir/watch-podman-dns.log" 2>&1 &
    printf '%s\n' "$!" > "$pid_file"
    log "CoreDNS registration watcher active through background process"
  fi
}

run_smoke_test() {
  local runtime_dir="$1"
  local network_name="$2"
  local zone="$3"
  local coredns_port="$4"
  local test_name="fortisai-coredns-smoke-$$"
  local coredns_dir="$runtime_dir/coredns"
  local hosts_file="$coredns_dir/fortisai.hosts"
  local dns_ok attempt

  log "Running CoreDNS registration smoke test"
  podman rm -f "$test_name" >/dev/null 2>&1 || true
  podman run -d --name "$test_name" --network "$network_name" docker.io/library/alpine:latest sh -c 'trap "exit 0" TERM INT; while true; do sleep 1 & wait $!; done' >/dev/null
  "$coredns_dir/register-podman-dns.sh"
  "$coredns_dir/merge-coredns-hosts.sh"

  if ! grep -Eq "[[:space:]]$test_name([[:space:]]|\\.|$)" "$hosts_file"; then
    podman rm -f "$test_name" >/dev/null 2>&1 || true
    err "Registration smoke test failed; $test_name was not written to $hosts_file"
    exit 1
  fi

  if command -v dig >/dev/null 2>&1; then
    dns_ok="false"
    for attempt in $(seq 1 15); do
      if dig "@127.0.0.1" -p "$coredns_port" "$test_name.$zone" +short | grep -Eq '^[0-9a-fA-F:.]+$'; then
        dns_ok="true"
        break
      fi
      sleep 1
    done
    if [[ "$dns_ok" != "true" ]]; then
      podman rm -f "$test_name" >/dev/null 2>&1 || true
      err "CoreDNS query smoke test failed for $test_name.$zone"
      exit 1
    fi
  else
    log "dig is not installed; validated registration through hosts file"
  fi

  podman stop -t 5 "$test_name" >/dev/null 2>&1 || true
  podman rm -f "$test_name" >/dev/null
  "$coredns_dir/register-podman-dns.sh"
  "$coredns_dir/merge-coredns-hosts.sh"
  if grep -Eq "[[:space:]]$test_name([[:space:]]|\\.|$)" "$hosts_file"; then
    err "Deregistration smoke test failed; $test_name remained in $hosts_file"
    exit 1
  fi
  log "CoreDNS registration smoke test passed"
}

main() {
  require_cmd podman
  require_cmd python3

  local runtime_dir="${FORTISAI_DEV_HOME:-$HOME/fortisai-dev}"
  local network_name="${FORTISAI_CALICO_NETWORK_NAME:-fortisai-calico-net}"
  local zone="${FORTISAI_CALICO_DNS_ZONE:-fortisai.local}"
  local coredns_container="${FORTISAI_COREDNS_CONTAINER_NAME:-fortisai-coredns}"
  local coredns_image="${FORTISAI_COREDNS_IMAGE:-docker.io/coredns/coredns:latest}"
  local coredns_port="${FORTISAI_COREDNS_PORT:-1053}"
  local calico_mode="${FORTISAI_CALICO_MODE:-netavark-compatible}"
  local run_test="${FORTISAI_CALICO_RUN_TEST:-true}"
  local cluster_routes_json="${FORTISAI_CALICO_CLUSTER_ROUTES_JSON:-[]}"

  write_runtime_files "$runtime_dir" "$network_name" "$zone" "$coredns_port" "$coredns_container" "$coredns_image" "$calico_mode" "$cluster_routes_json"
  ensure_network "$network_name" "$calico_mode"
  install_route_service "$runtime_dir" "$cluster_routes_json"
  start_coredns "$runtime_dir" "$network_name" "$coredns_container" "$coredns_image" "$coredns_port"
  start_registration_watcher "$runtime_dir" "$network_name" "$zone"

  if [[ "$run_test" == "true" ]]; then
    run_smoke_test "$runtime_dir" "$network_name" "$zone" "$coredns_port"
  fi

  log "Calico/CoreDNS layer active: network=$network_name dns=127.0.0.1:$coredns_port zone=$zone"
}

main "$@"
REMOTE
}

host_copy_file() {
  local source_file="$1"
  local hostname="$2"
  local userid="$3"
  local identity="$4"
  local relative_dest="$5"
  local target="$userid@$hostname"

  if host_is_local "$hostname"; then
    mkdir -p "$HOME/$(dirname "$relative_dest")"
    cp "$source_file" "$HOME/$relative_dest"
  else
    local -a ssh_args
    mapfile -t ssh_args < <(host_ssh_args "$identity")
    ssh "${ssh_args[@]}" "$target" "mkdir -p $(shell_quote "$(dirname "$relative_dest")")"
    scp "${ssh_args[@]}" "$source_file" "$target:$relative_dest" >/dev/null
  fi
}

host_fact_command() {
  local quoted_network quoted_zone
  quoted_network="$(shell_quote "$CALICO_NETWORK_NAME")"
  quoted_zone="$(shell_quote "$CALICO_DNS_ZONE")"
  cat <<CMD
set -euo pipefail
runtime_dir="\${FORTISAI_DEV_HOME:-\$HOME/fortisai-dev}"
network_name=$quoted_network
zone=$quoted_zone
if [[ -x "\$runtime_dir/coredns/register-podman-dns.sh" ]]; then
  FORTISAI_CALICO_NETWORK_NAME="\$network_name" "\$runtime_dir/coredns/register-podman-dns.sh" >/dev/null 2>&1 || true
fi
inspect_json="\$(podman network inspect "\$network_name" --format '{{json .}}' 2>/dev/null || printf '{}')"
subnet="\$(python3 -c 'import json,sys; payload=json.loads(sys.argv[1] or "{}"); payload=payload[0] if isinstance(payload,list) and payload else payload; print(next((item.get("subnet","") for item in payload.get("subnets",[]) if "." in item.get("subnet","")), ""))' "\$inspect_json")"
lan_ip="\$(hostname -I 2>/dev/null | awk '{for (i=1;i<=NF;i++) if (\$i ~ /^[0-9]+\\./) {print \$i; exit}}')"
hosts_file="\$runtime_dir/coredns/fortisai.local.hosts"
if [[ -f "\$hosts_file" ]]; then
  hosts_b64="\$(base64 -w0 "\$hosts_file")"
else
  hosts_b64=""
fi
published_hosts_b64="\$(python3 - "\$network_name" "\$zone" "\$lan_ip" <<'PY' | base64 -w0
import json
import re
import socket
import subprocess
import sys

network_name, zone, lan_ip = sys.argv[1:4]
zone = zone.strip(".")

def clean_name(value):
    value = str(value or "").strip().strip("/")
    value = re.sub(r"[^A-Za-z0-9_.-]+", "-", value)
    value = value.strip(".-")
    if not value:
        return ""
    return value[:63] if "." not in value else value[:253]

def is_noise_name(value):
    value = str(value or "").lower()
    return bool(
        re.fullmatch(r"[0-9a-f]{12,64}", value)
        or re.fullmatch(r"[0-9a-f]{12}-infra", value)
    )

def has_lan_binding(item):
    ports = ((item.get("NetworkSettings") or {}).get("Ports") or {})
    for bindings in ports.values():
        for binding in bindings or []:
            host_port = str(binding.get("HostPort") or "").strip()
            host_ip = str(binding.get("HostIp") or "").strip()
            if not host_port:
                continue
            if host_ip in {"", "0.0.0.0", "::", lan_ip}:
                return True
    return False

records = {}
if lan_ip:
    hostname = clean_name(socket.gethostname().split(".", 1)[0])
    names = {hostname}
    if hostname and zone:
        names.add(f"{hostname}.{zone}")
    names.discard("")
    if names:
        records.setdefault(lan_ip, set()).update(names)

try:
    ids = subprocess.check_output(
        ["podman", "ps", "--format", "{{.ID}}"],
        text=True,
        stderr=subprocess.DEVNULL,
    ).splitlines()
except Exception:
    ids = []

if lan_ip and ids:
    try:
        inspected = json.loads(subprocess.check_output(["podman", "inspect", *ids], text=True))
    except Exception:
        inspected = []
    for item in inspected:
        networks = ((item.get("NetworkSettings") or {}).get("Networks") or {})
        if network_name not in networks:
            continue
        if not has_lan_binding(item):
            continue
        names = set()
        names.add(item.get("Name", ""))
        labels = ((item.get("Config") or {}).get("Labels") or {})
        names.add(labels.get("io.podman.pod.name", ""))
        for alias in (networks.get(network_name) or {}).get("Aliases") or []:
            names.add(alias)
        cleaned = []
        for name in names:
            name = clean_name(name)
            if not name or is_noise_name(name):
                continue
            cleaned.append(name)
            if zone and not name.endswith("." + zone):
                cleaned.append(f"{name}.{zone}")
        if cleaned:
            records.setdefault(lan_ip, set()).update(cleaned)

print("# Generated by FortisAI host-reachable service registration.")
print("# Edits are replaced automatically.")
for ip in sorted(records):
    for name in sorted(records[ip]):
        print(f"{ip} {name}")
PY
)"
printf '%s\t%s\t%s\t%s\n' "\$lan_ip" "\$subnet" "\$hosts_b64" "\$published_hosts_b64"
CMD
}

collect_cluster_facts() {
  local rows="$1"
  local facts_file="$2"
  local key hostname userid identity fact

  : > "$facts_file"
  while IFS=$'\t' read -r key hostname userid identity; do
    [[ -n "$hostname" ]] || continue
    log "Collecting Calico/CoreDNS facts from $hostname"
    if fact="$(host_run "$hostname" "$userid" "$identity" "$(host_fact_command)")"; then
      printf '%s\t%s\t%s\n' "$key" "$hostname" "$fact" >> "$facts_file"
    else
      log "Warning: could not collect Calico/CoreDNS facts from $hostname"
    fi
  done <<< "$rows"
}

build_cluster_state_files() {
  local facts_file="$1"
  local output_dir="$2"

  python3 - "$facts_file" "$output_dir" <<'PY'
import base64
import json
import re
import sys
from pathlib import Path

facts_file = Path(sys.argv[1])
output_dir = Path(sys.argv[2])
output_dir.mkdir(parents=True, exist_ok=True)

facts = []
for raw_line in facts_file.read_text(encoding="utf-8").splitlines():
    if not raw_line.strip():
        continue
    parts = raw_line.split("\t", 5)
    if len(parts) < 5:
        continue
    key, hostname, lan_ip, subnet, hosts_b64 = parts[:5]
    published_hosts_b64 = parts[5] if len(parts) > 5 else ""
    try:
        local_hosts = base64.b64decode(hosts_b64.encode()).decode("utf-8") if hosts_b64 else ""
    except Exception:
        local_hosts = ""
    try:
        published_hosts = base64.b64decode(published_hosts_b64.encode()).decode("utf-8") if published_hosts_b64 else ""
    except Exception:
        published_hosts = ""
    facts.append(
        {
            "key": key,
            "hostname": hostname,
            "short": hostname.split(".", 1)[0].lower(),
            "lan_ip": lan_ip.strip(),
            "subnet": subnet.strip(),
            "local_hosts": local_hosts,
            "published_hosts": published_hosts,
        }
    )

records = set()
for fact in facts:
    for raw_record in fact["published_hosts"].splitlines():
        record = raw_record.strip()
        if not record or record.startswith("#"):
            continue
        records.add(record)

cluster_hosts = output_dir / "fortisai.cluster.hosts"
cluster_hosts.write_text(
    "\n".join(
        [
            "# Generated by FortisAI multi-host Podman/CoreDNS registration.",
            "# Edits are replaced automatically.",
            *sorted(records),
        ]
    )
    + "\n",
    encoding="utf-8",
)

def safe_name(value: str) -> str:
    return re.sub(r"[^A-Za-z0-9_.-]+", "-", value).strip(".-") or "host"

for fact in facts:
    routes = []
    for other in facts:
        if other["key"] == fact["key"]:
            continue
        if not other["subnet"] or not other["lan_ip"]:
            continue
        if other["subnet"] == fact["subnet"]:
            continue
        routes.append(
            {
                "host": other["hostname"],
                "subnet": other["subnet"],
                "via": other["lan_ip"],
            }
        )
    (output_dir / f"routes-{safe_name(fact['key'])}.json").write_text(
        json.dumps(routes, indent=2) + "\n",
        encoding="utf-8",
    )

(output_dir / "summary.json").write_text(json.dumps(facts, indent=2) + "\n", encoding="utf-8")
PY
}

sync_cluster_state() {
  local rows="$1"
  local work_dir facts_file cluster_hosts_file
  local key hostname userid identity route_file sudo_prefix remote_cmd

  work_dir="$(mktemp -d "${TMPDIR:-/tmp}/fortisai-calico-sync.XXXXXX")"
  facts_file="$work_dir/facts.tsv"
  collect_cluster_facts "$rows" "$facts_file"
  build_cluster_state_files "$facts_file" "$work_dir"
  cluster_hosts_file="$work_dir/fortisai.cluster.hosts"

  while IFS=$'\t' read -r key hostname userid identity; do
    [[ -n "$hostname" ]] || continue
    route_file="$work_dir/routes-$key.json"
    if [[ ! -f "$route_file" ]]; then
      route_file="$work_dir/routes-$(printf '%s' "$key" | tr -c 'A-Za-z0-9_.-' '-').json"
    fi
    [[ -f "$route_file" ]] || printf '[]\n' > "$route_file"

    log "Publishing shared CoreDNS records and routes to $hostname"
    host_copy_file "$cluster_hosts_file" "$hostname" "$userid" "$identity" "fortisai-dev/coredns/fortisai.cluster.hosts"
    host_copy_file "$route_file" "$hostname" "$userid" "$identity" "fortisai-dev/calico/cluster-routes.json"

    sudo_prefix=""
    if [[ -n "${FORTISAI_SUDO_PASSWORD:-}" ]]; then
      sudo_prefix="FORTISAI_SUDO_PASSWORD=$(shell_quote "$FORTISAI_SUDO_PASSWORD") "
    fi
    remote_cmd="set -e; if [[ -x \"\$HOME/fortisai-dev/coredns/register-podman-dns.sh\" ]]; then \"\$HOME/fortisai-dev/coredns/register-podman-dns.sh\" >/dev/null 2>&1 || true; fi; if [[ -x \"\$HOME/fortisai-dev/coredns/merge-coredns-hosts.sh\" ]]; then \"\$HOME/fortisai-dev/coredns/merge-coredns-hosts.sh\"; fi; if [[ -x \"\$HOME/fortisai-dev/calico/install-route-service.sh\" ]]; then ${sudo_prefix}\"\$HOME/fortisai-dev/calico/install-route-service.sh\" || true; fi"
    host_run "$hostname" "$userid" "$identity" "$remote_cmd"
  done <<< "$rows"

  rm -rf "$work_dir"
}

install_cluster_dns_sync_timer() {
  if [[ "$LOCAL_ONLY" == "true" || "$SYNC_DNS_ONLY" == "true" || -n "$ONLY_HOST" ]]; then
    return 0
  fi
  if ! command -v systemctl >/dev/null 2>&1 || ! systemctl --user status >/dev/null 2>&1; then
    log "User systemd is not available; shared CoreDNS sync timer skipped"
    return 0
  fi

  local service_dir="$HOME/.config/systemd/user"
  local service_file="$service_dir/fortisai-calico-sync-dns.service"
  local timer_file="$service_dir/fortisai-calico-sync-dns.timer"
  mkdir -p "$service_dir"
  cat > "$service_file" <<EOF
[Unit]
Description=FortisAI shared CoreDNS record synchronization

[Service]
Type=oneshot
Environment=ACTIVE_HOSTS_FILE=$ACTIVE_HOSTS_FILE
ExecStart=$SCRIPT_DIR/$(basename "$0") --sync-dns-only
EOF
  cat > "$timer_file" <<'EOF'
[Unit]
Description=Refresh FortisAI shared CoreDNS records

[Timer]
OnBootSec=2min
OnUnitActiveSec=1min
AccuracySec=15s
Persistent=true

[Install]
WantedBy=timers.target
EOF
  systemctl --user daemon-reload
  systemctl --user enable --now fortisai-calico-sync-dns.timer >/dev/null
  log "Shared CoreDNS sync timer active through user systemd"
}

deploy_host() {
  local key="$1"
  local hostname="$2"
  local userid="$3"
  local identity="$4"
  local target="$userid@$hostname"

  log "Deploying Calico/CoreDNS on $hostname"

  if host_is_local "$hostname"; then
    FORTISAI_CALICO_NETWORK_NAME="$CALICO_NETWORK_NAME" \
      FORTISAI_CALICO_DNS_ZONE="$CALICO_DNS_ZONE" \
      FORTISAI_COREDNS_CONTAINER_NAME="$COREDNS_CONTAINER_NAME" \
      FORTISAI_COREDNS_IMAGE="$COREDNS_IMAGE" \
      FORTISAI_COREDNS_PORT="$COREDNS_PORT" \
      FORTISAI_CALICO_MODE="$CALICO_MODE" \
      FORTISAI_CALICO_RUN_TEST="$RUN_TEST" \
      bash -s < <(remote_payload)
  else
    local ssh_args=("-o" "BatchMode=yes" "-o" "ConnectTimeout=15")
    if [[ -n "$identity" && -f "$identity" ]]; then
      ssh_args+=("-i" "$identity")
    fi
    ssh "${ssh_args[@]}" "$target" \
      "FORTISAI_CALICO_NETWORK_NAME='$CALICO_NETWORK_NAME' FORTISAI_CALICO_DNS_ZONE='$CALICO_DNS_ZONE' FORTISAI_COREDNS_CONTAINER_NAME='$COREDNS_CONTAINER_NAME' FORTISAI_COREDNS_IMAGE='$COREDNS_IMAGE' FORTISAI_COREDNS_PORT='$COREDNS_PORT' FORTISAI_CALICO_MODE='$CALICO_MODE' FORTISAI_CALICO_RUN_TEST='$RUN_TEST' bash -s" \
      < <(remote_payload)
  fi
}

main() {
  local rows row_count=0
  rows="$(host_rows)"
  if [[ -z "$rows" ]]; then
    err "No matching hosts found in $ACTIVE_HOSTS_FILE"
    exit 1
  fi

  if [[ "$SYNC_DNS_ONLY" != "true" ]]; then
    while IFS=$'\t' read -r key hostname userid identity; do
      [[ -n "$hostname" ]] || continue
      deploy_host "$key" "$hostname" "$userid" "$identity"
      row_count=$((row_count + 1))
    done <<< "$rows"
  fi

  if [[ "$SYNC_CLUSTER_DNS" == "true" && "$LOCAL_ONLY" != "true" ]]; then
    sync_cluster_state "$rows"
    install_cluster_dns_sync_timer
  fi

  if [[ "$SYNC_DNS_ONLY" == "true" ]]; then
    log "Calico/CoreDNS shared DNS synchronization completed"
  else
    log "Calico/CoreDNS deployment completed on $row_count host(s)"
  fi
}

main "$@"
