#!/bin/bash
set -e

# Generate validator keys for each region
REGIONS=(
    "australiaeast"
    "germanywestcentral"
    "centralindia"
    "uaenorth"
    "brazilsouth"
    "francecentral"
    "uksouth"
    "japaneast"
    "southeastasia"
    "israelcentral"
    "polandcentral"
    "norwayeast"
    "spaincentral"
    "italynorth"
)

# Initialize validator keys and enode URLs
for region in "${REGIONS[@]}"; do
    echo "Generating keys for $region..."
    besu --data-path=data-$region public-key export-address --to=data-$region/address
    besu --data-path=data-$region public-key export --to=data-$region/node-public-key
    
    # Add node to permissions config
    ENODE=$(besu --data-path=data-$region public-key export-enode --to=data-$region/enode)
    echo "enode://$ENODE@$region:30303" >> permissions-config.toml
done

# Update genesis block with validator addresses
VALIDATOR_ADDRESSES=$(cat */address | tr '\n' ',' | sed 's/,$//')
sed -i "s/\"extraData\":.*$/\"extraData\": \"0x0000000000000000000000000000000000000000000000000000000000000000$VALIDATOR_ADDRESSES0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000\",/" qbft-config.json

echo "Network bootstrap configuration complete"
