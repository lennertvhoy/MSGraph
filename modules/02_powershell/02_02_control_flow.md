# Control Flow en Loops

In deze les gaan we leren hoe we beslissingen kunnen maken en herhalende taken kunnen uitvoeren in PowerShell. Dit zijn essentiële concepten voor het schrijven van effectieve scripts.

## If/Else Statements

### Basis If/Else

```powershell
# Eenvoudige if/else
if ($leeftijd -ge 18) {
    Write-Host "Je bent volwassen"
} else {
    Write-Host "Je bent minderjarig"
}

# If/elseif/else
if ($score -ge 90) {
    Write-Host "Uitstekend!"
} elseif ($score -ge 70) {
    Write-Host "Goed"
} elseif ($score -ge 50) {
    Write-Host "Voldoende"
} else {
    Write-Host "Onvoldoende"
}
```

### Inline If (Ternary Operator)

```powershell
# PowerShell 7+ syntax
$status = $isActief ? "Online" : "Offline"

# Oudere PowerShell versies
$status = if ($isActief) { "Online" } else { "Offline" }
```

## Switch Statements

### Basis Switch

```powershell
# Eenvoudige switch
switch ($dag) {
    "Maandag" { Write-Host "Begin van de week" }
    "Vrijdag" { Write-Host "Einde van de week" }
    "Zaterdag" { Write-Host "Weekend" }
    "Zondag" { Write-Host "Weekend" }
    default { Write-Host "Werkdag" }
}
```

### Geavanceerde Switch

```powershell
# Switch met expressies
switch ($score) {
    { $_ -ge 90 } { Write-Host "A" }
    { $_ -ge 80 } { Write-Host "B" }
    { $_ -ge 70 } { Write-Host "C" }
    { $_ -ge 60 } { Write-Host "D" }
    default { Write-Host "F" }
}

# Switch met regex
switch -Regex ($email) {
    "^[a-z]+@contoso\.com$" { Write-Host "Contoso email" }
    "^[a-z]+@fabrikam\.com$" { Write-Host "Fabrikam email" }
    default { Write-Host "Onbekend email domein" }
}
```

## ForEach Loops

### Basis ForEach

```powershell
# Array doorlopen
$namen = @("Jan", "Piet", "Marie")
foreach ($naam in $namen) {
    Write-Host "Hallo $naam!"
}

# Pipeline ForEach
$namen | ForEach-Object {
    Write-Host "Hallo $_!"
}
```

### ForEach met Index

```powershell
# Met index
$namen = @("Jan", "Piet", "Marie")
for ($i = 0; $i -lt $namen.Count; $i++) {
    Write-Host "Gebruiker $($i + 1): $($namen[$i])"
}

# Met ForEach-Object
$namen | ForEach-Object -Begin { $i = 0 } -Process {
    $i++
    Write-Host "Gebruiker $i : $_"
}
```

## While/Do Loops

### While Loop

```powershell
# Basis while loop
$teller = 0
while ($teller -lt 5) {
    Write-Host "Teller: $teller"
    $teller++
}

# While met conditie
$isGereed = $false
while (-not $isGereed) {
    $input = Read-Host "Voer 'stop' in om te stoppen"
    if ($input -eq "stop") {
        $isGereed = $true
    }
}
```

### Do/While Loop

```powershell
# Do/While loop
$teller = 0
do {
    Write-Host "Teller: $teller"
    $teller++
} while ($teller -lt 5)

# Do/Until loop
$teller = 0
do {
    Write-Host "Teller: $teller"
    $teller++
} until ($teller -ge 5)
```

## Error Handling

### Try/Catch/Finally

```powershell
# Basis try/catch
try {
    # Gevaarlijke code
    $result = 1/0
} catch {
    # Fout afhandelen
    Write-Host "Er is een fout opgetreden: $_"
}

# Met finally
try {
    # Code die resources gebruikt
    $file = [System.IO.File]::Open("test.txt", "Create")
} catch {
    Write-Host "Fout bij openen bestand: $_"
} finally {
    # Resources opruimen
    if ($file) { $file.Close() }
}
```

### Error Action Preference

```powershell
# Stop bij fouten
$ErrorActionPreference = "Stop"

# Fouten negeren
$ErrorActionPreference = "SilentlyContinue"

# Fouten opslaan en doorgaan
$ErrorActionPreference = "Continue"

# Fouten opslaan in variabele
$ErrorActionPreference = "Continue"
$errors = @()
try {
    # Code die fouten kan veroorzaken
} catch {
    $errors += $_
}
```

## Break en Continue

### Break Statement

```powershell
# Loop stoppen
foreach ($item in $items) {
    if ($item -eq "stop") {
        break
    }
    Write-Host $item
}

# Switch stoppen
switch ($dag) {
    "Zondag" { 
        Write-Host "Weekend"
        break
    }
    default { Write-Host "Werkdag" }
}
```

### Continue Statement

```powershell
# Iteratie overslaan
foreach ($nummer in 1..10) {
    if ($nummer % 2 -eq 0) {
        continue
    }
    Write-Host "Oneven nummer: $nummer"
}
```

## Best Practices

1. **Loop Selectie**
   - Gebruik ForEach voor collecties
   - Gebruik While voor onbekende iteraties
   - Gebruik For voor numerieke ranges

2. **Error Handling**
   - Implementeer altijd try/catch
   - Gebruik finally voor cleanup
   - Log fouten adequaat

3. **Performance**
   - Vermijd nested loops waar mogelijk
   - Gebruik break/continue efficiënt
   - Beperk loop iteraties

## Volgende Stap

Nu je weet hoe je control flow en loops kunt gebruiken, gaan we in de volgende les kijken naar [functions en modules](02_03_functions.md). Daar leren we hoe we code kunnen hergebruiken en modulair kunnen maken. 