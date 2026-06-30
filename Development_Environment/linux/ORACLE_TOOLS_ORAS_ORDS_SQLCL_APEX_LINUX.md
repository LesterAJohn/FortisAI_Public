# Oracle Tools on Linux (ORAS, ORDS, SQLcl, APEX)

This guide describes helper-driven Oracle tooling workflows on Linux.

## Services and Endpoints

- ORDS: `http://127.0.0.1:8181/ords/`
- APEX (optional): `http://127.0.0.1:8181/ords/apex`
- Oracle DB listener: `localhost:1521`

## Core Commands

```bash
./linux/fortisai-dev-helper.sh up
./linux/fortisai-dev-helper.sh logs oracle-db
./linux/fortisai-dev-helper.sh logs ords
./linux/fortisai-dev-helper.sh logs sqlcl
./linux/fortisai-dev-helper.sh sqlcl-shell
./linux/fortisai-dev-helper.sh sqlcl-mcp
./linux/fortisai-dev-helper.sh sqlcl-mcp-smoke
```

## APEX Workflow

```bash
./linux/fortisai-dev-helper.sh apex-install
./linux/fortisai-dev-helper.sh apex-check
./linux/fortisai-dev-helper.sh apex-reset
```

## OCR Pre-Pull Workflow

If you require authenticated OCR pulls:

```bash
export OCR_USERNAME="<your-ocr-username>"
export OCR_AUTH_TOKEN="<your-ocr-token>"
./linux/fortisai-dev-helper.sh oracle-db-pull
```

## ORAS Usage

Install ORAS using your distro package manager or official release binary. Use ORAS for OCI artifact push/pull workflows as required by your pipeline process.
