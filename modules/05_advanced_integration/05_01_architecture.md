# Architectuur en Design Patterns

In deze les gaan we kijken naar verschillende architectuurpatronen en design patterns die je kunt gebruiken bij het integreren van de Microsoft Graph API in je systemen. We behandelen microservices, event-driven design, caching en error handling.

## Microservices Architectuur

### Basis Microservice Structuur

```python
from fastapi import FastAPI, HTTPException
from msgraph import GraphServiceClient
from azure.identity import ClientSecretCredential
import asyncio

class UserService:
    def __init__(self, client_id: str, client_secret: str, tenant_id: str):
        self.credential = ClientSecretCredential(
            tenant_id=tenant_id,
            client_id=client_id,
            client_secret=client_secret
        )
        self.graph_client = GraphServiceClient(credentials=self.credential)

    async def get_user(self, user_id: str):
        try:
            user = await self.graph_client.users.by_user_id(user_id).get()
            return user
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))

class EmailService:
    def __init__(self, graph_client: GraphServiceClient):
        self.graph_client = graph_client

    async def get_user_emails(self, user_id: str):
        try:
            messages = await self.graph_client.users.by_user_id(user_id).messages.get()
            return messages.value
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))

# FastAPI applicatie
app = FastAPI()
user_service = UserService(...)
email_service = EmailService(...)

@app.get("/users/{user_id}")
async def get_user(user_id: str):
    return await user_service.get_user(user_id)

@app.get("/users/{user_id}/emails")
async def get_user_emails(user_id: str):
    return await email_service.get_user_emails(user_id)
```

### Service Discovery

```python
class ServiceRegistry:
    def __init__(self):
        self.services = {}

    def register_service(self, name: str, service: Any):
        self.services[name] = service

    def get_service(self, name: str) -> Any:
        if name not in self.services:
            raise ValueError(f"Service {name} niet gevonden")
        return self.services[name]

# Service registry setup
registry = ServiceRegistry()
registry.register_service("user", user_service)
registry.register_service("email", email_service)
```

## Event-Driven Design

### Event Bus

```python
from typing import Callable, Dict, List
import asyncio

class EventBus:
    def __init__(self):
        self.subscribers: Dict[str, List[Callable]] = {}

    def subscribe(self, event_type: str, callback: Callable):
        if event_type not in self.subscribers:
            self.subscribers[event_type] = []
        self.subscribers[event_type].append(callback)

    async def publish(self, event_type: str, data: Any):
        if event_type in self.subscribers:
            for callback in self.subscribers[event_type]:
                await callback(data)

# Event handlers
async def handle_user_created(user_data: dict):
    # Verwerk nieuwe gebruiker
    pass

async def handle_email_received(email_data: dict):
    # Verwerk nieuwe email
    pass

# Event bus setup
event_bus = EventBus()
event_bus.subscribe("user.created", handle_user_created)
event_bus.subscribe("email.received", handle_email_received)
```

### Change Notification Handler

```python
class ChangeNotificationHandler:
    def __init__(self, event_bus: EventBus):
        self.event_bus = event_bus

    async def process_notification(self, notification: dict):
        resource_type = notification['resource']
        change_type = notification['changeType']
        
        event_type = f"{resource_type}.{change_type}"
        await self.event_bus.publish(event_type, notification)
```

## Caching Strategieën

### Distributed Cache

```python
from azure.core.cache import DistributedCache
import json

class GraphCache:
    def __init__(self, connection_string: str):
        self.cache = DistributedCache(connection_string)

    async def get(self, key: str):
        data = await self.cache.get(key)
        return json.loads(data) if data else None

    async def set(self, key: str, value: Any, ttl: int = 300):
        await self.cache.set(
            key,
            json.dumps(value),
            ttl
        )

    async def delete(self, key: str):
        await self.cache.delete(key)
```

### Cache Manager

```python
class CacheManager:
    def __init__(self, cache: GraphCache):
        self.cache = cache

    async def get_or_set(self, key: str, fetch_func: Callable, ttl: int = 300):
        # Probeer eerst uit cache te halen
        cached_data = await self.cache.get(key)
        if cached_data:
            return cached_data
        
        # Als niet in cache, haal op en cache
        data = await fetch_func()
        await self.cache.set(key, data, ttl)
        return data
```

## Error Handling Patterns

### Circuit Breaker

```python
from tenacity import retry, stop_after_attempt, wait_exponential

class CircuitBreaker:
    def __init__(self, max_failures: int = 3):
        self.max_failures = max_failures
        self.failures = 0
        self.state = "CLOSED"
        self.lock = asyncio.Lock()

    async def execute(self, func: Callable):
        async with self.lock:
            if self.state == "OPEN":
                raise Exception("Circuit breaker is open")
            
            try:
                result = await func()
                self.failures = 0
                return result
            except Exception as e:
                self.failures += 1
                if self.failures >= self.max_failures:
                    self.state = "OPEN"
                raise e
```

### Retry Pattern

```python
class RetryHandler:
    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=4, max=10),
        reraise=True
    )
    async def execute_with_retry(self, func: Callable):
        try:
            return await func()
        except Exception as e:
            if self._is_retryable_error(e):
                raise
            return None

    def _is_retryable_error(self, error: Exception) -> bool:
        return isinstance(error, (TimeoutError, ConnectionError))
```

## Best Practices

### 1. Dependency Injection

```python
class ServiceContainer:
    def __init__(self):
        self.services = {}

    def register(self, name: str, service: Any):
        self.services[name] = service

    def get(self, name: str) -> Any:
        return self.services[name]

# Container setup
container = ServiceContainer()
container.register("graph_client", graph_client)
container.register("cache", cache)
container.register("event_bus", event_bus)
```

### 2. Configuration Management

```python
class Config:
    def __init__(self):
        self.settings = {
            "cache_ttl": 300,
            "max_retries": 3,
            "batch_size": 100,
            "rate_limit": {
                "requests": 100,
                "window": 60
            }
        }

    def get(self, key: str, default: Any = None):
        return self.settings.get(key, default)

    def set(self, key: str, value: Any):
        self.settings[key] = value
```

### 3. Logging en Monitoring

```python
class MonitoringService:
    def __init__(self):
        self.metrics = {}
        self.logger = logging.getLogger(__name__)

    def track_metric(self, name: str, value: float):
        if name not in self.metrics:
            self.metrics[name] = []
        self.metrics[name].append(value)
        self.logger.info(f"Metric {name}: {value}")

    def get_metric_stats(self, name: str):
        if name not in self.metrics:
            return None
        values = self.metrics[name]
        return {
            "min": min(values),
            "max": max(values),
            "avg": sum(values) / len(values)
        }
```

## Volgende Stap

Nu je bekend bent met verschillende architectuurpatronen en design patterns, gaan we in de volgende les kijken naar [security en authenticatie](05_02_security.md). Daar leren we hoe we de beveiliging van onze integratie kunnen waarborgen. 