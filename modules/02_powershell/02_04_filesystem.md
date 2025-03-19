# Bestandssysteem en I/O

In deze les gaan we leren hoe we kunnen werken met bestanden en data kunnen in- en exporteren in PowerShell. Dit is essentieel voor het opslaan van configuraties, het genereren van rapporten en het verwerken van data.

## Bestanden Lezen en Schrijven

### Tekstbestanden

```powershell
# Bestand schrijven
$content = "Dit is een test bestand"
$content | Out-File -Path "C:\Temp\test.txt" -Encoding UTF8

# Bestand lezen
$content = Get-Content -Path "C:\Temp\test.txt"
Write-Host $content

# Bestand toevoegen
"Extra regel" | Add-Content -Path "C:\Temp\test.txt"
```

### Binary Bestanden

```powershell
# Binary bestand schrijven
$bytes = [System.Text.Encoding]::UTF8.GetBytes("Binary data")
[System.IO.File]::WriteAllBytes("C:\Temp\test.bin", $bytes)

# Binary bestand lezen
$bytes = [System.IO.File]::ReadAllBytes("C:\Temp\test.bin")
$content = [System.Text.Encoding]::UTF8.GetString($bytes)
```

## CSV Verwerking

### CSV Schrijven

```powershell
# Data voorbereiden
$users = @(
    [PSCustomObject]@{
        Naam = "Jan"
        Email = "jan@contoso.com"
        Afdeling = "IT"
    },
    [PSCustomObject]@{
        Naam = "Piet"
        Email = "piet@contoso.com"
        Afdeling = "HR"
    }
)

# CSV exporteren
$users | Export-Csv -Path "C:\Temp\users.csv" -NoTypeInformation -Encoding UTF8
```

### CSV Lezen

```powershell
# CSV importeren
$users = Import-Csv -Path "C:\Temp\users.csv"

# CSV data verwerken
foreach ($user in $users) {
    Write-Host "Naam: $($user.Naam), Email: $($user.Email)"
}
```

## JSON Verwerking

### JSON Schrijven

```powershell
# Data voorbereiden
$config = @{
    AppName = "TestApp"
    Version = "1.0"
    Settings = @{
        Theme = "Dark"
        Language = "NL"
    }
}

# JSON exporteren
$config | ConvertTo-Json -Depth 10 | Out-File -Path "C:\Temp\config.json"
```

### JSON Lezen

```powershell
# JSON importeren
$jsonContent = Get-Content -Path "C:\Temp\config.json" -Raw
$config = $jsonContent | ConvertFrom-Json

# JSON data gebruiken
Write-Host "App: $($config.AppName)"
Write-Host "Theme: $($config.Settings.Theme)"
```

## Logging

### Log File Maken

```powershell
# Logging function
function Write-Log {
    param (
        [string]$Message,
        [ValidateSet("Info", "Warning", "Error")]
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    Add-Content -Path "C:\Temp\app.log" -Value $logMessage
}

# Logging gebruiken
Write-Log -Message "Applicatie gestart" -Level "Info"
Write-Log -Message "Waarschuwing: configuratie ontbreekt" -Level "Warning"
Write-Log -Message "Fout: database niet bereikbaar" -Level "Error"
```

### Log Rotation

```powershell
# Log rotation function
function Rotate-LogFile {
    param (
        [string]$LogPath,
        [int]$MaxFiles = 5
    )
    
    if (Test-Path $LogPath) {
        $logFile = Get-Item $LogPath
        $logDir = $logFile.DirectoryName
        $logName = $logFile.BaseName
        $logExt = $logFile.Extension
        
        # Verwijder oudste bestanden
        Get-ChildItem -Path $logDir -Filter "$logName.*$logExt" |
            Sort-Object LastWriteTime -Descending |
            Select-Object -Skip $MaxFiles |
            Remove-Item -Force
        
        # Hernoem huidig bestand
        $newName = "$logName.$(Get-Date -Format 'yyyyMMdd')$logExt"
        Rename-Item -Path $LogPath -NewName $newName
    }
}
```

## Configuratie Bestanden

### Configuratie Opslaan

```powershell
# Configuratie class
class AppConfig {
    [string]$AppName
    [string]$Version
    [hashtable]$Settings
    
    AppConfig() {
        $this.AppName = "TestApp"
        $this.Version = "1.0"
        $this.Settings = @{
            Theme = "Dark"
            Language = "NL"
        }
    }
}

# Configuratie opslaan
$config = [AppConfig]::new()
$config | ConvertTo-Json | Out-File -Path "C:\Temp\appconfig.json"
```

### Configuratie Laden

```powershell
# Configuratie laden
$jsonConfig = Get-Content -Path "C:\Temp\appconfig.json" -Raw
$config = $jsonConfig | ConvertFrom-Json

# Configuratie gebruiken
Write-Host "App: $($config.AppName)"
Write-Host "Theme: $($config.Settings.Theme)"
```

## Bestandssysteem Operaties

### Directory Operaties

```powershell
# Directory maken
New-Item -Path "C:\Temp\NewFolder" -ItemType Directory -Force

# Directory inhoud ophalen
Get-ChildItem -Path "C:\Temp" -Recurse

# Directory verwijderen
Remove-Item -Path "C:\Temp\NewFolder" -Recurse -Force
```

### Bestand Operaties

```powershell
# Bestand kopiëren
Copy-Item -Path "C:\Temp\source.txt" -Destination "C:\Temp\backup.txt"

# Bestand verplaatsen
Move-Item -Path "C:\Temp\source.txt" -Destination "C:\Temp\archive\"

# Bestand verwijderen
Remove-Item -Path "C:\Temp\backup.txt" -Force
```

## Best Practices

1. **Bestandsoperaties**
   - Gebruik -Force met voorzichtigheid
   - Controleer bestaande bestanden
   - Gebruik try/catch voor foutafhandeling

2. **Data Formaten**
   - Gebruik UTF8 encoding
   - Valideer data voor import/export
   - Documenteer data structuren

3. **Logging**
   - Implementeer log rotation
   - Gebruik consistente log levels
   - Log belangrijke events

4. **Configuratie**
   - Scheid configuratie van code
   - Valideer configuratie data
   - Gebruik versie controle

## Volgende Stap

Nu je weet hoe je kunt werken met bestanden en data kunt in- en exporteren, gaan we in de volgende les kijken naar [praktische oefeningen](02_05_praktische_oefeningen.md). Daar gaan we alles wat we hebben geleerd in praktijk brengen. 