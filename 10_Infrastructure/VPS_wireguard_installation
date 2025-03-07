# WireGuard VPN Bridge Dokumentation

## 📌 Netzwerkarchitektur

Die WireGuard-VPN-Bridge ermöglicht die Verbindung zwischen mehreren Heimnetzen sowie mobilen Clients. Alle Heimnetze und Peers sind über den zentralen VPS-Server verbunden.

### **Subnetze der Heimnetze**

| Heimnetz   | Funktion                   | Subnetz           |
|------------|----------------------------|-------------------|
| Heimnetz 1 | Admin / Netzwerkgeräte     | 192.168.10.0/24   |
|            | Productive                 | 192.168.30.0/24   |
|            | Guests                     | 192.168.40.0/24   |
|            | IoT                        | 192.168.50.0/24   |
|            | Work                       | 192.168.60.0/24   |
| Heimnetz 2 | Hauptnetz                  | 192.168.70.0/24   |
|            | IoT                        | 192.168.75.0/24   |
|            | Gäste                      | 192.168.76.0/24   |
| Heimnetz 3 | Hauptnetz (Freund 1)       | 192.168.80.0/24   |
|            | IoT                        | 192.168.85.0/24   |
| Heimnetz 4 | Hauptnetz (Freund 2)       | 192.168.90.0/24   |
|            | IoT                        | 192.168.95.0/24   |
| VPN-Clients | Mobile Geräte             | 10.10.50.0/24     |

### **WireGuard Peers**

| Peer                 | IP-Adresse   | Beschreibung                           |
|----------------------|--------------|----------------------------------------|
| VPS-Server           | 10.10.10.1   | Zentrale VPN-Bridge (WireGuard-Server) |
| UDM Pro (Heimnetz 1) | 10.10.10.2   | Heimnetz 1 Gateway                     |
| Heimnetz 2           | 10.10.20.1   | Gateway für Heimnetz 2                 |
| Heimnetz 3           | 10.10.30.1   | Gateway für Heimnetz 3 (Freund 1)      |
| Heimnetz 4           | 10.10.40.1   | Gateway für Heimnetz 4 (Freund 2)      |
| Mobiler Client 1     | 10.10.50.10  | Laptop                                 |
| Mobiler Client 2     | 10.10.50.11  | iPad                                   |
| Mobiler Client 3     | 10.10.50.12  | Handy                                  |

---

### **Setup VPS Client**

#### **1. Installation (Ionos VPS XS)**
- Auf dem VPS wird ein Ubuntu installiert.
- In den Einstellungen der Firewall unter Netzwerk wird der Port **22 TCP** geöffnet (für SSH) und der **WireGuard-Port 55120 UDP**.
- Nach Aufbau der Verbindung kann Port 22 in der Ionos-Firewall wieder geschlossen werden.
- Falls später **Firezone** genutzt wird, müssen auch **Port 80/443** geöffnet werden.
- **Der VPS sollte nicht als root laufen.**

##### **Benutzer anlegen und root deaktivieren**
```bash
sudo adduser vpsuser
sudo usermod -aG sudo vpsuser
sudo nano /etc/ssh/sshd_config
```
Ändere folgende Zeilen:
```plaintext
PermitRootLogin no
```
Danach den SSH-Dienst neu starten:
```bash
sudo systemctl restart sshd
```
Anschließend mit dem neuen Benutzer anmelden:
```bash
ssh vpsuser@VPS_IP
```

##### **SSH Keys erstellen und einbinden**
[Link zur Anleitung]

---



## 🔧 **Installieren von WireGuard auf dem VPS**

### 2️⃣ **WireGuard Installation**
```bash
sudo apt update -y && sudo apt upgrade -y && sudo apt install software-properties-common wireguard wireguard-tools unzip -y
```

### 3️⃣ **IP-Forwarding aktivieren**
```bash
sudo nano /etc/sysctl.conf
```
**Folgende Zeilen am Ende hinzufügen:**
```plaintext
# Enable IPv4 packet forwarding
net.ipv4.ip_forward=1

# Enable Proxy ARP
net.ipv4.conf.all.proxy_arp=1

# Disable IPv6 packet forwarding
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
```
**Änderungen aktivieren:**
```bash
sudo sysctl -p && sudo sysctl --system
```

### 4️⃣ **Schlüssel generieren**
```bash
(umask 077 && printf "PrivateKey= " | sudo tee /etc/wireguard/privatekey_unifi > /dev/null) && wg genkey | sudo tee -a /etc/wireguard/privatekey_unifi | wg pubkey | sudo tee /etc/wireguard/publickey_unifi && sudo cat /etc/wireguard/privatekey_unifi && sudo touch /etc/wireguard/unifi.conf
```

### 5️⃣ **Schlüssel anzeigen**
```bash
sudo cat /etc/wireguard/privatekey_unifi && sudo cat /etc/wireguard/publickey_unifi
```

### 6️⃣ **WireGuard Konfiguration erstellen**
```bash
sudo nano /etc/wireguard/unifi.conf
```
**Folgenden Inhalt einfügen:**
```ini
[Interface]
PrivateKey= !!!Private Key der oben erzeugt wurde!!!
ListenPort = 55120
Address = 10.10.10.1/32

# Standard Routing
# Die Netzwerkkarte eth0 muss angepasst werden (z.B. via `ip addr` prüfen)
PostUp     = iptables -t nat -A POSTROUTING -o unifi -j MASQUERADE
PostDown   = iptables -t nat -D POSTROUTING -o unifi -j MASQUERADE
PostUp     = iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown   = iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
PublicKey = !!!PUBLIC KEY DER UDM PRO (aus WireGuard Client kopieren)!!!
AllowedIPs = 10.10.10.0/24, 192.168.50.0/24
# bei AllowedIPs gegebenenfalls weitere Heimnetzsubnetze eintragen. Die Freigabe einzelner IPs erfolgt dann in der UDMPro Firewall
```

### 6️⃣ **WireGuard starten und aktivieren**
```bash
sudo systemctl start wg-quick@unifi && sudo systemctl enable wg-quick@unifi
```

### 7️⃣ **Testen, ob WireGuard läuft**
```bash
sudo wg
```
**Der Status sollte folgendes anzeigen:**
```plaintext
interface: unifi
  public key: (KEY)
  private key: (hidden)
  listening port: 55120

peer: (KEY)
  endpoint: IP:AusgehandelterPort
  allowed ips: Die erlaubten IP-Bereiche
  latest handshake: 7 seconds ago
  transfer: 30.43 kB received, 93.85 kB sent
```
Falls unten unter `transfer` kein Datenverkehr zu sehen ist, ist die Verbindung nicht korrekt aufgebaut.

## **Routing und Firewall**

### 1️⃣ **Routen eintragen**

#### **Auf dem VPS**
Die folgenden Routen müssen hinzugefügt werden, um die Kommunikation mit der UDM und dem Heimnetz 1 zu ermöglichen:
```bash
# Vermutlich nicht erforderlich. Wichtig ist, dass alle beteiligten Netzte bei AllowedIPs in Firezone eingetragen sind. 
#sudo ip route add 10.10.10.0/24 via 10.10.10.2 dev unifi
#sudo ip route add 192.168.10.0/24 via 10.10.10.2 dev unifi
```

#### **Auf der UDM Pro**
Im **UniFi Webinterface** unter **Routing & Firewall**:
1. Gehe zu **Statische Routen** und füge eine neue Route hinzu:
   - **Name:** VPN-Routing
   - **Subnetz:** `10.10.10.0/24`
   - **Nächster Hop:** `10.10.10.2`
   - **Distance:** `1`

2. Eine zweite Route für das Heimnetz hinzufügen:
   - **Name:** VPN-Heimnetz
   - **Subnetz:** `192.168.10.0/24`
   - **Nächster Hop:** `10.10.10.2`
   - **Distance:** `1`

### 2️⃣ **Firewall-Regeln auf der UDM Pro**
#### **Netzwerkprofile erstellen**
Erstelle unter **Einstellungen → Profiles --> Network Objects** neue Netzwerkprofile:
- `VPN - VPN Adress Dreammaschine`
- `VPN - VPN Networks`
- `VPN - VPS WireGuard Server Adress`

#### **Firewall-Regeln für VPN Zugriff**
✅ 1. **Regel für die Kommunikation vom VPS zur UDM** (Internet Local & Internet In)
   - **Name:** `VPN-Allow-VPS-to-DM`
   - **Typ:** Internet Local
   - **Aktion:** **Allow**
   - **Protokoll:** **UDP, TCP**
   - **Source Type:** Object
   - **Address Group:** `VPN-VPS`
   - **Port Object:** `WireGuard-Port (55120)`, `SSH (22)`
   - **Destination Type:** Object
   - **Address Group:** `VPN-DreamMachine`
   - **Port Object:** `WireGuard-Port (55120)`, `SSH (22)`

✅ 2. **Regel für den Ping-Test (ICMP)** (Internet Local & Internet In)
   - **Name:** `VPN-Allow-ICMP`
   - **Typ:** Internet Local
   - **Aktion:** **Allow**
   - **Protokoll:** **ICMP**
   - **Source Type:** Object
   - **Address Group:** `VPN-VPS`
   - **Destination Type:** Object
   - **Address Group:** `VPN-DreamMachine`

### **Hinweis zur aktuellen Unifi-Firewall-Lösung**
Derzeit wird das VPN-Netzwerk in UniFi nicht als LAN erkannt, sondern als "Internet" klassifiziert. Das führt dazu, dass Firewall-Regeln über "Internet Local" und "Internet In" erstellt werden müssen. Eine saubere Lösung wäre es, das VPN-Netzwerk als LAN einzubinden, was aktuell in UniFi nicht direkt möglich ist. Deshalb ist dieser Workaround erforderlich.

Speichere die Regeln und wende sie an. Nach wenigen Sekunden sollten sie aktiv sein.

Nun kann getestet werden, ob der Zugriff funktioniert:
```bash
ping 10.10.10.2
ping 192.168.10.1
```

---


## ** WireGuard Bridge härten **

### ** Firewall VPS Server - minimale offene Ports **

Wenn die WireGuard Bridge funktioniert, können alle Ports blockiert werden, bis auf die WireGuard Ports.

#### ✅ Erforderliche Ports (offen lassen)
| Dienst        | Port    | Protokoll | Zweck |
|--------------|--------|----------|------|
| **WireGuard (nativ, zur UDM)** | `55120` | UDP | Verbindung zur UDM |
| **Firezone (Docker, für Clients)** | `51820` | UDP | Verbindung für VPN-Clients |

#### ❌ Nicht benötigte Ports (schließen)
| Dienst        | Port    | Protokoll | Grund |
|--------------|--------|----------|------|
| **Firezone Webinterface (HTTPS)** | `443` | TCP | Nur für neue Client-Anmeldungen nötig |
| **Firezone Webinterface (HTTP Redirect)** | `80` | TCP | Kann abgeschaltet werden, wenn nicht genutzt |
| **SSH (falls nicht remote nötig)** | `22` | TCP | Nur offen lassen, wenn SSH gebraucht wird |


### ** 🔒 Maximale Härtung der UDM Pro Firewall **

#### 📌 Ziel:
Nur noch die folgenden Verbindungen zulassen:  
1️⃣ **Firezone-Clients → Heimserver `192.168.0.50` auf Port `8123`**  
2️⃣ **Firezone-Clients → VPS (`10.10.10.1`) auf SSH (`Port 22`)**  

🚀 **Alles andere wird blockiert!**  

---

### ** 🛠 1️⃣ Firewall-Regeln für UDM Pro anpassen **

#### ✅ Regel 1: Zugriff auf den Heimserver (`192.168.0.50:8123`) erlauben
**Standort:** `Einstellungen → Routing & Firewall → Firewall-Regeln → Internet Local & Internet In`
- **Name:** `Allow Firezone → Heimserver`
- **Aktion:** **Allow**
- **Source:** `VPN-Firezone (10.10.50.0/24)`
- **Destination:** `192.168.0.50`
- **Protokoll:** **TCP**
- **Port:** `8123`

---

#### ✅ Regel 2: Zugriff auf den VPS (`10.10.10.1:22`) erlauben
**Standort:** `Einstellungen → Routing & Firewall → Firewall-Regeln → Internet Local & Internet In`
- **Name:** `Allow Firezone → VPS SSH`
- **Aktion:** **Allow**
- **Source:** `VPN-Firezone (10.10.50.0/24)`
- **Destination:** `10.10.10.1`
- **Protokoll:** **TCP**
- **Port:** `22`

---

#### ❌ Regel 3: Alle anderen Verbindungen blockieren (Default-Deny)
**Standort:** `Einstellungen → Routing & Firewall → Firewall-Regeln → Internet Local & Internet In`
- **Name:** `Block All Firezone`
- **Aktion:** **Deny**
- **Source:** `VPN-Firezone (10.10.50.0/24)`
- **Destination:** `Any`
- **Protokoll:** `Any`
- **Port:** `Any`

🚀 **Reihenfolge der Regeln beachten!**  
⚠️ **Die Block-Regel muss ganz unten stehen**, damit erst die erlaubten Verbindungen durchgelassen werden.

---