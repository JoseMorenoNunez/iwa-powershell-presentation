# Ausfuehren von Scripten erlaubt ohne Restriction
Set-ExecutionPolicy Unrestricted

# Aktiviere die Remotefunktionalitaet
Enable-PSRemoting

# Einlesen der Konfigurationsdatei
$configFile = "Z:\\Code\\config.json"
$config = Get-Content -Raw -Path $configFile | ConvertFrom-Json

# Logging Funktion
function Write-Log {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $message"
    Add-Content -Path "Z:\\Code\\service_check.log" -Value $logMessage
}

# Ueberpruefen und Neustarten von Diensten
function Check-Service {
    param (
        [string]$computerName,
        [string]$serviceName
    )

    Write-Log "Ueberprüfe Dienst '$serviceName' auf Computer '$computerName'."
    $service = Get-Service -ComputerName $computerName -Name $serviceName -ErrorAction SilentlyContinue

    if ($null -eq $service) {
        Write-Log "Dienst '$serviceName' auf Computer '$computerName' wurde nicht gefunden."
        return
    }

    if ($service.Status -ne 'Running') {
        Write-Log "Dienst '$serviceName' auf Computer '$computerName' laeuft nicht. Starte neu."
        try {
            Invoke-Command -ComputerName $computerName -ScriptBlock { Start-Service -Name $using:serviceName }
            Write-Log "Dienst '$serviceName' auf Computer '$computerName' wurde erfolgreich gestartet."
        } catch {
            Write-Log "Fehler beim Starten des Dienstes '$serviceName' auf Computer '$computerName'."
        }
    } else {
        Write-Log "Dienst '$serviceName' auf Computer '$computerName' laeuft bereits."
    }
}

# Hauptroutine
foreach ($computer in $config.Computers) {
    if ($null -ne $computer.Name) {
        foreach ($service in $computer.Services) {
            if ($null -ne $service) {
                Check-Service -computerName $computer.Name -serviceName $service
            } else {
                Write-Log "Dienstname ist null fuer Computer '$computer.Name'."
            }
        }
    } else {
        Write-Log "Computername ist null."
    }
}
