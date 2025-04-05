# setup_restic_backup.ps1
# Vollständige Initialisierung mit Admin-Prüfung und dynamischem Restic-Pfad

# Eingaben abfragen
$nasUser = Read-Host "QNAP-Benutzername"
$nasFolder = Read-Host "QNAP-BackupUserFolder"
$nasPass = Read-Host "QNAP-Passwort" -AsSecureString
$resticPassword = Read-Host "Restic Repository Passwort" -AsSecureString


# Optional: restic Pfad ermitteln
$resticCommand = "restic"
if (-not (Get-Command restic -ErrorAction SilentlyContinue)) {
    $customPath = Read-Host "Restic konnte nicht gefunden werden. Bitte gib den vollständigen Pfad zu restic.exe an (z.B. C:\Programme\restic\restic.exe)"
    if (-not (Test-Path $customPath)) {
        Write-Host "❌ Restic konnte nicht gefunden werden unter: $customPath"
        Exit 1
    }
    $resticCommand = "`"$customPath`""
}

# Klartextpasswörter für spätere Verwendung
$nasPassPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($nasPass))
$resticPasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($resticPassword))

# Netzlaufwerk verbinden und initialisieren
try {
    Write-Host "`n🔗 Verbinde Netzlaufwerk Z: mit QNAP..."
    net use Z: "\\192.168.30.2\backup" /user:$nasUser $nasPassPlain

    if (!(Test-Path -Path "Z:\$nasFolder")) {
        throw "❌ Unterordner '$nasFolder' existiert nicht auf dem NAS!"
    }

    Write-Host "🚀 Initialisiere Restic Repository..."
    $env:RESTIC_PASSWORD = $resticPasswordPlain
    & $resticCommand -r "Z:\$nasFolder\restic-repo" init

    Write-Host "📴 Trenne Netzlaufwerk..."
    net use Z: /delete /y
}
catch {
    Write-Host "❌ Fehler während Initialisierung: $_"
    Exit 1
}

# Backup-Ordner und Dateien vorbereiten
$backupDir = "C:\Backup"
if (!(Test-Path -Path $backupDir)) {
    New-Item -Path $backupDir -ItemType Directory | Out-Null
    Write-Host "📁 Verzeichnis C:\Backup wurde erstellt."
}

$resticPasswordPlain | Out-File -FilePath "$backupDir\restic_password.txt" -Encoding utf8 -Force
Write-Host "🔐 Passwortdatei gespeichert."

# Skriptdatei anlegen
$scriptContent = @"
`$env:RESTIC_PASSWORD = Get-Content 'C:\Backup\restic_password.txt'
net use Z: \\192.168.1.100\backup /user=$nasUser "$nasPassPlain"
& $resticCommand -r Z:\$nasFolder\restic-repo backup C:\Users\$env:USERNAME\Documents
& $resticCommand -r Z:\$nasFolder\restic-repo forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune
net use Z: /delete
"@
$scriptContent | Out-File -FilePath "$backupDir\restic_backup.ps1" -Encoding utf8 -Force
Write-Host "📜 Backup-Skript gespeichert unter $backupDir\restic_backup.ps1"