# Appsmith on Linux

This document covers Appsmith usage in the Linux FortisAI local stack.

## Lifecycle

Appsmith is part of default helper lifecycle.
Run these commands from the `Development_Environment` directory.

```bash
./linux/fortisai-dev-helper.sh up
./linux/fortisai-dev-helper.sh down
```

## URL and Logs

- URL: `http://localhost:18080`
- Logs: `./linux/fortisai-dev-helper.sh logs appsmith`
- MongoDB logs: `./linux/fortisai-dev-helper.sh logs mongodb`

## Shared Wiring

Appsmith is attached to the Linux selected shared network (`fortisai-calico-net` when the Calico/CoreDNS deployment is present, otherwise `fortisai-dev-net`) and receives helper-generated env wiring for shared services:

- MongoDB: `mongodb://fortisai-mongodb.fortisai.local:27017/appsmith?replicaSet=rs0`
- Redis: `redis://fortisai-redis.fortisai.local:6379`
- pgvector: `postgresql://fortisai:fortisai@fortisai-pgvector.fortisai.local:5432/fortisai`

Startup order in helper `up` ensures MongoDB is started and replica set `rs0` is initialized before Appsmith starts.

## Troubleshooting

- Ensure shared services are running (`mongodb`, `redis`, `pgvector`).
- Confirm port `18080` is not in use by another process.
- Re-run `setup` if compose artifacts are stale:

```bash
./linux/fortisai-dev-helper.sh setup
```

- Validate health including MongoDB ping:

```bash
./linux/fortisai-dev-helper.sh check
```
