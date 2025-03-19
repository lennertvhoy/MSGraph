# API Overzicht en Authenticatie

In deze les gaan we de basis van de Microsoft Graph API leren. We beginnen met een overzicht van de API architectuur en gaan daarna dieper in op authenticatie en autorisatie.

## Microsoft Graph API Architectuur

### Wat is Microsoft Graph?

Microsoft Graph is een unified API endpoint die toegang biedt tot Microsoft 365 services. Het biedt een consistente manier om te communiceren met:

- Microsoft 365 (Exchange, SharePoint, Teams)
- Enterprise Mobility + Security
- Windows 10/11
- Dynamics 365

### API Structuur

```
https://graph.microsoft.com/{version}/{resource}/{property}
```

Voorbeelden:
```
# Gebruikers ophalen
GET https://graph.microsoft.com/v1.0/users

# Specifieke gebruiker ophalen
GET https://graph.microsoft.com/v1.0/users/{user-id}

# Gebruikers email ophalen
GET https://graph.microsoft.com/v1.0/users/{user-id}/messages
```

### API Versies

1. **v1.0**
   - Productie-ready endpoints
   - Stabiele functionaliteit
   - Aanbevolen voor productie

2. **beta**
   - Nieuwe features
   - Experimentele functionaliteit
   - Kan wijzigen

## Authenticatie Methoden

### 1. Client Credentials Flow

```python
from azure.identity import ClientSecretCredential
from msgraph import GraphServiceClient

# Azure AD configuratie
tenant_id = "your-tenant-id"
client_id = "your-client-id"
client_secret = "your-client-secret"

# Credentials maken
credentials = ClientSecretCredential(
    tenant_id=tenant_id,
    client_id=client_id,
    client_secret=client_secret
)

# Graph client maken
graph_client = GraphServiceClient(credentials=credentials)
```

### 2. Authorization Code Flow

```python
from msal import ConfidentialClientApplication

# MSAL configuratie
config = {
    "client_id": "your-client-id",
    "client_secret": "your-client-secret",
    "authority": "https://login.microsoftonline.com/your-tenant-id"
}

# MSAL client maken
app = ConfidentialClientApplication(
    client_id=config["client_id"],
    client_credential=config["client_secret"],
    authority=config["authority"]
)

# Token ophalen
result = app.acquire_token_by_authorization_code(
    code="authorization-code",
    scopes=["https://graph.microsoft.com/.default"]
)
```

### 3. Device Code Flow

```python
from msal import PublicClientApplication

# MSAL configuratie
app = PublicClientApplication(
    client_id="your-client-id",
    authority="https://login.microsoftonline.com/your-tenant-id"
)

# Device code flow
flow = app.initiate_device_flow(scopes=["https://graph.microsoft.com/.default"])
print(f"Ga naar {flow['verification_uri']} en voer code {flow['user_code']} in")

# Token ophalen
result = app.acquire_token_by_device_flow(flow)
```

## Autorisatie en Permissies

### App Permissies

```json
{
    "permissions": [
        {
            "resourceAppId": "00000003-0000-0000-c000-000000000000",
            "resourceAccess": [
                {
                    "id": "e1fe6dd8-ba31-4d61-89e7-88639da4683d",
                    "type": "Scope"
                }
            ]
        }
    ]
}
```

### Delegated Permissies

```json
{
    "permissions": [
        {
            "resourceAppId": "00000003-0000-0000-c000-000000000000",
            "resourceAccess": [
                {
                    "id": "570282fd-fa5c-430d-a7fd-fc8dc98a9dca",
                    "type": "Scope"
                }
            ]
        }
    ]
}
```

### Permissie Scopes

```python
# Basis scopes
scopes = [
    "https://graph.microsoft.com/.default",
    "User.Read",
    "User.Read.All",
    "Mail.Read",
    "Mail.Send"
]

# Admin scopes
admin_scopes = [
    "https://graph.microsoft.com/.default",
    "Directory.Read.All",
    "Directory.ReadWrite.All",
    "User.Read.All",
    "User.ReadWrite.All"
]
```

## API Endpoints

### Basis Endpoints

```python
# Gebruikers
users = await graph_client.users.get()

# Groepen
groups = await graph_client.groups.get()

# Mail
messages = await graph_client.users.by_user_id(user_id).messages.get()

# Bestanden
files = await graph_client.users.by_user_id(user_id).drive.root.children.get()
```

### Beta Endpoints

```python
# Teams
teams = await graph_client.teams.get()

# Chat
chats = await graph_client.chats.get()

# Planner
plans = await graph_client.planner.plans.get()
```

## Best Practices

### 1. Token Management

```python
class TokenManager:
    def __init__(self, credentials):
        self.credentials = credentials
        self._token = None
        self._expires_at = None

    async def get_token(self):
        if not self._token or self._is_expired():
            self._token = await self.credentials.get_token()
            self._expires_at = time.time() + self._token.expires_in
        return self._token

    def _is_expired(self):
        return time.time() >= self._expires_at
```

### 2. Error Handling

```python
from msgraph.generated.models.o_data_errors.o_data_error import ODataError

async def safe_graph_call(func):
    try:
        return await func()
    except ODataError as e:
        if e.error.code == "Authorization_RequestDenied":
            print("Geen toegang tot deze resource")
        elif e.error.code == "Request_ResourceNotFound":
            print("Resource niet gevonden")
        else:
            print(f"Graph API Error: {e.error.message}")
        return None
    except Exception as e:
        print(f"Onverwachte fout: {str(e)}")
        return None
```

### 3. Rate Limiting

```python
from asyncio import sleep

class RateLimiter:
    def __init__(self, max_requests: int = 100, time_window: int = 60):
        self.max_requests = max_requests
        self.time_window = time_window
        self.requests = []

    async def wait_if_needed(self):
        now = time.time()
        self.requests = [req for req in self.requests if now - req < self.time_window]
        
        if len(self.requests) >= self.max_requests:
            wait_time = self.requests[0] + self.time_window - now
            await sleep(wait_time)
        
        self.requests.append(now)
```

## Volgende Stap

Nu je een goed begrip hebt van de Microsoft Graph API architectuur en authenticatie, gaan we in de volgende les kijken naar [basis API operaties](04_02_basic_operations.md). Daar leren we hoe we HTTP requests kunnen maken en responses kunnen verwerken. 