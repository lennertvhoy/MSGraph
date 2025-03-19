# Functions en Modules

In deze les gaan we leren hoe we code kunnen hergebruiken door functions te maken en modules te ontwikkelen. Dit maakt onze scripts modulair en makkelijker te onderhouden.

## Functions

### Basis Function

```powershell
# Eenvoudige function
function Get-Greeting {
    param (
        [string]$Naam
    )
    
    return "Hallo $Naam!"
}

# Function aanroepen
$bericht = Get-Greeting -Naam "Jan"
Write-Host $bericht
```

### Parameters

```powershell
# Function met verschillende parameter types
function Set-UserInfo {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Naam,
        
        [Parameter(Mandatory=$false)]
        [int]$Leeftijd = 0,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("Actief", "Inactief")]
        [string]$Status = "Actief",
        
        [Parameter(Mandatory=$false)]
        [switch]$IsAdmin
    )
    
    # Function body
    Write-Host "Naam: $Naam"
    Write-Host "Leeftijd: $Leeftijd"
    Write-Host "Status: $Status"
    Write-Host "Is Admin: $IsAdmin"
}
```

### Pipeline Support

```powershell
# Function met pipeline input
function Get-UserStatus {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$true)]
        [string]$UserName
    )
    
    begin {
        Write-Host "Start verwerking..."
    }
    
    process {
        Write-Host "Verwerk gebruiker: $UserName"
    }
    
    end {
        Write-Host "Verwerking voltooid."
    }
}

# Pipeline gebruiken
"Jan", "Piet", "Marie" | Get-UserStatus
```

### Return Values

```powershell
# Function met return value
function Get-UserDetails {
    param (
        [string]$UserName
    )
    
    # Return object
    return [PSCustomObject]@{
        Naam = $UserName
        Email = "$UserName@contoso.com"
        Afdeling = "IT"
        LaatsteLogin = (Get-Date).AddDays(-1)
    }
}

# Return value gebruiken
$user = Get-UserDetails -UserName "Jan"
Write-Host "Email: $($user.Email)"
```

## Modules

### Module Structuur

```powershell
# Maak module directory
New-Item -Path "C:\Modules\UserManagement" -ItemType Directory -Force

# Maak module manifest
New-ModuleManifest -Path "C:\Modules\UserManagement\UserManagement.psd1" `
    -RootModule "UserManagement.psm1" `
    -Author "Jan" `
    -Description "User Management Module" `
    -ModuleVersion "1.0.0"
```

### Module Code

```powershell
# UserManagement.psm1
# Private functions
function Get-UserFromAD {
    param (
        [string]$UserName
    )
    # AD query code
}

# Public functions
function Get-UserInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$UserName
    )
    
    # Gebruik private function
    $user = Get-UserFromAD -UserName $UserName
    
    return [PSCustomObject]@{
        Naam = $user.Name
        Email = $user.Email
        Afdeling = $user.Department
    }
}

# Export public functions
Export-ModuleMember -Function Get-UserInfo
```

### Module Importeren

```powershell
# Module importeren
Import-Module "C:\Modules\UserManagement"

# Module functies gebruiken
$userInfo = Get-UserInfo -UserName "Jan"
```

## Advanced Function Patterns

### Error Handling

```powershell
function Get-SafeUserInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$UserName
    )
    
    try {
        # Gevaarlijke operatie
        $user = Get-UserFromAD -UserName $UserName
        
        if (-not $user) {
            throw "Gebruiker niet gevonden"
        }
        
        return $user
    }
    catch {
        Write-Error "Fout bij ophalen gebruiker: $_"
        return $null
    }
}
```

### Parameter Validation

```powershell
function Set-UserPassword {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$UserName,
        
        [Parameter(Mandatory=$true)]
        [ValidateLength(8, 32)]
        [string]$Password,
        
        [Parameter(Mandatory=$false)]
        [ValidateRange(0, 90)]
        [int]$PasswordAge = 30
    )
    
    # Function body
}
```

### Pipeline ByValue/ByPropertyName

```powershell
function Get-UserStatus {
    [CmdletBinding()]
    param (
        [Parameter(
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [string]$UserName
    )
    
    process {
        Write-Host "Verwerk gebruiker: $UserName"
    }
}

# Pipeline by value
"Jan" | Get-UserStatus

# Pipeline by property name
[PSCustomObject]@{UserName="Jan"} | Get-UserStatus
```

## Best Practices

1. **Function Naming**
   - Gebruik Verb-Noun formaat
   - Maak namen beschrijvend
   - Volg PowerShell conventies

2. **Parameter Design**
   - Maak parameters verplicht waar nodig
   - Gebruik parameter validation
   - Geef default values waar logisch

3. **Error Handling**
   - Gebruik try/catch
   - Implementeer Write-Error
   - Return null bij fouten

4. **Module Design**
   - Scheid public/private functions
   - Documenteer functies
   - Versie modules correct

## Volgende Stap

Nu je weet hoe je functions en modules kunt maken, gaan we in de volgende les kijken naar [bestandssysteem en I/O](02_04_filesystem.md). Daar leren we hoe we kunnen werken met bestanden en data kunnen in- en exporteren. 