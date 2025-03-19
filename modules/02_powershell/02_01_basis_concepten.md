# PowerShell Basis Concepten

In deze les gaan we de basis concepten van PowerShell leren. Deze kennis is essentieel voor het schrijven van effectieve scripts en het werken met Microsoft Graph.

## Variabelen en Datatypes

### Variabelen Definiëren

```powershell
# Basis variabelen
$naam = "Jan"
$leeftijd = 30
$isActief = $true
$prijs = 19.99

# Variabele met specifiek datatype
[System.String]$email = "jan@contoso.com"
[System.Int32]$aantal = 42
[System.DateTime]$datum = Get-Date
```

### Datatypes

PowerShell ondersteunt verschillende datatypes:

1. **Strings (Tekst)**
   ```powershell
   $tekst = "Dit is een string"
   $tekst2 = 'Dit is ook een string'
   $multiline = @"
   Dit is een
   multiline string
   "@
   ```

2. **Numbers (Getallen)**
   ```powershell
   $integer = 42
   $float = 3.14
   $decimal = 19.99m
   $percentage = 0.15
   ```

3. **Booleans (Waar/Onwaar)**
   ```powershell
   $isWaar = $true
   $isOnwaar = $false
   ```

4. **DateTime (Datums)**
   ```powershell
   $nu = Get-Date
   $specifiekeDatum = [DateTime]"2024-01-01"
   ```

## Arrays en Collections

### Arrays Maken

```powershell
# Eenvoudige array
$namen = @("Jan", "Piet", "Marie")

# Array met verschillende datatypes
$gemengd = @("Tekst", 42, $true, (Get-Date))

# Lege array
$leeg = @()

# Array met range
$getallen = 1..5
```

### Array Operaties

```powershell
# Element toevoegen
$namen += "Sophie"

# Element verwijderen
$namen = $namen | Where-Object { $_ -ne "Piet" }

# Array sorteren
$namen = $namen | Sort-Object

# Array filteren
$volwassenen = $gebruikers | Where-Object { $_.Leeftijd -ge 18 }
```

### Collections

```powershell
# ArrayList (dynamische array)
$arrayList = New-Object System.Collections.ArrayList
$arrayList.Add("Item 1")
$arrayList.Add("Item 2")

# Queue
$queue = New-Object System.Collections.Queue
$queue.Enqueue("Eerste")
$queue.Enqueue("Tweede")

# Stack
$stack = New-Object System.Collections.Stack
$stack.Push("Bovenste")
$stack.Push("Onderste")
```

## Hashtables en Objects

### Hashtables

```powershell
# Basis hashtable
$config = @{
    Naam = "Test App"
    Versie = "1.0"
    Actief = $true
}

# Nested hashtable
$complex = @{
    Database = @{
        Server = "localhost"
        Port = 1433
    }
    API = @{
        Endpoint = "https://api.example.com"
        Key = "secret123"
    }
}
```

### Custom Objects

```powershell
# PSCustomObject maken
$gebruiker = [PSCustomObject]@{
    Naam = "Jan"
    Email = "jan@contoso.com"
    Afdeling = "IT"
}

# Object met methods
$calculator = [PSCustomObject]@{
    Value = 0
    Add = { param($x) $this.Value += $x }
    Subtract = { param($x) $this.Value -= $x }
}
```

## Operators en Vergelijkingen

### Vergelijkingsoperators

```powershell
# Numerieke vergelijkingen
$isGelijk = 5 -eq 5
$isNietGelijk = 5 -ne 3
$isGroter = 10 -gt 5
$isKleiner = 3 -lt 5
$isGroterOfGelijk = 5 -ge 5
$isKleinerOfGelijk = 3 -le 3

# String vergelijkingen
$isGelijk = "test" -eq "test"
$isNietGelijk = "test" -ne "TEST"
$isGroter = "b" -gt "a"
$isKleiner = "a" -lt "b"
```

### Logische Operators

```powershell
# AND operator
$resultaat = $true -and $true

# OR operator
$resultaat = $true -or $false

# NOT operator
$resultaat = -not $false

# XOR operator
$resultaat = $true -xor $true
```

### Wiskundige Operators

```powershell
# Basis wiskunde
$som = 5 + 3
$verschil = 5 - 3
$product = 5 * 3
$quotient = 6 / 2
$rest = 7 % 3

# Verhoog/Verlaag
$getal = 5
$getal++
$getal--
```

## Type Conversie

```powershell
# String naar nummer
$nummer = [int]"42"
$decimaal = [decimal]"19.99"

# Nummer naar string
$tekst = [string]42
$tekst2 = 42.ToString()

# DateTime parsing
$datum = [DateTime]"2024-01-01"
$datum2 = [DateTime]::ParseExact("01-01-2024", "dd-MM-yyyy", $null)
```

## Best Practices

1. **Variabele Benaming**
   - Gebruik beschrijvende namen
   - Begin met een letter
   - Gebruik camelCase of PascalCase
   - Vermijd speciale tekens

2. **Type Declaratie**
   - Declareer types waar mogelijk
   - Gebruik [PSCustomObject] voor complexe objecten
   - Valideer input data

3. **Performance**
   - Gebruik ArrayList voor dynamische collecties
   - Vermijd onnodige type conversies
   - Gebruik pipeline operators efficiënt

## Volgende Stap

Nu je de basis concepten van PowerShell kent, gaan we in de volgende les kijken naar [control flow en loops](02_02_control_flow.md). Daar leren we hoe we deze concepten kunnen gebruiken om beslissingen te maken en herhalende taken uit te voeren. 