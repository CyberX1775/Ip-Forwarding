#!/bin/bash

# Prompt for the Main VPS IP
read -p "Enter the Main VPS IP: " MAIN_VPS_IP

# Enable IP forwarding
echo "Enabling IP forwarding..."
echo 1 > /proc/sys/net/ipv4/ip_forward
sysctl -w net.ipv4.ip_forward=1

# Set up NAT for outgoing traffic (MASQUERADE for all traffic)
echo "Setting up NAT for outgoing traffic..."
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Forward all incoming traffic to the Main VPS (dynamic handling of all ports and protocols)
echo "Forwarding all traffic to Main VPS ($MAIN_VPS_IP)..."
iptables -t nat -A PREROUTING -j DNAT --to-destination $MAIN_VPS_IP

# SNAT to ensure responses go back through Routing VPS
echo "Setting up SNAT to ensure proper routing of responses..."
iptables -t nat -A POSTROUTING -j MASQUERADE

# Allow forwarding rules
echo "Allowing forwarding rules..."
iptables -A FORWARD -d $MAIN_VPS_IP -j ACCEPT
iptables -A FORWARD -s $MAIN_VPS_IP -j ACCEPT

# Save iptables rules
echo "Saving iptables rules..."
mkdir -p /etc/iptables
iptables-save > /etc/iptables/rules.v4

echo "Routing VPS setup completed!"
