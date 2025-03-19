# Praktische Oefeningen

In deze les ga je de opgedane kennis over de Microsoft Graph API in de praktijk toepassen. We behandelen verschillende scenario's die je als systeembeheerder tegen kunt komen.

## Oefening 1: Gebruikersbeheer

### Doel
Ontwikkel een script dat gebruikers beheert via de Microsoft Graph API, inclusief het ophalen van gebruikers, het filteren op basis van criteria en het bijwerken van gebruikersgegevens.

### Stappen
1. Maak een nieuw Python-bestand `user_management.py`
2. Implementeer de volgende functionaliteit:
   - Ophalen van alle gebruikers
   - Filteren op afdeling
   - Gebruikersgegevens bijwerken
   - Batch operaties voor meerdere gebruikers

### Code Voorbeeld

```python
from msgraph import GraphServiceClient
from azure.identity import ClientSecretCredential
import asyncio

class UserManagement:
    def __init__(self, client_id: str, client_secret: str, tenant_id: str):
        self.credential = ClientSecretCredential(
            tenant_id=tenant_id,
            client_id=client_id,
            client_secret=client_secret
        )
        self.graph_client = GraphServiceClient(credentials=self.credential)

    async def get_all_users(self):
        users = await self.graph_client.users.get()
        return users.value

    async def get_users_by_department(self, department: str):
        users = await self.graph_client.users.get()
        return [user for user in users.value if user.department == department]

    async def update_user(self, user_id: str, updates: dict):
        user = await self.graph_client.users.by_user_id(user_id).patch(updates)
        return user

    async def batch_update_users(self, user_updates: List[dict]):
        requests = []
        for update in user_updates:
            requests.append({
                "id": update['id'],
                "method": "PATCH",
                "url": f"/users/{update['id']}",
                "body": update['changes']
            })
        
        batch = {"requests": requests}
        response = await self.graph_client.batch.post(batch)
        return response
```

### Verificatie
1. Test het script met verschillende afdelingen
2. Controleer of de updates correct worden toegepast
3. Verifieer de batch operaties werken

## Oefening 2: Email Beheer

### Doel
Ontwikkel een script dat emails beheert via de Microsoft Graph API, inclusief het ophalen van emails, het filteren op basis van criteria en het versturen van emails.

### Stappen
1. Maak een nieuw Python-bestand `email_management.py`
2. Implementeer de volgende functionaliteit:
   - Ophalen van emails
   - Filteren op onderwerp en afzender
   - Email versturen
   - Batch email operaties

### Code Voorbeeld

```python
class EmailManagement:
    def __init__(self, graph_client: GraphServiceClient):
        self.graph_client = graph_client

    async def get_user_emails(self, user_id: str):
        messages = await self.graph_client.users.by_user_id(user_id).messages.get()
        return messages.value

    async def filter_emails(self, user_id: str, subject: str = None, sender: str = None):
        messages = await self.graph_client.users.by_user_id(user_id).messages.get()
        filtered_messages = messages.value
        
        if subject:
            filtered_messages = [msg for msg in filtered_messages if subject.lower() in msg.subject.lower()]
        
        if sender:
            filtered_messages = [msg for msg in filtered_messages if sender.lower() in msg.from_.email_address.address.lower()]
        
        return filtered_messages

    async def send_email(self, user_id: str, to_recipients: List[str], subject: str, body: str):
        message = {
            "message": {
                "subject": subject,
                "body": {
                    "contentType": "HTML",
                    "content": body
                },
                "toRecipients": [
                    {"emailAddress": {"address": recipient}}
                    for recipient in to_recipients
                ]
            }
        }
        
        await self.graph_client.users.by_user_id(user_id).send_mail.post(message)
```

### Verificatie
1. Test het ophalen van emails met verschillende filters
2. Verifieer het versturen van emails
3. Controleer de batch operaties

## Oefening 3: Bestandsbeheer

### Doel
Ontwikkel een script dat bestanden beheert via de Microsoft Graph API, inclusief het ophalen van bestanden, het uploaden van nieuwe bestanden en het delen van bestanden.

### Stappen
1. Maak een nieuw Python-bestand `file_management.py`
2. Implementeer de volgende functionaliteit:
   - Ophalen van bestanden
   - Uploaden van bestanden
   - Delen van bestanden
   - Delta queries voor wijzigingen

### Code Voorbeeld

```python
class FileManagement:
    def __init__(self, graph_client: GraphServiceClient):
        self.graph_client = graph_client

    async def get_user_files(self, user_id: str):
        drive = await self.graph_client.users.by_user_id(user_id).drive.get()
        items = await self.graph_client.users.by_user_id(user_id).drive.root.children.get()
        return items.value

    async def upload_file(self, user_id: str, file_path: str, file_name: str):
        with open(file_path, 'rb') as file:
            file_content = file.read()
            
        await self.graph_client.users.by_user_id(user_id).drive.root.item_with_path(file_name).put(file_content)
        return await self.graph_client.users.by_user_id(user_id).drive.root.item_with_path(file_name).get()

    async def share_file(self, user_id: str, file_id: str, share_with: str):
        permission = {
            "requireSignIn": True,
            "sendInvitation": True,
            "roles": ["read"],
            "grantedToIdentities": [
                {
                    "user": {
                        "email": share_with
                    }
                }
            ]
        }
        
        await self.graph_client.users.by_user_id(user_id).drive.items.by_drive_item_id(file_id).create_link.post(permission)
```

### Verificatie
1. Test het ophalen van bestanden
2. Verifieer het uploaden van nieuwe bestanden
3. Controleer het delen van bestanden

## Bonus Oefening: Change Notifications

### Doel
Implementeer een systeem dat automatisch notificaties ontvangt wanneer er wijzigingen zijn in Microsoft 365 resources.

### Stappen
1. Maak een nieuw Python-bestand `change_notifications.py`
2. Implementeer de volgende functionaliteit:
   - Aanmaken van subscriptions
   - Verwerken van notificaties
   - Automatisch vernieuwen van subscriptions

### Code Voorbeeld

```python
class ChangeNotificationSystem:
    def __init__(self, graph_client: GraphServiceClient):
        self.graph_client = graph_client
        self.subscriptions = {}

    async def create_subscription(self, resource: str, webhook_url: str, expiration: datetime):
        subscription = {
            "changeType": "created,updated,deleted",
            "notificationUrl": webhook_url,
            "resource": resource,
            "expirationDateTime": expiration.isoformat()
        }
        
        response = await self.graph_client.subscriptions.post(subscription)
        self.subscriptions[response.id] = response
        return response

    async def process_notification(self, notification_data: dict):
        # Verwerk de notificatie
        for notification in notification_data['value']:
            resource_type = notification['resource']
            change_type = notification['changeType']
            resource_id = notification['resourceData']['id']
            
            # Update lokale state
            await self._update_local_state(resource_type, resource_id, change_type)

    async def renew_subscriptions(self):
        for sub_id, subscription in self.subscriptions.items():
            if datetime.fromisoformat(subscription.expirationDateTime) < datetime.now():
                await self._renew_subscription(subscription)
```

### Verificatie
1. Test het aanmaken van subscriptions
2. Verifieer het ontvangen van notificaties
3. Controleer het automatisch vernieuwen van subscriptions

## Tips voor Implementatie

1. **Error Handling**
   - Implementeer uitgebreide error handling
   - Log alle fouten en waarschuwingen
   - Gebruik retry mechanismen voor tijdelijke fouten

2. **Performance**
   - Gebruik batch requests waar mogelijk
   - Implementeer caching voor veel gebruikte data
   - Beperk het aantal API calls

3. **Security**
   - Gebruik de juiste permissies
   - Implementeer rate limiting
   - Beveilig gevoelige data

4. **Testing**
   - Schrijf unit tests voor alle functionaliteit
   - Test edge cases
   - Verifieer error scenarios

## Volgende Stap

Na het voltooien van deze oefeningen heb je praktische ervaring opgedaan met het werken met de Microsoft Graph API. Je kunt nu overgaan naar [Module 5: Geavanceerde Integratie](05_advanced_integration/README.md) waar we dieper ingaan op het integreren van de Microsoft Graph API in bestaande systemen. 