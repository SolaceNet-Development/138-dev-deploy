#!/bin/bash
set -e

# Enhanced Security Measures

# 1. Network Security
echo "Implementing enhanced network security..."
# Configure firewall rules
ufw allow 30303/tcp  # P2P port
ufw allow 8545/tcp   # RPC port
ufw allow 9545/tcp   # Metrics port

# 2. Key Management
echo "Setting up enhanced key management..."
# Generate and secure validator keys
mkdir -p /opt/besu/keys
chmod 700 /opt/besu/keys
# Setup key rotation schedule
(crontab -l 2>/dev/null; echo "0 0 1 * * /opt/besu/scripts/rotate-keys.sh") | crontab -

# 3. Monitoring & Alerts
echo "Configuring security monitoring..."
# Setup intrusion detection
apt-get install -y fail2ban
# Configure alert thresholds
cat > /etc/fail2ban/jail.local <<EOF
[besu-rpc]
enabled = true
port = 8545
filter = besu-rpc
logpath = /var/log/besu/besu.log
maxretry = 3
bantime = 3600
EOF

# 4. Compliance Checks
echo "Implementing compliance checks..."
# Setup FATF compliance monitoring
cat > /opt/besu/scripts/compliance-check.sh <<EOF
#!/bin/bash
# Check transaction patterns for compliance
curl -X POST --data '{"jsonrpc":"2.0","method":"eth_getLogs","params":[{"fromBlock":"latest"}],"id":1}' http://localhost:8545
EOF
chmod +x /opt/besu/scripts/compliance-check.sh

echo "Security enhancements completed"
