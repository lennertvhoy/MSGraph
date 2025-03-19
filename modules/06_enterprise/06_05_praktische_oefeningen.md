# Praktische Oefeningen

In deze les gaan we een enterprise-level applicatie ontwikkelen die gebruik maakt van de Microsoft Graph API. We implementeren alle geleerde concepten zoals architectuur, security, performance, monitoring en logging.

## Oefening 1: Enterprise Architectuur Implementatie

### Doel
Ontwikkel een microservices-gebaseerde applicatie die gebruikers en e-mails beheert via de Microsoft Graph API.

### Stappen

1. Maak een nieuwe directory en initialiseer een Python project:
```bash
mkdir enterprise_graph_app
cd enterprise_graph_app
python -m venv venv
source venv/bin/activate  # Op Windows: venv\Scripts\activate
pip install fastapi uvicorn msal azure-identity redis prometheus-client structlog
```

2. Maak de volgende bestandsstructuur:
```
enterprise_graph_app/
├── config/
│   └── settings.py
├── services/
│   ├── user_service.py
│   └── email_service.py
├── middleware/
│   ├── auth.py
│   └── logging.py
├── monitoring/
│   ├── health.py
│   └── metrics.py
├── utils/
│   └── helpers.py
└── main.py
```

3. Implementeer de configuratie (`config/settings.py`):
```python
from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    AZURE_TENANT_ID: str
    AZURE_CLIENT_ID: str
    AZURE_CLIENT_SECRET: str
    REDIS_URL: str = "redis://localhost:6379"
    LOG_LEVEL: str = "INFO"
    
    class Config:
        env_file = ".env"

settings = Settings()
```

4. Implementeer de user service (`services/user_service.py`):
```python
from msgraph.core import GraphClient
from azure.identity import DefaultAzureCredential
from config.settings import settings
from monitoring.metrics import MetricsCollector
from monitoring.health import HealthMonitor
import logging

class UserService:
    def __init__(self):
        self.credential = DefaultAzureCredential()
        self.client = GraphClient(credentials=self.credential)
        self.metrics = MetricsCollector()
        self.health = HealthMonitor()
        self.logger = logging.getLogger(__name__)

    async def get_users(self, department: str = None):
        try:
            query = "/users"
            if department:
                query += f"?$filter=department eq '{department}'"
            
            response = await self.client.get(query)
            self.metrics.record_request("users", "GET", response.status_code, 0)
            return response.json()
        except Exception as e:
            self.metrics.record_error("get_users")
            self.logger.error(f"Error getting users: {str(e)}")
            raise

    async def update_user(self, user_id: str, data: dict):
        try:
            response = await self.client.patch(f"/users/{user_id}", json=data)
            self.metrics.record_request("users", "PATCH", response.status_code, 0)
            return response.json()
        except Exception as e:
            self.metrics.record_error("update_user")
            self.logger.error(f"Error updating user: {str(e)}")
            raise
```

5. Implementeer de email service (`services/email_service.py`):
```python
from msgraph.core import GraphClient
from azure.identity import DefaultAzureCredential
from config.settings import settings
from monitoring.metrics import MetricsCollector
from monitoring.health import HealthMonitor
import logging

class EmailService:
    def __init__(self):
        self.credential = DefaultAzureCredential()
        self.client = GraphClient(credentials=self.credential)
        self.metrics = MetricsCollector()
        self.health = HealthMonitor()
        self.logger = logging.getLogger(__name__)

    async def get_emails(self, user_id: str, folder: str = "inbox"):
        try:
            response = await self.client.get(
                f"/users/{user_id}/mailFolders/{folder}/messages"
            )
            self.metrics.record_request("emails", "GET", response.status_code, 0)
            return response.json()
        except Exception as e:
            self.metrics.record_error("get_emails")
            self.logger.error(f"Error getting emails: {str(e)}")
            raise

    async def send_email(self, user_id: str, to: list, subject: str, body: str):
        try:
            data = {
                "message": {
                    "subject": subject,
                    "body": {"contentType": "HTML", "content": body},
                    "toRecipients": [{"emailAddress": {"address": recipient}} for recipient in to]
                }
            }
            response = await self.client.post(
                f"/users/{user_id}/sendMail",
                json=data
            )
            self.metrics.record_request("emails", "POST", response.status_code, 0)
            return response.json()
        except Exception as e:
            self.metrics.record_error("send_email")
            self.logger.error(f"Error sending email: {str(e)}")
            raise
```

6. Implementeer de main applicatie (`main.py`):
```python
from fastapi import FastAPI, Depends, HTTPException
from services.user_service import UserService
from services.email_service import EmailService
from middleware.auth import AuthMiddleware
from middleware.logging import LoggingMiddleware
from monitoring.health import HealthMonitor
from monitoring.metrics import MetricsCollector
import logging

app = FastAPI(title="Enterprise Graph API Application")

# Middleware
app.add_middleware(AuthMiddleware)
app.add_middleware(LoggingMiddleware)

# Services
user_service = UserService()
email_service = EmailService()

# Monitoring
health_monitor = HealthMonitor()
metrics_collector = MetricsCollector()

@app.get("/health")
async def health_check():
    return await health_monitor.check_health()

@app.get("/metrics")
async def get_metrics():
    return metrics_collector.get_metrics()

@app.get("/users")
async def get_users(department: str = None):
    return await user_service.get_users(department)

@app.patch("/users/{user_id}")
async def update_user(user_id: str, data: dict):
    return await user_service.update_user(user_id, data)

@app.get("/users/{user_id}/emails")
async def get_user_emails(user_id: str, folder: str = "inbox"):
    return await email_service.get_emails(user_id, folder)

@app.post("/users/{user_id}/send-email")
async def send_email(user_id: str, to: list, subject: str, body: str):
    return await email_service.send_email(user_id, to, subject, body)
```

## Oefening 2: Performance Optimalisatie

### Doel
Optimaliseer de applicatie door caching, batch processing en rate limiting te implementeren.

### Stappen

1. Voeg caching toe met Redis (`utils/cache.py`):
```python
from redis import Redis
import json
from config.settings import settings

class RedisCache:
    def __init__(self):
        self.redis = Redis.from_url(settings.REDIS_URL)
        self.logger = logging.getLogger(__name__)

    async def get(self, key: str):
        try:
            data = self.redis.get(key)
            if data:
                return json.loads(data)
            return None
        except Exception as e:
            self.logger.error(f"Error getting from cache: {str(e)}")
            return None

    async def set(self, key: str, value: any, ttl: int = 3600):
        try:
            self.redis.setex(
                key,
                ttl,
                json.dumps(value)
            )
        except Exception as e:
            self.logger.error(f"Error setting cache: {str(e)}")
            raise
```

2. Implementeer batch email versturen (`services/email_service.py`):
```python
class EmailService:
    # ... bestaande code ...

    async def send_batch_emails(self, user_id: str, emails: list):
        try:
            batch_requests = []
            for email in emails:
                batch_requests.append({
                    "id": str(uuid.uuid4()),
                    "method": "POST",
                    "url": f"/users/{user_id}/sendMail",
                    "body": {
                        "message": {
                            "subject": email["subject"],
                            "body": {"contentType": "HTML", "content": email["body"]},
                            "toRecipients": [
                                {"emailAddress": {"address": recipient}}
                                for recipient in email["to"]
                            ]
                        }
                    }
                })

            response = await self.client.post(
                "/$batch",
                json={"requests": batch_requests}
            )
            self.metrics.record_request("emails", "BATCH", response.status_code, 0)
            return response.json()
        except Exception as e:
            self.metrics.record_error("send_batch_emails")
            self.logger.error(f"Error sending batch emails: {str(e)}")
            raise
```

3. Implementeer rate limiting (`middleware/rate_limit.py`):
```python
from fastapi import Request, HTTPException
from datetime import datetime, timedelta
from collections import defaultdict

class RateLimiter:
    def __init__(self, max_requests: int = 100, time_window: int = 60):
        self.max_requests = max_requests
        self.time_window = time_window
        self.requests = defaultdict(list)
        self.logger = logging.getLogger(__name__)

    async def check_rate_limit(self, request: Request):
        client_id = request.client.host
        now = datetime.utcnow()
        window_start = now - timedelta(seconds=self.time_window)
        
        # Verwijder oude requests
        self.requests[client_id] = [
            req_time for req_time in self.requests[client_id]
            if req_time > window_start
        ]
        
        if len(self.requests[client_id]) >= self.max_requests:
            self.logger.warning(f"Rate limit exceeded for client: {client_id}")
            raise HTTPException(status_code=429, detail="Rate limit exceeded")
        
        self.requests[client_id].append(now)
```

## Oefening 3: Monitoring en Logging

### Doel
Implementeer uitgebreide monitoring en logging voor de applicatie.

### Stappen

1. Voeg Prometheus metrics toe (`monitoring/metrics.py`):
```python
from prometheus_client import Counter, Histogram, Gauge

class MetricsCollector:
    def __init__(self):
        self.request_counter = Counter(
            'graph_api_requests_total',
            'Total number of Graph API requests',
            ['endpoint', 'method', 'status']
        )
        self.request_duration = Histogram(
            'graph_api_request_duration_seconds',
            'Request duration in seconds',
            ['endpoint']
        )
        self.error_counter = Counter(
            'graph_api_errors_total',
            'Total number of Graph API errors',
            ['error_type']
        )
        self.active_requests = Gauge(
            'graph_api_active_requests',
            'Number of active requests'
        )

    def record_request(self, endpoint: str, method: str, status: int, duration: float):
        self.request_counter.labels(
            endpoint=endpoint,
            method=method,
            status=status
        ).inc()
        self.request_duration.labels(endpoint=endpoint).observe(duration)

    def record_error(self, error_type: str):
        self.error_counter.labels(error_type=error_type).inc()

    def set_active_requests(self, count: int):
        self.active_requests.set(count)
```

2. Implementeer health checks (`monitoring/health.py`):
```python
class HealthMonitor:
    def __init__(self):
        self.health_checks = {}
        self.logger = logging.getLogger(__name__)

    def register_health_check(self, name: str, check_func):
        self.health_checks[name] = check_func
        self.logger.info(f"Registered health check: {name}")

    async def check_health(self):
        results = {}
        for name, check_func in self.health_checks.items():
            try:
                is_healthy = await check_func()
                results[name] = {
                    "healthy": is_healthy,
                    "timestamp": datetime.utcnow().isoformat()
                }
            except Exception as e:
                self.logger.error(f"Health check failed for {name}: {str(e)}")
                results[name] = {
                    "healthy": False,
                    "error": str(e),
                    "timestamp": datetime.utcnow().isoformat()
                }
        return results
```

3. Implementeer logging middleware (`middleware/logging.py`):
```python
from fastapi import Request
import structlog
import time

class LoggingMiddleware:
    def __init__(self):
        self.logger = structlog.get_logger()

    async def __call__(self, request: Request, call_next):
        start_time = time.time()
        
        try:
            response = await call_next(request)
            duration = time.time() - start_time
            
            self.logger.info(
                "request_completed",
                method=request.method,
                url=str(request.url),
                status_code=response.status_code,
                duration=duration
            )
            
            return response
        except Exception as e:
            duration = time.time() - start_time
            self.logger.error(
                "request_failed",
                method=request.method,
                url=str(request.url),
                error=str(e),
                duration=duration
            )
            raise
```

## Bonus Oefening: Error Handling en Retry Logic

### Doel
Implementeer robuuste error handling en retry logica voor API calls.

### Stappen

1. Implementeer retry decorator (`utils/retry.py`):
```python
import asyncio
from functools import wraps
import logging

def async_retry(max_retries: int = 3, delay: float = 1.0):
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            last_exception = None
            for attempt in range(max_retries):
                try:
                    return await func(*args, **kwargs)
                except Exception as e:
                    last_exception = e
                    if attempt < max_retries - 1:
                        await asyncio.sleep(delay * (2 ** attempt))
                        logging.warning(
                            f"Retry attempt {attempt + 1}/{max_retries} for {func.__name__}"
                        )
            raise last_exception
        return wrapper
    return decorator
```

2. Implementeer circuit breaker pattern (`utils/circuit_breaker.py`):
```python
class CircuitBreaker:
    def __init__(self, failure_threshold: int = 5, reset_timeout: int = 60):
        self.failure_threshold = failure_threshold
        self.reset_timeout = reset_timeout
        self.failures = 0
        self.last_failure_time = None
        self.state = "CLOSED"
        self.logger = logging.getLogger(__name__)

    async def __call__(self, func):
        if self.state == "OPEN":
            if time.time() - self.last_failure_time > self.reset_timeout:
                self.state = "HALF-OPEN"
                self.failures = 0
            else:
                raise RuntimeError("Circuit breaker is OPEN")

        try:
            result = await func()
            if self.state == "HALF-OPEN":
                self.state = "CLOSED"
                self.failures = 0
            return result
        except Exception as e:
            self.failures += 1
            self.last_failure_time = time.time()
            
            if self.failures >= self.failure_threshold:
                self.state = "OPEN"
                self.logger.error("Circuit breaker opened")
            
            raise
```

## Implementatie Tips

1. **Error Handling**
   - Gebruik try-except blocks voor alle API calls
   - Log errors met context
   - Implementeer retry logic voor tijdelijke fouten
   - Gebruik circuit breaker voor chronische problemen

2. **Performance**
   - Implementeer caching waar mogelijk
   - Gebruik batch requests voor meerdere operaties
   - Monitor response times
   - Implementeer rate limiting

3. **Security**
   - Valideer alle input
   - Gebruik HTTPS
   - Implementeer proper authentication
   - Log security events

4. **Testing**
   - Schrijf unit tests voor alle services
   - Implementeer integration tests
   - Test error scenarios
   - Test performance onder load

## Volgende Stap

Nu je een enterprise-level applicatie hebt ontwikkeld met de Microsoft Graph API, kun je deze kennis gebruiken om complexe integraties te bouwen. In de volgende module gaan we kijken naar [advanced topics](07_advanced/README.md) zoals AI integratie, real-time communicatie en edge computing. 