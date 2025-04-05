# 💾 QNAP Vorbereitung: Freigabeordner & Benutzer einrichten

Bevor du Restic auf einem Windows-Client einrichtest, musst du deinen QNAP vorbereiten.  
Ziel ist ein sicherer Freigabeordner mit dedizierten Benutzerordnern für jedes Backup.

---

## ✅ Zielstruktur auf dem QNAP

```text
/share/backup/
├── backup_max/
├── backup_anna/
└── backup_jonas/
```

---

## 📁 Schritt 1: Freigabeordner `backup` erstellen

1. Melde dich am QNAP Webinterface (QTS) als Admin an
2. Öffne: **Systemsteuerung → Freigabeordner → Erstellen**
3. Name: `backup`
4. Ort: `DataVol1` (empfohlen, falls RAID-geschützt)
5. Optionen:
   - 📦 **Papierkorb**: ❌ Deaktivieren (nicht sinnvoll für Backups)
   - 🔐 **SMB aktivieren**: ✅
   - ❌ Kein NFS, WebDAV, FTP, usw.
6. Erstellen → bestätigen

---

## 👤 Schritt 2: Benutzer für jeden Windows-Client anlegen

1. Systemsteuerung → **Benutzer** → **Benutzer erstellen**
2. Für jeden Nutzer:
   - z. B. `backup_max`, `backup_anna`, `backup_jonas`
3. Anwendungsbrechtigungen:
   - ✅ Nur **Microsoft-Netzwerk**
   - ❌ Alles andere deaktivieren
4. Starkes Passwort setzen
5. Benutzergruppen:
   - ❌ `everyone` abwählen (nicht möglich: wird automatisch gesetzt, später in Berechtigungen entfernen)
   - ❌ Nicht zur Administrator-Gruppe hinzufügen

---

## 📂 Schritt 3: Persönliche Unterordner erstellen

Im File Station oder per SSH/Shell:

```bash
mkdir /share/backup/backup_max
mkdir /share/backup/backup_anna
mkdir /share/backup/backup_jonas
```

Alternativ: über die **QNAP File Station** → Rechtsklick → „Ordner erstellen“

---

## 🔐 Schritt 4: Berechtigungen korrekt setzen

### A) Freigabe-Ebene (Systemsteuerung → Freigabeordner → `backup` → Berechtigungen)

| Benutzer       | Zugriff        |
|----------------|----------------|
| `backup_max`   | ✅ **Lesen**    |
| `admin`        | ✅ **RW**       |
| `everyone`     | ❌ Kein Zugriff |

⚠️ Wichtig: Nur so kann `backup_max` in seinen Unterordner wechseln, aber **nicht** auf andere Unterordner zugreifen.

### B) Unterordner-Ebene (File Station → `backup/backup_max` → Eigenschaften → Berechtigungen)

- Vererbung **deaktivieren**
- Nur explizit:
  - ✅ `backup_max`: **Lesen + Schreiben**
  - ✅ `admin`: **RW**
  - ❌ `everyone`: entfernen

---

## 📸 Schritt 5: Snapshots für /backup aktivieren (Volume DataVol1)

1. Öffne: Speicher & Snapshots → Snapshot-Manager
2. Wähle links: DataVol1
3. Klicke auf „Snapshot-Zeitplan“ → Neu hinzufügen
4. Zeitplan:
   - Intervall: täglich, z. B. 23:00 Uhr
   - Aufbewahrung: z. B. 30 Tage
5. Aktivieren:
   - ✅ „Nur Administratoren dürfen Snapshots wiederherstellen“
   - ✅ „Snapshot-Ablauf verwenden“
   - ✅ „Garantierten Snapshot-Speicherplatz aktivieren“ (z. B. 10–15 % von Volumegröße)
6. Bestätigen und speichern

➡️ Snapshots schützen deine Backup-Ziele zusätzlich gegen Ransomware und versehentliches Löschen.

---

## Schritt 6: Vorbereitung für Restic
- Stelle sicher, dass jeder backup_*-Benutzer Schreibzugriff auf seinen eigenen Ordner im Freigabeordner backup hat

- Für Windows-Backup-Skripte:
   - Jeder Windows-Client verwendet den passenden backup_user
   - Restic-Repository liegt z. B. in \\192.168.1.100\backup\backup_max\restic-repo
   - Jeder Client verwendet ein eigenes Repository und Passwort

---

## 💡 Empfehlung

- Snapshots für den Ordner `/backup` aktivieren (→ täglicher Schutz)
- QNAP-Volume: `DataVol1` oder Volume mit **RAID-Schutz**
- Optional: Nur Administratoren dürfen Snapshots wiederherstellen

---

➡️ Danach kannst du wie in der Windows-Dokumentation mit dem Restic-Client fortfahren.
