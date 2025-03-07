#!/bin/bash

# Enable IP forwarding
echo "Enabling IP forwarding..."
echo 1 > /proc/sys/net/ipv4/ip_forward
sysctl -w net.ipv4.ip_forward=1

# Ensure responses dynamically return to the Routing VPS
echo "Allowing forwarding rules for dynamic response handling..."
iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -j ACCEPT

# Save iptables rules
echo "Saving iptables rules..."
mkdir -p /etc/iptables
iptables-save > /etc/iptables/rules.v4

echo "Main VPS setup completed!"
