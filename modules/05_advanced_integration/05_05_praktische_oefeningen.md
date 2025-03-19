# Praktische Oefeningen

In deze les gaan we verschillende praktische oefeningen uitvoeren om onze kennis van geavanceerde integratie met de Microsoft Graph API in de praktijk te brengen. We zullen een complete applicatie bouwen die gebruik maakt van alle concepten die we hebben geleerd.

## Oefening 1: Geavanceerde Architectuur Implementatie

### Doel
Ontwikkel een microservices-gebaseerde applicatie die gebruikers en e-mails beheert via de Microsoft Graph API.

### Stappen

1. Maak een nieuwe directory `advanced_integration` en initialiseer een Python project:
```bash
mkdir advanced_integration
cd advanced_integration
python -m venv venv
source venv/bin/activate  # Op Windows: venv\Scripts\activate
pip install fastapi uvicorn msgraph azure-identity structlog prometheus-client
```

2. Maak de volgende bestandsstructuur:
```
advanced_integration/
├── services/
│   ├── __init__.py
│   ├── user_service.py
│   └── email_service.py
├── core/
│   ├── __init__.py
│   ├── config.py
│   └── logging.py
├── api/
│   ├── __init__.py
│   └── routes.py
└── main.py
```

3. Implementeer de configuratie (`core/config.py`):
```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    AZURE_TENANT_ID: str
    AZURE_CLIENT_ID: str
    AZURE_CLIENT_SECRET: str
    LOG_LEVEL: str = "INFO"
    CACHE_TTL: int = 300

    class Config:
        env_file = ".env"

settings = Settings()
```

4. Implementeer de logging configuratie (`core/logging.py`):
```python
import structlog
from .config import settings

def setup_logging():
    structlog.configure(
        processors=[
            structlog.processors.TimeStamper(fmt="iso"),
            structlog.processors.JSONRenderer()
        ],
        logger_factory=structlog.PrintLoggerFactory(),
        wrapper_class=structlog.make_filtering_bound_logger(
            getattr(logging, settings.LOG_LEVEL)
        )
    )
    return structlog.get_logger()
```

5. Implementeer de user service (`services/user_service.py`):
```python
from msgraph import GraphServiceClient
from azure.identity import ClientSecretCredential
from core.config import settings
from core.logging import setup_logging

logger = setup_logging()

class UserService:
    def __init__(self):
        self.credential = ClientSecretCredential(
            tenant_id=settings.AZURE_TENANT_ID,
            client_id=settings.AZURE_CLIENT_ID,
            client_secret=settings.AZURE_CLIENT_SECRET
        )
        self.client = GraphServiceClient(credentials=self.credential)

    async def get_users(self, department: str = None):
        try:
            logger.info("Fetching users", department=department)
            users = await self.client.users.get()
            
            if department:
                users = [u for u in users.value 
                        if u.department == department]
            
            return users.value
        except Exception as e:
            logger.error("Error fetching users", error=str(e))
            raise

    async def update_user(self, user_id: str, data: dict):
        try:
            logger.info("Updating user", user_id=user_id)
            user = await self.client.users.by_user_id(user_id).patch(data)
            return user
        except Exception as e:
            logger.error("Error updating user", 
                        user_id=user_id, 
                        error=str(e))
            raise
```

6. Implementeer de email service (`services/email_service.py`):
```python
from msgraph import GraphServiceClient
from azure.identity import ClientSecretCredential
from core.config import settings
from core.logging import setup_logging

logger = setup_logging()

class EmailService:
    def __init__(self):
        self.credential = ClientSecretCredential(
            tenant_id=settings.AZURE_TENANT_ID,
            client_id=settings.AZURE_CLIENT_ID,
            client_secret=settings.AZURE_CLIENT_SECRET
        )
        self.client = GraphServiceClient(credentials=self.credential)

    async def get_emails(self, user_id: str, folder: str = "inbox"):
        try:
            logger.info("Fetching emails", 
                       user_id=user_id, 
                       folder=folder)
            messages = await self.client.users.by_user_id(user_id)\
                .mail_folders.by_mail_folder_id(folder)\
                .messages.get()
            return messages.value
        except Exception as e:
            logger.error("Error fetching emails", 
                        user_id=user_id, 
                        error=str(e))
            raise

    async def send_email(self, user_id: str, to: str, subject: str, body: str):
        try:
            logger.info("Sending email", 
                       user_id=user_id, 
                       to=to)
            message = {
                "toRecipients": [{"emailAddress": {"address": to}}],
                "subject": subject,
                "body": {"content": body}
            }
            await self.client.users.by_user_id(user_id)\
                .send_mail.post(message)
        except Exception as e:
            logger.error("Error sending email", 
                        user_id=user_id, 
                        error=str(e))
            raise
```

7. Implementeer de API routes (`api/routes.py`):
```python
from fastapi import APIRouter, Depends, HTTPException
from services.user_service import UserService
from services.email_service import EmailService
from core.logging import setup_logging

logger = setup_logging()
router = APIRouter()

@router.get("/users")
async def get_users(department: str = None):
    service = UserService()
    return await service.get_users(department)

@router.patch("/users/{user_id}")
async def update_user(user_id: str, data: dict):
    service = UserService()
    return await service.update_user(user_id, data)

@router.get("/users/{user_id}/emails")
async def get_emails(user_id: str, folder: str = "inbox"):
    service = EmailService()
    return await service.get_emails(user_id, folder)

@router.post("/users/{user_id}/send-email")
async def send_email(user_id: str, to: str, subject: str, body: str):
    service = EmailService()
    await service.send_email(user_id, to, subject, body)
    return {"status": "success"}
```

8. Implementeer de main applicatie (`main.py`):
```python
from fastapi import FastAPI
from api.routes import router
from core.logging import setup_logging
from prometheus_client import make_asgi_app

logger = setup_logging()

app = FastAPI(title="Graph API Integration")
app.include_router(router, prefix="/api")
metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)

@app.on_event("startup")
async def startup_event():
    logger.info("Application starting up")

@app.on_event("shutdown")
async def shutdown_event():
    logger.info("Application shutting down")
```

### Verificatie

1. Maak een `.env` bestand met je Azure credentials:
```
AZURE_TENANT_ID=your_tenant_id
AZURE_CLIENT_ID=your_client_id
AZURE_CLIENT_SECRET=your_client_secret
```

2. Start de applicatie:
```bash
uvicorn main:app --reload
```

3. Test de endpoints:
```bash
# Gebruikers ophalen
curl http://localhost:8000/api/users

# Emails ophalen voor een gebruiker
curl http://localhost:8000/api/users/{user_id}/emails

# Email versturen
curl -X POST http://localhost:8000/api/users/{user_id}/send-email \
  -H "Content-Type: application/json" \
  -d '{"to": "recipient@example.com", "subject": "Test", "body": "Hello"}'
```

## Oefening 2: Performance Optimalisatie

### Doel
Optimaliseer de prestaties van de applicatie door caching, batch processing en rate limiting te implementeren.

### Stappen

1. Voeg caching toe aan de user service:
```python
from core.config import settings
import aioredis
import json

class UserService:
    def __init__(self):
        # Bestaande initialisatie...
        self.redis = aioredis.from_url("redis://localhost")

    async def get_users(self, department: str = None):
        cache_key = f"users:{department or 'all'}"
        
        # Check cache
        cached_data = await self.redis.get(cache_key)
        if cached_data:
            return json.loads(cached_data)
        
        # Fetch from API
        users = await self._fetch_users(department)
        
        # Cache result
        await self.redis.setex(
            cache_key,
            settings.CACHE_TTL,
            json.dumps([u.to_dict() for u in users])
        )
        
        return users
```

2. Implementeer batch processing voor emails:
```python
class EmailService:
    async def send_batch_emails(self, user_id: str, emails: List[dict]):
        batch_requests = []
        for i, email in enumerate(emails):
            batch_requests.append({
                "id": str(i),
                "method": "POST",
                "url": f"/users/{user_id}/sendMail",
                "body": {
                    "message": {
                        "toRecipients": [{"emailAddress": {"address": email["to"]}}],
                        "subject": email["subject"],
                        "body": {"content": email["body"]}
                    }
                }
            })
        
        batch_request = {"requests": batch_requests}
        return await self.client.batch.post(batch_request)
```

3. Implementeer rate limiting:
```python
from fastapi import HTTPException
import time

class RateLimiter:
    def __init__(self, max_requests: int = 100, time_window: int = 60):
        self.max_requests = max_requests
        self.time_window = time_window
        self.requests = []

    async def check_rate_limit(self):
        now = time.time()
        self.requests = [req for req in self.requests 
                        if now - req < self.time_window]
        
        if len(self.requests) >= self.max_requests:
            raise HTTPException(
                status_code=429,
                detail="Too many requests"
            )
        
        self.requests.append(now)
```

## Oefening 3: Monitoring en Logging

### Doel
Implementeer uitgebreide monitoring en logging voor de applicatie.

### Stappen

1. Voeg Prometheus metrics toe:
```python
from prometheus_client import Counter, Histogram

class Metrics:
    def __init__(self):
        self.request_counter = Counter(
            'graph_api_requests_total',
            'Total number of Graph API requests',
            ['method', 'endpoint', 'status']
        )
        
        self.request_duration = Histogram(
            'graph_api_request_duration_seconds',
            'Duration of Graph API requests',
            ['method', 'endpoint']
        )

metrics = Metrics()
```

2. Implementeer health checks:
```python
class HealthCheck:
    def __init__(self):
        self.checks = {}

    def register_check(self, name: str, check_func: callable):
        self.checks[name] = check_func

    async def check_health(self):
        results = {}
        for name, check in self.checks.items():
            try:
                status = await check()
                results[name] = {
                    "status": "healthy" if status else "unhealthy",
                    "timestamp": datetime.utcnow().isoformat()
                }
            except Exception as e:
                results[name] = {
                    "status": "error",
                    "error": str(e),
                    "timestamp": datetime.utcnow().isoformat()
                }
        return results
```

3. Voeg logging decorators toe:
```python
import functools
from core.logging import setup_logging

logger = setup_logging()

def log_execution(func):
    @functools.wraps(func)
    async def wrapper(*args, **kwargs):
        start_time = time.time()
        try:
            result = await func(*args, **kwargs)
            duration = time.time() - start_time
            logger.info(
                "Function executed",
                function=func.__name__,
                duration=duration,
                status="success"
            )
            return result
        except Exception as e:
            duration = time.time() - start_time
            logger.error(
                "Function failed",
                function=func.__name__,
                duration=duration,
                error=str(e),
                status="error"
            )
            raise
    return wrapper
```

## Bonus Oefening: Error Handling en Retry Logic

### Doel
Implementeer robuuste error handling en retry logica voor de API calls.

### Stappen

1. Implementeer een retry decorator:
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

2. Implementeer circuit breaker pattern:
```python
class CircuitBreaker:
    def __init__(self, failure_threshold: int = 5, reset_timeout: int = 60):
        self.failure_threshold = failure_threshold
        self.reset_timeout = reset_timeout
        self.failures = 0
        self.last_failure_time = None
        self.state = "closed"

    async def execute(self, func: callable, *args, **kwargs):
        if self.state == "open":
            if time.time() - self.last_failure_time > self.reset_timeout:
                self.state = "half-open"
                self.failures = 0
            else:
                raise Exception("Circuit breaker is open")

        try:
            result = await func(*args, **kwargs)
            if self.state == "half-open":
                self.state = "closed"
            return result
        except Exception as e:
            self.failures += 1
            self.last_failure_time = time.time()
            if self.failures >= self.failure_threshold:
                self.state = "open"
            raise
```

## Tips voor Implementatie

1. **Error Handling**
   - Gebruik try-except blocks voor alle API calls
   - Log alle errors met context
   - Implementeer retry logic voor tijdelijke fouten

2. **Performance**
   - Gebruik caching waar mogelijk
   - Implementeer batch processing voor bulk operaties
   - Monitor response times en resource gebruik

3. **Security**
   - Valideer alle input
   - Gebruik environment variables voor gevoelige data
   - Implementeer rate limiting

4. **Testing**
   - Schrijf unit tests voor alle services
   - Implementeer integration tests
   - Gebruik mocking voor API calls

## Volgende Stap

Nu je de praktische oefeningen hebt voltooid, heb je een solide basis voor het bouwen van geavanceerde integraties met de Microsoft Graph API. In de volgende module gaan we kijken naar enterprise-level scenario's en hoe we deze kunnen implementeren. 