# Praktische Oefeningen

In deze les gaan we alle geleerde concepten in de praktijk toepassen door een robuuste applicatie te bouwen die gebruik maakt van de Microsoft Graph API met moderne integratiepatronen.

## Oefening 1: Moderne Integratie Architectuur

### Doel
Ontwikkel een applicatie die gebruik maakt van microservices, serverless functions, en event-driven architectuur met de Microsoft Graph API.

### Stappen

1. Maak een nieuwe project directory:
```bash
mkdir modern-graph-app
cd modern-graph-app
```

2. Initialiseer het Python project:
```bash
python -m venv venv
source venv/bin/activate  # Op Windows: venv\Scripts\activate
pip install msgraph-core azure-identity python-dotenv azure-functions azure-eventhub azure-servicebus
```

3. Maak een `.env` bestand:
```env
AZURE_TENANT_ID=your_tenant_id
AZURE_CLIENT_ID=your_client_id
AZURE_CLIENT_SECRET=your_client_secret
AZURE_SUBSCRIPTION_ID=your_subscription_id
AZURE_RESOURCE_GROUP=your_resource_group
```

4. Implementeer de basis structuur:

```python
# config.py
from dotenv import load_dotenv
import os

load_dotenv()

class Config:
    TENANT_ID = os.getenv('AZURE_TENANT_ID')
    CLIENT_ID = os.getenv('AZURE_CLIENT_ID')
    CLIENT_SECRET = os.getenv('AZURE_CLIENT_SECRET')
    SUBSCRIPTION_ID = os.getenv('AZURE_SUBSCRIPTION_ID')
    RESOURCE_GROUP = os.getenv('AZURE_RESOURCE_GROUP')
```

```python
# services/graph_service.py
from msgraph.core import GraphClient
from azure.identity import ClientSecretCredential
from config import Config

class GraphService:
    def __init__(self):
        self.credential = ClientSecretCredential(
            tenant_id=Config.TENANT_ID,
            client_id=Config.CLIENT_ID,
            client_secret=Config.CLIENT_SECRET
        )
        self.client = GraphClient(credential=self.credential)

    async def get_user_info(self, user_id):
        """Haalt gebruikersinformatie op."""
        try:
            response = await self.client.get(f'/users/{user_id}')
            return response.json()
        except Exception as e:
            print(f"Error getting user info: {e}")
            return None
```

```python
# services/event_service.py
from azure.eventhub import EventHubProducerClient
from azure.eventhub import EventData
from config import Config

class EventService:
    def __init__(self):
        self.client = EventHubProducerClient.from_connection_string(
            Config.EVENT_HUB_CONNECTION_STRING
        )

    async def publish_event(self, event_type, payload):
        """Publiceert een event."""
        try:
            event_data = EventData(
                body=str(payload).encode('utf-8'),
                properties={'type': event_type}
            )
            
            async with self.client as producer:
                await producer.send_batch([event_data])
            
            return True
        except Exception as e:
            print(f"Error publishing event: {e}")
            return False
```

```python
# functions/user_sync.py
import azure.functions as func
from services.graph_service import GraphService
from services.event_service import EventService

async def main(req: func.HttpRequest) -> func.HttpResponse:
    try:
        # Initialiseer services
        graph_service = GraphService()
        event_service = EventService()

        # Haal gebruikers op
        users = await graph_service.get_users()

        # Publiceer events voor elke gebruiker
        for user in users:
            await event_service.publish_event(
                'user_sync',
                user
            )

        return func.HttpResponse(
            "User sync completed successfully",
            status_code=200
        )
    except Exception as e:
        return func.HttpResponse(
            f"Error: {str(e)}",
            status_code=500
        )
```

## Oefening 2: AI-Powered Email Analysis

### Doel
Implementeer een AI-powered email analyse systeem dat gebruik maakt van Azure Cognitive Services en de Microsoft Graph API.

### Stappen

1. Installeer extra dependencies:
```bash
pip install azure-cognitiveservices-language-textanalytics azure-storage-blob
```

2. Implementeer de email analyse service:

```python
# services/email_analyzer.py
from azure.cognitiveservices.language.textanalytics import TextAnalyticsClient
from msrest.authentication import CognitiveServicesCredentials
from config import Config

class EmailAnalyzer:
    def __init__(self):
        self.client = TextAnalyticsClient(
            endpoint=Config.COGNITIVE_SERVICES_ENDPOINT,
            credentials=CognitiveServicesCredentials(
                Config.COGNITIVE_SERVICES_KEY
            )
        )

    async def analyze_email(self, email_content):
        """Analyseert de inhoud van een email."""
        try:
            # Analyseer sentiment
            sentiment = await self.client.sentiment(
                documents=[email_content]
            )

            # Extraheer entiteiten
            entities = await self.client.entities(
                documents=[email_content]
            )

            # Detecteer key phrases
            key_phrases = await self.client.key_phrases(
                documents=[email_content]
            )

            return {
                'sentiment': sentiment,
                'entities': entities,
                'key_phrases': key_phrases
            }
        except Exception as e:
            print(f"Error analyzing email: {e}")
            return None
```

```python
# functions/email_analysis.py
import azure.functions as func
from services.graph_service import GraphService
from services.email_analyzer import EmailAnalyzer

async def main(req: func.HttpRequest) -> func.HttpResponse:
    try:
        # Initialiseer services
        graph_service = GraphService()
        email_analyzer = EmailAnalyzer()

        # Haal emails op
        emails = await graph_service.get_emails()

        # Analyseer elke email
        for email in emails:
            analysis = await email_analyzer.analyze_email(
                email['body']['content']
            )

            # Sla analyse op
            await graph_service.save_email_analysis(
                email['id'],
                analysis
            )

        return func.HttpResponse(
            "Email analysis completed successfully",
            status_code=200
        )
    except Exception as e:
        return func.HttpResponse(
            f"Error: {str(e)}",
            status_code=500
        )
```

## Oefening 3: Real-time Activity Monitoring

### Doel
Implementeer een real-time activiteit monitoring systeem met SignalR en de Microsoft Graph API.

### Stappen

1. Installeer extra dependencies:
```bash
pip install azure-signalr azure-functions-signalr
```

2. Implementeer de monitoring service:

```python
# services/activity_monitor.py
from azure.signalr import SignalRServiceClient
from config import Config

class ActivityMonitor:
    def __init__(self):
        self.client = SignalRServiceClient(
            connection_string=Config.SIGNALR_CONNECTION_STRING
        )

    async def broadcast_activity(self, activity):
        """Broadcast activiteit naar alle verbonden clients."""
        try:
            await self.client.send_to_all(
                'activity',
                activity
            )
            return True
        except Exception as e:
            print(f"Error broadcasting activity: {e}")
            return False

    async def send_to_user(self, user_id, activity):
        """Stuurt activiteit naar een specifieke gebruiker."""
        try:
            await self.client.send_to_user(
                user_id,
                'activity',
                activity
            )
            return True
        except Exception as e:
            print(f"Error sending to user: {e}")
            return False
```

```python
# functions/activity_monitor.py
import azure.functions as func
from services.graph_service import GraphService
from services.activity_monitor import ActivityMonitor

async def main(req: func.HttpRequest) -> func.HttpResponse:
    try:
        # Initialiseer services
        graph_service = GraphService()
        activity_monitor = ActivityMonitor()

        # Haal activiteiten op
        activities = await graph_service.get_activities()

        # Monitor en broadcast activiteiten
        for activity in activities:
            await activity_monitor.broadcast_activity(activity)

        return func.HttpResponse(
            "Activity monitoring completed successfully",
            status_code=200
        )
    except Exception as e:
        return func.HttpResponse(
            f"Error: {str(e)}",
            status_code=500
        )
```

## Implementatie Tips

1. **Error Handling**
   - Implementeer robuuste error handling
   - Log errors adequaat
   - Implementeer retry mechanismen

2. **Performance**
   - Gebruik caching waar mogelijk
   - Implementeer batch processing
   - Monitor performance metrics

3. **Security**
   - Implementeer de juiste authenticatie
   - Gebruik de juiste permissions
   - Volg security best practices

4. **Testing**
   - Schrijf unit tests
   - Implementeer integration tests
   - Test error scenarios

## Volgende Stap

Na het voltooien van deze oefeningen heb je een goed begrip van hoe je moderne integratiepatronen kunt implementeren met de Microsoft Graph API. Je bent nu klaar om je eigen innovatieve applicaties te bouwen die gebruik maken van de nieuwste features en technologieën. 