# Wat is Microsoft Graph?

Microsoft Graph is een krachtige API (Application Programming Interface) die je toegang geeft tot een enorme hoeveelheid Microsoft 365 data en functionaliteit. Als systeembeheerder kun je deze API gebruiken om je dagelijkse taken te automatiseren en efficiënter te maken.

## Wat is een API?

Een API is als een menu in een restaurant:
- Het menu (de API) vertelt je welke gerechten (functionaliteit) beschikbaar zijn
- Je bestelt via de ober (maakt een API call)
- De keuken (de server) bereidt je bestelling (verwerkt je verzoek)
- Je krijgt je gerecht (de response)

In het geval van Microsoft Graph:
- Het "menu" is de API documentatie
- Je "bestelling" is je code die een verzoek doet
- De "keuken" is Microsoft's servers
- Je "gerecht" is de data of functionaliteit die je krijgt

## Waarom Microsoft Graph?

Als systeembeheerder werk je waarschijnlijk veel met:
- Gebruikers beheren
- Groepen beheren
- Licenties toewijzen
- Rapporten genereren
- Beveiliging configureren

Microsoft Graph maakt het mogelijk om al deze taken te automatiseren. In plaats van handmatig door de Azure portal te klikken, kun je scripts schrijven die deze taken voor je doen.

## Belangrijke Concepten

### 1. Endpoints
Een endpoint is een specifieke URL waar je data kunt ophalen of wijzigen. Bijvoorbeeld:
- `/users` - voor gebruikersinformatie
- `/groups` - voor groepen
- `/devices` - voor apparaten

### 2. Permissions
Je hebt specifieke rechten nodig om bepaalde data te kunnen zien of wijzigen:
- `User.Read` - om gebruikersinformatie te lezen
- `Group.ReadWrite.All` - om groepen te beheren
- `Device.Read.All` - om apparaten te beheren

### 3. Authentication
Je moet jezelf identificeren voordat je de API kunt gebruiken:
- Via een app registratie in Azure AD
- Met een client ID en client secret
- Of via interactieve login

## Praktisch Voorbeeld

Stel je wilt een lijst van alle gebruikers ophalen. Zonder Microsoft Graph zou je dit handmatig moeten doen in de Azure portal. Met Microsoft Graph kun je dit automatiseren:

```powershell
# PowerShell voorbeeld
Connect-MgGraph
Get-MgUser -All
```

```python
# Python voorbeeld
from msgraph.core import GraphClient

def get_all_users():
    client = get_graph_client()
    response = client.get('/users')
    return response.json()
```

## Voordelen voor Systeembeheerders

1. **Automatisering**
   - Herhalende taken automatiseren
   - Minder handmatig werk
   - Minder fouten

2. **Efficiëntie**
   - Sneller werken
   - Grotere hoeveelheden data verwerken
   - Real-time updates

3. **Integratie**
   - Combineren met andere systemen
   - Custom dashboards maken
   - Automatische rapportage

4. **Beveiliging**
   - Gecontroleerde toegang
   - Audit logging
   - Compliance monitoring

## Volgende Stap

Nu je begrijpt wat Microsoft Graph is, gaan we in de volgende les kijken naar [authenticatie en autorisatie](01_02_authenticatie.md). Dit is een belangrijk onderdeel omdat je altijd eerst moet authenticeren voordat je de API kunt gebruiken. 