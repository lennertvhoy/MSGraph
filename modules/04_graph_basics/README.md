# Module 4: Microsoft Graph API Basis

Welkom bij Module 4 van de Microsoft Graph API cursus! In deze module gaan we dieper in op de Microsoft Graph API zelf. We leren hoe we de API effectief kunnen gebruiken voor het beheren van Microsoft 365 resources.

## Module Inhoud

1. [API Overzicht en Authenticatie](04_01_api_overview.md)
   - Microsoft Graph API architectuur
   - Authenticatie methoden
   - Autorisatie en permissies
   - API versies en endpoints

2. [Basis API Operaties](04_02_basic_operations.md)
   - HTTP methoden
   - Query parameters
   - Response handling
   - Error handling

3. [Resource Modellen](04_03_resource_models.md)
   - Gebruikers en groepen
   - Mail en kalender
   - Bestanden en SharePoint
   - Teams en chat

4. [Geavanceerde API Technieken](04_04_advanced_techniques.md)
   - Batch requests
   - Delta queries
   - Change notifications
   - Rate limiting

5. [Praktische Oefeningen](04_05_praktische_oefeningen.md)
   - Oefening 1: User Management
   - Oefening 2: Email Automation
   - Oefening 3: File Management
   - Bonus oefening: Teams Integration

## Leerdoelen

Na het voltooien van deze module kun je:
- De Microsoft Graph API architectuur begrijpen
- Authenticatie en autorisatie implementeren
- Basis API operaties uitvoeren
- Resource modellen gebruiken
- Geavanceerde API technieken toepassen

## Benodigde Materialen

- Azure AD tenant met Microsoft 365
- Azure AD app registratie
- PowerShell 7.0 of hoger
- Python 3.8 of hoger
- Visual Studio Code met relevante extensies

## Voorbereiding

1. **Azure AD Setup**
   - Maak een Azure AD tenant aan (indien nog niet aanwezig)
   - Registreer een nieuwe app in Azure AD
   - Configureer de benodigde API permissies
   - Genereer client credentials

2. **Ontwikkelomgeving**
   ```bash
   # Installeer benodigde PowerShell modules
   Install-Module Microsoft.Graph -Scope CurrentUser
   Install-Module AzureAD -Scope CurrentUser

   # Installeer Python packages
   pip install msgraph-sdk azure-identity
   ```

3. **Configuratie**
   - Maak een `config.json` bestand met je Azure AD credentials
   - Configureer logging en error handling
   - Test de basis connectiviteit

## Flashcards

Je vindt de flashcards voor deze module in:
- [Module 4 Flashcards](flashcards/module_04.txt)

Deze kunnen worden geïmporteerd in Anki voor het leren van de belangrijkste concepten.

## Zelftest

Na het voltooien van deze module kun je je kennis testen met de [zelftest](zelftest/module_04.md).

## Volgende Module

Na het voltooien van deze module ga je verder met [Module 5: Geavanceerde Microsoft Graph Toepassingen](../05_advanced_applications/README.md). 