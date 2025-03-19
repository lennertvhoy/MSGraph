# Praktische Oefeningen Module 2

In deze les gaan we de kennis die we hebben opgedaan in praktijk brengen met een aantal oefeningen. We beginnen met eenvoudige oefeningen en bouwen dit op naar meer complexe scenario's.

## Oefening 1: Data Verwerking

### Doel
Leer hoe je data kunt verwerken en exporteren naar verschillende formaten.

### Stappen

1. **Script Maken**
   ```powershell
   # Maak een nieuw script bestand
   New-Item -Path "C:\Temp\Process-Data.ps1" -ItemType File
   ```

2. **Script Inhoud**
   ```powershell
   # Data verwerking script
   function Process-UserData {
       param (
           [string]$OutputPath = "C:\Temp\output"
       )
       
       # Maak output directory
       if (-not (Test-Path $OutputPath)) {
           New-Item -Path $OutputPath -ItemType Directory -Force
       }
       
       # Genereer test data
       $users = @()
       $departments = @("IT", "HR", "Finance", "Marketing")
       
       for ($i = 1; $i -le 10; $i++) {
           $users += [PSCustomObject]@{
               ID = $i
               Naam = "Gebruiker $i"
               Email = "gebruiker$i@contoso.com"
               Afdeling = $departments[(Get-Random -Maximum $departments.Count)]
               LaatsteLogin = (Get-Date).AddDays(-(Get-Random -Maximum 30))
               IsActief = (Get-Random -InputObject @($true, $false))
           }
       }
       
       # Exporteer naar CSV
       $users | Export-Csv -Path "$OutputPath\users.csv" -NoTypeInformation -Encoding UTF8
       
       # Exporteer naar JSON
       $users | ConvertTo-Json | Out-File -Path "$OutputPath\users.json" -Encoding UTF8
       
       # Maak rapport
       $report = @"
       Gebruikers Rapport
       =================
       Totaal aantal gebruikers: $($users.Count)
       Actieve gebruikers: $($users | Where-Object { $_.IsActief } | Measure-Object).Count
       
       Gebruikers per afdeling:
       "@
       
       $users | Group-Object Afdeling | ForEach-Object {
           $report += "`n$($_.Name): $($_.Count) gebruikers"
       }
       
       $report | Out-File -Path "$OutputPath\report.txt" -Encoding UTF8
       
       Write-Host "Data verwerking voltooid. Output in: $OutputPath"
   }
   
   # Script uitvoeren
   Process-UserData
   ```

3. **Script Uitvoeren**
   ```powershell
   # Script uitvoeren
   .\Process-Data.ps1
   ```

### Verificatie
Controleer of:
- De output directory is aangemaakt
- Het CSV bestand correct is gegenereerd
- Het JSON bestand correct is gegenereerd
- Het rapport bestand de juiste informatie bevat

## Oefening 2: Error Handling

### Doel
Leer hoe je fouten kunt afhandelen en logging kunt implementeren.

### Stappen

1. **Script Maken**
   ```powershell
   # Maak een nieuw script bestand
   New-Item -Path "C:\Temp\Handle-Errors.ps1" -ItemType File
   ```

2. **Script Inhoud**
   ```powershell
   # Error handling script
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
   
   function Test-FileOperation {
       param (
           [string]$FilePath
       )
       
       try {
           Write-Log -Message "Start bestandsoperatie: $FilePath" -Level "Info"
           
           # Test bestand maken
           if (Test-Path $FilePath) {
               throw "Bestand bestaat al: $FilePath"
           }
           
           "Test data" | Out-File -Path $FilePath -Encoding UTF8
           Write-Log -Message "Bestand succesvol aangemaakt" -Level "Info"
           
           # Test bestand lezen
           $content = Get-Content -Path $FilePath
           Write-Log -Message "Bestand succesvol gelezen" -Level "Info"
           
           # Test bestand verwijderen
           Remove-Item -Path $FilePath -Force
           Write-Log -Message "Bestand succesvol verwijderd" -Level "Info"
       }
       catch {
           Write-Log -Message "Fout opgetreden: $_" -Level "Error"
           throw
       }
   }
   
   # Script uitvoeren
   $testFile = "C:\Temp\test.txt"
   Test-FileOperation -FilePath $testFile
   ```

3. **Script Uitvoeren**
   ```powershell
   # Script uitvoeren
   .\Handle-Errors.ps1
   ```

### Verificatie
Controleer of:
- Het log bestand is aangemaakt
- Log berichten correct zijn opgeslagen
- Fouten netjes worden afgehandeld
- Resources correct worden opgeruimd

## Oefening 3: Module Ontwikkeling

### Doel
Leer hoe je een PowerShell module kunt ontwikkelen en gebruiken.

### Stappen

1. **Module Directory Maken**
   ```powershell
   # Maak module directory
   $modulePath = "C:\Modules\FileManager"
   New-Item -Path $modulePath -ItemType Directory -Force
   ```

2. **Module Manifest Maken**
   ```powershell
   # Maak module manifest
   New-ModuleManifest -Path "$modulePath\FileManager.psd1" `
       -RootModule "FileManager.psm1" `
       -Author "Jan" `
       -Description "File Management Module" `
       -ModuleVersion "1.0.0"
   ```

3. **Module Code**
   ```powershell
   # FileManager.psm1
   # Private functions
   function Get-FileHash {
       param (
           [string]$FilePath
       )
       
       $hash = Get-FileHash -Path $FilePath -Algorithm SHA256
       return $hash.Hash
   }
   
   # Public functions
   function Copy-FileWithBackup {
       [CmdletBinding()]
       param (
           [Parameter(Mandatory=$true)]
           [string]$SourcePath,
           
           [Parameter(Mandatory=$true)]
           [string]$DestinationPath,
           
           [Parameter(Mandatory=$false)]
           [switch]$CreateBackup
       )
       
       try {
           if (-not (Test-Path $SourcePath)) {
               throw "Bronbestand niet gevonden: $SourcePath"
           }
           
           if ($CreateBackup -and (Test-Path $DestinationPath)) {
               $backupPath = "$DestinationPath.backup"
               Copy-Item -Path $DestinationPath -Destination $backupPath -Force
               Write-Host "Backup gemaakt: $backupPath"
           }
           
           Copy-Item -Path $SourcePath -Destination $DestinationPath -Force
           Write-Host "Bestand gekopieerd: $DestinationPath"
           
           $hash = Get-FileHash -FilePath $DestinationPath
           Write-Host "Bestandshash: $hash"
       }
       catch {
           Write-Error "Fout bij kopiëren bestand: $_"
           throw
       }
   }
   
   # Export public functions
   Export-ModuleMember -Function Copy-FileWithBackup
   ```

4. **Test Script**
   ```powershell
   # Maak test script
   New-Item -Path "C:\Temp\Test-Module.ps1" -ItemType File
   ```

5. **Test Script Inhoud**
   ```powershell
   # Import module
   Import-Module "C:\Modules\FileManager"
   
   # Test bestanden maken
   "Test data" | Out-File -Path "C:\Temp\source.txt" -Encoding UTF8
   
   # Test module functie
   Copy-FileWithBackup -SourcePath "C:\Temp\source.txt" `
       -DestinationPath "C:\Temp\destination.txt" `
       -CreateBackup
   ```

6. **Test Script Uitvoeren**
   ```powershell
   # Script uitvoeren
   .\Test-Module.ps1
   ```

### Verificatie
Controleer of:
- De module correct is geïnstalleerd
- De module functies beschikbaar zijn
- Het backup bestand is aangemaakt
- De bestandshash wordt weergegeven

## Bonus Oefening: Configuratie Beheer

### Doel
Leer hoe je configuratie kunt beheren en valideren.

### Stappen

1. **Script Maken**
   ```powershell
   # Maak een nieuw script bestand
   New-Item -Path "C:\Temp\Manage-Config.ps1" -ItemType File
   ```

2. **Script Inhoud**
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
               LogLevel = "Info"
               MaxRetries = 3
           }
       }
       
       [bool]Validate() {
           if ([string]::IsNullOrEmpty($this.AppName)) {
               return $false
           }
           
           if ([string]::IsNullOrEmpty($this.Version)) {
               return $false
           }
           
           if ($this.Settings.Count -eq 0) {
               return $false
           }
           
           return $true
       }
   }
   
   # Configuratie beheer functies
   function Save-Config {
       param (
           [AppConfig]$Config,
           [string]$Path
       )
       
       if (-not $Config.Validate()) {
           throw "Configuratie is ongeldig"
       }
       
       $Config | ConvertTo-Json | Out-File -Path $Path -Encoding UTF8
       Write-Host "Configuratie opgeslagen: $Path"
   }
   
   function Load-Config {
       param (
           [string]$Path
       )
       
       if (-not (Test-Path $Path)) {
           throw "Configuratie bestand niet gevonden: $Path"
       }
       
       $json = Get-Content -Path $Path -Raw
       $config = $json | ConvertFrom-Json
       
       # Valideer configuratie
       if (-not $config.Validate()) {
           throw "Configuratie is ongeldig"
       }
       
       return $config
   }
   
   # Script uitvoeren
   $configPath = "C:\Temp\appconfig.json"
   
   # Maak en sla configuratie op
   $config = [AppConfig]::new()
   Save-Config -Config $config -Path $configPath
   
   # Laad en gebruik configuratie
   $loadedConfig = Load-Config -Path $configPath
   Write-Host "App: $($loadedConfig.AppName)"
   Write-Host "Theme: $($loadedConfig.Settings.Theme)"
   ```

3. **Script Uitvoeren**
   ```powershell
   # Script uitvoeren
   .\Manage-Config.ps1
   ```

### Verificatie
Controleer of:
- De configuratie correct wordt opgeslagen
- De configuratie correct wordt geladen
- Validatie werkt
- Fouten netjes worden afgehandeld

## Volgende Stap

Nu je deze praktische oefeningen hebt voltooid, heb je een goede basis voor het werken met PowerShell. Je kunt doorgaan naar [Module 3: Python voor Systeembeheerders](../03_python/README.md) om je kennis uit te breiden met Python. 