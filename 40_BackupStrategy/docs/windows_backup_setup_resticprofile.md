# 🪟 Windows Backup Setup mit Restic und `backup_user`

Diese Anleitung beschreibt Schritt für Schritt, wie du auf einem Windows-PC einen sicheren, automatisierten Backup-Client mit `resticprofile` und einem dedizierten Benutzer (`backup_user`) einrichtest.

---

## ✅ Ziel

- Einrichtung eines dedizierten Windows-Benutzers `backup_user`
- Absicherung von Skript und Passwortdatei
- Installation von `restic` und `resticprofile`
- Zeitgesteuertes Backup mit dem Windows-Taskplaner

---

## 🧰 Vorbereitung: Restic & Resticprofile installieren

1. Offizielle Seite öffnen: https://restic.net
2. Lade `restic.exe` herunter → z. B. nach `C:\restic\`
3. Lade von https://github.com/creativeprojects/resticprofile/releases `resticprofile.exe` herunter → ebenfalls nach `C:\restic\`
4. Öffne: Systemsteuerung → System → Erweiterte Systemeinstellungen → Umgebungsvariablen
5. Ergänze die **Systemvariable `Path`** um:
   ```
   C:\restic\
   ```
6. Test in PowerShell oder CMD:
   ```powershell
   restic version
   resticprofile version
   ```

---

## 👤 `backup_user` erstellen

Als Administrator in PowerShell:

```powershell
net user backup_user DeinSicheresPasswort /add
net localgroup "Administratoren" backup_user /add
```

> 🔐 Alternativ kannst du ihn **nicht** zur Administratorgruppe hinzufügen und gezielt Berechtigungen auf Quellordner setzen.

---

## 🔐 Setup starten mit Script

1. Führe das vorbereitete Setup-Script aus:
   ```powershell
   powershell -ExecutionPolicy Bypass -File "C:\Backup\windows_resticprofile_setup.ps1"
   ```

Das Script legt unter `C:\Backup` alle benötigten Dateien an:
- `profiles.yaml`
- `restic_password.txt`
- `logs\` Ordner
- Eventuell Beispiel-Backup-Ordner

---

## 👤 Wechsel in PowerShell-Konsole als `backup_user`

```cmd
runas /user:backup_user cmd
```
Dann innerhalb der CMD:
```cmd
powershell
```

---

## 🔐 Zugriff auf zu sichernde Ordner gewähren

1. Rechtsklick auf z. B. `C:\Users\Max\Documents` → Eigenschaften → Sicherheit
2. Klicke auf **Bearbeiten** → **Hinzufügen**
3. Benutzer `backup_user` eintragen
4. Berechtigungen: mindestens **Lesen & Ordnerinhalt anzeigen**
5. Sicherstellen, dass der zu sichernde Pfad unter Sources in der Profiles.yaml eingetragen ist
6. Übernehmen → OK

---

## 🧪 Manueller Test: Backup dry-run & Initialisierung

### 1. Dry Run
```powershell
resticprofile.exe -c C:\Backup\profiles.yaml backup --dry-run
```

### 2. Initial Backup durchführen
```powershell
resticprofile.exe -c C:\Backup\profiles.yaml backup
```

### 3. Snapshots prüfen
```powershell
resticprofile.exe -c C:\Backup\profiles.yaml snapshots
```

---

## 🗓️ Scheduler einrichten

Automatische Ausführung registrieren:
```powershell
resticprofile.exe -c C:\Backup\profiles.yaml schedule --all
```

---

## 🛠️ Anmeldung als Stapelverarbeitungsauftrag erlauben

### Rechte setzen:

1. `secpol.msc` → Lokale Richtlinien → Zuweisen von Benutzerrechten
2. Doppelklick auf „Anmelden als Stapelverarbeitungsauftrag“
3. Benutzer `backup_user` hinzufügen
4. ggf. `gpupdate /force` in einer Admin Powershell ausführen

---

## 🔍 Aufgaben im Taskplaner prüfen

- Öffne Taskplaner als Admin
- Unter `resticprofile backup`, `check`, `forget` findest du geplante Tasks
- Prüfe:
  - Benutzer: `backup_user`
  - Rechte: mit höchsten Privilegien
  - Letzte Ausführung / Nächste Ausführung
- Im Taskplaner > Eigenschaften der Aufgabe > Reiter „Bedingungen“:
  - ✅ Haken setzen bei:
    - „Aufgabe so schnell wie möglich nach einem verpassten Start ausführen“
    - „Computer zum Ausführen der Aufgabe reaktivieren“ (falls relevant)
- Testen:
  ```powershell
  Get-ScheduledTask | Where-Object {$_.TaskName -like "*default*"} | Select TaskName
  ```
  ```powershell
  Start-ScheduledTask -TaskName "default backup" -TaskPath "\resticprofile backup\"
  ```

---

## 📋 Status & Logs auswerten

### Backup-Status:
```powershell
Get-Content "C:\Backup\restic_status.json" | ConvertFrom-Json
```

### Optional: Logs filtern und archivieren
Alle Logs liegen unter `C:\Backup\logs\backup_YYYY-MM-DD_HH-MM-SS.log`

---

## ✅ Test nach 1. Nacht

1. Prüfe ob neue Snapshot erstellt wurde:
```powershell
resticprofile.exe -c C:\Backup\profiles.yaml snapshots
```

2. Prüfe Statusdatei:
```powershell
Get-Content "C:\Backup\restic_status.json" | ConvertFrom-Json
```

3. Kontrolliere Log-Dateien

---

## 🔐 Sicherheitshinweise

- `restic_password.txt` nur für `backup_user` zugänglich machen
- Keine Passwörter im Klartext in YAML oder Skript-Dateien hinterlegen
- Dateisystemrechte für `C:\Backup` korrekt setzen

---
