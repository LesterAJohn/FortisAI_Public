# LM Studio Setup on Windows

This guide installs and starts LM Studio for local model inference on Windows.

## Prerequisites

- Windows 11 or Windows 10 with `winget`
- PowerShell

## Use the Helper Script (Recommended)

Run from this folder:

```powershell
cd C:\Users\<your-user>\Desktop\FortisAI\Development_Environment\windows
.\fortisai-dev-helper.ps1 lmstudio-setup
.\fortisai-dev-helper.ps1 lmstudio-start
.\fortisai-dev-helper.ps1 lmstudio-check
```

What these commands do:

- `lmstudio-setup`: installs LM Studio using `winget` when not installed.
- `lmstudio-start`: launches LM Studio.
- `lmstudio-check`: checks the local API endpoint at `http://localhost:1234/v1/models`.

## Configure Local API in LM Studio

After LM Studio opens:

1. Download or load a model.
2. Open Developer or Local Server settings.
3. Start the local server on port `1234`.

Then verify again:

```powershell
.\fortisai-dev-helper.ps1 lmstudio-check
```

Expected output should show an HTTP response code from the local models endpoint.

## Dify Integration Note

For Dify integration with LM Studio in this project:

- Use the compatible-openai-llm module (OpenAI API Compatible provider).
- Do not use the LM Studio plugin in Dify.

Dify provider details:

- Provider: `langgenius/openai_api_compatible/openai_api_compatible`
- Base URL: `http://host.containers.internal:1234/v1` (for Dify running in containers)
- Alternative base URL: `http://localhost:1234/v1` (for host-process testing)
- API key: any non-empty value if LM Studio does not require auth

## Optional Environment Override

If your LM Studio API endpoint is different:

```powershell
$env:LMSTUDIO_MODELS_URL = "http://localhost:1234/v1/models"
```

Then re-run `lmstudio-check`.
