# WireGuard VPN Bridge Dokumentation

## Netzwerkarchitektur

Die WireGuard-VPN-Bridge ermöglicht die Verbindung zwischen mehreren Heimnetzen sowie mobilen Clients.  
Alle Heimnetze und Peers sind über den zentralen VPS-Server verbunden.

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

## Installation

### Installation von WireGuard als Server

Um WireGuard als VPN-Server auf deinem VPS zu installieren, folge dieser Anleitung:  
[Anleitung Installation WireGuard Server auf VPS](http://dummy-link.example)

---

## Firezone Installation mit Legacy-Script

### Voraussetzungen

- **Docker CE** muss korrekt installiert sein.  
  - Siehe dazu die offizielle [Docker CE Installationsanleitung](https://docs.docker.com/engine/install/) oder nutze die oben beschriebene Vorgehensweise für Ubuntu/Debian.
- **Docker Compose v2** oder höher.  
  - Das Installationsscript prüft automatisch, ob Docker Compose in der richtigen Version verfügbar ist.

### Verwendung des Legacy-Installationsscripts

Firezone bietet (oder bot) ein sogenanntes „Legacy-Install-Script“, das Container und nötige Abhängigkeiten automatisch einrichtet.  
Wenn du dieses Script ausführst, legt es ein Standard-Setup mit Postgres und Caddy in Docker-Containern an.  

> **Hinweis**: Dieses Script setzt auf ein älteres Installationsverfahren und kann nicht immer die neuesten Funktionen abbilden. Nach dem Durchlauf kannst du deine Ports und IP-Adressbereiche anpassen (siehe unten).

---

## Port-Anpassungen für Firezone

### Hintergrund

Firezone bringt einen **eigenen** WireGuard-Dienst mit. Wenn du bereits einen **nativ** installierten WireGuard-Server mit Port `55120` betreibst, musst du bei Firezone einen **anderen** Port verwenden (z. B. `55121`).

1. **Docker-Compose-Konfiguration anpassen**  
   - Nach der Installation befindet sich ein `docker-compose.yml` (oder ähnlich benannt) im zuvor gewählten Installationsverzeichnis (z. B. `$HOME/.firezone`).  
   - Öffne diese Datei oder die `.env`-Datei, um den Port für den Firezone-WireGuard-Dienst zu ändern.

2. **Port ändern**  
   - Firezone nutzt üblicherweise `51820/udp` als Standardinternen Port.  
   - In deiner `docker-compose.yml` oder `.env`-Datei trage stattdessen `55121` ein, z. B.:
     ```
     FZ_DEFAULT_WG_PORT=55121
     ```
   - Stelle sicher, dass du im VPS (und ggf. im Cloud-Panel) den UDP-Port `55121` freigibst.

3. **Änderungen anwenden**  
   - Fahre die Container herunter und starte sie neu:
     ```bash
     docker compose down
     docker compose up -d
     ```
   - Prüfe die Logs mit:
     ```bash
     docker compose logs -f
     ```
     um sicherzugehen, dass Firezone korrekt startet.

---

## Anpassung des Firezone-WireGuard-Netzwerks

Damit Firezone nicht mit deinem bereits vorhandenen WireGuard-Subnetz kollidiert, kannst du ein eigenes Netz wie `10.10.50.0/24` nutzen.

1. **Netzwerk auf `10.10.50.0/24` setzen**  
   - In der `.env`-Datei oder `docker-compose.yml` kannst du den Adressbereich anpassen.  
   - Je nach Firezone-Version heißt die Variable z. B. `FZ_DEFAULT_WG_IPV4_NETWORK`.  
   - Setze sie auf `10.10.50.0/24`.  
   - Als Serveradresse kannst du `10.10.50.1` wählen.

2. **Firewall**  
   - Achte darauf, dass deine VPS-Firewall oder iptables das neue Subnetz (10.10.50.0/24) und den Port (55121/udp) nicht blockiert.

3. **Container neu starten**  
   ```bash
   docker compose down
   docker compose up -d
   ```

---

## Konfiguration in Firezone

1. **Peers erstellen**  
   - Im Firezone-Webinterface kannst du neue WireGuard-Peers anlegen, die jeweils eine IP aus `10.10.50.0/24` erhalten (z. B. `10.10.50.2, 10.10.50.3` usw.).  
   - Der Endpoint sollte dann `deine-domain.de:55121` lauten (bzw. die Subdomain, die du bei `EXTERNAL_URL` konfiguriert hast).

2. **Routing-Regeln**  
   - Passe die Routen an, damit du auf deine anderen Heimnetze (192.168.x.0/24) zugreifen kannst.  
   - Firezone kann diese Routen automatisch verteilen oder du trägst sie manuell in den Peer-Konfigurationen ein.

3. **Firewall-Regeln**  
   - Definiere in Firezone, welche Peers auf welche Netzbereiche zugreifen dürfen.  
   - Prüfe, ob du Heimnetz 2, 3, 4 blocken oder erlauben möchtest.

---

## Firewall-Regeln & Routing

- **Heimnetz 1** hat Zugriff auf alle anderen Heimnetze.  
- **Heimnetz 2, 3 und 4** haben keinen direkten Zugriff aufeinander, sondern nur auf Heimnetz 1.  
- **Mobile Clients** haben Zugriff auf Heimnetz 1, aber nicht auf Heimnetz 2, 3 oder 4.  
- Falls doppelte Subnetze vorkommen, werden sie per NAT auf dem VPS umgeschrieben.

---

## TODOs

- [ ] Konfiguration der WireGuard-Server und Peers auf dem VPS.  
- [ ] Einrichtung der Routing-Regeln auf dem VPS.  
- [ ] Firewall-Regeln definieren und umsetzen.  
- [ ] NAT-Regeln für doppelte Subnetze implementieren (falls erforderlich).
