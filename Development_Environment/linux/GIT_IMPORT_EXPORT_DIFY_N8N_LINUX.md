# Git Import and Export Workflow (Linux)

This document defines the Linux workflow for exporting local artifacts and syncing config repositories.

## Repositories

Helper scaffold path:

- `~/fortisai-dev/config-repos/dify-config`
- `~/fortisai-dev/config-repos/n8n-config`

Create/recreate scaffolding:

```bash
./linux/fortisai-dev-helper.sh scaffold-config-repos
```

## Dify Export Pattern

- Export Dify app/workflow artifacts as YAML from Dify.
- Store them in the `dify-config` repository using your team naming conventions.
- Commit and push through your standard branch/PR flow.

## n8n Export Pattern

- Export workflows/credentials metadata as JSON from n8n.
- Store them in the `n8n-config` repository using stable file naming.
- Commit and push through your standard branch/PR flow.

## Recommended Baseline Commands

```bash
cd ~/fortisai-dev/config-repos/dify-config
git status
git add .
git commit -m "Update Dify configs"
git push

cd ~/fortisai-dev/config-repos/n8n-config
git status
git add .
git commit -m "Update n8n configs"
git push
```

## Notes

- Keep secrets out of exported artifacts.
- Prefer environment-based references for runtime credentials.
- Validate schema/format in CI before promotion.
