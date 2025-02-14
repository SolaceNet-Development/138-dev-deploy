#!/bin/bash
set -e

# Setup validator node with monitoring
REGION=$1
if [ -z "$REGION" ]; then
    echo "Usage: $0 <region>"
    exit 1
fi

# Install and configure monitoring stack
echo "Setting up monitoring for $REGION..."
cat > prometheus.yml <<EOF
global:
  scrape_interval: 15s
scrape_configs:
  - job_name: 'besu'
    static_configs:
      - targets: ['localhost:9545']
EOF

# Start monitoring stack
docker-compose up -d prometheus grafana

# Initialize validator
echo "Initializing validator node for $REGION..."
./plugin-setup.sh
./start-node.sh --data-path=data-$REGION --config-file=node-config.toml

echo "Validator node setup complete for $REGION"
