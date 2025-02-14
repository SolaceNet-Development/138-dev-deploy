#!/bin/bash
set -e

# Test QBFT Consensus
echo "Testing QBFT Consensus..."
curl -X POST --data '{"jsonrpc":"2.0","method":"qbft_getValidatorsByBlockNumber","params":["latest"],"id":1}' http://localhost:8545

# Test Privacy Features
echo "Testing Tessera Private Transactions..."
curl -X POST --data '{"jsonrpc":"2.0","method":"priv_getPrivacyPrecompileAddress","params":[],"id":1}' http://localhost:8545

# Test Plugins
echo "Testing Besu Plugins..."
# Metrics Plugin
curl http://localhost:9545/metrics

# Test Base Contracts
echo "Testing Base Contracts..."
node deployment/test/test-contracts.js

# Test Cross-Chain Communication
echo "Testing Cross-Chain Messaging..."
node deployment/test/test-cross-chain.js

# Test Regulatory Compliance
echo "Testing Compliance Features..."
node deployment/test/test-compliance.js
