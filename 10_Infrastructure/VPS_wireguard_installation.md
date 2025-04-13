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


## ** 🔒 Maximale Härtung der UDM Pro Firewall **

### 🔧 Ziel

Erlaube einem VPN-Client (z. B. iPad via Firezone) den Zugriff auf **Home Assistant** im Heimnetzwerk.

### 📍 Server-Details

- **Home Assistant IP:** `192.168.101.12`
- **Home Assistant Port:** `8123` (TCP)
- **VPN-Subnetz(e):** `10.10.50.0/24`, `10.10.10.0/24`

---

### ✅ Schritt-für-Schritt Anleitung

#### **1️⃣ Profil erstellen: Zielgerät**

**Ort:** *UniFi → Settings → Profiles → Network Groups*

| Typ     | Name                                 | Inhalt              |
|---------|--------------------------------------|---------------------|
| Address | `VPN - Local Server - HomeAssistant` | `192.168.101.12`    |

---

#### **2️⃣ Profil erstellen: Ports**

**Ort:** *UniFi → Settings → Profiles → Port Groups*

| Typ     | Name                             | Ports   | Protokoll |
|---------|----------------------------------|---------|-----------|
| Port    | `VPN - Ports - HomeAssistant`    | `8123`  | TCP       |

---

#### **3️⃣ Firewallregel anlegen**

**Ort:** *UniFi → Settings → Firewall → Internet In*

| Feld              | Wert                                  |
|-------------------|----------------------------------------|
| **Name**          | `VPN → Home Assistant`                |
| **Action**        | `Allow`                               |
| **Protocol**      | `TCP`                                 |
| **Source Type**   | `Address Group`                       |
| **Source**        | `VPN - Remote Subnet`                 |
| **Destination Type** | `Address Group`                   |
| **Destination**   | `VPN - Local Server - HomeAssistant`  |
| **Port Group**    | `VPN - Ports - HomeAssistant`         |

> 🔁 **Wiederhole die Regel ggf. unter `Internet Local`, falls der Dienst auf der UDM selbst laufen sollte.**

---

### 🧪 Test

**Vom VPN-Client (iPad):**

```bash
curl http://192.168.101.12:8123
```
→ Sollte die Home Assistant Weboberfläche zurückliefern.


🚀 **Reihenfolge der Regeln beachten!**  
⚠️ **Die Block-Regel muss ganz unten stehen**, damit erst die erlaubten Verbindungen durchgelassen werden.

---

## 🧱 UniFi Firewall – Unterschied zwischen „Internet In“ und „Internet Local“ (bei VPN)

### 🔍 Hintergrund

UniFi unterscheidet zwei zentrale Firewall-Zonen für eingehende Verbindungen aus externen Netzwerken:

| Zone             | Beschreibung                                                                 |
|------------------|------------------------------------------------------------------------------|
| **Internet In**   | Betrifft alle Verbindungen **vom Internet** (z. B. VPN-Clients) an **interne Geräte** im LAN |
| **Internet Local** | Betrifft alle Verbindungen **vom Internet** an die **UDM Pro selbst** (z. B. Web UI, SSH)     |

### 📡 Warum betrifft VPN den „Internet“-Bereich?

Obwohl VPN-Clients oft IPs wie `10.10.x.x` erhalten, behandelt UniFi diese standardmäßig **nicht als LAN**, sondern als **Internet**.

Das gilt sowohl für:
- Firezone (z. B. `10.10.50.0/24`)
- WireGuard Bridge (z. B. `10.10.10.0/24`)

---

### ✅ Praxisbeispiele

| Zugriff von       | Ziel                 | Benötigte Zone     | Erklärung                            |
|-------------------|----------------------|---------------------|---------------------------------------|
| VPN-Client (iPad) | `192.168.100.16`     | **Internet In**      | Gerät im LAN                          |
| VPN-Client (iPad) | `10.10.10.2`         | **Internet Local**   | Zugriff auf die UDM Pro selbst (Web UI / SSH) |
| VPN-Client (iPad) | `192.168.0.50:8123`  | **Internet In**      | Home Assistant im LAN                 |

---

### ✅ Empfehlung

> 💡 **Immer beide Regeln anlegen**, wenn du nicht sicher bist.

**Beispiel-Strategie:**
- Regel 1: VPN → Heimserver (`Internet In`)
- Regel 2: VPN → UDM Pro (`Internet Local`)
- Regel 3: VPN → Ping erlaubt (`Internet In + Local`)
- Regel 4: VPN Block All → **ganz unten** (`Internet In + Local`)

---

### 🧠 Merksatz

> **„Internet Local = Zugriff auf die UDM Pro selbst“**  
> **„Internet In = Zugriff auf alles andere im Heimnetz“**

---


