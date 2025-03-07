# Umstellung des Domain Name Servers (DNS) auf Cloudflare

## Einleitung
Die Umstellung des Domain Name Servers (DNS) auf Cloudflare ermöglicht eine bessere Verwaltung der DNS-Einträge, eine schnellere Performance und zusätzliche Sicherheitsfunktionen wie DDoS-Schutz. Diese Anleitung beschreibt die Schritte zur Umstellung und Verwaltung der DNS-Einträge in Cloudflare.

---

## 1. DNS-Umstellung beim Domainprovider (All-Inkl)
Bevor Cloudflare die DNS-Verwaltung übernehmen kann, müssen die **Nameserver beim aktuellen Domainprovider** geändert werden. Eine detaillierte Anleitung zur Einrichtung von Cloudflare als DNS-Provider bei **All-Inkl** findest du hier:

👉 [All-Inkl Anleitung: DNS-Umstellung auf Cloudflare](https://all-inkl.com/wichtig/anleitungen/providerwechsel/einrichtung/dns/cloudflare_491.html)

💡 **Wichtig:** Sobald die Umstellung abgeschlossen ist, verwaltet **nur noch Cloudflare** deine DNS-Einträge. Änderungen beim alten DNS-Provider haben keine Wirkung mehr!

---

## 2. Einrichtung der DNS-Zone bei Cloudflare
Nachdem die Nameserver auf Cloudflare umgestellt wurden, müssen **alle bisherigen DNS-Einträge in Cloudflare manuell eingerichtet werden**, da der alte Provider sie nicht mehr verwaltet.

### **Schritte bei Cloudflare:**
1. **In das Cloudflare Dashboard einloggen:**
   👉 [Cloudflare Login](https://dash.cloudflare.com/)
2. **Domain zur Verwaltung hinzufügen (`+ Add Site`)**
3. **Den "Free Plan" oder einen anderen Tarif auswählen**
4. **Cloudflare scannt automatisch vorhandene DNS-Einträge**
5. **Alle Einträge prüfen und ggf. manuell anpassen:**
   - `A-Records` für Webserver & VPS
   - `CNAME-Records` für Alias-Domains
   - `MX-Records` für E-Mail-Dienste
   - `TXT-Records` für Verifizierungen (z. B. SPF, DKIM, DMARC)
   
   👉 Eine detaillierte Anleitung dazu gibt es in der [All-Inkl Anleitung: DNS-Umstellung auf Cloudflare](https://all-inkl.com/wichtig/anleitungen/providerwechsel/einrichtung/dns/cloudflare_491.html)

6. **Proxy-Status prüfen:**
   - Orange Wolke ☁️ = Cloudflare-Proxy aktiv (DDoS-Schutz, CDN)
   - Graue Wolke 🌐 = Nur DNS-Auflösung (z. B. für Mailserver erforderlich)
7. **Speichern & Änderungen übernehmen**

💡 **Hinweis:** Cloudflare wartet nach der Nameserver-Änderung auf die Aktualisierung, was mehrere Stunden dauern kann. Falls E-Mail-Dienste genutzt werden, muss der `MX-Record` korrekt eingetragen sein und die zugehörigen `SPF`, `DKIM` und `DMARC` `TXT-Records` ebenfalls übernommen werden.

---

## 3. Wichtige Hinweise nach der Umstellung
- Nach der Umstellung sind **alle bisherigen DNS-Einträge beim alten Provider inaktiv**.
- **Neue oder geänderte DNS-Records müssen direkt in Cloudflare erstellt oder aktualisiert werden.**
- Änderungen an den DNS-Einstellungen können bis zu **24 Stunden dauern**, bis sie weltweit verbreitet sind (meistens innerhalb weniger Minuten).
- Falls **Let's Encrypt mit der DNS-Challenge** genutzt wird, muss der API-Zugang in Cloudflare korrekt eingerichtet sein.

---

## 4. Überprüfung der DNS-Konfiguration
Nach der Umstellung sollte geprüft werden, ob die DNS-Einträge korrekt gesetzt sind:

### **1. Nameserver-Check**
Prüfen, ob Cloudflare die DNS-Anfragen verwaltet:
```bash
whois meinedomain.com | grep -i "Name Server"
```
👉 Erwartetes Ergebnis: Die Cloudflare-Nameserver sollten angezeigt werden.

### **2. DNS-Record-Test**
Prüfen, ob die A-Records korrekt sind:
```bash
nslookup vps.meinedomain.com 1.1.1.1
```
ODER
```bash
dig vps.meinedomain.com @1.1.1.1
```
👉 Erwartetes Ergebnis: Die öffentliche IP-Adresse des VPS sollte angezeigt werden.

Falls falsche Werte angezeigt werden, kann es an **DNS-Caching** liegen – einfach ein paar Stunden warten und erneut testen.

---

## Fazit
✅ **Cloudflare verwaltet nun die DNS-Einträge der Domain.**  
✅ **Der alte Domain-Provider ist für DNS nicht mehr relevant.**  
✅ **Alle neuen DNS-Änderungen müssen direkt in Cloudflare erfolgen.**  

🚀 **Falls weitere Fragen auftauchen, einfach die Cloudflare-Dokumentation oder die All-Inkl-Anleitung nutzen!** 😊

