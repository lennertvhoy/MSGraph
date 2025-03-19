# Setup script voor PowerShell omgeving
# Dit script installeert alle benodigde modules en configureert de PowerShell omgeving

# Controleer of we administratieve rechten hebben
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warning "Dit script heeft administratieve rechten nodig. Start PowerShell als administrator en voer het script opnieuw uit."
    exit
}

# Functie om te controleren of een module is geïnstalleerd
function Test-ModuleInstalled {
    param (
        [string]$ModuleName
    )
    return (Get-Module -ListAvailable -Name $ModuleName) -ne $null
}

# Functie om een module te installeren
function Install-RequiredModule {
    param (
        [string]$ModuleName,
        [string]$Version = "Latest"
    )
    if (-not (Test-ModuleInstalled -ModuleName $ModuleName)) {
        Write-Host "Installeer module: $ModuleName"
        Install-Module -Name $ModuleName -Force -AllowClobber -Scope CurrentUser
    } else {
        Write-Host "Module $ModuleName is al geïnstalleerd"
    }
}

# Installeer benodigde modules
$requiredModules = @(
    "Microsoft.Graph",
    "Microsoft.Graph.Intune",
    "AzureAD",
    "MSAL.PS",
    "PSFzf",
    "Terminal-Icons"
)

foreach ($module in $requiredModules) {
    Install-RequiredModule -ModuleName $module
}

# Configureer PowerShell profiel
$profilePath = $PROFILE.CurrentUserCurrentHost
if (-not (Test-Path $profilePath)) {
    New-Item -ItemType File -Path $profilePath -Force
}

# Voeg nuttige aliases en functies toe aan het profiel
$profileContent = @"
# Microsoft Graph API Cursus - PowerShell Profiel
# Laatst bijgewerkt: $(Get-Date)

# Importeer modules
Import-Module Microsoft.Graph
Import-Module Microsoft.Graph.Intune
Import-Module AzureAD
Import-Module MSAL.PS
Import-Module PSFzf
Import-Module Terminal-Icons

# Configureer PSFzf
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t'
Set-PsFzfOption -PSReadlineChordReverseHistory 'Ctrl+r'

# Handige aliases
Set-Alias -Name gconnect -Value Connect-MgGraph
Set-Alias -Name gdisconnect -Value Disconnect-MgGraph
Set-Alias -Name gget -Value Get-MgGraph
Set-Alias -Name gset -Value Set-MgGraph

# Functie om snel te connecteren met Microsoft Graph
function Connect-GraphAPI {
    param (
        [string[]]$Scopes = @("User.Read", "Group.Read.All")
    )
    Connect-MgGraph -Scopes $Scopes
}

# Functie om snel gebruikersinformatie op te halen
function Get-GraphUserInfo {
    param (
        [string]$UserPrincipalName
    )
    Get-MgUser -UserId $UserPrincipalName
}

# Functie om groepen op te halen
function Get-GraphGroups {
    Get-MgGroup -All
}

Write-Host "PowerShell omgeving is geconfigureerd voor Microsoft Graph API cursus"
"@

# Voeg de content toe aan het profiel
$profileContent | Out-File -FilePath $profilePath -Encoding UTF8

# Maak een directory voor de cursus
$courseDir = Join-Path $HOME "MSGraphCourse"
if (-not (Test-Path $courseDir)) {
    New-Item -ItemType Directory -Path $courseDir
}

Write-Host "`nSetup voltooid! Start PowerShell opnieuw om de wijzigingen toe te passen."
Write-Host "Je kunt nu beginnen met de Microsoft Graph API cursus."
Write-Host "Gebruik de volgende commando's om te starten:"
Write-Host "1. Connect-GraphAPI - om te verbinden met Microsoft Graph"
Write-Host "2. Get-GraphUserInfo - om gebruikersinformatie op te halen"
Write-Host "3. Get-GraphGroups - om groepen op te halen" 