# LM Studio Setup on macOS

This guide installs and starts LM Studio for local model inference on macOS.

## Prerequisites

- Homebrew
- macOS user with permission to install apps

## Use the Helper Script (Recommended)

Run from this folder:

```bash
cd /path/to/FortisAI/Development_Environment/mac
./fortisai-dev-helper.sh lmstudio-setup
./fortisai-dev-helper.sh lmstudio-start
./fortisai-dev-helper.sh lmstudio-check
```

What these commands do:

- `lmstudio-setup`: installs LM Studio using Homebrew cask `lm-studio` if it is not already installed.
- `lmstudio-start`: opens LM Studio.
- `lmstudio-check`: checks the local API endpoint at `http://localhost:1234/v1/models`.

## Configure Local API in LM Studio

After LM Studio opens:

1. Download or load a model.
2. Open the Local Server panel.
3. Start the server (default port `1234`).

Then verify again:

```bash
./fortisai-dev-helper.sh lmstudio-check
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

If your LM Studio API endpoint is different, set:

```bash
export LMSTUDIO_MODELS_URL="http://localhost:1234/v1/models"
```

Then re-run `lmstudio-check`.
