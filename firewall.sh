#!/usr/bin/env bash
set -euo pipefail

CHAIN="HW4-EGRESS"
AGENT_IP="172.30.0.10"
WEB_IP="172.30.0.40"
C2_IP="172.30.0.66"

# Enable filtering of bridged IPv4 traffic.
sudo modprobe br_netfilter
sudo sysctl -w net.bridge.bridge-nf-call-iptables=1

# Remove any previous HW4 rules before installing new ones.
./firewall-reset.sh

# Create a dedicated chain for HW4.
sudo iptables -N "$CHAIN"

# Rule 1: Allow established connections and related return traffic.
sudo iptables -A "$CHAIN" \
    -m conntrack --ctstate ESTABLISHED,RELATED \
    -j RETURN

# Rule 2: Allow legitimate HTTP traffic from agent-node to web-lab.
sudo iptables -A "$CHAIN" \
    -s "$AGENT_IP" -d "$WEB_IP" \
    -p tcp --dport 8000 \
    -m conntrack --ctstate NEW \
    -j RETURN

# Rule 3: Log new connections from agent-node to mock-c2:8080.
sudo iptables -A "$CHAIN" \
    -s "$AGENT_IP" -d "$C2_IP" \
    -p tcp --dport 8080 \
    -m conntrack --ctstate NEW \
    -j LOG --log-prefix "HW4-C2-DROP: " --log-level 4

# Rule 4: Drop new connections from agent-node to mock-c2:8080.
sudo iptables -A "$CHAIN" \
    -s "$AGENT_IP" -d "$C2_IP" \
    -p tcp --dport 8080 \
    -m conntrack --ctstate NEW \
    -j DROP

# Rule 5: Drop all other new forwarded connections from agent-node.
sudo iptables -A "$CHAIN" \
    -s "$AGENT_IP" \
    -m conntrack --ctstate NEW \
    -j DROP

# Rule 6: Return unrelated traffic to Docker's normal processing.
sudo iptables -A "$CHAIN" -j RETURN

# Connect the custom chain to Docker's user firewall chain.
sudo iptables -I DOCKER-USER 1 -j "$CHAIN"

echo "HW4 firewall installed successfully."
