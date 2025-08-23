# Firewall UDM Pro & VPS

## 1. Grundprinzipien Firewall-Regeln & Routing

- **Heimnetz 1** hat Zugriff auf alle anderen Heimnetze.  
- **Heimnetz 2, 3 und 4** haben keinen direkten Zugriff aufeinander, sondern nur auf Heimnetz 1.  
- **Mobile Clients** (Firezone) haben Zugriff auf Heimnetz 1, aber nicht auf Heimnetz 2, 3 oder 4.  
- Falls doppelte Subnetze vorkommen, werden sie per NAT auf dem VPS umgeschrieben.

👉 **AllowedIPs** sind bewusst breiter (ganze Subnetze) definiert, um Änderungen an den `.conf`-Dateien zu vermeiden.  
Die Feineinstellung erfolgt **immer über die UDM Pro Firewall**.

---

## 2. Schritt-für-Schritt Firewall-Konfiguration UDM Pro

### 2.1 Netzwerk-Objekte anlegen

**Ort:** *UniFi → Settings → Profiles → Network Groups → Create new*  

| Name          | Typ     | Inhalt            |
|---------------|---------|-------------------|
| VPN-HN2       | Subnet  | `192.168.20.0/24` |
| VPN-Firezone  | Subnet  | `10.10.50.0/24`   |
| UDM-Pro       | Address | `192.168.10.1`    |
| NAS           | Address | `192.168.30.2`    |
| HomeAssistant | Address | `192.168.50.12`   |
| VPS-Tunnel    | Address | `10.10.20.1`      |

---

### 2.2 Port-Gruppen anlegen

**Ort:** *UniFi → Settings → Profiles → Port Groups → Create new*  

| Name        | Ports            | Protokoll | Zweck              |
|-------------|------------------|-----------|--------------------|
| Ports-UDM   | 22,443           | TCP       | SSH, WebUI UDM     |
| Ports-NAS   | 22,445,5000,5001 | TCP       | SSH, SMB, DSM Web  |
| Ports-HA    | 8123             | TCP       | Home Assistant     |
| Ports-VPS   | 22               | TCP       | SSH zum VPS        |

---

### 2.3 Firewall-Regeln erstellen

#### Internet Local (Zugriff auf UDM & VPS)

1. **HN2 → UDM-Pro (Web/SSH)**  
   - Action: **Allow**  
   - Source: `VPN-HN2`  
   - Destination: `UDM-Pro`  
   - Port Group: `Ports-UDM`

2. **HN2 → VPS (SSH im Tunnel)**  
   - Action: **Allow**  
   - Source: `VPN-HN2`  
   - Destination: `VPS-Tunnel`  
   - Port Group: `Ports-VPS`

3. **Firezone → UDM-Pro (Web/SSH)**  
   - Action: **Allow**  
   - Source: `VPN-Firezone`  
   - Destination: `UDM-Pro`  
   - Port Group: `Ports-UDM`

#### Internet In (Zugriff auf LAN-Geräte)

4. **HN2 → NAS**  
   - Action: **Allow**  
   - Source: `VPN-HN2`  
   - Destination: `NAS`  
   - Port Group: `Ports-NAS`

5. **HN2 → Home Assistant**  
   - Action: **Allow**  
   - Source: `VPN-HN2`  
   - Destination: `HomeAssistant`  
   - Port Group: `Ports-HA`

6. **Firezone → NAS**  
   - Action: **Allow**  
   - Source: `VPN-Firezone`  
   - Destination: `NAS`  
   - Port Group: `Ports-NAS`

7. **Firezone → Home Assistant**  
   - Action: **Allow**  
   - Source: `VPN-Firezone`  
   - Destination: `HomeAssistant`  
   - Port Group: `Ports-HA`

#### Block-All

8. **HN2 → Drop All (Local & In)**  
   - Action: **Drop**  
   - Source: `VPN-HN2`  
   - Destination: Any  
   - Ports: Any  
   - **Ganz unten platzieren!**

9. **Firezone → Drop All (Local & In)**  
   - Action: **Drop**  
   - Source: `VPN-Firezone`  
   - Destination: Any  
   - Ports: Any  
   - **Ganz unten platzieren!**

---

## 3. Schritt-für-Schritt Firewall-Konfiguration VPS (nftables)

### 3.1 Zielsetzung
- Verkehr **aus HN2** (Interface `hn2`) darf nur zu:  
  - `192.168.10.1` (UDM Pro)  
  - `192.168.30.2` (NAS)  
  - `192.168.50.12` (Home Assistant)  
  - `10.10.20.1` (VPS selbst, SSH im Tunnel)
- Verkehr **aus Firezone** (Interface `firezone`) darf nur zu:  
  - `192.168.10.1` (UDM Pro)  
  - `192.168.30.2` (NAS)  
  - `192.168.50.12` (Home Assistant)

### 3.2 Konfiguration

```bash
sudo nano /etc/nftables.conf
```

```nft
#!/usr/sbin/nft -f

flush ruleset

table inet filter {

  chain input {
    type filter hook input priority 0;
    policy drop;

    # Loopback & etablierte Verbindungen
    iif lo accept
    ct state established,related accept

    # WireGuard-UDP-Ports (UDM/HN1, HN2, Firezone)
    udp dport { 55120, 51822, 55121 } accept

    # SSH nur im Tunnel (HN2)
    iif "hn2" tcp dport 22 accept

    # (Optional) Firezone HTTPS
    # tcp dport {80,443} accept
  }

  chain forward {
    type filter hook forward priority 0;
    policy drop;

    # Etablierte Sessions
    ct state established,related accept

    # HN2 → erlaubte Ziele
    iif "hn2" ip daddr { 192.168.10.1, 192.168.30.2, 192.168.50.12, 10.10.20.1 } accept

    # Firezone → erlaubte Ziele
    iif "firezone" ip daddr { 192.168.10.1, 192.168.30.2, 192.168.50.12 } accept
  }
}
```

### 3.3 Aktivieren & prüfen

```bash
sudo systemctl enable nftables
sudo systemctl restart nftables
sudo nft list ruleset
```

---

## 4. Best Practices
- **UDM Pro:** Regeln immer in Internet Local & In trennen. Allow-Regeln oben, Drop-All ganz unten.  
- **VPS:** Policy = Drop, nur Whitelist aktiv.  
- **SSH:** ausschließlich im Tunnel verfügbar, Public-SSH auf dem VPS deaktivieren.  
- **Fallback:** Ein Admin-Client über Firezone mit vollen Rechten einplanen, falls man sich aussperrt.

---

## 5. Checkliste für Tests

### VPN Tunnel
```bash
wg show
```
- Prüfen, ob **latest handshake** aktuell ist.  
- Übertragenes Volumen (`transfer`) zeigt, ob Daten fließen.

### Pings
- Von VPS → UDM:
```bash
ping 192.168.10.1
```
- Von VPS → NAS:
```bash
ping 192.168.30.2
```
- Von VPS → Home Assistant:
```bash
ping 192.168.50.12
```

### Dienste testen
- Home Assistant vom HN2-Client:
```bash
curl http://192.168.50.12:8123
```
- UDM Weboberfläche:
```bash
curl -k https://192.168.10.1
```

### nftables Ruleset prüfen
```bash
sudo nft list ruleset
```
- Sicherstellen, dass `policy drop` aktiv ist.  
- Erlaubte Ziele erscheinen als Whitelist-Einträge.

---

