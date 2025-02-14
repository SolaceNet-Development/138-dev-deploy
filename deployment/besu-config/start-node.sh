#!/bin/bash
set -e

# Start Tessera
tessera -configfile tessera-config.json &

# Wait for Tessera to start
sleep 10

# Start Besu with QBFT
besu --config-file=node-config.toml \
     --genesis-file=qbft-config.json \
     --network-id=2025 \
     --permissions-nodes-config-file-enabled=true \
     --permissions-accounts-config-file-enabled=true \
     --metrics-enabled \
     --metrics-protocol=prometheus
