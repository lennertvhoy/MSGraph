# Praktische Oefeningen Module 1

In deze les gaan we de kennis die we hebben opgedaan in praktijk brengen met een aantal oefeningen. We beginnen met eenvoudige oefeningen en bouwen dit op naar meer complexe scenario's.

## Oefening 1: App Registratie Maken

### Doel
Leer hoe je een app registratie maakt in Azure AD en de benodigde credentials verkrijgt.

### Stappen

1. **Azure Portal Openen**
   ```powershell
   Start-Process "https://portal.azure.com"
   ```

2. **App Registratie Maken**
   - Ga naar "Azure Active Directory" > "App registraties"
   - Klik op "Nieuwe registratie"
   - Vul de volgende gegevens in:
     - Naam: "MSGraph Cursus App"
     - Ondersteunde accounttypen: "Accounts in deze organisatiemap"
     - Redirect URI: "http://localhost"
   - Klik op "Registreren"

3. **Credentials Opslaan**
   - Noteer de "Application (client) ID"
   - Noteer de "Directory (tenant) ID"
   - Maak een client secret aan onder "Certificates & secrets"

4. **Permissions Toevoegen**
   - Ga naar "API permissions"
   - Klik op "Add a permission"
   - Kies "Microsoft Graph"
   - Selecteer de volgende permissions:
     - User.Read
     - Group.Read.All
   - Klik op "Grant admin consent"

### Verificatie
Controleer of je de volgende bestanden hebt:
- Een notitie met je client ID
- Een notitie met je tenant ID
- Een notitie met je client secret
- Een screenshot van je geconfigureerde permissions

## Oefening 2: PowerShell Verbinding Testen

### Doel
Leer hoe je een verbinding maakt met Microsoft Graph via PowerShell en basis informatie ophaalt.

### Stappen

1. **PowerShell Script Maken**
   ```powershell
   # Maak een nieuw script bestand
   New-Item -Path "C:\Temp\Test-GraphConnection.ps1" -ItemType File
   ```

2. **Script Inhoud**
   ```powershell
   # Test script voor Microsoft Graph verbinding
   try {
       # Verbinding maken
       Write-Host "Verbinding maken met Microsoft Graph..."
       Connect-MgGraph -Scopes "User.Read", "Group.Read.All"
       
       # Context ophalen
       $context = Get-MgContext
       Write-Host "`nVerbinding succesvol!"
       Write-Host "Tenant ID: $($context.TenantId)"
       Write-Host "Client ID: $($context.ClientId)"
       
       # Test gebruiker ophalen
       Write-Host "`nTest gebruiker ophalen..."
       $me = Get-MgUser -UserId "me"
       Write-Host "Naam: $($me.DisplayName)"
       Write-Host "Email: $($me.UserPrincipalName)"
       
       # Test groep ophalen
       Write-Host "`nTest groep ophalen..."
       $groups = Get-MgGroup -Top 5
       Write-Host "`nEerste 5 groepen:"
       foreach ($group in $groups) {
           Write-Host "- $($group.DisplayName)"
       }
   }
   catch {
       Write-Host "Er is een fout opgetreden: $_"
   }
   finally {
       # Verbinding sluiten
       Write-Host "`nVerbinding sluiten..."
       Disconnect-MgGraph
   }
   ```

3. **Script Uitvoeren**
   ```powershell
   # Script uitvoeren
   .\Test-GraphConnection.ps1
   ```

### Verificatie
Controleer of:
- Het script zonder fouten uitvoert
- Je gebruikersinformatie ziet
- Je een lijst van groepen ziet
- De verbinding netjes wordt afgesloten

## Oefening 3: Gebruikers Rapport Generator

### Doel
Maak een script dat een CSV rapport genereert met gebruikersinformatie.

### Stappen

1. **Script Maken**
   ```powershell
   # Maak een nieuw script bestand
   New-Item -Path "C:\Temp\Get-UserReport.ps1" -ItemType File
   ```

2. **Script Inhoud**
   ```powershell
   # Gebruikers rapport generator
   function Get-UserReport {
       param (
           [string]$OutputPath = "C:\Temp\GebruikersRapport.csv"
       )
       
       try {
           # Verbinding maken
           Write-Host "Verbinding maken met Microsoft Graph..."
           Connect-MgGraph -Scopes "User.Read"
           
           # Gebruikers ophalen
           Write-Host "Gebruikers ophalen..."
           $users = Get-MgUser -All
           
           # Rapport maken
           Write-Host "Rapport genereren..."
           $report = @()
           foreach ($user in $users) {
               $report += [PSCustomObject]@{
                   Naam = $user.DisplayName
                   Email = $user.UserPrincipalName
                   Afdeling = $user.Department
                   Functie = $user.JobTitle
                   LaatsteLogin = $user.SignInActivity.LastSignInDateTime
                   AccountStatus = if ($user.AccountEnabled) { "Actief" } else { "Inactief" }
                   MFAStatus = if ($user.StrongAuthenticationMethods.Count -gt 0) { "Ingeschakeld" } else { "Uitgeschakeld" }
               }
           }
           
           # Rapport exporteren
           Write-Host "Rapport exporteren naar $OutputPath..."
           $report | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
           
           Write-Host "`nRapport succesvol gegenereerd!"
           Write-Host "Aantal gebruikers: $($report.Count)"
       }
       catch {
           Write-Host "Er is een fout opgetreden: $_"
       }
       finally {
           # Verbinding sluiten
           Write-Host "`nVerbinding sluiten..."
           Disconnect-MgGraph
       }
   }
   
   # Script uitvoeren
   Get-UserReport
   ```

3. **Script Uitvoeren**
   ```powershell
   # Script uitvoeren
   .\Get-UserReport.ps1
   ```

### Verificatie
Controleer of:
- Het rapport wordt gegenereerd
- Alle gebruikersinformatie correct is
- Het CSV bestand kan worden geopend in Excel
- De data goed is geformatteerd

## Bonus Oefening: Groep Beheer Script

### Doel
Maak een script dat groepen en hun leden beheert.

### Stappen

1. **Script Maken**
   ```powershell
   # Maak een nieuw script bestand
   New-Item -Path "C:\Temp\Manage-Groups.ps1" -ItemType File
   ```

2. **Script Inhoud**
   ```powershell
   # Groep beheer script
   function Get-GroupInfo {
       param (
           [string]$GroupName
       )
       
       try {
           # Verbinding maken
           Write-Host "Verbinding maken met Microsoft Graph..."
           Connect-MgGraph -Scopes "Group.Read.All"
           
           # Groep zoeken
           Write-Host "`nZoeken naar groep: $GroupName"
           $group = Get-MgGroup -Filter "displayName eq '$GroupName'"
           
           if ($group) {
               Write-Host "`nGroep gevonden!"
               Write-Host "Naam: $($group.DisplayName)"
               Write-Host "ID: $($group.Id)"
               Write-Host "Type: $($group.GroupTypes -join ', ')"
               
               # Leden ophalen
               Write-Host "`nLeden ophalen..."
               $members = Get-MgGroupMember -GroupId $group.Id
               
               Write-Host "`nLeden van de groep:"
               foreach ($member in $members) {
                   Write-Host "- $($member.DisplayName) ($($member.UserPrincipalName))"
               }
               
               # Statistieken
               Write-Host "`nStatistieken:"
               Write-Host "Totaal aantal leden: $($members.Count)"
           }
           else {
               Write-Host "Groep niet gevonden!"
           }
       }
       catch {
           Write-Host "Er is een fout opgetreden: $_"
       }
       finally {
           # Verbinding sluiten
           Write-Host "`nVerbinding sluiten..."
           Disconnect-MgGraph
       }
   }
   
   # Script uitvoeren
   $groupName = Read-Host "Voer de naam van de groep in"
   Get-GroupInfo -GroupName $groupName
   ```

3. **Script Uitvoeren**
   ```powershell
   # Script uitvoeren
   .\Manage-Groups.ps1
   ```

### Verificatie
Controleer of:
- Het script de juiste groep vindt
- Alle groepsleden worden weergegeven
- De statistieken correct zijn
- De verbinding netjes wordt afgesloten

## Volgende Stap

Nu je deze praktische oefeningen hebt voltooid, heb je een goede basis voor het werken met Microsoft Graph via PowerShell. Je kunt doorgaan naar [Module 2: PowerShell Fundamentals](../02_powershell/README.md) om je PowerShell kennis verder uit te breiden. 