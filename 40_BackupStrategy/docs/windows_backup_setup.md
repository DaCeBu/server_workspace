# 🪟 Windows Backup Setup mit Restic und `backup_user`

Diese Anleitung beschreibt Schritt für Schritt, wie du auf einem Windows-PC einen sicheren, automatisierten Backup-Client mit `restic` und einem dedizierten Benutzer (`backup_user`) einrichtest.

---

## ✅ Ziel

- Einrichtung eines dedizierten Windows-Benutzers `backup_user`
- Absicherung von Skript und Passwortdatei
- Installation von `restic` unter Windows
- Zeitgesteuertes Backup mit dem Windows-Taskplaner

---

## 🧰 Vorbereitung: Restic installieren

1. Offizielle Seite öffnen: https://restic.net
2. Lade die aktuelle `restic.exe` herunter
3. Lege sie in z. B. `C:\Programme\restic\`
4. Offizielle Seite öffnen: https://github.com/creativeprojects/resticprofile/releases
5. Lege sie in z. B. `C:\Programme\resticprofile\`
6. Öffne Systemsteuerung → System → Erweiterte Systemeinstellungen → Umgebungsvariablen
7. Ergänze die **Systemvariable `Path`** um:
   ```
   C:\Programme\restic\
   ```
8. Test in PowerShell oder CMD:
   ```powershell
   restic version
   ```

> 💡 Hinweis: Die Warnung „unbekannter Herausgeber“ ist normal, wenn du direkt von [restic.net](https://restic.net) herunterlädst.

---

## 👤 `backup_user` erstellen und konfigurieren

> 💡 Hinweis: Gleiche Benutzerdaten wie für den Backup User am QNAP verwenden. Geht zwar auch anders, macht die Sache aber einfacher. 

### 1. Benutzer anlegen

Als Administrator in PowerShell:
```powershell
net user backup_user DeinSicheresPasswort /add
net localgroup "Administratoren" backup_user /add
```

> 🔐 Alternativ kannst du ihn **nicht** zur Administratorgruppe hinzufügen und gezielt Berechtigungen auf Quellordner setzen.

---
## 🔐 Setup Restic Backup initialisieren

An dieser Stelle das powershell Skript setup_restic_backup.ps1 ausführen.

> 💡 Hinweis: Damit das funktioniert muss Visual Studio Code mit Adminrechten gestartet werden. 

1. User Qnap eingeben
2. Folder Name auf dem Qnap eingeben (idealerweise entspricht Username = Ordnername)
3. Passwort User Qnap eingeben
4. Restic Passwort eingeben
5. Script läuft durch

## 🔐 Zugriff auf zu sichernde Ordner gewähren

1. Rechtsklick auf z. B. `C:\Users\Max\Documents` → Eigenschaften → Sicherheit
2. Klicke auf **Bearbeiten** → **Hinzufügen**
3. Benutzer `backup_user` eintragen
4. Berechtigungen: mindestens **Lesen & Ordnerinhalt anzeigen**
5. Übernehmen → OK

---

## 🗂️ Verzeichnisstruktur

```
C:\
├── Backup\
│   ├── restic_backup.ps1
│   └── restic_password.txt
```

---

## 🔑 Passwortdatei anlegen und absichern

1. Erstelle Datei: `C:\Backup\restic_password.txt`
2. Inhalt: Nur das Passwort für das Restic-Repository

🔧 Wichtig: Berechtigungsvererbung deaktivieren

🧩 Variante A: Manuell über GUI
1. Rechtsklick auf C:\Backup\restic_password.txt → Eigenschaften
   - Reiter Sicherheit → Erweitert
   - Oben: „Berechtigungen ändern“
   - Haken bei „Berechtigungen von übergeordnetem Objekt übernehmen“ → Deaktivieren
   - Du wirst gefragt, ob du vorhandene Einträge behalten willst → „Nur explizite behalten“ wählen
   - Benutzer `backup_user` eintragen
   - Alle anderen bis auf Administratoren und System entfernen
   - Berechtigungen: mindestens **Lesen & Ordnerinhalt anzeigen**
   - Übernehmen → OK

---

## 📜 Backup-Skript erstellen

Pfad: `C:\Backup\restic_backup.ps1`

```powershell
$env:RESTIC_PASSWORD = Get-Content "C:\Backup\restic_password.txt"
net use Z: \\192.168.1.100\backup /user:backup_max "geheim123!"
restic -r Z:\backup_max\restic-repo backup C:\Users\Max\Documents
restic -r Z:\backup_max\restic-repo forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune
net use Z: /delete
```

> 💡 Alternativ: `C:\Users\Max` durch andere Pfade ersetzen (z. B. zusätzliche Verzeichnisse)

---
## 🛠 Recht zur Anmeldung als Stapelverarbeitungsauftrag hinzufügen (lokale Sicherheitsrichtlinie)

🔐 Problem: backup_user fehlt das Benutzerrecht „Anmelden als Stapelverarbeitungsauftrag“
Das ist ein Windows-Sicherheitsrecht, das erforderlich ist, damit ein Benutzer von Task Scheduler oder Scheduled Task-Diensten verwendet werden darf.

✅ Lösung: Benutzer backup_user dieses Recht über lokale Sicherheitsrichtlinie zuweisen

1. Start → secpol.msc öffnen (Lokale Sicherheitsrichtlinie)
2. Navigiere zu:
3. Sicherheitsoptionen → Lokale Richtlinien → Zuweisen von Benutzerrechten
4. Doppelklick auf: „Anmelden als Stapelverarbeitungsauftrag“
5. Klicke auf Benutzer oder Gruppe hinzufügen
6. Tippe backup_user ein → Namen überprüfen → OK
7. Übernehmen → Neustart nicht nötig
8. Falls doch, dann kann anstelle Neustart in einem Admin Terminal mit gpupdate /force die Richtlinie neu geladen werden. 

💡 Wenn du in einer Firmenumgebung arbeitest, kann diese Richtlinie durch Gruppenrichtlinien (GPO) überschrieben werden.


---

## 🗓️ Taskplaner-Aufgabe erstellen (tägliches Backup)

1. Starte **Taskplaner** als Admin
2. Neue Aufgabe → Name: `Tägliches Restic Backup`
3. Reiter **Allgemein**:
   - Benutzer: `backup_user`
   - ✅ „Mit höchsten Rechten ausführen“
   - ✅ „Unabhängig von Benutzeranmeldung ausführen“
4. Reiter **Trigger**:
   - Täglich, z. B. 03:00 Uhr
5. Reiter **Aktionen**:
   - Programm: `powershell.exe`
   - Argumente:
     ```
     -ExecutionPolicy Bypass -File "C:\Backup\restic_backup.ps1"
     ```

---

## 🧪 Test und Protokollierung

Optionales Logging:
```powershell
if ($LASTEXITCODE -eq 0) {
    "Backup erfolgreich: $(Get-Date)" | Out-File C:\Backup\success.log -Append
} else {
    "Backup FEHLGESCHLAGEN: $(Get-Date)" | Out-File C:\Backup\error.log -Append
}
```

---

## 🔄 Manueller Test

🔧 Variante A: Interaktive PowerShell-Sitzung mit runas:

1. Starte erst eine Shell, dann rufe das Skript darin auf:

```cmd
runas /user:backup_user cmd
```

   - Du wirst nach dem Passwort gefragt
   - Jetzt öffnet sich ein neues CMD-Fenster als backup_user

2. Powershell starten

```cmd
powershell
```

3. Script manuell ausführen

```powershell

powershell -ExecutionPolicy Bypass -File "C:\Backup\restic_backup.ps1"
```

- Jetzt siehst du alle Fehlermeldungen live.


---

## 🛡️ Sicherheitshinweise

- Skript- und Passwortdateien nur für `backup_user` zugänglich machen
- Keine sensiblen Daten im Skript hardcoden (außer Testphase)
- Optional: Task-Log aktivieren im Taskplaner

---

