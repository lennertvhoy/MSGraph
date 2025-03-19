# Enterprise Architectuur

In deze les gaan we kijken naar verschillende architectuurpatronen en best practices voor het bouwen van enterprise-level applicaties met de Microsoft Graph API. We behandelen microservices, event-driven design, caching strategieën en error handling patterns.

## Microservices Architectuur

### Service Discovery

```python
from fastapi import FastAPI
from pydantic import BaseModel
from typing import List, Optional
import aiohttp
import asyncio

class Service(BaseModel):
    name: str
    url: str
    health: str
    last_updated: str

class ServiceRegistry:
    def __init__(self):
        self.services: List[Service] = []
        self.health_checks = {}
        self.logger = logging.getLogger(__name__)

    async def register_service(self, service: Service):
        self.services.append(service)
        self.health_checks[service.name] = asyncio.create_task(
            self._health_check(service)
        )
        self.logger.info(f"Service registered: {service.name}")

    async def _health_check(self, service: Service):
        while True:
            try:
                async with aiohttp.ClientSession() as session:
                    async with session.get(f"{service.url}/health") as response:
                        if response.status == 200:
                            service.health = "healthy"
                        else:
                            service.health = "unhealthy"
            except Exception as e:
                service.health = "unhealthy"
                self.logger.error(f"Health check failed for {service.name}: {str(e)}")
            
            service.last_updated = datetime.utcnow().isoformat()
            await asyncio.sleep(30)  # Check every 30 seconds

    async def get_service(self, name: str) -> Optional[Service]:
        return next((s for s in self.services if s.name == name), None)

    async def get_healthy_services(self) -> List[Service]:
        return [s for s in self.services if s.health == "healthy"]
```

### Service Gateway

```python
class ServiceGateway:
    def __init__(self, registry: ServiceRegistry):
        self.registry = registry
        self.logger = logging.getLogger(__name__)

    async def route_request(self, service_name: str, method: str, path: str, data: dict = None):
        service = await self.registry.get_service(service_name)
        if not service or service.health != "healthy":
            raise HTTPException(
                status_code=503,
                detail=f"Service {service_name} is not available"
            )

        try:
            async with aiohttp.ClientSession() as session:
                async with session.request(
                    method,
                    f"{service.url}{path}",
                    json=data
                ) as response:
                    return await response.json()
        except Exception as e:
            self.logger.error(
                f"Request failed for {service_name}",
                error=str(e),
                method=method,
                path=path
            )
            raise
```

## Event-Driven Design

### Event Bus

```python
from typing import Dict, List, Callable
import asyncio
from pydantic import BaseModel

class Event(BaseModel):
    type: str
    data: dict
    timestamp: str
    source: str

class EventBus:
    def __init__(self):
        self.subscribers: Dict[str, List[Callable]] = {}
        self.logger = logging.getLogger(__name__)

    def subscribe(self, event_type: str, callback: Callable):
        if event_type not in self.subscribers:
            self.subscribers[event_type] = []
        self.subscribers[event_type].append(callback)
        self.logger.info(f"Subscribed to event: {event_type}")

    async def publish(self, event: Event):
        if event.type not in self.subscribers:
            return

        tasks = []
        for callback in self.subscribers[event.type]:
            tasks.append(asyncio.create_task(callback(event)))

        await asyncio.gather(*tasks)
        self.logger.info(f"Published event: {event.type}")

class EventHandler:
    def __init__(self, event_bus: EventBus):
        self.event_bus = event_bus
        self.setup_handlers()

    def setup_handlers(self):
        self.event_bus.subscribe("user.created", self.handle_user_created)
        self.event_bus.subscribe("email.sent", self.handle_email_sent)

    async def handle_user_created(self, event: Event):
        # Implementeer user creation logica
        pass

    async def handle_email_sent(self, event: Event):
        # Implementeer email sent logica
        pass
```

### Message Queue

```python
from azure.servicebus import ServiceBusClient, ServiceBusMessage
import json

class MessageQueue:
    def __init__(self, connection_string: str, queue_name: str):
        self.client = ServiceBusClient.from_connection_string(connection_string)
        self.queue = self.client.get_queue_client(queue_name)
        self.logger = logging.getLogger(__name__)

    async def send_message(self, message: dict):
        try:
            service_bus_message = ServiceBusMessage(
                json.dumps(message),
                content_type="application/json"
            )
            await self.queue.send_messages(service_bus_message)
            self.logger.info(f"Message sent: {message['type']}")
        except Exception as e:
            self.logger.error(f"Failed to send message: {str(e)}")
            raise

    async def receive_messages(self, callback: Callable):
        while True:
            try:
                messages = await self.queue.receive_messages()
                for message in messages:
                    data = json.loads(str(message))
                    await callback(data)
                    await self.queue.complete_message(message)
            except Exception as e:
                self.logger.error(f"Error receiving messages: {str(e)}")
                await asyncio.sleep(1)
```

## Caching Strategieën

### Distributed Cache

```python
from azure.core.cache import DistributedCache
import json
from typing import Any, Optional

class CacheManager:
    def __init__(self, connection_string: str):
        self.cache = DistributedCache(connection_string)
        self.default_ttl = 300  # 5 minuten
        self.logger = logging.getLogger(__name__)

    async def get(self, key: str) -> Optional[Any]:
        try:
            data = await self.cache.get(key)
            return json.loads(data) if data else None
        except Exception as e:
            self.logger.error(f"Cache get failed: {str(e)}")
            return None

    async def set(self, key: str, value: Any, ttl: int = None):
        try:
            await self.cache.set(
                key,
                json.dumps(value),
                ttl or self.default_ttl
            )
        except Exception as e:
            self.logger.error(f"Cache set failed: {str(e)}")
            raise

    async def delete(self, key: str):
        try:
            await self.cache.delete(key)
        except Exception as e:
            self.logger.error(f"Cache delete failed: {str(e)}")
            raise

    async def get_or_set(self, key: str, fetch_func: callable, ttl: int = None):
        cached_data = await self.get(key)
        if cached_data:
            return cached_data
        
        data = await fetch_func()
        await self.set(key, data, ttl)
        return data
```

### Cache Invalidation

```python
class CacheInvalidator:
    def __init__(self, cache: CacheManager):
        self.cache = cache
        self.patterns = {}
        self.logger = logging.getLogger(__name__)

    def register_pattern(self, pattern: str, keys: List[str]):
        self.patterns[pattern] = keys
        self.logger.info(f"Registered pattern: {pattern}")

    async def invalidate_by_pattern(self, pattern: str):
        if pattern not in self.patterns:
            return
        
        for key in self.patterns[pattern]:
            await self.cache.delete(key)
            self.logger.info(f"Invalidated cache key: {key}")

    async def invalidate_all(self):
        for pattern in self.patterns:
            await self.invalidate_by_pattern(pattern)
```

## Error Handling Patterns

### Circuit Breaker

```python
class CircuitBreaker:
    def __init__(self, failure_threshold: int = 5, reset_timeout: int = 60):
        self.failure_threshold = failure_threshold
        self.reset_timeout = reset_timeout
        self.failures = 0
        self.last_failure_time = None
        self.state = "closed"
        self.logger = logging.getLogger(__name__)

    async def execute(self, func: callable, *args, **kwargs):
        if self.state == "open":
            if time.time() - self.last_failure_time > self.reset_timeout:
                self.state = "half-open"
                self.failures = 0
                self.logger.info("Circuit breaker half-open")
            else:
                raise Exception("Circuit breaker is open")

        try:
            result = await func(*args, **kwargs)
            if self.state == "half-open":
                self.state = "closed"
                self.logger.info("Circuit breaker closed")
            return result
        except Exception as e:
            self.failures += 1
            self.last_failure_time = time.time()
            if self.failures >= self.failure_threshold:
                self.state = "open"
                self.logger.error("Circuit breaker opened")
            raise
```

### Retry Pattern

```python
def retry(max_attempts: int = 3, delay: float = 1.0):
    def decorator(func):
        @functools.wraps(func)
        async def wrapper(*args, **kwargs):
            attempts = 0
            while attempts < max_attempts:
                try:
                    return await func(*args, **kwargs)
                except Exception as e:
                    attempts += 1
                    if attempts == max_attempts:
                        raise
                    logger.warning(
                        "Retrying function",
                        function=func.__name__,
                        attempt=attempts,
                        error=str(e)
                    )
                    await asyncio.sleep(delay * attempts)
        return wrapper
    return decorator
```

## Best Practices

### 1. Dependency Injection

```python
class ServiceContainer:
    def __init__(self):
        self.services = {}
        self.logger = logging.getLogger(__name__)

    def register(self, name: str, service: Any):
        self.services[name] = service
        self.logger.info(f"Registered service: {name}")

    def get(self, name: str) -> Any:
        if name not in self.services:
            raise KeyError(f"Service not found: {name}")
        return self.services[name]

class ServiceFactory:
    def __init__(self, container: ServiceContainer):
        self.container = container

    def create_user_service(self) -> UserService:
        return UserService(
            graph_client=self.container.get("graph_client"),
            cache=self.container.get("cache")
        )

    def create_email_service(self) -> EmailService:
        return EmailService(
            graph_client=self.container.get("graph_client"),
            event_bus=self.container.get("event_bus")
        )
```

### 2. Configuration Management

```python
class Config:
    def __init__(self):
        self.settings = {}
        self.logger = logging.getLogger(__name__)

    def load_from_env(self):
        self.settings = {
            "AZURE_TENANT_ID": os.getenv("AZURE_TENANT_ID"),
            "AZURE_CLIENT_ID": os.getenv("AZURE_CLIENT_ID"),
            "AZURE_CLIENT_SECRET": os.getenv("AZURE_CLIENT_SECRET"),
            "REDIS_URL": os.getenv("REDIS_URL", "redis://localhost"),
            "SERVICE_BUS_CONNECTION": os.getenv("SERVICE_BUS_CONNECTION"),
            "LOG_LEVEL": os.getenv("LOG_LEVEL", "INFO")
        }
        self.logger.info("Configuration loaded from environment")

    def get(self, key: str, default: Any = None) -> Any:
        return self.settings.get(key, default)
```

## Volgende Stap

Nu je bekend bent met enterprise architectuur, gaan we in de volgende les kijken naar [security en compliance](06_02_security_compliance.md). Daar leren we hoe we onze enterprise applicaties veilig en compliant kunnen maken. 