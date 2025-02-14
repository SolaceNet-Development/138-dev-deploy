#!/bin/bash
set -e

# Install required Besu plugins
PLUGIN_DIR="plugins"
mkdir -p $PLUGIN_DIR

# Privacy Plugin (Tessera)
echo "Setting up Privacy Plugin..."
curl -L https://hyperledger.jfrog.io/artifactory/besu-binaries/privacy-plugin/latest/privacy-plugin.jar -o $PLUGIN_DIR/privacy-plugin.jar

# Permissioning Plugin
echo "Setting up Permissioning Plugin..."
curl -L https://hyperledger.jfrog.io/artifactory/besu-binaries/permissioning-plugin/latest/permissioning-plugin.jar -o $PLUGIN_DIR/permissioning-plugin.jar

# Tracing Plugin
echo "Setting up Tracing Plugin..."
curl -L https://hyperledger.jfrog.io/artifactory/besu-binaries/tracing-plugin/latest/tracing-plugin.jar -o $PLUGIN_DIR/tracing-plugin.jar

# Metrics Plugin (Prometheus/Grafana)
echo "Setting up Metrics Plugin..."
curl -L https://hyperledger.jfrog.io/artifactory/besu-binaries/metrics-plugin/latest/metrics-plugin.jar -o $PLUGIN_DIR/metrics-plugin.jar

# EVM Plugin
echo "Setting up EVM Plugin..."
curl -L https://hyperledger.jfrog.io/artifactory/besu-binaries/evm-plugin/latest/evm-plugin.jar -o $PLUGIN_DIR/evm-plugin.jar

echo "All plugins installed successfully"
