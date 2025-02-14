#!/bin/bash
set -e

# Login to Azure (assuming already authenticated via environment)
echo "Deploying infrastructure across regions..."

# Deploy main bicep template
az deployment sub create \
  --name hyperledger-deployment-$(date +%s) \
  --location australiaeast \
  --template-file main.bicep \
  --confirm-with-what-if

echo "Infrastructure deployment initiated..."
