# Prompt: Routing-Umstellung HN1 <-> HN2 (ohne NAT)

Du bist mein Setup-Coach.  
Wir stellen mein Setup so um, dass zwischen HN1 (UDM) und HN2 (Raspberry Pi) **echtes Routing ohne NAT** läuft.  
Firezone bleibt unverändert (darf NAT benutzen).  

# Ausgangslage
- VPS dient als Bridge. Interfaces:
  - `unifi` → WireGuard-Interface zu UDM (10.10.10.1)
  - `norden` → WireGuard-Interface zu Pi/HN2 (10.10.20.1)
- Aktuell läuft iptables-MASQUERADE auf dem VPS → das entfernen wir.
- Ziel: Pakete von HN1 ↔ HN2 laufen mit Originalquellen durch (kein NAT).

# Schrittfolge
1. **Bestehende NAT-Regeln auf dem VPS prüfen**
   ```bash
   sudo iptables -t nat -S | grep MASQUERADE
   ```
   → Liste der aktiven MASQUERADE-Regeln.  
   Erwartung: Regeln für `-o unifi` und `-o norden`.

2. **Neue NAT-Policy setzen**
   - Entferne globale MASQUERADE-Regeln für `unifi` und `norden`.
   ```bash
   sudo iptables -t nat -D POSTROUTING -o unifi -j MASQUERADE
   sudo iptables -t nat -D POSTROUTING -o norden -j MASQUERADE
   ```
   - Behalte MASQUERADE nur für Firezone/Docker-Netze (172.17.0.0/16, 172.18.0.0/16, 172.19.0.0/16, eth0 ins Internet).

3. **Routing sicherstellen**
   - Auf dem VPS statische Weiterleitung prüfen:
   ```bash
   ip route | grep 192.168.20
   ip route | grep 192.168.10
   ```
   Erwartet:
   - 192.168.20.0/24 → via 10.10.20.2 dev norden
   - 192.168.10.0/24 (und andere VLANs) → via 10.10.10.2 dev unifi

4. **UDM anpassen**
   - In den UDM-Routen sicherstellen:
     ```
     192.168.20.0/24 → Next Hop 10.10.10.2
     ```
   - Das erzwingt Routing via WG-Interface statt NAT.

5. **Tests**
   - Vom Pi:
     ```bash
     ping -c3 192.168.10.1
     ```
   - Vom UDM:
     ```bash
     ping -c3 192.168.20.10
     ```
   - Vom VPS:
     ```bash
     ping -c3 192.168.20.1
     ping -c3 192.168.10.1
     ```

6. **Persistenz**
   - iptables-Regeln dauerhaft sichern:
   ```bash
   sudo sh -c "iptables-save > /etc/iptables/rules.v4"
   ```

# Hinweise
- Firezone bleibt bei NAT (keine Änderungen an dessen Compose-Setup).  
- Wichtig: nftables am Pi filtert bereits selektiv, keine Änderung nötig.  
- Nach Entfernen des NAT auf dem VPS sieht man auf der Gegenseite wieder die **echten Quell-IPs**.
