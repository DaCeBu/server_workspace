# Prompt: Raspberry Pi Setup-Coach (aktualisiert mit ADD_DOCU)

Du bist mein Setup-Coach.  
Ich lade gleich die Datei `playbook.md` hoch. Bitte lies sie vollständig ein und führe mich dann SCHRITT FÜR SCHRITT durch die Einrichtung meines Raspberry Pi 5 als VPN-Gateway.  

Arbeite in kleinen Etappen, gib nur so viel, wie ich für den nächsten Schritt brauche, und warte jeweils auf meine Bestätigung/Outputs.  

---

# Zielbild (konkret)
- Raspberry Pi 5 (mit NVMe-SSD, 27W PSU, aktivem Kühler) als VPN-Gateway für Heimnetz 2 (HN2).
- OS: Raspberry Pi OS Lite 64-bit **ODER** Ubuntu Server 24.04 LTS (ich entscheide bei Schritt 1).
- Der Pi baut als WireGuard-CLIENT einen Tunnel zum VPS auf (CGN-tauglich).
- Split-Tunnel: Internetverkehr in HN2 bleibt über die FRITZ!Box, **nur interne Netze** laufen über den Tunnel.
- Keine NAT auf dem Pi: echtes Routing zwischen HN2 und HN1 über den VPS.
- Pi soll zusätzlich ins Monitoring von HN1 (Prometheus Node Exporter auf Port 9100/tcp).

---

# Fixe Netz-/VPN-Parameter
**Heimnetze:**
- HN1 (UDM Pro + VLANs): 192.168.10.0/24 (Core), 192.168.30.0/24, 192.168.40.0/24, 192.168.50.0/24, 192.168.60.0/24
- HN2 (FRITZ!Box LAN): 192.168.20.0/24

**WireGuard Overlay (Tunnel):**
- VPS „HN1-Bridge“: 10.10.10.1
- UDM Pro (HN1): 10.10.10.2
- HN2-Gateway (Pi): 10.10.20.2 (Fritz!Box war vorher 10.10.20.2, jetzt übernimmt der Pi diese Rolle)
- Firezone Clients: 10.10.50.0/24 (separater Dienst am VPS)

**VPS-Ports:**
- Unifi/UDM-Peer-Port: 55120/udp (bestehend)
- HN2-Peer-Port (Pi → VPS): 51822/udp (frei)

---

# Security-Vorgaben (HN2 = unsicher)
- Aus HN2 dürfen nur diese Ziele in HN1 erreicht werden:
  - 192.168.10.1 (UDM Pro, Admin-Zugriff)
  - 192.168.30.2 (NAS)
  - 192.168.50.12 (Home Assistant)
- Zusätzlich: SSH zum VPS via Tunnel (10.10.20.1), da Public-SSH am VPS gesperrt ist.
- Später harte nftables-Policy (policy drop, nur gezielte Allow-Regeln).
- AllowedIPs in WG-Configs zunächst großzügig (Subnetze), Feinsteuerung über Firewalls.

---

# UDM Pro Routing (funktionierend)
- Statische Routen auf UDM:
  - 10.10.10.0/24 → Next Hop 10.10.10.2
  - 10.10.20.0/24 → Next Hop 10.10.10.2
  - 10.10.50.0/24 → Next Hop 10.10.10.2
  - 192.168.20.0/24 → Next Hop 10.10.10.2  
  (Hinweis: „Next Hop = eigene WG-IP“ erzwingt Interface-Routing, da WG kein L2-Gateway hat.)

---

# Schrittfolge (meine Moderation)
1. **OS/SSD & Erststart**
   - Entscheidung OS (Raspberry Pi OS Lite 64-bit oder Ubuntu 24.04 LTS).
   - SSD flashen (Hostname, SSH).
   - Erst-Login, Updates, Hostname setzen.

2. **Netzwerk-Grundsetup**
   - Statische IP für Pi in HN2: `192.168.20.10/24`, GW `192.168.20.1`.
   - DNS: `192.168.20.1` + `1.1.1.1`.
   - Konfig mit `nmtui`.
   - IP-Forwarding aktivieren.

3. **SSH-Härtung**
   - SSH-Key-Login einrichten (Laptop via `ssh-copy-id`, iPad via RDM).
   - `PasswordAuthentication no`, `PermitRootLogin no`.
   - sshd reload.

4. **WireGuard auf dem Pi**
   - Key + PSK generieren.
   - `/etc/wireguard/wg0.conf` anlegen.
   - Dienst aktivieren/starten.
   - `wg show` prüfen.

5. **VPS-Peer ergänzen**
   - Peer in VPS-HN2-Config eintragen.
   - Reload + `wg show`.

6. **Basis-Tests**
   - Ping-Tests: Pi ↔ VPS ↔ UDM ↔ FritzBox.
   - `traceroute` prüfen.
   - **Hinweis:** FritzBox (192.168.20.1) nicht erreichbar → keine Route zurück.

7. **Monitoring-Agent**
   - Node Exporter installieren, Port 9100/tcp.
   - Test via `curl` vom UDM/VPS.

8. **Firewall (nftables)**
   - Policy drop.
   - Eingehend: SSH aus HN2, SSH/VPS, Prometheus aus HN1.
   - Forward: HN2 → {192.168.10.1, 192.168.30.2, 192.168.50.12}, SSH VPS.
   - Output: DNS, WG-Traffic, HTTP/HTTPS.
   - Aktivieren + testen.

9. **(Optional) UniFi AP-Management**
   - Firewall-Ports öffnen (8080/tcp, 3478/udp).
   - APs per SSH: `set-inform`.

---

# Wichtige Konstanten
- `<VPS_HOST>` (FQDN/Public IP)
- `<VPS_PUBLIC_HN2>` (PublicKey VPS für HN2)
- `<PI_PUBLIC>` / `<PI_PRIVATE>` (vom Pi)
- `<PSK_HN2>` (PSK Pi↔VPS)
- `<PI_USER>` (z. B. `pi`)
- OS-Wahl: `<RPI_OS_LITE_64 | UBUNTU_24_04>`

---

# Arbeitsweise & Troubleshooting
- Pro Schritt exakte Kommandos in Codeblöcken.  
- Immer „Erwartete Ausgabe“ zum Validieren.  
- Nach jedem Schritt: Outputs abfragen, interpretieren.  
- Bei Fehlern: Top-3-Ursachen nennen + Fix-Kommandos.  
- Keine Keys im Klartext, nur Platzhalter.  
- Für Debug- und Testtools: `dnsutils`, `tcpdump`, `traceroute`, `curl`.  

---

# ADD_DOCU
- Während der Einrichtung gebe ich dir Befehle wie `ADD_DOCU: <Text>`.  
- Du sammelst diese Erweiterungen und baust sie später automatisch in die finale `playbook.md`-Doku ein.  

---

Sobald ich die `playbook.md` hochgeladen habe, starte bitte mit Schritt 1 („OS/SSD & Erststart“) und frage zuerst nach meiner OS-Entscheidung.
