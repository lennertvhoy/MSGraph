# Module 1: Introductie tot Microsoft Graph

Welkom bij Module 1 van de Microsoft Graph API cursus! In deze module gaan we de basis leren van Microsoft Graph en hoe je ermee kunt werken als systeembeheerder.

## Module Inhoud

1. [Wat is Microsoft Graph?](01_01_wat_is_graph.md)
   - Definitie en doel
   - Belangrijke concepten
   - Voordelen voor systeembeheerders

2. [Authenticatie en Autorisatie](01_02_authenticatie.md)
   - Azure AD basis
   - App registratie
   - Permissions en scopes
   - OAuth 2.0 flow

3. [Eerste Stappen met PowerShell](01_03_powershell_basics.md)
   - PowerShell installatie
   - Microsoft.Graph module
   - Basis commando's
   - Eerste verbinding maken

4. [Praktische Oefeningen](01_04_praktische_oefeningen.md)
   - Oefening 1: App registratie maken
   - Oefening 2: PowerShell verbinding testen
   - Oefening 3: Basis gebruikersinformatie ophalen

## Leerdoelen

Na het voltooien van deze module kun je:
- Uitleggen wat Microsoft Graph is en waarom het belangrijk is
- Een app registratie maken in Azure AD
- Verbinding maken met Microsoft Graph via PowerShell
- Basis gebruikersinformatie ophalen via de API

## Benodigde Materialen

- Azure AD tenant (gratis developer account is voldoende)
- PowerShell 7.0 of hoger
- Visual Studio Code (aanbevolen)

## Voorbereiding

1. Voer de setup scripts uit uit de `setup` directory:
   ```powershell
   .\setup\setup_powershell.ps1
   ```

2. Maak een Azure AD developer account aan als je die nog niet hebt:
   - Ga naar [portal.azure.com](https://portal.azure.com)
   - Maak een gratis account aan
   - Maak een nieuwe tenant aan

## Flashcards

Je vindt de flashcards voor deze module in:
- [Module 1 Flashcards](flashcards/module_01.txt)

Deze kunnen worden geïmporteerd in Anki voor het leren van de belangrijkste concepten.

## Zelftest

Na het voltooien van deze module kun je je kennis testen met de [zelftest](zelftest/module_01.md).

## Volgende Module

Na het voltooien van deze module ga je verder met [Module 2: PowerShell Fundamentals](../02_powershell/README.md). 