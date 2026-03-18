cat >/root/portfwd_final.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

IFACE="$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}')"
PUBIP="$(ip -4 addr show dev "$IFACE" | awk '/inet /{print $2}' | cut -d/ -f1 | head -n1)"

# Forwarding + rp_filter (Hetzner /32 + DNAT için güvenli)
sysctl -w net.ipv4.ip_forward=1 >/dev/null
sysctl -w net.ipv4.conf.all.rp_filter=0 >/dev/null
sysctl -w net.ipv4.conf.default.rp_filter=0 >/dev/null
sysctl -w "net.ipv4.conf.${IFACE}.rp_filter=0" >/dev/null || true

mkdir -p /etc/sysctl.d
cat >/etc/sysctl.d/99-portfwd.conf <<SYS
net.ipv4.ip_forward=1
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
SYS

# Kendi chain'lerimiz (idempotent)
iptables -t nat -N PORTFWD 2>/dev/null || true
iptables -t nat -F PORTFWD
iptables -N PORTFWD_FWD 2>/dev/null || true
iptables -F PORTFWD_FWD

# Jump'lar
iptables -t nat -C PREROUTING -i "$IFACE" -j PORTFWD 2>/dev/null || iptables -t nat -I PREROUTING 1 -i "$IFACE" -j PORTFWD
iptables -t nat -C OUTPUT -d "$PUBIP/32" -j PORTFWD 2>/dev/null || iptables -t nat -I OUTPUT 1 -d "$PUBIP/32" -j PORTFWD
iptables -C FORWARD -j PORTFWD_FWD 2>/dev/null || iptables -I FORWARD 1 -j PORTFWD_FWD
iptables -C PORTFWD_FWD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || iptables -A PORTFWD_FWD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# SNAT/MASQUERADE
iptables -t nat -C POSTROUTING -o "$IFACE" -j MASQUERADE 2>/dev/null || iptables -t nat -A POSTROUTING -o "$IFACE" -j MASQUERADE

rules=(
  "46707 45.8.93.230"
  "8080 38.180.164.187"
  "1775 93.183.83.224"
  "10086 46.62.138.180"
  "1080 89.187.73.233"
  "443 51.77.32.235"
  "8443 91.107.153.131"
)

for r in "${rules[@]}"; do
  port="${r%% *}"; ip="${r##* }"
  iptables -t nat -A PORTFWD -p tcp --dport "$port" -j DNAT --to-destination "$ip:$port"
  iptables -t nat -A PORTFWD -p udp --dport "$port" -j DNAT --to-destination "$ip:$port"
  iptables -A PORTFWD_FWD -p tcp -d "$ip" --dport "$port" -j ACCEPT
  iptables -A PORTFWD_FWD -p udp -d "$ip" --dport "$port" -j ACCEPT
done

mkdir -p /etc/iptables
iptables-save > /etc/iptables/rules.v4

# Kalıcı yükleme (Debian/Ubuntu)
if command -v apt-get >/dev/null 2>&1; then
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y >/dev/null 2>&1 || true
  apt-get install -y iptables-persistent >/dev/null 2>&1 || true
  command -v netfilter-persistent >/dev/null 2>&1 && netfilter-persistent save >/dev/null 2>&1 || true
fi

echo "OK: applied on $PUBIP (iface=$IFACE)"
EOF

chmod +x /root/portfwd_final.sh
/root/portfwd_final.sh
