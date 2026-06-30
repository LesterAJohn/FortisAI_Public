# LLM Directory

This directory is the default model source for the Linux llama router helper commands.

## Default Router Wiring

- Helper script: `Development_Environment/linux/fortisai-dev-helper.sh`
- Model mount source: `Development_Environment/llm_directory`
- Container mount target: `/models` (read-only)
- OpenAI-compatible endpoint: `http://127.0.0.1:8011/v1`

## Supported Model Files

Place GGUF files here (nested folders are supported), for example:

- `Development_Environment/llm_directory/claude/Negentropy-claude-opus-4.7-9B-Q4_K_M.gguf`
- `Development_Environment/llm_directory/mistral/Devstral-Small-2507-Q8_0.gguf`

## Linux Helper Commands

```bash
cd Development_Environment/linux
./fortisai-dev-helper.sh llama-router-up
./fortisai-dev-helper.sh llama-router-models
./fortisai-dev-helper.sh llama-router-switch claude/Negentropy-claude-opus-4.7-9B-Q4_K_M.gguf
./fortisai-dev-helper.sh llama-router-status
./fortisai-dev-helper.sh llama-router-down
```

## Override Model Directory

To use a different model directory:

```bash
export LLAMA_MODELS_DIR="/path/to/your/models"
cd Development_Environment/linux
./fortisai-dev-helper.sh llama-router-up
```
