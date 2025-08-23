# VPS Installation & Grundsetup (IONOS)

## 1. Server vorbereiten

- Basis: **Ubuntu LTS** auf Ionos VPS.
- In Ionos Firewall **22/tcp** und die benötigten **WireGuard-Ports (UDP)** öffnen.
- Nach Einrichtung kann **22/tcp** wieder gesperrt werden.

## 2. System aktualisieren & Pakete installieren

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y software-properties-common wireguard wireguard-tools unzip
```

## 3. Benutzer & SSH absichern

```bash
sudo adduser vpsuser
sudo usermod -aG sudo vpsuser
sudo nano /etc/ssh/sshd_config
```

Ändern:
```ini
PermitRootLogin no
```

Neustarten:
```bash
sudo systemctl restart sshd
```

SSH Key hinterlegen, anschließend mit neuem User verbinden:
```bash
ssh vpsuser@<VPS_IP>
```

