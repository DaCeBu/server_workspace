<#
.SYNOPSIS
  Installiert resticprofile auf Windows, kopiert Konfig, legt geplanten Task an.
#>

Write-Host "🔧 Starte Installation für resticprofile-Backup..."

$installDir = "C:\Backup"
$profilePath = "$installDir\profiles.yaml"
$exePath = "$installDir\resticprofile.exe"
$taskScript = "$installDir\resticprofile_backup.ps1"

# 1. Verzeichnisse anlegen
if (-Not (Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir | Out-Null
}

# 2. resticprofile.exe herunterladen
if (-Not (Test-Path $exePath)) {
    Write-Host "⬇️ Lade resticprofile.exe herunter..."
    Invoke-WebRequest -Uri "https://github.com/creativeprojects/resticprofile/releases/latest/download/resticprofile-windows-amd64.exe" -OutFile $exePath
}

# 3. profiles.yaml kopieren (aus dem aktuellen Ordner)
if (-Not (Test-Path $profilePath)) {
    Copy-Item ".\profiles.yaml" $profilePath
}

# 4. Backup-Skript kopieren
if (-Not (Test-Path $taskScript)) {
    Copy-Item ".\resticprofile_backup.ps1" $taskScript
}

# 5. Taskplaner-Eintrag erstellen
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$taskScript`""
$trigger = New-ScheduledTaskTrigger -Daily -At 3am
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERNAME" -RunLevel Highest
$task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -Settings (New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries)

Register-ScheduledTask -TaskName "ResticProfileBackup" -InputObject $task -Force

Write-Host "✅ resticprofile Setup abgeschlossen. Backup läuft täglich um 03:00 Uhr."

