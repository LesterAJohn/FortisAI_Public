# Git Import and Export Workflow for Dify and n8n

This guide covers how to:

- export Dify configurations into Git-managed YAML files
- export n8n workflows into Git-managed JSON files
- organize those files for the FortisAI pipeline triggers
- import changes into production through the existing `main` branch automation

## Scope

The repository automation in this project is configured to react to:

- Dify repository changes to `**/*.yaml` and `**/*.yml`
- n8n repository changes to `**/*.json`

On push to `main`, OCI DevOps triggers the matching import pipeline.

Related implementation:

- Dify import trigger and parameters: [pipeline/main.tf](../../pipeline/main.tf)
- Config repository variables: [pipeline/variables.tf](../../pipeline/variables.tf)
- Local Mac environment setup: [MAC_DEV_SETUP_DIFY_N8N_OPENWEBUI.md](MAC_DEV_SETUP_DIFY_N8N_OPENWEBUI.md)

## Recommended Repository Layout

Use separate repositories:

- `dify-config`
- `n8n-config`

Recommended structure:

```text
Dify repository
  apps/
    customer-support.yaml
    internal-rag.yml
  prompts/
    summarizer.yaml
  datasets/
    product-catalog.yaml

n8n repository
  workflows/
    lead-intake.json
    sync-contacts.json
  credentials/
    README.md
  metadata/
    tags.json
```

Keep production-importable files in the matching file types:

- Dify: `.yaml` or `.yml`
- n8n: `.json`

## OCI DevOps Repository Connection

The landing-zone Terraform stack provisions two dedicated OCI DevOps repositories:

- **n8n-config**: Stores and versioned n8n workflow JSON files
- **dify-config**: Stores versioned Dify application YAML files

These repositories auto-trigger import pipelines when you push to the `main` branch.

### Get Repository URLs

```bash
# From the landing-zone directory, output the repository URLs:
terraform -chdir=landing-zone output devops_repository_http_urls

# Output example:
# {
#   "dify-config" = "https://devops.scmservice.us-phoenix-1.oci.oraclecloud.com/namespaces/.../projects/.../repositories/dify-config"
#   "n8n-config" = "https://devops.scmservice.us-phoenix-1.oci.oraclecloud.com/namespaces/.../projects/.../repositories/n8n-config"
#   ...
# }
```

### Authenticate with OCI DevOps

OCI DevOps repositories use HTTPS with OCI API key authentication. Store credentials in OCI Vault or use the `.netrc` file:

```bash
echo "machine devops.scmservice.us-phoenix-1.oci.oraclecloud.com" >> ~/.netrc
echo "login <oci-username>" >> ~/.netrc
echo "password <oci-auth-token>" >> ~/.netrc
chmod 600 ~/.netrc
```

Or use Git credential helper:

```bash
git config --global credential.helper cache
git config --global credential.cacheDaemon \
  'git-credential-cache--daemon --timeout=3600'
```

### Connect Local Repository to OCI DevOps

For the in-workspace `n8n-config` and `dify-config` directories:

```bash
# Navigate to n8n-config
cd /path/to/FortisAI/Development_Environment/n8n-config/main

# Initialize if not already a git repo
git init

# Add OCI DevOps remote
git remote add oci <n8n-config-repo-url>

# Push initial commit to main
git add .
git commit -m "Initial n8n workflow configurations"
git push -u oci main

# Repeat for dify-config
cd /path/to/FortisAI/Development_Environment/dify-config/main
git init
git remote add oci <dify-config-repo-url>
git add .
git commit -m "Initial dify application configurations"
git push -u oci main
```

## Local Scaffold Command

Optionally, the helper app can create the recommended local repository structure separate from the workspace:

```bash
cd /path/to/FortisAI/Development_Environment/mac
./fortisai-dev-helper.sh scaffold-config-repos
```

This creates:

- `~/fortisai-dev/config-repos/dify-config`
- `~/fortisai-dev/config-repos/n8n-config`

with starter folders, starter files, and local Git repositories initialized on `main`. You can then connect these to OCI DevOps using the same `git remote add oci` workflow above.

## Naming Conventions

Use stable, lowercase, hyphenated filenames so diffs remain readable and imports stay predictable.

### Dify YAML Naming

Recommended patterns:

- `apps/<domain>-<capability>.yaml`
- `prompts/<domain>-<purpose>.yaml`
- `datasets/<domain>-<dataset>.yaml`

Examples:

- `apps/customer-support-agent.yaml`
- `apps/internal-rag-assistant.yml`
- `prompts/sales-followup-summary.yaml`
- `datasets/product-catalog.yaml`

Rules:

- use one exported Dify artifact per file
- keep filenames aligned with the app or prompt name shown in Dify
- include business domain first when multiple teams share one repo
- do not encode secrets, tokens, or environment-specific credentials in the filename or file body

### n8n JSON Naming

Recommended patterns:

- `workflows/<domain>-<workflow>.json`
- `metadata/<domain>-tags.json`

Examples:

- `workflows/lead-intake.json`
- `workflows/crm-contact-sync.json`
- `workflows/customer-onboarding.json`
- `metadata/revenue-ops-tags.json`

Rules:

- keep one workflow per JSON file where possible
- use the workflow business name, not an internal ticket number, as the base filename
- prefer stable filenames even if the workflow display name changes slightly
- never commit exported credentials or live tokens into the workflow repository

## Git Setup and Workflow

### Initial Setup

1. Configure Git identity if needed:
   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "you@example.com"
   ```

2. Clone or initialize OCI DevOps repositories:
   ```bash
   # Clone if using separate local repos
   git clone <dify_config_repo_url> ~/fortisai-dev/config-repos/dify-config
   git clone <n8n_config_repo_url> ~/fortisai-dev/config-repos/n8n-config

   # Or initialize workspace directories
   cd /path/to/FortisAI/Development_Environment/n8n-config/main && git init
   cd /path/to/FortisAI/Development_Environment/dify-config/main && git init
   ```

### Development Workflow

**Option A: Feature Branch → PR → Merge → Auto-Import**

1. Create feature branch: `git checkout -b feature/my-changes`
2. Export or edit Dify or n8n config files locally
3. Commit changes: `git add . && git commit -m "Add/update <description>"`
4. Push feature branch: `git push oci feature/my-changes`
5. Open PR in OCI DevOps (optional, for review)
6. Merge to `main`: `git checkout main && git merge feature/my-changes`
7. Push to main: `git push oci main`
8. OCI DevOps automatically triggers import pipeline

**Option B: Direct Push to Main**

1. Make local changes
2. Export new configurations
3. Commit: `git add . && git commit -m "<description>"`
4. Push: `git push oci main`
5. Import pipeline auto-triggers

### Monitor Import Status

After pushing to main:

```bash
# View OCI DevOps build pipelines
terraform -chdir=landing-zone output devops_project_name

# Then navigate to OCI Console:
# DevOps → Projects → <project-name> → Build Pipelines
# Select dify-config-import or n8n-config-import to view run status
```

### Example Workflow

```bash
cd ~/fortisai-dev/config-repos/dify-config
git checkout -b feature/update-support-bot
```

## Export from Dify to Git

Dify exports should be committed as YAML files.

Recommended approach:

1. Open the local or production Dify UI.
2. Export the app, workflow, prompt, or DSL artifact in YAML format.
3. Save the file into the Dify config repository under a stable path.
4. Commit and push the file.

Example:

```bash
cp ~/Downloads/customer-support.yaml ~/fortisai-dev/config-repos/dify-config/apps/customer-support.yaml
cd ~/fortisai-dev/config-repos/dify-config
git add apps/customer-support.yaml
git commit -m "Export Dify customer support app"
git push origin feature/update-support-bot
```

Recommendations:

- Use stable filenames so diffs stay readable.
- Keep one exported artifact per file.
- Avoid mixing unrelated apps in the same commit.
- Keep secrets out of YAML files.

## Import to Dify via Git

After review, merge the branch into `main`.

The existing pipeline is wired to:

- watch the configured Dify config repository
- trigger only when YAML or YML files change on `refs/heads/main`
- clone the configured repository URL
- call the Dify import API with the configured bearer token

Required pipeline values are defined in [pipeline/variables.tf](../../pipeline/variables.tf):

- `dify_config_repository_id`
- `dify_config_repo_url`
- `dify_config_repo_token_secret_id`
- `dify_import_api_base_url`
- `dify_import_api_token_secret_id`

## Export from n8n to Git

n8n exports should be committed as JSON files.

There are two practical options.

### Option A: Export from the n8n UI

1. Open the workflow in n8n.
2. Export the workflow as JSON.
3. Save it into the n8n config repository.
4. Commit and push the JSON file.

Example:

```bash
cp ~/Downloads/lead-intake.json ~/fortisai-dev/config-repos/n8n-config/workflows/lead-intake.json
cd ~/fortisai-dev/config-repos/n8n-config
git add workflows/lead-intake.json
git commit -m "Export n8n lead intake workflow"
git push origin feature/update-lead-intake
```

### Option B: Export from the local container CLI

Check the exact CLI flags supported by the n8n version first:

```bash
podman exec -it fortisai-n8n n8n export:workflow --help
```

Then export workflows to a file or directory supported by that version and copy the output into the Git repository.

This approach is useful for bulk workflow export and repeatable backups.

Recommendations:

- Store one workflow per JSON file when possible.
- Keep filenames aligned with workflow names or business domains.
- Do not commit credential secrets.
- Treat exported credentials separately from exported workflows.

## Import to n8n via Git

After review, merge the branch into `main`.

The existing pipeline is wired to:

- watch the configured n8n config repository
- trigger only when JSON files change on `refs/heads/main`
- clone the configured repository URL
- call the n8n import API with the configured bearer token

Required pipeline values are defined in [pipeline/variables.tf](../../pipeline/variables.tf):

- `n8n_config_repository_id`
- `n8n_config_repo_url`
- `n8n_config_repo_token_secret_id`
- `n8n_import_api_base_url`
- `n8n_import_api_token_secret_id`

## Suggested Day-to-Day Flow

### Dify

```bash
cd ~/fortisai-dev/config-repos/dify-config
git checkout main
git pull
git checkout -b feature/dify-update
cp ~/Downloads/my-flow.yaml apps/my-flow.yaml
git add apps/my-flow.yaml
git commit -m "Update Dify flow"
git push origin feature/dify-update
```

### n8n

```bash
cd ~/fortisai-dev/config-repos/n8n-config
git checkout main
git pull
git checkout -b feature/n8n-update
cp ~/Downloads/my-workflow.json workflows/my-workflow.json
git add workflows/my-workflow.json
git commit -m "Update n8n workflow"
git push origin feature/n8n-update
```

## Validation Before Merge

Before merging:

- confirm Dify exports are valid YAML
- confirm n8n exports are valid JSON
- keep production secrets out of tracked files
- keep changes small and app-specific
- verify file extensions match the trigger filters

Basic validation commands:

```bash
yq eval '.' ~/fortisai-dev/config-repos/dify-config/apps/customer-support.yaml >/dev/null
jq empty ~/fortisai-dev/config-repos/n8n-config/workflows/lead-intake.json
```

If `yq` is not installed:

```bash
brew install yq
```

## Production Import Notes

If your local environment connects to production through bastion, use the bastion workflow documented in [MAC_DEV_SETUP_DIFY_N8N_OPENWEBUI.md](MAC_DEV_SETUP_DIFY_N8N_OPENWEBUI.md).

Useful helper commands:

```bash
cd /path/to/FortisAI/Development_Environment/mac
./fortisai-dev-helper.sh prod-template
./fortisai-dev-helper.sh validate-prod
./fortisai-dev-helper.sh link-prod
```

## OCI Git Credentials

If your Dify and n8n config repositories are OCI DevOps repositories, retrieve the Git username and token from Vault using the secret IDs documented in the Mac guide.

The pipeline exports these secret IDs:

- `devops_git_username_secret_id`
- `devops_git_token_secret_id`

Then authenticate Git operations with a credential helper pattern such as:

```bash
git -c credential.helper='!f() { echo username=$OCI_GIT_USERNAME; echo password=$OCI_GIT_TOKEN; }; f' ls-remote <oci_devops_repo_url>
```

## Troubleshooting

### Authentication Failed

```bash
# Clear Git credentials and re-authenticate
git credential-cache exit
# Or update .netrc
vi ~/.netrc
```

### Push Rejected (Non-Fast-Forward)

```bash
# Fetch latest and rebase
git fetch oci
git rebase oci/main
git push oci main

# Or force push (be careful with shared repos)
git push oci main -f
```

### Import Pipeline Didn't Trigger

1. Verify push to `main`: `git log --oneline -n 5`
2. Confirm file type matches trigger: `.yaml`, `.yml` (Dify) or `.json` (n8n)
3. Check OCI Console:
   ```bash
   # Get project name and view in OCI Console
   terraform -chdir=landing-zone output devops_project_name
   # DevOps → Projects → <project> → Build Pipelines → dify-config-import or n8n-config-import
   ```

## Operational Rule of Thumb

- Dify changes belong in YAML and go through the Dify config repository.
- n8n changes belong in JSON and go through the n8n config repository.
- Only merge production-ready exports into `main`.
- `main` is the production import trigger boundary for both tools.
- Use feature branches for review; merge to `main` triggers auto-import.

## Security Notes

- Never commit secrets or tokens to config repositories.
- Keep credentials in OCI Vault and reference via secret OCIDs in import pipelines.
- Use bastion-linked access where private endpoints are required.
- Store OCI DevOps Git credentials (username, auth token) in OCI Vault for production deployments.
