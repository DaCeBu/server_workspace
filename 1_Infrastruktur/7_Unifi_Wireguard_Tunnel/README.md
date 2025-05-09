# Hauptseite
[Hauptseite Link](/README.md)

# Legende
### VPS = Virtual Private Server, zb Ionos VPS XS
https://www.ionos.de/server/vps#tarife
### Wireguard = Sicheres und schnelles VPN Protokoll über UDP -> wesentlich schlanker und  schneller, da in vielen Linux Kernel bereits integriert
# Vorraussetungen in diesem Setup
### Diese Anleitung bezieht sich auf einer Unifi UDM Pro im Heimnetzwerk und einem VPS im Internet mit fester IP4 und einem installiertem Ubuntu. Die Anleitung lässt sich natürlich auch mit anderer Hard & Software einsetzen, allerdings sind dann nicht alle Befehle und Einstellungen identisch.


# Setup Unifi UDM Pro
## Menü
- Gehe auf -> System -> VPN -> VPN Client -> Create NEW
- Klicke auf Wireguard oben
- Vergebe einen Namen zb Wireguard VPS Server
- Klicke auf "manual"
- Private Key und Public Key werden bereits mit Pünktchen angezeigt, den Public Key kann man mit "Copy" kopieren und für den File unten auf dem VPS einfügen 
- Tunnel IP = 10.10.10.2 und Netmask 32
- Server Address = IP oder FQDN des VPS
- Port = 55120
- Public Server Key = Key der unten auf dem VPS Server erstellt wurde
- Pre-Shared Key = LEER
- Primary DNS server = DNS Server, das kann auch ein lokaler PiHole server sein oder ein  DNS Server auf einer NAS, ansonsten einen öffentlichen nehmen zb 8.8.8.8 oder 1.1.1.1
- Secondary DNS server = Hier kann ein zweiter eingegeben werden, falls der erste nicht erreichbar ist
- Mit "Apply Changes" wird der Client gestartet, falls der Server auf der VPS bereits läuft, wird die Verbindung in wenigen Sekunden aufgebaut und die Verbidung leuchtet grün

## Setup Firewall
- Die Einstellung ist eigentlich NICHT korrekt für Unifi und ich hoffe sie ändern das noch einmal. Eigentlich müsste die Firewall Regel als Eingang den VPN Client haben, aber die Möglichkeit besteht NICHT. Also müssen wir uns hier mit einer "Behelfslösung" momentan zufrieden geben.
- Es empfiehlt sich 2 Profile in der UDM Pro Firewall Anzulegen, einmal für die IP der Wireguard Adresse auf dem VPS (10.10.10.1) oder mehreren IP wenn man ein Mesh Netzwerk hat, dann eine Gruppe mit den IP Netzwerken oder einzelnen IP für Geräte auf die über Wireguard zugegriffen werden darf, fals das alle Geräte sein sollen, kann man hier auch den Bereich für ALLE privaten Adressen nehmen, evtl. habt ihr diesen IP Bereich bereits angelegt (10.0.0.0/8 & 172.16.0.0/12 & 192.168.0.0/16)
- Gehe in Settings -> Security -> Firewall Rules
- Gehe auf Internet und Create new Rule, wähle Internet In
-  Protocol sind Alle, Der Source ist die Gruppe der IPs von den Wireguard Adressen die rein. dürfen, also der VPS
- Ports sind bei Source und Destination any, als Ziel gibt man die Gruppe der IP an, welche erreicht werden dürfen.
P.S.: Ihr solltet hier evtl. den Adressbereich des Wireguard Tunnel verändern, damit niemand diesen Bereich kennt und versuchen kann sich damit einzuloggen.
- Gehe dann erneut auf Internet und Create new Rule, wähle Internet Local aus und stelle das gleiche wie bei Internet in nochmal ein

# VPS Server Ionos
## Setup VPS Client

### Installation (Ionos VPS XS)
Auf dem VPS wird ein Ubuntu installiert, in den Einstellungen der Firewall unter Netzwerk wird der Port 22 TCP geöffnet und der Wireguard Port (in unserem Beispiel 55120 UDP).
Nach Aufbau der Verbindung kann auch die Ionos Firewall Port 22 geschlossen werden (falls man Services von aussen auf dem VPS später hinzufügen möchte, dann muss der entsprechende Port geöffnet werden).
Bei späterer Einrichtung eines Firezone Servers 
[PortainerStacks Firezone Link](/3_Server/PortainerStacks/firezone/README.MD)
sollte man auch Port 80/443 öffnen.

## Installieren von Wireguard (falls nicht vorhanden)
```
apt update -y && apt upgrade -y && apt install software-properties-common wireguard wireguard-tools unzip -y
```
# Einstellen der Port forwarding (falls nicht vorhanden)
```
nano /etc/sysctl.conf
```
## Inhalt unten anhängen

```
# Enable IPv4 packet forwarding
net.ipv4.ip_forward=1

# Enable Proxy ARP (https://en.wikipedia.org/wiki/Proxy_ARP)
net.ipv4.conf.all.proxy_arp=1

# Disable IPv6 packet forwarding
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
```
## Neustart und anzeigen ob alles korrekt
```
sysctl -p && sysctl --system
```

## Keys erzeugen
```
(umask 077 && printf "PrivateKey= " | tee /etc/wireguard/privatekey_unifi > /dev/null) && wg genkey | tee -a /etc/wireguard/privatekey_unifi | wg pubkey | tee /etc/wireguard/publickey_unifi && cat /etc/wireguard/privatekey_unifi && touch /etc/wireguard/unifi.conf
```
## Keys anzeigen
```
cat /etc/wireguard/privatekey_unifi && cat /etc/wireguard/publickey_unifi
```

## Wireguard conf erstellen
```
nano /etc/wireguard/unifi.conf
```
## diesen Inhalt einfügen und die Parameter ändern
```
[Interface]
PrivateKey= !!!Private Key der oben erzeugt wurde !!!
ListenPort = 55120
Address = 10.10.10.1/32

# Standard Routing
# Die Netzwerkkarte eth0 muss ausgetauscht werden gegen die Netzwerkkarte des VPS Servers (mit ip addr heraus zu finden, zb  etho, enps192, ens6 etc...)
PostUp     = iptables -t nat -A POSTROUTING -o unifi -j MASQUERADE
PostDown   = iptables -t nat -D POSTROUTING -o unifi -j MASQUERADE
PostUp     = iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown   = iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
PublicKey = !!!PUBLIC KEY DER UDM PRO (kann in Wireguard Client kopiert werden)!!!
AllowedIPs = 10.10.10.0/24, !!!192.168.0.0/24 -> Hier die IP Netze der UDM Pro rein wodrauf zugegriffen werden darf!!!
```
# Wireguard starten
```
systemctl start wg-quick@unifi && systemctl enable wg-quick@unifi
```
## Stoppen
```
systemctl stop wg-quick@unifi && systemctl disable wg-quick@unifi
```
## Stop & Start nacheinander
```
systemctl stop wg-quick@unifi && systemctl disable wg-quick@unifi && systemctl start wg-quick@unifi && systemctl enable wg-quick@unifi
```

# Testen ob Wireguard läuft
```
wg
```
- Der Status zeigt folgendes:
```
interface: unifi
  public key: (KEY)
  private key: (hidden)
  listening port: 55120

peer: (KEY)
  endpoint: IP:AusgehandelterPort
  allowed ips: Die Erlaubten IP Bereiche
  latest handshake: 7 seconds ago
  transfer: 30.43 kB received, 93.85 kB sent
```
- Unten im Status transfer sollten bei gesendet sowie empfangen etwas stehen, falls das nicht der Fall ist, dann ist die Verbindung nicht korrekt aufgebaut.


# Zusätzlich feste Ports direkt an einen Server weiterleiten
#### Forward zu einem Server 192.168.0.230 (Beispiel) mit PORT 1234 (Beispiel)
#### Öffne auf dem VPS den gewünschten Port in der Firewall 1234 (Beispiel)
#### in dem Wireguard Konfiguration unifi.conf auf dem VPS hinzuzufügen
#### ens6 ist die Netzwerkkarte des VPS und entsprechend zu ändern (z.b. ETH0, etc...)
#### Wichtig: Das Endgerät ist für die Sicherheit verantwortlich, da alle anfragen an die IP4 des VPS direkt an den Server weitergeleitet werden

```
PostUp = iptables -A FORWARD -i ens6 -o unifi -p tcp --syn --dport 1234 -m conntrack --ctstate NEW -j ACCEPT
PostUp = iptables -A FORWARD -i unifi -o ens6 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
PostUp = iptables -t nat -A PREROUTING -i ens6 -p tcp --dport 1234 -j DNAT --to-destination 192.168.0.230
PostUp = iptables -t nat -A POSTROUTING -o unifi -p tcp --dport 1234 -d 192.168.0.230 -j SNAT --to-source 192.168.0.230
PostDown = iptables -D FORWARD -i ens6 -o unifi -p tcp --syn --dport 1234 -m conntrack --ctstate NEW -j ACCEPT
PostDown = iptables -D FORWARD -i unifi -o ens6 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
PostDown = iptables -t nat -D PREROUTING -i ens6 -p tcp --dport 1234 -j DNAT --to-destination 192.168.0.230
PostDown = iptables -t nat -D POSTROUTING -o unifi -p tcp --dport 1234 -d 192.168.0.230 -j SNAT --to-source 192.168.0.230
```

# Ohne Firezone ein Mobiles Gerät hinzufügen (Empfohlen wird hier aber ein Docker mit Firezone Container oder einem anderem Wireguard Zugang mit grafischer Oberfläche zur einfacheren Verwaltung)
- Folge der Anleitung oben "## Setup VPS Client", Tausche aber Port und Tunnel IP aus zb. Port 55121 und Tunnel IP 10.10.11.2. gebe sonst keine adressen unter Allowed Ip hier ein.
- Vergiß nicht den Port auf der IONOS Firewall frei zu geben. Tausche in den Namen das unifi.conf gegen zb. handy.conf aus.
- Auf dem Handy starte die Wireguard Software und klicke auf das + oben rechts.
- Wähle "selbst erstellen" und vergebe einen Namen
- Klicke Schlüsselpaar erzeugen und kopiere den öffentlichen Schlüssel für die Datei handy.conf
- Unter Adressen kommt die Tunnel IP rein (10.10.11.2/32)
- Klicke auf Peer hinzufügen und gebe hier den neuen öffentlichen Schlüssel vom VPS ein
- Füge die IP / DNS deines VPS unter Endpunkt ein, gebe den Port (55121) mit Doppelpunkt hinter der Adresse ein und gebe MTU 1280 ein, DNS Server die gleichen wie im anderem Setup.
- Zulässige IP´s wären hier jetzt die 10.10.11.0/24, !!!192.168.0.0/24 -> Hier die IP Netze der UDM Pro rein wodrauf zugegriffen werden darf!!!
- Keepalive kann auf 25 gesetzt werden. Klicke am Handy auf sichern, starte den Server auf der VPS und klicke die Verbindung in dem Handy an. Die Verbindung sollte erstellt werden

### Testen ob Verbindung korrekt läuft
- Klicke nach dem Verbinden auf den Namen der Verbindung, unten sieht man Daten empfangen, Daten gesendet und Letzer Handshake -> Alle drei sollten hier eine Änderung von zumindest ein paar kb anzeigen. Die Verbindung mit dem VPS steht.
- Um die Verbindung mit dem Unifi zu testen, logge dich per ssh auf dem VPS ein und setzte ein PING an ein Gerät im Netzwerk ab. Die Pings sollten ankommen.
- Versuche vom Handy aus auf z.b. einer Webseite im Netzwerk zuzugreifen.

# Zugang aus dem Heimnetz zum internem Netzwerk des VPS bzw auf Netzwerkbereiche hinter dem VPS
- Um sich aus dem Unifi Netzerk auf die IP des Wireguard zu verbinden, muss man eine "Traffic Route" Weiterleitung einrichten in der UDM Pro, zb das Netzwerk 10.10.10.0/24 oder die IP 10.10.10.1/32 unter IP eintragen und als Interface wählt man den Tunnel zum VPS aus.
- Falls man sich zu Netzwerken hinter dem VPS verbinden möchte, weil man mehrere Rechner zu einem Mesh System miteinander verbunden hat, muss man in der UDM Pro eine Static Route einrichten mit den Ziel IP und der IP des UDM Pro Tunnel als Next Hop (10.10.10.2)

# Aufbau meines Wireguard Mesh System
### Alle Rechner sind untereinander erreichbar (so lange die Firewall es nicht gewollt blockt)

![Wireguard](/1_Infrastruktur/7_Unifi_Wireguard_Tunnel/Wireguard.jpg)