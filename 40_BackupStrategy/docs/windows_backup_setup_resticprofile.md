# 🪟 Windows Backup Setup mit ResticProfile

Diese Anleitung beschreibt die vollständige Einrichtung eines sicheren, automatisierten Backup-Systems auf Windows-Clients mit `resticprofile` und einem QNAP NAS als Backup-Ziel.

---

## ✅ Voraussetzungen

- SMB-Zugriff auf das NAS (z. B. `\\192.168.1.100\backup\backup_max`)
- Dedizierter Windows-Benutzer (z. B. `backup_max`)
- Freigabe auf dem NAS mit Snapshots
- `resticprofile.exe` und `restic.exe` auf dem Client
- Schreibrechte auf den Quellordnern

---

## 🔧 Vorbereitung

1. Erstelle auf dem NAS den Ordner `/backup/backup_max/`
2. Weise dem Benutzer `backup_max` auf dem NAS nur Zugriff auf diesen Unterordner zu
3. Aktiviere Snapshots auf `DataVol1` für `/backup`

---

## 📂 Verzeichnisstruktur (Windows)

```
C:└── Backup    ├── profiles.yaml
    ├── restic_password.txt
    ├── resticprofile.exe
    ├── restic.exe
    └── resticprofile_backup.ps1
```

---

## 🔑 profiles.yaml

Die Datei `profiles.yaml` steuert alle Backup-, Vergessen- und Prüfroutinen. Beispiel:

```yaml
default:
  lock: "C:\Windows\Temp\resticprofile-profile-default.lock"
  force-inactive-lock: true
  initialize: true
  repository: "\\192.168.1.100\backup\backup_{{ .Env.USERNAME }}\restic-repo"
  password-file: "C:\Backup\restic_password.txt"
  status-file: "C:\Backup\restic_status.json"
  env:
    RESTIC_PASSWORD_FILE: "C:\Backup\restic_password.txt"
  backup:
    one-file-system: true
    source:
      - "C:\Users\{{ .Env.USERNAME }}\Documents"
      - "C:\Users\{{ .Env.USERNAME }}\Pictures"
    schedule: "03:00"
    schedule-permission: user
    schedule-lock-wait: 10m
    schedule-log: "{{ tempFile \"backup.log\" }}"
    verbose: 2
    run-finally:
      - 'powershell -Command "Select-String -Path {{ tempFile \"backup.log\" }} -Pattern '^unchanged' -NotMatch | Set-Content -Path C:\Backup\backup.log"'
  forget:
    keep-daily: 7
    keep-weekly: 4
    keep-monthly: 6
    prune: true
    schedule: "03:30"
    schedule-permission: user
    schedule-lock-wait: 1h
  check:
    schedule: "04:00"
    schedule-permission: user
    schedule-lock-wait: 1h
```

---

## 📜 Backup-Skript

Datei: `C:\Backup\resticprofile_backup.ps1`

```powershell
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$logfile = "C:\Backup\resticprofile_run.log"

function Log($msg) {
    "$timestamp $msg" | Out-File $logfile -Append
}

Log "=== resticprofile Backup gestartet ==="

try {
    & "C:\Backup\resticprofile.exe" -c "C:\Backup\profiles.yaml" backup
    if ($LASTEXITCODE -eq 0) {
        Log "Backup erfolgreich abgeschlossen."
    } else {
        Log "Backup mit Fehlern beendet. Exitcode: $LASTEXITCODE"
    }
} catch {
    Log "❌ Fehler beim Ausführen von resticprofile: $_"
}

Log "=== resticprofile Backup beendet ==="
```

---

## ⏱️ Automatisierung

1. Taskplaner → Aufgabe erstellen → Name `ResticProfileBackup`
2. Benutzer: `backup_max`
3. Trigger: täglich 03:00 Uhr
4. Aktion:
   - Programm: `powershell.exe`
   - Argumente:
     ```
     -ExecutionPolicy Bypass -File "C:\Backup\resticprofile_backup.ps1"
     ```

---

## ✅ Test

```powershell
C:\Backup
esticprofile.exe -c C:\Backup\profiles.yaml backup
```

Ergebnisse findest du in `C:\Backup
esticprofile_run.log`.

---

## 🔍 Status

```powershell
C:\Backup
esticprofile.exe -c C:\Backup\profiles.yaml status
```

