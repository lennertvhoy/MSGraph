# Eerste Stappen met PowerShell

In deze les gaan we leren hoe je PowerShell kunt gebruiken om met Microsoft Graph te werken. We beginnen met de basis en bouwen dit stap voor stap op.

## PowerShell Installatie

### 1. PowerShell 7 Installeren

```powershell
# Download PowerShell 7
$url = "https://github.com/PowerShell/PowerShell/releases/download/v7.3.0/PowerShell-7.3.0-win-x64.msi"
$outPath = "$env:TEMP\PowerShell-7.3.0-win-x64.msi"
Invoke-WebRequest -Uri $url -OutFile $outPath

# Installeer PowerShell 7
Start-Process msiexec.exe -Wait -ArgumentList '/I', $outPath, '/quiet', '/norestart'
```

### 2. Microsoft.Graph Module Installeren

```powershell
# Installeer de Microsoft.Graph module
Install-Module Microsoft.Graph -Scope CurrentUser -Force

# Importeer de module
Import-Module Microsoft.Graph
```

## Basis PowerShell Concepten

### 1. Variabelen

```powershell
# Variabele definiëren
$naam = "Jan"
$leeftijd = 30

# Variabele gebruiken
Write-Host "Hallo $naam, je bent $leeftijd jaar oud"
```

### 2. Arrays

```powershell
# Array maken
$gebruikers = @("Jan", "Piet", "Marie")

# Array doorlopen
foreach ($gebruiker in $gebruikers) {
    Write-Host "Gebruiker: $gebruiker"
}
```

### 3. Hashtables

```powershell
# Hashtable maken
$config = @{
    TenantId = "12345678-1234-1234-1234-123456789012"
    ClientId = "87654321-4321-4321-4321-210987654321"
}

# Waarde ophalen
Write-Host "Tenant ID: $($config.TenantId)"
```

## Microsoft Graph Basis Commando's

### 1. Verbinding Maken

```powershell
# Verbinding maken met Microsoft Graph
Connect-MgGraph -Scopes "User.Read", "Group.Read.All"

# Controleer de verbinding
Get-MgContext
```

### 2. Gebruikers Ophalen

```powershell
# Alle gebruikers ophalen
Get-MgUser -All

# Specifieke gebruiker ophalen
Get-MgUser -UserId "jan@contoso.com"

# Gebruikers filteren
Get-MgUser -Filter "startsWith(displayName,'Jan')"
```

### 3. Groepen Ophalen

```powershell
# Alle groepen ophalen
Get-MgGroup -All

# Specifieke groep ophalen
Get-MgGroup -GroupId "12345678-1234-1234-1234-123456789012"

# Groepsleden ophalen
Get-MgGroupMember -GroupId "12345678-1234-1234-1234-123456789012"
```

## Error Handling

### 1. Try-Catch Blokken

```powershell
try {
    # Probeer verbinding te maken
    Connect-MgGraph -Scopes "User.Read"
    
    # Haal gebruikers op
    $gebruikers = Get-MgUser -All
}
catch {
    # Vang eventuele fouten op
    Write-Host "Er is een fout opgetreden: $_"
}
finally {
    # Altijd uitvoeren
    Disconnect-MgGraph
}
```

### 2. Error Action Preference

```powershell
# Stop bij fouten
$ErrorActionPreference = "Stop"

# Of negeer fouten
$ErrorActionPreference = "SilentlyContinue"
```

## Praktische Oefeningen

### Oefening 1: Gebruikers Rapport

```powershell
# Script om een gebruikersrapport te maken
function Get-UserReport {
    try {
        # Verbinding maken
        Connect-MgGraph -Scopes "User.Read"
        
        # Gebruikers ophalen
        $users = Get-MgUser -All
        
        # Rapport maken
        $report = @()
        foreach ($user in $users) {
            $report += [PSCustomObject]@{
                Naam = $user.DisplayName
                Email = $user.UserPrincipalName
                Afdeling = $user.Department
                LaatsteLogin = $user.SignInActivity.LastSignInDateTime
            }
        }
        
        # Rapport exporteren
        $report | Export-Csv -Path "C:\Temp\GebruikersRapport.csv" -NoTypeInformation
    }
    catch {
        Write-Host "Fout bij maken rapport: $_"
    }
    finally {
        Disconnect-MgGraph
    }
}
```

### Oefening 2: Groep Beheer

```powershell
# Script om groepen te beheren
function Get-GroupMembership {
    param (
        [string]$GroupName
    )
    
    try {
        # Verbinding maken
        Connect-MgGraph -Scopes "Group.Read.All"
        
        # Groep zoeken
        $group = Get-MgGroup -Filter "displayName eq '$GroupName'"
        
        if ($group) {
            # Leden ophalen
            $members = Get-MgGroupMember -GroupId $group.Id
            
            # Leden weergeven
            foreach ($member in $members) {
                Write-Host "Lid: $($member.DisplayName)"
            }
        }
        else {
            Write-Host "Groep niet gevonden"
        }
    }
    catch {
        Write-Host "Fout bij ophalen groepsleden: $_"
    }
    finally {
        Disconnect-MgGraph
    }
}
```

## Best Practices

1. **Verbinding Beheer**
   - Maak altijd verbinding met minimale benodigde scopes
   - Sluit verbindingen netjes af
   - Gebruik try-catch blokken

2. **Performance**
   - Gebruik -All parameter voor grote datasets
   - Filter data waar mogelijk
   - Gebruik paginering voor grote resultaten

3. **Security**
   - Gebruik geen hardcoded credentials
   - Implementeer error handling
   - Log belangrijke acties

## Volgende Stap

Nu je de basis van PowerShell met Microsoft Graph kent, gaan we in de volgende les kijken naar [praktische oefeningen](01_04_praktische_oefeningen.md) waar we alles wat we hebben geleerd in praktijk brengen. 