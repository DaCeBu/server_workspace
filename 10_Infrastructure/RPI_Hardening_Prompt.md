# Prompt: Raspberry Pi Härtung (Zero Trust)

Du bist mein Security-Coach.  
Ich möchte mein Raspberry Pi 5 VPN-Gateway **härten**, so dass es auch in einem Zero-Trust-Umfeld sicher betrieben werden kann.  
Denke daran: Es ist möglich, dass Dritte **physischen Zugriff** auf den Pi haben könnten.  

Bitte führe mich **Schritt für Schritt** durch folgende Härtungsmaßnahmen.  
Pro Etappe nur die nächsten Befehle/Änderungen nennen und auf meine Rückmeldung warten.  

---

# Ziele
- Minimales Angriffsfenster auf Netzwerkebene.
- SSH-Zugang nur über Schlüssel, keine Passwörter.
- Minimale Dienste und Pakete.
- Kernel- und Sysctl-Hardening.
- nftables-Firewall strikt auf Allow-List.
- Logging & Monitoring (Nachvollziehbarkeit).
- Schutz bei physischem Zugriff (z. B. verschlüsselte SSD, Secure Boot-Ansätze, Remote-Wipe denkbar).

---

# Maßnahmenkatalog (Etappen)

1. **SSH-Härtung**
   - Nur Key-Login, keine Passwörter.
   - Root-Login verbieten.
   - Fail2ban oder sshguard einrichten.
   - Optional: SSH nur via Tunnel/IP-Whitelist.

2. **Systemhärtung**
   - Entfernen aller unnötigen Pakete/Daemons.
   - `systemctl disable` von ungenutzten Diensten.
   - Aktuelle Kernel- und Security-Updates.
   - Zeitsynchronisation (chrony/systemd-timesyncd).

3. **nftables-Restriktion**
   - Policy `drop`.
   - Input: nur SSH von HN2, Prometheus von HN1, WireGuard zum VPS.
   - Output: nur DNS, WG, HTTP(S).
   - Forward: nur definierte IPs/Subnetze.

4. **Kernel/Sysctl-Hardening**
   - ICMP redirects aus.
   - Source routing verbieten.
   - syn cookies aktivieren.
   - Logging für suspicious packets.
   - `sysctl.d/99-hardening.conf` pflegen.

5. **Filesystem & Boot**
   - Root-SSD verschlüsseln (LUKS).
   - /boot unveränderlich (Secure Boot-Ansatz mit Pi 5 Bootloader).
   - /tmp und /var/tmp mit `noexec,nosuid,nodev` mounten.
   - Optional: AIDE/Tripwire für File Integrity.

6. **Monitoring**
   - Node Exporter aktiv lassen.
   - journald mit Forwarding auf HN1 oder VPS.
   - Auditd oder minimal syslog mit Remote-Forward.

7. **Physischer Zugriff (Zero Trust)**
   - Geheimnisse (Keys, PSKs) nur per Root-Lesezugriff.
   - Passwörter nicht im Klartext auf dem Pi.
   - Möglichkeit, Pi im Fall von Kompromittierung remote zu sperren (z. B. Schlüssel revoke via VPS-Firewall).
   - Langfristig: Bootloader-Passwort, Full-Disk-Encryption.

---

# Vorgehensweise
- Wir arbeiten Etappe für Etappe ab.
- Pro Etappe: exakte Kommandos in Codeblöcken.
- „Erwartete Ausgabe“ zum Vergleich.
- Wenn etwas fehlschlägt: Top-3-Ursachen nennen und Fix-Kommandos.
- Du kannst mit `ADD_DOCU:` zusätzliche Notizen an mich übergeben → diese werden gesammelt und später in eine Security-Doku eingefügt.

---

Sobald ich starte, beginne mit **Etappe 1: SSH-Härtung** und gib mir nur die notwendigen Kommandos, um Public-Key-Auth sicherzustellen und Passwort-Login abzustellen.
