# check_user_identity.ps1
# Prüft, ob Windows- und QNAP-Username gleich sind und empfiehlt Einrichtung

$windowsUser = $env:USERNAME
Write-Host "👤 Lokaler Windows-Benutzername: $windowsUser"

# Benutzer zur Eingabe der QNAP-Zugangsdaten auffordern
$qnapIP = Read-Host "🖥️ IP-Adresse oder Hostname des QNAP (z. B. 192.168.1.100)"
$qnapUser = Read-Host "👤 Benutzername am QNAP"
$qnapPass = Read-Host "🔐 Passwort für QNAP-Zugriff" -AsSecureString
$qnapPassPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($qnapPass))

# Entscheidung
if ($windowsUser -eq $qnapUser) {
    Write-Host "`n✅ Benutzername ist auf beiden Systemen identisch."
    Write-Host "   Empfehlung: Verwende auf beiden Systemen das gleiche Passwort."
    Write-Host "   Damit kannst du auf Netzfreigaben ohne zusätzliche Authentifizierung zugreifen."
}
else {
    Write-Host "`n⚠️ Benutzername unterscheidet sich:"
    Write-Host "   Windows: $windowsUser"
    Write-Host "   QNAP:    $qnapUser"
    Write-Host "`n❗ Empfehlung: Lege auf dem QNAP einen Benutzer '$windowsUser' mit dem gleichen Passwort wie auf Windows an."
}

# Optional: Netzlaufwerk testen
$drive = "Z:"
$unc = "\\$qnapIP\backup"
Write-Host "`n🔗 Teste Verbindung zu: $unc"

try {
    net use $drive /delete /y | Out-Null
    net use $drive $unc /user:$qnapUser $qnapPassPlain
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Verbindung erfolgreich aufgebaut!"
        net use $drive /delete /y | Out-Null
    }
    else {
        Write-Host "❌ Verbindung fehlgeschlagen. Prüfe Benutzername, Passwort und Rechte auf dem QNAP."
    }
}
catch {
    Write-Host "❌ Ausnahme bei Verbindungsaufbau: $_"
}
