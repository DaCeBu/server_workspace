# Raspberry Pi 5 VPN-Gateway Playbook

## 1. Hardware Setup
- Raspberry Pi 5 (8 GB RAM empfohlen)
- Netzteil 27W USB-C
- Aktiver Kühler oder Gehäuse mit Kühlung
- NVMe SSD Kit für das Root-Dateisystem
- Gehäuse (z. B. KKSB mit GPIO Zugang)
- Patchkabel Cat 6a oder Cat 7 für >1 Gbit/s

---

## 2. OS-Installation
- Raspberry Pi Imager nutzen → **Raspberry Pi OS Lite (64bit)** oder **Ubuntu Server 24.04 LTS**
- Direkt auf die NVMe SSD flashen
- Erststart mit Monitor+Tastatur oder per Netzwerk (falls SSH aktiviert)

---

## 3. Grundsetup

### 3.1 User anlegen
```bash
sudo adduser piadmin
sudo usermod -aG sudo piadmin
```

### 3.2 System aktualisieren
```bash
sudo apt update && sudo apt upgrade -y
```

### 3.3 SSH aktivieren (falls nicht aktiv)
```bash
sudo systemctl enable ssh --now
```

### 3.4 SSH absichern (Keys & Passwort deaktivieren)

#### Alternative 1: SSH-Key auf dem Laptop erzeugen & hochladen
```bash
ssh-keygen -t ed25519 -C "mein-laptop"
ssh-copy-id piadmin@<PI_IP>
```

#### Alternative 2: SSH-Key direkt auf dem Pi erzeugen
```bash
ssh-keygen -t ed25519 -C "pi@vpn-gateway"
cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

#### Auf dem Pi `sshd_config` anpassen
```bash
sudo nano /etc/ssh/sshd_config
```
Ändern/ergänzen:
```ini
PasswordAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
```

SSH neu starten:
```bash
sudo systemctl restart sshd
```

Jetzt ist nur noch **Login per SSH-Key** möglich.

---

## 4. WireGuard installieren
```bash
sudo apt install wireguard wireguard-tools -y
```

- Keys generieren: `wg genkey | tee privatekey | wg pubkey > publickey`
- Config anlegen: `/etc/wireguard/wg0.conf`
- Systemdienst starten: `sudo systemctl enable wg-quick@wg0 --now`

---

## 5. Firewall (nftables)
- `sudo apt install nftables`
- Regeln analog zur VPS-Doku setzen (Drop by default, nur definierte Netze & Ports erlauben)

---

## 6. Monitoring-Agent (Integration HN1)

Damit der Pi ins zentrale Monitoring (z. B. Prometheus in HN1) eingebunden werden kann:

### 6.1 Node Exporter installieren
```bash
wget https://github.com/prometheus/node_exporter/releases/download/v1.8.1/node_exporter-1.8.1.linux-arm64.tar.gz
tar xvf node_exporter-*.tar.gz
sudo mv node_exporter-*/node_exporter /usr/local/bin/
```

### 6.2 Systemd Service anlegen
```bash
sudo nano /etc/systemd/system/node_exporter.service
```
Inhalt:
```ini
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
ExecStart=/usr/local/bin/node_exporter
User=nobody
Group=nogroup

[Install]
WantedBy=multi-user.target
```

Aktivieren & starten:
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now node_exporter
```

### 6.3 Firewall-Port freigeben
- Node Exporter läuft auf Port **9100/tcp**.
- In nftables oder UDM-Regeln nur von HN1-Monitoring-Server erlauben.

### 6.4 Test
Von HN1 aus prüfen:
```bash
curl http://<PI_IP>:9100/metrics
```

---

## 7. Tests
- `wg show` → prüft Handshake & Traffic
- `ping` zwischen Tunnel-Endpunkten (10.10.x.x)
- `curl` auf definierte Ziele (z. B. Home Assistant, NAS)
- Monitoring erreichbar auf `http://<PI_IP>:9100/metrics`

---

## 8. Pflege
- Regelmäßig `sudo apt update && sudo apt upgrade -y`
- `sudo wg` zur VPN-Überwachung
- Logs prüfen: `journalctl -u wg-quick@wg0`, `journalctl -u node_exporter`
- Updates für Prometheus Node Exporter gelegentlich einspielen

