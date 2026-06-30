# Git Import and Export Workflow for Dify and n8n (Windows)

This guide describes Windows-oriented Git workflows for:

- exporting Dify configurations as YAML
- exporting n8n workflows as JSON
- committing to config repositories
- triggering production imports by merging to `main`

## Trigger Scope

FortisAI automation currently triggers on:

- Dify repository: `**/*.yaml` and `**/*.yml`
- n8n repository: `**/*.json`

Trigger reference: [pipeline/main.tf](../../pipeline/main.tf).

## Recommended Repository Structure

```text
dify-config
  apps/
  prompts/
  datasets/

n8n-config
  workflows/
  metadata/
  credentials/
```

## Naming Conventions

Dify files:

- `apps/<domain>-<capability>.yaml`
- `prompts/<domain>-<purpose>.yaml`
- `datasets/<domain>-<dataset>.yaml`

n8n files:

- `workflows/<domain>-<workflow>.json`
- `metadata/<domain>-tags.json`

## Local Scaffold

```powershell
cd C:\Users\<your-user>\Desktop\FortisAI\Development_Environment\windows
.\fortisai-dev-helper.ps1 scaffold-config-repos
```

Created paths:

- `$HOME\fortisai-dev\config-repos\dify-config`
- `$HOME\fortisai-dev\config-repos\n8n-config`

## OCI DevOps Repository Connection

Landing-zone creates two OCI DevOps repositories that auto-trigger on push to `main`:

- **n8n-config**: n8n workflow JSON files
- **dify-config**: Dify application YAML files

### Get Repository URLs

```powershell
# From landing-zone directory
cd landing-zone
terraform output devops_repository_http_urls
```

### Authenticate

Use `.netrc` or Git credential cache:

```powershell
# PowerShell: Add to profile or run once per session
$env:NETRC = "$env:USERPROFILE\.netrc"
if (!(Test-Path $env:NETRC)) {
    @(
        "machine devops.scmservice.us-phoenix-1.oci.oraclecloud.com",
        "login <oci-username>",
        "password <oci-auth-token>"
    ) | Out-File -FilePath $env:NETRC -Encoding ASCII
    (Get-Item $env:NETRC).Attributes = 'Hidden'
}
```

Or configure Git credential helper:

```powershell
git config --global credential.helper wincred
```

### Connect Repository

```powershell
# For workspace n8n-config
cd C:\Users\<your-user>\Desktop\FortisAI\Development_Environment\n8n-config\main
git init
git remote add oci <n8n-config-repo-url>
git add .
git commit -m "Initial n8n workflows"
git push -u oci main

# For workspace dify-config
cd C:\Users\<your-user>\Desktop\FortisAI\Development_Environment\dify-config\main
git init
git remote add oci <dify-config-repo-url>
git add .
git commit -m "Initial dify applications"
git push -u oci main
```

## Git Flow

1. Create feature branch: `git checkout -b feature/my-update`
2. Export Dify or n8n artifacts locally
3. Commit YAML/JSON changes: `git add . && git commit -m "<description>"`
4. Push to feature branch: `git push oci feature/my-update`
5. (Optional) Open PR in OCI DevOps for review
6. Merge to `main`: `git checkout main && git merge feature/my-update`
7. Push main: `git push oci main`
8. OCI DevOps import pipeline runs automatically

### Monitor Import Status

```powershell
# View OCI DevOps project name
cd landing-zone
terraform output devops_project_name

# Navigate to OCI Console:
# DevOps → Projects → fortisai → Build Pipelines
# Select dify-config-import or n8n-config-import
```

## Dify Export to OCI DevOps Example

```powershell
# Export from Dify UI to Downloads
# Then copy to OCI DevOps repository
Copy-Item "$HOME\Downloads\customer-support.yaml" `
          "C:\Users\<user>\Desktop\FortisAI\Development_Environment\dify-config\main\dify\configurations\customer-support-agent.yaml"

# Navigate to dify-config and push
cd "C:\Users\<user>\Desktop\FortisAI\Development_Environment\dify-config\main"
git checkout -b feature/dify-customer-support-update
git add dify/configurations/customer-support-agent.yaml
git commit -m "Update Dify customer support agent"
git push oci feature/dify-customer-support-update

# Open PR or directly merge to main if approved
git checkout main
git merge feature/dify-customer-support-update
git push oci main

# Import pipeline auto-triggers on push to main
```

## n8n Export to OCI DevOps Example

```powershell
# Export from n8n UI to Downloads
# Then copy to OCI DevOps repository
Copy-Item "$HOME\Downloads\lead-intake.json" `
          "C:\Users\<user>\Desktop\FortisAI\Development_Environment\n8n-config\main\n8n\configurations\lead-intake.json"

# Navigate to n8n-config and push
cd "C:\Users\<user>\Desktop\FortisAI\Development_Environment\n8n-config\main"
git checkout -b feature/n8n-lead-intake-update
git add n8n/configurations/lead-intake.json
git commit -m "Update n8n lead intake workflow"
git push oci feature/n8n-lead-intake-update

# Open PR or directly merge to main if approved
git checkout main
git merge feature/n8n-lead-intake-update
git push oci main

# Import pipeline auto-triggers on push to main
```

## Validation Before Merge

YAML and JSON validation:

```powershell
yq eval '.' "$HOME\fortisai-dev\config-repos\dify-config\apps\customer-support-agent.yaml" > $null
jq empty "$HOME\fortisai-dev\config-repos\n8n-config\workflows\lead-intake.json"
```

Install tools if needed:

```powershell
winget install MikeFarah.yq
winget install jqlang.jq
```

## Required Pipeline Variables

Defined in [pipeline/variables.tf](../../pipeline/variables.tf):

Dify:

- `dify_config_repository_id`
- `dify_config_repo_url`
- `dify_config_repo_token_secret_id`
- `dify_import_api_base_url`
- `dify_import_api_token_secret_id`

n8n:

- `n8n_config_repository_id`
- `n8n_config_repo_url`
- `n8n_config_repo_token_secret_id`
- `n8n_import_api_base_url`
- `n8n_import_api_token_secret_id`

## Troubleshooting Push Errors

### Authentication Failed

```powershell
# Clear Git credentials and re-authenticate
git credential-manager erase
# Or clear .netrc
Remove-Item "$env:USERPROFILE\.netrc" -Force
```

### Push Rejected (Non-Fast-Forward)

```powershell
# Fetch latest and rebase
git fetch oci
git rebase oci/main
git push oci main

# Or force push (be careful with shared repos)
git push oci main -f
```

### Import Pipeline Didn't Trigger

1. Verify push went to `main` branch: `git log --oneline -n 5`
2. Check file types match trigger: `.yaml`, `.yml` for dify; `.json` for n8n
3. Navigate to OCI Console and manually check build pipeline:
   - DevOps → Projects → fortisai → Build Pipelines
   - Select `dify-config-import` or `n8n-config-import`
   - Look for recent build runs

## Security Notes

- Never commit secrets or tokens to config repositories.
- Keep credentials in OCI Vault and reference via secret OCIDs in import pipelines.
- Use bastion-linked access where private endpoints are required.
- Store OCI DevOps Git credentials (username, auth token) in OCI Vault for production deployments.

Related setup guide: [WINDOWS_DEV_SETUP_DIFY_N8N_OPENWEBUI.md](WINDOWS_DEV_SETUP_DIFY_N8N_OPENWEBUI.md).
