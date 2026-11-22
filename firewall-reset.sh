#!/usr/bin/env bash
set -euo pipefail

# Name of the custom chain used by HW4.
CHAIN="HW4-EGRESS"

# Remove the jump from DOCKER-USER to our custom chain.
# The loop also handles accidental duplicate jump rules.
while sudo iptables -C DOCKER-USER -j "$CHAIN" 2>/dev/null; do
    sudo iptables -D DOCKER-USER -j "$CHAIN"
done

# Remove the custom chain if it exists.
if sudo iptables -L "$CHAIN" -n >/dev/null 2>&1; then
    sudo iptables -F "$CHAIN"
    sudo iptables -X "$CHAIN"
fi

echo "HW4 firewall rules removed successfully."
