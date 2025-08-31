# Raspberry Pi 5 als VPN-Gateway für HN2

## 1. OS/SSD & Erststart
- OS: Raspberry Pi OS Lite 64-bit  
- SSD flashen mit Raspberry Pi Imager (Voreinstellungen: Hostname, SSH an).  
- Erst-Login per SSH, System-Updates, Hostname setzen.  

```bash
sudo apt update && sudo apt upgrade -y
sudo raspi-config   # Hostname setzen
```

## 2. Netzwerk-Grundsetup
- Statische IP für `eth0`: `192.168.20.10/24`, GW `192.168.20.1`.  
- DNS: `192.168.20.1` + `1.1.1.1`.  
- Konfiguration via `nmtui`.  
- Neustart, mit `ip addr` und `ip route` prüfen.  

Beispielausgabe:
```
default via 192.168.20.1 dev eth0 proto static metric 100
192.168.20.0/24 dev eth0 proto kernel scope link src 192.168.20.10 metric 100
```

- IP-Forwarding aktivieren:
```bash
sudo sysctl -w net.ipv4.ip_forward=1
echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf
```

## 3. SSH-Härtung
- `PasswordAuthentication` → `no` (nach erfolgreichem Key-Test).  
- `PermitRootLogin` → `no`.  
- Login via SSH-Key (Laptop → `ssh-copy-id`, iPad via RDM-Keys).  
- sshd reload:
```bash
sudo systemctl reload ssh
```

## 4. WireGuard auf dem Pi
- Key und PSK generieren:
```bash
wg genkey | tee privatekey | wg pubkey > publickey
wg genpsk > presharedkey
```

- `/etc/wireguard/wg0.conf`:
```ini
[Interface]
Address = 10.10.20.2/32
PrivateKey = <PI_PRIVATE>

[Peer]
PublicKey = <VPS_PUBLIC_HN2>
PresharedKey = <PSK_HN2>
Endpoint = <VPS_HOST>:51822
AllowedIPs = 10.10.10.0/24, 192.168.10.0/24, 192.168.30.0/24, 192.168.40.0/24, 192.168.50.0/24, 192.168.60.0/24
PersistentKeepalive = 25
```

- Aktivieren:
```bash
sudo systemctl enable wg-quick@wg0
sudo systemctl start wg-quick@wg0
```

- Status prüfen:
```bash
sudo wg show
ip addr show wg0
```

## 5. VPS-Peer ergänzen
- Peer in VPS-WG-Konfig:
```ini
[Peer]
PublicKey = <PI_PUBLIC>
PresharedKey = <PSK_HN2>
AllowedIPs = 10.10.20.2/32, 192.168.20.0/24
```
- Service reload, `wg show` prüfen.  

## 6. Basis-Tests
- Vom Pi:
```bash
ping -c3 10.10.20.1      # VPS
ping -c3 192.168.10.1    # UDM
```

- Vom VPS: ping ins HN2 via 10.10.20.2.  
- Vom UDM: ping ins HN2 (`192.168.20.10`).  
- Mit `traceroute` sichtbar: FritzBox → Pi → VPS → UDM.  
- **Wichtig:** FritzBox selbst (192.168.20.1) ist vom Tunnel aus nicht erreichbar (keine Route zurück).

## 7. Monitoring (Node Exporter)
- Installation:
```bash
wget https://github.com/prometheus/node_exporter/releases/download/v1.8.2/node_exporter-1.8.2.linux-arm64.tar.gz
tar -xzf node_exporter-*.tar.gz
sudo mv node_exporter-*/node_exporter /usr/local/bin/
```

- systemd-Unit:
```ini
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
ExecStart=/usr/local/bin/node_exporter
User=nobody
Restart=on-failure

[Install]
WantedBy=default.target
```

- Port 9100/tcp → aus HN1 erreichbar.  
- Test: `curl http://192.168.20.10:9100/metrics` (vom VPS/UDM).  

## 8. Firewall (nftables)
- Policy: DROP, gezielte Erlaubnisse.  
- `/etc/nftables.conf`:
```nft
table inet filter {
  chain input {
    type filter hook input priority 0; policy drop;
    ct state established,related accept
    iifname "lo" accept
    ip protocol icmp accept
    iifname "eth0" tcp dport 22 ip saddr 192.168.20.0/24 accept
    iifname "wg0"  tcp dport 22 ip saddr 10.10.20.1 accept
    iifname "wg0"  tcp dport 9100 ip saddr {192.168.10.0/24,10.10.10.2,10.10.20.1} accept
  }

  chain forward {
    type filter hook forward priority 0; policy drop;
    ct state established,related accept
    iif "eth0" oif "wg0" ip saddr 192.168.20.0/24 ip daddr { 192.168.10.1, 192.168.30.2, 192.168.50.12 } accept
    iif "eth0" oif "wg0" ip saddr 192.168.20.0/24 ip daddr 10.10.20.1 tcp dport 22 accept
  }

  chain output {
    type filter hook output priority 0; policy drop;
    ct state established,related accept
    oifname "lo" accept
    ip protocol icmp accept
    udp dport 53 accept
    tcp dport 53 accept
    ip daddr 194.164.204.150 udp dport 51822 oifname "eth0" accept
    tcp dport {80,443} accept
  }
}
```

- Aktivieren:
```bash
sudo systemctl enable nftables
sudo systemctl restart nftables
```

## 9. Firezone (VPS)
- Firezone läuft in Docker, NAT bleibt aktiv (Clients erscheinen als 10.10.20.1).  
- Zugriff auf Pi via nftables für `10.10.20.1` explizit freigeschaltet.  
- Caddy reverse-proxy für Web-UI.  

## 10. Tests & Troubleshooting
- Tools: `dnsutils`, `tcpdump`, `traceroute`, `curl`.  
- Systematische Teststufen:  
  - RPi → VPS → UDM  
  - VPS → Pi (SSH, Prometheus)  
  - UDM → Pi (über Tunnel)  
  - Firezone-Client → Pi/UDM/NAS  

---

# Fazit
- Split-Tunnel umgesetzt: Internet in HN2 läuft über FritzBox, interne Netze via Tunnel.  
- Pi routet ohne NAT, Firewall regelt selektiv.  
- Monitoring eingebunden.  
- Firezone-Clients funktionieren mit NAT (SRC=10.10.20.1).  
