# Python en Microsoft Graph

In deze les gaan we leren hoe we Python kunnen gebruiken om met de Microsoft Graph API te werken. We beginnen met de basis setup en bouwen dit op naar meer complexe scenario's.

## Microsoft Graph SDK Installatie

### Benodigde Packages

```bash
# Installeer de Microsoft Graph SDK en Azure Identity
pip install msgraph-sdk azure-identity
```

### Basis Imports

```python
from azure.identity import ClientSecretCredential
from msgraph import GraphServiceClient
from msgraph.generated.users.users_request_builder import UsersRequestBuilder
from msgraph.generated.models.user import User
```

## Authenticatie en Autorisatie

### Client Secret Credentials

```python
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

### Scopes en Permissies

```python
# Basis scopes voor Microsoft Graph
scopes = [
    "https://graph.microsoft.com/.default",
    "User.Read",
    "User.Read.All",
    "Group.Read.All"
]

# Credentials met scopes
credentials = ClientSecretCredential(
    tenant_id=tenant_id,
    client_id=client_id,
    client_secret=client_secret,
    scopes=scopes
)
```

## Basis API Calls

### Gebruikers Ophalen

```python
# Alle gebruikers ophalen
async def get_users():
    users = await graph_client.users.get()
    return users.value

# Specifieke gebruiker ophalen
async def get_user(user_id: str):
    user = await graph_client.users.by_user_id(user_id).get()
    return user

# Gebruikers filteren
async def get_active_users():
    users = await graph_client.users.get()
    return [user for user in users.value if user.account_enabled]
```

### Groepen Beheren

```python
# Alle groepen ophalen
async def get_groups():
    groups = await graph_client.groups.get()
    return groups.value

# Groepslidmaatschap beheren
async def add_user_to_group(user_id: str, group_id: str):
    await graph_client.groups.by_group_id(group_id).members.ref.post({
        "@odata.id": f"https://graph.microsoft.com/v1.0/users/{user_id}"
    })

async def remove_user_from_group(user_id: str, group_id: str):
    await graph_client.groups.by_group_id(group_id).members.by_directory_object_id(user_id).ref.delete()
```

### Email Verwerking

```python
# Emails ophalen
async def get_user_emails(user_id: str):
    messages = await graph_client.users.by_user_id(user_id).messages.get()
    return messages.value

# Email versturen
async def send_email(user_id: str, to_email: str, subject: str, body: str):
    message = {
        "message": {
            "subject": subject,
            "body": {
                "contentType": "HTML",
                "content": body
            },
            "toRecipients": [
                {
                    "emailAddress": {
                        "address": to_email
                    }
                }
            ]
        }
    }
    
    await graph_client.users.by_user_id(user_id).send_mail.post(message)
```

## Error Handling

### Graph API Errors

```python
from msgraph.generated.models.o_data_errors.o_data_error import ODataError

async def safe_graph_call(func):
    try:
        return await func()
    except ODataError as e:
        print(f"Graph API Error: {e.error.message}")
        return None
    except Exception as e:
        print(f"Unexpected error: {str(e)}")
        return None

# Gebruik
async def get_user_safe(user_id: str):
    return await safe_graph_call(lambda: get_user(user_id))
```

### Retry Logic

```python
from tenacity import retry, stop_after_attempt, wait_exponential

@retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=4, max=10))
async def get_user_with_retry(user_id: str):
    return await get_user(user_id)
```

## Best Practices

### Configuratie Beheer

```python
# config.py
from dataclasses import dataclass
from typing import List

@dataclass
class GraphConfig:
    tenant_id: str
    client_id: str
    client_secret: str
    scopes: List[str]

# config.json
{
    "tenant_id": "your-tenant-id",
    "client_id": "your-client-id",
    "client_secret": "your-client-secret",
    "scopes": [
        "https://graph.microsoft.com/.default",
        "User.Read",
        "User.Read.All"
    ]
}

# Configuratie laden
import json

def load_config(config_path: str) -> GraphConfig:
    with open(config_path) as f:
        config_data = json.load(f)
    return GraphConfig(**config_data)
```

### Logging

```python
import logging

# Logging setup
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Logging in functies
async def get_user_with_logging(user_id: str):
    logger.info(f"Fetching user: {user_id}")
    try:
        user = await get_user(user_id)
        logger.info(f"Successfully fetched user: {user_id}")
        return user
    except Exception as e:
        logger.error(f"Error fetching user {user_id}: {str(e)}")
        raise
```

### Rate Limiting

```python
from asyncio import sleep

async def rate_limited_call(func, delay: float = 1.0):
    result = await func()
    await sleep(delay)
    return result

# Gebruik
async def get_users_with_rate_limit():
    return await rate_limited_call(get_users)
```

## Volgende Stap

Nu je weet hoe je Python kunt gebruiken met de Microsoft Graph API, gaan we in de volgende les kijken naar [geavanceerde Python concepten](03_03_advanced_concepts.md). Daar leren we hoe we onze code nog krachtiger kunnen maken met object-oriented programming, decorators en asynchrone programmering. 