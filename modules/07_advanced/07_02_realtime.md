# Real-time Communicatie

In deze les gaan we kijken naar verschillende manieren om real-time communicatie te implementeren met de Microsoft Graph API. We behandelen change notifications, webhooks, SignalR integratie en real-time updates.

## Change Notifications

### Subscription Management

```python
from msgraph.core import GraphClient
from typing import Dict, List
import logging
from datetime import datetime, timedelta

class SubscriptionManager:
    def __init__(self, graph_client: GraphClient):
        self.client = graph_client
        self.logger = logging.getLogger(__name__)

    async def create_subscription(self, resource: str, notification_url: str, 
                                expiration_time: datetime) -> Dict[str, any]:
        try:
            subscription = {
                "changeType": "created,updated,deleted",
                "notificationUrl": notification_url,
                "resource": resource,
                "expirationDateTime": expiration_time.isoformat()
            }
            
            result = await self.client.post("/subscriptions", json=subscription)
            return result.json()
        except Exception as e:
            self.logger.error(f"Error creating subscription: {str(e)}")
            raise

    async def renew_subscription(self, subscription_id: str, 
                               expiration_time: datetime) -> Dict[str, any]:
        try:
            patch_data = {
                "expirationDateTime": expiration_time.isoformat()
            }
            
            result = await self.client.patch(
                f"/subscriptions/{subscription_id}",
                json=patch_data
            )
            return result.json()
        except Exception as e:
            self.logger.error(f"Error renewing subscription: {str(e)}")
            raise

    async def list_subscriptions(self) -> List[Dict[str, any]]:
        try:
            result = await self.client.get("/subscriptions")
            return result.json()["value"]
        except Exception as e:
            self.logger.error(f"Error listing subscriptions: {str(e)}")
            raise
```

### Notification Handler

```python
from fastapi import FastAPI, Request
from typing import Dict, any
import logging

class NotificationHandler:
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        self.app = FastAPI()
        self.setup_routes()

    def setup_routes(self):
        @self.app.post("/notifications")
        async def handle_notification(request: Request):
            try:
                data = await request.json()
                await self.process_notification(data)
                return {"status": "success"}
            except Exception as e:
                self.logger.error(f"Error handling notification: {str(e)}")
                return {"status": "error", "message": str(e)}

    async def process_notification(self, data: Dict[str, any]):
        try:
            # Verwerk de notificatie data
            validation_token = data.get("validationToken")
            if validation_token:
                return validation_token

            # Verwerk de change notificaties
            for notification in data.get("value", []):
                await self.handle_change(notification)
        except Exception as e:
            self.logger.error(f"Error processing notification: {str(e)}")
            raise

    async def handle_change(self, change: Dict[str, any]):
        try:
            change_type = change.get("changeType")
            resource = change.get("resource")
            
            self.logger.info(
                f"Processing change: {change_type} for resource: {resource}"
            )
            
            # Implementeer specifieke change handling logica
        except Exception as e:
            self.logger.error(f"Error handling change: {str(e)}")
            raise
```

## Webhooks

### Webhook Manager

```python
class WebhookManager:
    def __init__(self, graph_client: GraphClient):
        self.client = graph_client
        self.logger = logging.getLogger(__name__)

    async def setup_webhook(self, resource: str, webhook_url: str) -> Dict[str, any]:
        try:
            webhook_config = {
                "changeType": "created,updated,deleted",
                "notificationUrl": webhook_url,
                "resource": resource,
                "expirationDateTime": (datetime.utcnow() + timedelta(days=3)).isoformat()
            }
            
            result = await self.client.post("/subscriptions", json=webhook_config)
            return result.json()
        except Exception as e:
            self.logger.error(f"Error setting up webhook: {str(e)}")
            raise

    async def validate_webhook(self, validation_token: str) -> str:
        try:
            return validation_token
        except Exception as e:
            self.logger.error(f"Error validating webhook: {str(e)}")
            raise
```

### Webhook Handler

```python
class WebhookHandler:
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        self.app = FastAPI()
        self.setup_routes()

    def setup_routes(self):
        @self.app.post("/webhook")
        async def handle_webhook(request: Request):
            try:
                data = await request.json()
                await self.process_webhook(data)
                return {"status": "success"}
            except Exception as e:
                self.logger.error(f"Error handling webhook: {str(e)}")
                return {"status": "error", "message": str(e)}

    async def process_webhook(self, data: Dict[str, any]):
        try:
            # Verwerk de webhook data
            if "validationToken" in data:
                return data["validationToken"]

            # Verwerk de webhook payload
            for item in data.get("value", []):
                await self.handle_webhook_item(item)
        except Exception as e:
            self.logger.error(f"Error processing webhook: {str(e)}")
            raise

    async def handle_webhook_item(self, item: Dict[str, any]):
        try:
            # Implementeer specifieke webhook item handling logica
            pass
        except Exception as e:
            self.logger.error(f"Error handling webhook item: {str(e)}")
            raise
```

## SignalR Integratie

### SignalR Manager

```python
from azure.signalr import SignalRServiceClient
from typing import Dict, any
import logging

class SignalRManager:
    def __init__(self, connection_string: str):
        self.client = SignalRServiceClient.from_connection_string(connection_string)
        self.logger = logging.getLogger(__name__)

    async def broadcast_message(self, hub_name: str, message: Dict[str, any]):
        try:
            hub = self.client.get_hub(hub_name)
            await hub.send_to_all(message)
        except Exception as e:
            self.logger.error(f"Error broadcasting message: {str(e)}")
            raise

    async def send_to_user(self, hub_name: str, user_id: str, 
                          message: Dict[str, any]):
        try:
            hub = self.client.get_hub(hub_name)
            await hub.send_to_user(user_id, message)
        except Exception as e:
            self.logger.error(f"Error sending to user: {str(e)}")
            raise
```

### Real-time Updates

```python
class RealTimeUpdateManager:
    def __init__(self, signalr: SignalRManager):
        self.signalr = signalr
        self.logger = logging.getLogger(__name__)

    async def handle_graph_update(self, change: Dict[str, any]):
        try:
            # Verwerk de Graph update
            message = self.format_update_message(change)
            
            # Broadcast de update via SignalR
            await self.signalr.broadcast_message(
                "graphUpdates",
                message
            )
        except Exception as e:
            self.logger.error(f"Error handling graph update: {str(e)}")
            raise

    def format_update_message(self, change: Dict[str, any]) -> Dict[str, any]:
        try:
            return {
                "type": "graphUpdate",
                "changeType": change.get("changeType"),
                "resource": change.get("resource"),
                "timestamp": datetime.utcnow().isoformat()
            }
        except Exception as e:
            self.logger.error(f"Error formatting update message: {str(e)}")
            raise
```

## Best Practices

### 1. Error Handling

```python
class RealTimeErrorHandler:
    def __init__(self):
        self.logger = logging.getLogger(__name__)

    async def handle_real_time_error(self, error: Exception, context: dict):
        try:
            error_type = type(error).__name__
            error_message = str(error)
            
            self.logger.error(
                f"Real-time service error: {error_type}",
                error=error_message,
                context=context
            )
            
            # Implementeer error recovery logica
            return await self.recover_from_error(error_type, context)
        except Exception as e:
            self.logger.error(f"Error handling real-time error: {str(e)}")
            raise

    async def recover_from_error(self, error_type: str, context: dict):
        try:
            # Implementeer recovery logica
            pass
        except Exception as e:
            self.logger.error(f"Error in recovery process: {str(e)}")
            raise
```

### 2. Performance Optimization

```python
class RealTimeOptimizer:
    def __init__(self):
        self.logger = logging.getLogger(__name__)

    async def optimize_connection(self, connection: any):
        try:
            # Implementeer connection optimalisatie logica
            pass
        except Exception as e:
            self.logger.error(f"Error optimizing connection: {str(e)}")
            raise

    async def batch_updates(self, updates: List[Dict[str, any]]):
        try:
            # Implementeer batch update logica
            pass
        except Exception as e:
            self.logger.error(f"Error batching updates: {str(e)}")
            raise
```

## Volgende Stap

Nu je bekend bent met real-time communicatie, gaan we in de volgende les kijken naar [edge computing](07_03_edge.md). Daar leren we hoe we edge computing kunnen implementeren met de Microsoft Graph API. 