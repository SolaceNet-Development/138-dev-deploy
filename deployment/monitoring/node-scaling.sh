#!/bin/bash
set -e

# Dynamic Node Scaling based on network metrics
METRICS_ENDPOINT="http://localhost:9545/metrics"
MIN_NODES=4
MAX_NODES=16
SCALE_UP_TPS=1000
SCALE_DOWN_TPS=500

while true; do
    # Get current TPS
    current_tps=$(curl -s $METRICS_ENDPOINT | grep besu_blockchain_transactions_total | awk '{print $2}')
    
    # Get current node count
    current_nodes=$(curl -s $METRICS_ENDPOINT | grep besu_network_peer_count | awk '{print $2}')
    
    if [ "$current_tps" -gt "$SCALE_UP_TPS" ] && [ "$current_nodes" -lt "$MAX_NODES" ]; then
        echo "Scaling up nodes due to high TPS"
        ./validator-setup.sh
    elif [ "$current_tps" -lt "$SCALE_DOWN_TPS" ] && [ "$current_nodes" -gt "$MIN_NODES" ]; then
        echo "Scaling down nodes due to low TPS"
        # Graceful node shutdown logic
    fi
    
    sleep 300  # Check every 5 minutes
done
