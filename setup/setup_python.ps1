# Setup script voor Python omgeving
# Dit script installeert Python en configureert de ontwikkelomgeving

# Controleer of we administratieve rechten hebben
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warning "Dit script heeft administratieve rechten nodig. Start PowerShell als administrator en voer het script opnieuw uit."
    exit
}

# Controleer of Python is geïnstalleerd
$pythonVersion = python --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Python is niet geïnstalleerd. Installeer Python 3.8 of hoger van https://www.python.org/downloads/"
    Write-Host "Zorg ervoor dat je de optie 'Add Python to PATH' aanvinkt tijdens de installatie."
    exit
}

# Controleer of pip is geïnstalleerd
$pipVersion = pip --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "pip is niet geïnstalleerd. Installeer pip via https://pip.pypa.io/en/stable/installation/"
    exit
}

# Maak een virtuele omgeving aan
$venvPath = Join-Path $HOME "MSGraphCourse\venv"
if (-not (Test-Path $venvPath)) {
    Write-Host "Maak virtuele omgeving aan..."
    python -m venv $venvPath
}

# Activeer de virtuele omgeving
Write-Host "Activeer virtuele omgeving..."
& "$venvPath\Scripts\Activate.ps1"

# Installeer benodigde packages
$requirements = @"
msal>=1.20.0
msgraph-core>=0.2.2
msgraph-sdk>=1.0.0
azure-identity>=1.12.0
pandas>=1.5.0
requests>=2.28.0
python-dotenv>=0.19.0
jupyter>=1.0.0
black>=22.0.0
pylint>=2.15.0
pytest>=7.0.0
"@

# Schrijf requirements naar bestand
$requirementsPath = Join-Path $HOME "MSGraphCourse\requirements.txt"
$requirements | Out-File -FilePath $requirementsPath -Encoding UTF8

# Installeer packages
Write-Host "Installeer Python packages..."
pip install -r $requirementsPath

# Maak een voorbeeld .env bestand aan
$envContent = @"
# Microsoft Graph API Configuratie
TENANT_ID=your_tenant_id
CLIENT_ID=your_client_id
CLIENT_SECRET=your_client_secret

# API Permissions
SCOPES="User.Read Group.Read.All"
"@

$envPath = Join-Path $HOME "MSGraphCourse\.env"
if (-not (Test-Path $envPath)) {
    $envContent | Out-File -FilePath $envPath -Encoding UTF8
}

# Maak een basis projectstructuur aan
$projectDirs = @(
    "src",
    "src\graph",
    "src\utils",
    "tests",
    "notebooks",
    "examples"
)

foreach ($dir in $projectDirs) {
    $fullPath = Join-Path $HOME "MSGraphCourse\$dir"
    if (-not (Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force
    }
}

# Maak een voorbeeld script aan
$exampleScript = @"
# Voorbeeld script voor Microsoft Graph API
from msgraph.core import GraphClient
from azure.identity import ClientSecretCredential
import os
from dotenv import load_dotenv

# Laad omgevingsvariabelen
load_dotenv()

def get_graph_client():
    """Maak een Graph client aan met de juiste credentials."""
    tenant_id = os.getenv('TENANT_ID')
    client_id = os.getenv('CLIENT_ID')
    client_secret = os.getenv('CLIENT_SECRET')
    
    # Maak credentials aan
    credentials = ClientSecretCredential(
        tenant_id=tenant_id,
        client_id=client_id,
        client_secret=client_secret
    )
    
    # Maak Graph client aan
    return GraphClient(credentials=credentials)

def get_user_info(user_id):
    """Haal gebruikersinformatie op via Microsoft Graph."""
    client = get_graph_client()
    response = client.get(f'/users/{user_id}')
    return response.json()

if __name__ == "__main__":
    # Voorbeeld gebruik
    try:
        user_info = get_user_info("me")
        print("Gebruikersinformatie:", user_info)
    except Exception as e:
        print(f"Fout bij ophalen gebruikersinformatie: {e}")
"@

$exampleScriptPath = Join-Path $HOME "MSGraphCourse\src\graph\example.py"
$exampleScript | Out-File -FilePath $exampleScriptPath -Encoding UTF8

Write-Host "`nSetup voltooid! Je Python omgeving is nu klaar voor de Microsoft Graph API cursus."
Write-Host "`nVolgende stappen:"
Write-Host "1. Vul je Azure AD credentials in in het .env bestand"
Write-Host "2. Activeer de virtuele omgeving met: .\venv\Scripts\Activate.ps1"
Write-Host "3. Start met het voorbeeld script in src/graph/example.py"
Write-Host "`nTip: Gebruik 'deactivate' om de virtuele omgeving te verlaten wanneer je klaar bent." 