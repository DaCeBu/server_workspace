# restic_backup.ps1
# Führt ein Backup per Restic durch (Ziel: Netzlaufwerk), mit Logging, Fehlerbehandlung und Exclude-Datei

$logFile = "C:\Backup\restic_last_success.log"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$username = $env:USERNAME  # ← Ruft den aktuell angemeldeten Windows-Benutzernamen ab
$resticRepo = "Z:\backup_$username\restic-repo"
$sourceFolder = "C:\Users\$username\Documents"
$passFile = "C:\Backup\restic_password.txt"
$resticCommand = "restic" # oder Pfad zu restic.exe
$excludeFile = "C:\Backup\restic_excludes.txt"

# Logging-Funktion
function Log($message) {
    $line = "$timestamp [$username] $message"
    Write-Host $line
    Add-Content -Path $logFile -Value $line
}

Log "=== Backup gestartet ==="

# Exclude-Datei vorbereiten
if (!(Test-Path $excludeFile)) {
    @"
E:\$RECYCLE.BIN\
E:\System Volume Information\
"@ | Out-File -FilePath $excludeFile -Encoding UTF8
    Log "🗂️ Exclude-Datei wurde erstellt unter $excludeFile"
}

# Netzlaufwerk verbinden
try {
    net use Z: /delete /y | Out-Null
    $mapResult = net use Z: \\192.168.1.100\backup /user:backup_$username (Get-Content $passFile -Raw)
    if ($LASTEXITCODE -ne 0) {
        Log "❌ Netzlaufwerk konnte nicht verbunden werden"
        Exit 1
    } else {
        Log "🔗 Netzlaufwerk verbunden"
    }
}
catch {
    Log "❌ Fehler beim Verbinden des Netzlaufwerks: $_"
    Exit 1
}

# Restic Passwort setzen
$env:RESTIC_PASSWORD = Get-Content $passFile -Raw

# Backup ausführen
try {
    & $resticCommand -r $resticRepo backup $sourceFolder --exclude-file $excludeFile
    $exitcode = $LASTEXITCODE
    if ($exitcode -eq 0) {
        Log "✅ Backup erfolgreich abgeschlossen"
    } else {
        Log "❌ Fehler beim Backup (Exitcode $exitcode)"
        Exit $exitcode
    }
}
catch {
    Log "❌ Ausnahme beim Backup: $_"
    Exit 1
}

# Alte Snapshots aufräumen
try {
    & $resticCommand -r $resticRepo forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune
    Log "♻️ Alte Snapshots erfolgreich bereinigt"
}
catch {
    Log "⚠️ Fehler beim Aufräumen: $_"
}

# Verbindung trennen
net use Z: /delete /y | Out-Null
Log "🔌 Netzlaufwerk getrennt"

Log "=== Backup beendet ==="
