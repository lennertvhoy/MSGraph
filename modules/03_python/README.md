# Module 3: Python voor Systeembeheerders

Welkom bij Module 3 van de Microsoft Graph API cursus! In deze module gaan we Python leren, een krachtige en veelzijdige programmeertaal die perfect is voor systeembeheerders. We focussen op praktische toepassingen en het werken met Microsoft Graph API.

## Module Inhoud

1. [Python Basis Concepten](03_01_basis_concepten.md)
   - Variabelen en datatypes
   - Lists, dictionaries en sets
   - Control flow
   - Functions en modules

2. [Python en Microsoft Graph](03_02_graph_basics.md)
   - Microsoft Graph SDK installatie
   - Authenticatie en autorisatie
   - Basis API calls
   - Error handling

3. [Geavanceerde Python Concepten](03_03_advanced_concepts.md)
   - Object-oriented programming
   - Decorators en generators
   - Asynchrone programmering
   - Best practices

4. [Data Verwerking en I/O](03_04_data_io.md)
   - Bestanden lezen en schrijven
   - CSV en JSON verwerking
   - Logging
   - Configuratie beheer

5. [Praktische Oefeningen](03_05_praktische_oefeningen.md)
   - Oefening 1: Basis Python scripts
   - Oefening 2: Microsoft Graph integratie
   - Oefening 3: Data verwerking
   - Bonus oefening: Asynchrone applicatie

## Leerdoelen

Na het voltooien van deze module kun je:
- Python scripts schrijven met variabelen en datatypes
- Werken met de Microsoft Graph API in Python
- Geavanceerde Python concepten toepassen
- Data verwerken en I/O operaties uitvoeren
- Asynchrone applicaties ontwikkelen

## Benodigde Materialen

- Python 3.8 of hoger
- Visual Studio Code met Python extensie
- Een teksteditor voor het maken van scripts
- Microsoft Graph SDK voor Python

## Voorbereiding

1. Controleer of Python is geïnstalleerd:
   ```bash
   python --version
   ```

2. Installeer de Python extensie in VS Code:
   - Open VS Code
   - Ga naar Extensions (Ctrl+Shift+X)
   - Zoek naar "Python"
   - Installeer de officiële Python extensie

3. Maak een virtuele omgeving aan:
   ```bash
   python -m venv venv
   source venv/bin/activate  # Linux/Mac
   .\venv\Scripts\activate   # Windows
   ```

4. Installeer benodigde packages:
   ```bash
   pip install msgraph-sdk azure-identity
   ```

5. Maak een werkmap aan voor de oefeningen:
   ```bash
   mkdir ~/PythonGraphCourse
   ```

## Flashcards

Je vindt de flashcards voor deze module in:
- [Module 3 Flashcards](flashcards/module_03.txt)

Deze kunnen worden geïmporteerd in Anki voor het leren van de belangrijkste concepten.

## Zelftest

Na het voltooien van deze module kun je je kennis testen met de [zelftest](zelftest/module_03.md).

## Volgende Module

Na het voltooien van deze module ga je verder met [Module 4: Microsoft Graph API Basis](../04_graph_basics/README.md). 