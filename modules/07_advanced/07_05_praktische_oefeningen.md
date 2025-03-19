# Praktische Oefeningen

In deze les gaan we de geavanceerde concepten die we hebben geleerd in de praktijk toepassen. We maken een enterprise-level applicatie die gebruik maakt van AI, real-time communicatie, edge computing en advanced security.

## Oefening 1: AI-Powered Email Analysis

### Doel
Ontwikkel een applicatie die gebruik maakt van Azure Cognitive Services om e-mails te analyseren en inzichten te genereren.

### Stappen

1. Maak een nieuwe project directory:
```bash
mkdir email_analyzer
cd email_analyzer
python -m venv venv
source venv/bin/activate  # Op Windows: venv\Scripts\activate
```

2. Installeer de benodigde packages:
```bash
pip install azure-cognitiveservices-language-textanalytics azure-identity msgraph-core fastapi uvicorn python-dotenv
```

3. Maak een `.env` bestand:
```env
AZURE_TENANT_ID=your_tenant_id
AZURE_CLIENT_ID=your_client_id
AZURE_CLIENT_SECRET=your_client_secret
AZURE_TEXT_ANALYTICS_KEY=your_text_analytics_key
AZURE_TEXT_ANALYTICS_ENDPOINT=your_text_analytics_endpoint
```

4. Implementeer de email analyzer:

```python
# email_analyzer.py
from azure.cognitiveservices.language.textanalytics import TextAnalyticsClient
from azure.identity import DefaultAzureCredential
from msgraph.core import GraphClient
from fastapi import FastAPI, HTTPException
from typing import Dict, List
import logging
import os
from dotenv import load_dotenv

load_dotenv()

class EmailAnalyzer:
    def __init__(self):
        self.credential = DefaultAzureCredential()
        self.graph_client = GraphClient(credentials=self.credential)
        self.text_analytics = TextAnalyticsClient(
            endpoint=os.getenv("AZURE_TEXT_ANALYTICS_ENDPOINT"),
            credentials=DefaultAzureCredential()
        )
        self.logger = logging.getLogger(__name__)

    async def analyze_emails(self, user_id: str) -> List[Dict[str, any]]:
        try:
            # Haal e-mails op
            result = await self.graph_client.get(
                f"/users/{user_id}/messages"
            )
            emails = result.json()["value"]

            analyzed_emails = []
            for email in emails:
                analysis = await self.analyze_email_content(email["body"]["content"])
                analyzed_emails.append({
                    "id": email["id"],
                    "subject": email["subject"],
                    "analysis": analysis
                })

            return analyzed_emails
        except Exception as e:
            self.logger.error(f"Error analyzing emails: {str(e)}")
            raise

    async def analyze_email_content(self, content: str) -> Dict[str, any]:
        try:
            # Analyseer sentiment
            sentiment = await self.text_analytics.sentiment(content)
            
            # Haal key phrases op
            key_phrases = await self.text_analytics.key_phrases(content)
            
            return {
                "sentiment": {
                    "positive": sentiment.sentiment_scores.positive,
                    "neutral": sentiment.sentiment_scores.neutral,
                    "negative": sentiment.sentiment_scores.negative
                },
                "key_phrases": key_phrases.key_phrases
            }
        except Exception as e:
            self.logger.error(f"Error analyzing email content: {str(e)}")
            raise

# FastAPI applicatie
app = FastAPI()
analyzer = EmailAnalyzer()

@app.get("/analyze/{user_id}")
async def analyze_user_emails(user_id: str):
    try:
        return await analyzer.analyze_emails(user_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
```

5. Start de applicatie:
```bash
uvicorn email_analyzer:app --reload
```

## Oefening 2: Real-time Activity Monitoring

### Doel
Implementeer een real-time monitoring systeem dat gebruik maakt van change notifications en SignalR.

### Stappen

1. Maak een nieuwe project directory:
```bash
mkdir activity_monitor
cd activity_monitor
python -m venv venv
source venv/bin/activate  # Op Windows: venv\Scripts\activate
```

2. Installeer de benodigde packages:
```bash
pip install azure-signalr msgraph-core fastapi uvicorn python-dotenv
```

3. Maak een `.env` bestand:
```env
AZURE_TENANT_ID=your_tenant_id
AZURE_CLIENT_ID=your_client_id
AZURE_CLIENT_SECRET=your_client_secret
AZURE_SIGNALR_CONNECTION_STRING=your_signalr_connection_string
```

4. Implementeer de activity monitor:

```python
# activity_monitor.py
from azure.signalr import SignalRServiceClient
from msgraph.core import GraphClient
from azure.identity import DefaultAzureCredential
from fastapi import FastAPI, Request
from typing import Dict, List
import logging
import os
from dotenv import load_dotenv

load_dotenv()

class ActivityMonitor:
    def __init__(self):
        self.credential = DefaultAzureCredential()
        self.graph_client = GraphClient(credentials=self.credential)
        self.signalr = SignalRServiceClient.from_connection_string(
            os.getenv("AZURE_SIGNALR_CONNECTION_STRING")
        )
        self.logger = logging.getLogger(__name__)

    async def setup_subscription(self, resource: str, notification_url: str):
        try:
            subscription = {
                "changeType": "created,updated,deleted",
                "notificationUrl": notification_url,
                "resource": resource,
                "expirationDateTime": (datetime.utcnow() + timedelta(days=3)).isoformat()
            }
            
            result = await self.graph_client.post(
                "/subscriptions",
                json=subscription
            )
            return result.json()
        except Exception as e:
            self.logger.error(f"Error setting up subscription: {str(e)}")
            raise

    async def broadcast_activity(self, activity_data: Dict[str, any]):
        try:
            hub = self.signalr.get_hub("activityHub")
            await hub.send_to_all(activity_data)
        except Exception as e:
            self.logger.error(f"Error broadcasting activity: {str(e)}")
            raise

# FastAPI applicatie
app = FastAPI()
monitor = ActivityMonitor()

@app.post("/notifications")
async def handle_notification(request: Request):
    try:
        data = await request.json()
        
        # Verwerk de notificatie
        if "validationToken" in data:
            return data["validationToken"]
            
        # Broadcast de activiteit
        for item in data.get("value", []):
            await monitor.broadcast_activity(item)
            
        return {"status": "success"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/subscribe")
async def create_subscription(resource: str, notification_url: str):
    try:
        return await monitor.setup_subscription(resource, notification_url)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
```

5. Start de applicatie:
```bash
uvicorn activity_monitor:app --reload
```

## Oefening 3: Edge Computing Implementation

### Doel
Implementeer een edge computing oplossing die offline functionaliteit en lokale AI verwerking ondersteunt.

### Stappen

1. Maak een nieuwe project directory:
```bash
mkdir edge_computing
cd edge_computing
python -m venv venv
source venv/bin/activate  # Op Windows: venv\Scripts\activate
```

2. Installeer de benodigde packages:
```bash
pip install azure-iot-hub azure-identity msgraph-core sqlalchemy python-dotenv
```

3. Maak een `.env` bestand:
```env
AZURE_TENANT_ID=your_tenant_id
AZURE_CLIENT_ID=your_client_id
AZURE_CLIENT_SECRET=your_client_secret
AZURE_IOT_HUB_CONNECTION_STRING=your_iot_hub_connection_string
```

4. Implementeer de edge computing oplossing:

```python
# edge_computing.py
from azure.iot.hub import IoTHubRegistryManager
from azure.identity import DefaultAzureCredential
from msgraph.core import GraphClient
from sqlalchemy import create_engine, Column, Integer, String, JSON, DateTime
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from typing import Dict, List
import logging
import os
from dotenv import load_dotenv

load_dotenv()

Base = declarative_base()

class OfflineData(Base):
    __tablename__ = 'offline_data'
    
    id = Column(Integer, primary_key=True)
    resource_type = Column(String)
    resource_id = Column(String)
    data = Column(JSON)
    sync_status = Column(String)
    last_modified = Column(DateTime)

class EdgeManager:
    def __init__(self):
        self.credential = DefaultAzureCredential()
        self.graph_client = GraphClient(credentials=self.credential)
        self.registry_manager = IoTHubRegistryManager(
            os.getenv("AZURE_IOT_HUB_CONNECTION_STRING")
        )
        self.engine = create_engine('sqlite:///edge_data.db')
        Base.metadata.create_all(self.engine)
        self.Session = sessionmaker(bind=self.engine)
        self.logger = logging.getLogger(__name__)

    async def store_offline_data(self, resource_type: str, resource_id: str, 
                               data: Dict[str, any]):
        try:
            session = self.Session()
            offline_data = OfflineData(
                resource_type=resource_type,
                resource_id=resource_id,
                data=data,
                sync_status="pending",
                last_modified=datetime.utcnow()
            )
            session.add(offline_data)
            session.commit()
            session.close()
        except Exception as e:
            self.logger.error(f"Error storing offline data: {str(e)}")
            raise

    async def sync_data(self):
        try:
            session = self.Session()
            pending_items = session.query(OfflineData).filter_by(
                sync_status="pending"
            ).all()
            
            for item in pending_items:
                await self.sync_with_graph(item)
                item.sync_status = "synced"
            
            session.commit()
            session.close()
        except Exception as e:
            self.logger.error(f"Error syncing data: {str(e)}")
            raise

    async def sync_with_graph(self, item: OfflineData):
        try:
            # Implementeer sync logica
            pass
        except Exception as e:
            self.logger.error(f"Error syncing with Graph: {str(e)}")
            raise

# FastAPI applicatie
app = FastAPI()
edge_manager = EdgeManager()

@app.post("/store")
async def store_data(resource_type: str, resource_id: str, data: Dict[str, any]):
    try:
        await edge_manager.store_offline_data(resource_type, resource_id, data)
        return {"status": "success"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/sync")
async def sync_data():
    try:
        await edge_manager.sync_data()
        return {"status": "success"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
```

5. Start de applicatie:
```bash
uvicorn edge_computing:app --reload
```

## Oefening 4: Advanced Security Implementation

### Doel
Implementeer geavanceerde beveiligingsmaatregelen met Zero Trust en threat protection.

### Stappen

1. Maak een nieuwe project directory:
```bash
mkdir security_implementation
cd security_implementation
python -m venv venv
source venv/bin/activate  # Op Windows: venv\Scripts\activate
```

2. Installeer de benodigde packages:
```bash
pip install azure-identity azure-keyvault-secrets msgraph-core fastapi uvicorn python-dotenv
```

3. Maak een `.env` bestand:
```env
AZURE_TENANT_ID=your_tenant_id
AZURE_CLIENT_ID=your_client_id
AZURE_CLIENT_SECRET=your_client_secret
AZURE_KEY_VAULT_URL=your_key_vault_url
```

4. Implementeer de security oplossing:

```python
# security_implementation.py
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
from msgraph.core import GraphClient
from fastapi import FastAPI, HTTPException, Depends
from typing import Dict, List
import logging
import os
from dotenv import load_dotenv

load_dotenv()

class SecurityManager:
    def __init__(self):
        self.credential = DefaultAzureCredential()
        self.graph_client = GraphClient(credentials=self.credential)
        self.secret_client = SecretClient(
            vault_url=os.getenv("AZURE_KEY_VAULT_URL"),
            credential=self.credential
        )
        self.logger = logging.getLogger(__name__)

    async def verify_access(self, user_id: str, resource: str) -> bool:
        try:
            result = await self.graph_client.get(
                f"/users/{user_id}/appRoleAssignments"
            )
            roles = result.json()["value"]
            return await self.check_permissions(roles, resource)
        except Exception as e:
            self.logger.error(f"Error verifying access: {str(e)}")
            raise

    async def check_permissions(self, roles: List[Dict[str, any]], 
                              resource: str) -> bool:
        try:
            # Implementeer permission check logica
            return True
        except Exception as e:
            self.logger.error(f"Error checking permissions: {str(e)}")
            raise

    async def analyze_activity(self, activity_data: Dict[str, any]) -> Dict[str, any]:
        try:
            # Implementeer activity analyse logica
            return {
                "risk_level": "low",
                "threats": [],
                "recommendations": []
            }
        except Exception as e:
            self.logger.error(f"Error analyzing activity: {str(e)}")
            raise

# FastAPI applicatie
app = FastAPI()
security_manager = SecurityManager()

@app.get("/verify/{user_id}/{resource}")
async def verify_user_access(user_id: str, resource: str):
    try:
        has_access = await security_manager.verify_access(user_id, resource)
        return {"has_access": has_access}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/analyze")
async def analyze_user_activity(activity_data: Dict[str, any]):
    try:
        return await security_manager.analyze_activity(activity_data)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
```

5. Start de applicatie:
```bash
uvicorn security_implementation:app --reload
```

## Implementatie Tips

### 1. Error Handling
- Implementeer uitgebreide error handling voor alle API calls
- Gebruik logging voor het bijhouden van fouten
- Implementeer retry logic voor tijdelijke fouten

### 2. Performance
- Gebruik caching waar mogelijk
- Implementeer batch processing voor grote datasets
- Optimaliseer database queries

### 3. Security
- Gebruik managed identities waar mogelijk
- Implementeer rate limiting
- Valideer alle input data

### 4. Testing
- Schrijf unit tests voor alle componenten
- Implementeer integration tests
- Test error scenarios

## Volgende Stap

Nu je deze praktische oefeningen hebt voltooid, heb je een goed begrip van hoe je geavanceerde concepten kunt implementeren met de Microsoft Graph API. In de volgende module gaan we kijken naar best practices en troubleshooting. 