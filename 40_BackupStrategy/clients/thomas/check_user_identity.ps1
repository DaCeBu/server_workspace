# setup_backup_user.ps1
# Erstellt lokalen backup_user, legt Verzeichnisstruktur und Profile für Restic an

# === KONFIGURATION ===
$localUser = "backup_thomas"
$localPassword = "K~MNqVBq7J\~0CliQj*/"  # Optional: nur bei Neuanlage
$qnapShare = "\\192.168.30.2\backup"
$qnapUser = "backup_thomas"
$qnapPass = "K~MNqVBq7J\~0CliQj*/" # <-- HIER ERSETZEN
$backupPath = "C:\Backup"
$repoPath = "G:\Backup_Test\restic-repo"
$pwFile = "$backupPath\restic_password.txt"
$profileFile = "$backupPath\profiles.yaml"
$logPath = "$backupPath\logs"

# === FUNKTION: Benutzer prüfen ===
function Ensure-LocalUserExists {
    if (-not (Get-LocalUser -Name $localUser -ErrorAction SilentlyContinue)) {
        Write-Host "Lokaler Benutzer $localUser wird erstellt..."
        $securePassword = ConvertTo-SecureString $localPassword -AsPlainText -Force
        New-LocalUser -Name $localUser -Password $securePassword -FullName "Backup User" -Description "User for scheduled restic backups"
    } else {
        Write-Host "Benutzer $localUser existiert bereits."
    }
}

# === FUNKTION: QNAP-Share testen ===
function Test-QnapShareAccess {
    Write-Host "Teste Zugriff auf QNAP-Share..."
    cmd /c "net use Z: $qnapShare /user:$qnapUser $qnapPass" | Out-Null
    if (Test-Path "Z:\") {
        Write-Host "QNAP-Share erfolgreich verbunden."
        cmd /c "net use Z: /delete" | Out-Null
    } else {
        Write-Warning "Zugriff auf QNAP fehlgeschlagen. Bitte Zugang prüfen!"
    }
}

# === Verzeichnisse anlegen ===
function Ensure-DirectoryStructure {
    Write-Host "Lege Verzeichnisstruktur an..."
    New-Item -ItemType Directory -Force -Path $backupPath | Out-Null
    New-Item -ItemType Directory -Force -Path $logPath | Out-Null
}

# === Passwortdatei erstellen (falls nicht vorhanden) ===
function Ensure-PasswordFile {
    if (-not (Test-Path $pwFile)) {
        $resticPassword = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 32 | ForEach-Object {[char]$_})
        Set-Content -Path $pwFile -Value $resticPassword -Encoding UTF8
        Write-Host "restic Passwortdatei wurde erstellt unter $pwFile"
    } else {
        Write-Host "Passwortdatei existiert bereits."
    }
}

# === profiles.yaml kopieren ===
function Copy-ProfilesYaml {
    $scriptFolder = Split-Path -Parent $MyInvocation.MyCommand.Path
    $sourceProfile = Join-Path $scriptFolder "profiles.yaml"

    if (Test-Path $sourceProfile) {
        Copy-Item -Path $sourceProfile -Destination $profileTarget -Force
        Write-Host "profiles.yaml wurde nach $profileTarget kopiert."
    } else {
        Write-Warning "profiles.yaml wurde im Script-Ordner nicht gefunden!"
    }
}

# === AUSFÜHRUNG ===

Ensure-LocalUserExists
Test-QnapShareAccess
Ensure-DirectoryStructure
Ensure-PasswordFile
Copy-ProfilesYaml

Write-Host "`n✅ Setup abgeschlossen. Bitte öffne eine PowerShell als $localUser und führe anschließend `resticprofile backup --dry-run` aus."