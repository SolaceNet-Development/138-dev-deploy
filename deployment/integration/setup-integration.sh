#!/bin/bash
set -e

# Setup FireFly connectors
echo "Setting up FireFly connectors..."
curl -X POST http://firefly-integration:5000/api/v1/namespaces/default/connectors \
  -H "Content-Type: application/json" \
  -d '{
    "name": "besu",
    "type": "ethereum",
    "url": "http://besu:8545"
  }'

# Setup Cacti bridges
echo "Setting up Cacti blockchain bridges..."
curl -X POST http://cacti-integration:3000/api/v1/bridges \
  -H "Content-Type: application/json" \
  -d '{
    "name": "erc721-bridge",
    "type": "erc721",
    "networks": ["ethereum", "polygon"]
  }'

# Setup Identus DID registry
echo "Setting up Identus DID registry..."
curl -X POST http://identus-integration:7000/api/v1/did/registry \
  -H "Content-Type: application/json" \
  -d '{
    "method": "web",
    "zkpEnabled": true
  }'

echo "Integration setup complete"
