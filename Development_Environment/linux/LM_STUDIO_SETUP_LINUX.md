# LM Studio Setup on Linux

This guide covers Linux usage of LM Studio with FortisAI helper wiring.

## Goal

Use LM Studio as a local OpenAI-compatible endpoint for components such as:

- Honcho
- OpenClaw
- Hermes (via gateway models)

## Install

Install LM Studio for Linux from the official release page and start it on the host.

Enable local server mode in LM Studio and confirm it is reachable at:

- `http://localhost:1234/v1`

## Validate

```bash
curl -s http://localhost:1234/v1/models
```

## Helper Integration

Use the Linux helper commands:

```bash
./linux/fortisai-dev-helper.sh lmstudio-setup
./linux/fortisai-dev-helper.sh lmstudio-check
```

Key defaults in helper wiring:

- Honcho/OpenClaw base URL: `http://host.docker.internal:1234/v1`
- Host-native clients should use: `http://localhost:1234/v1`

## Troubleshooting

- If containers cannot resolve `host.docker.internal`, add an explicit host gateway mapping in your runtime or override URL env vars to reachable host IP.
- If no model appears, load a model in LM Studio and verify server mode remains enabled.
