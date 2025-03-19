# Praktische Oefeningen

In deze les gaan we de geleerde concepten in de praktijk toepassen met een aantal oefeningen. We bouwen een robuuste applicatie die gebruik maakt van de Microsoft Graph API met alle best practices die we hebben geleerd.

## Oefening 1: Best Practices Implementatie

### Doel
Ontwikkel een applicatie die gebruikers en hun e-mails beheert via de Microsoft Graph API, met focus op code structuur, error handling, en security best practices.

### Stappen

1. Maak een nieuwe project directory:
```bash
mkdir graph_best_practices
cd graph_best_practices
```

2. Initialiseer een Python project:
```bash
python -m venv venv
source venv/bin/activate  # Op Windows: venv\Scripts\activate
pip install msgraph-core azure-identity python-dotenv redis
```

3. Maak een `.env` bestand:
```env
AZURE_TENANT_ID=your_tenant_id
AZURE_CLIENT_ID=your_client_id
AZURE_CLIENT_SECRET=your_client_secret
REDIS_URL=redis://localhost:6379
```

4. Implementeer de basis structuur:

```python
# src/config.py
from typing import Dict, any
import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    def __init__(self):
        self.tenant_id = os.getenv("AZURE_TENANT_ID")
        self.client_id = os.getenv("AZURE_CLIENT_ID")
        self.client_secret = os.getenv("AZURE_CLIENT_SECRET")
        self.redis_url = os.getenv("REDIS_URL")
        self.graph_api_url = "https://graph.microsoft.com/v1.0"
        
    @property
    def auth_config(self) -> Dict[str, any]:
        return {
            "tenant_id": self.tenant_id,
            "client_id": self.client_id,
            "client_secret": self.client_secret
        }
```

```python
# src/services/user_service.py
from typing import Dict, any, List
import logging
from msgraph.core import GraphClient
from azure.identity import DefaultAzureCredential
from ..utils.cache_manager import CacheManager
from ..utils.error_handler import ErrorHandler
from ..utils.rate_limiter import RateLimiter

class UserService:
    def __init__(self, config: Config):
        self.logger = logging.getLogger(__name__)
        self.config = config
        self.credential = DefaultAzureCredential()
        self.client = GraphClient(credentials=self.credential)
        self.cache_manager = CacheManager()
        self.error_handler = ErrorHandler()
        self.rate_limiter = RateLimiter()

    @CacheManager.cached(ttl=300)
    async def get_users(self) -> List[Dict[str, any]]:
        try:
            if not await self.rate_limiter.check_rate_limit("users"):
                await self.rate_limiter.wait_for_rate_limit("users", 60)
            
            response = await self.client.get("/users")
            return response.json()["value"]
        except Exception as e:
            await self.error_handler.handle_error(e, {"operation": "get_users"})
            raise

    async def get_user(self, user_id: str) -> Dict[str, any]:
        try:
            if not await self.rate_limiter.check_rate_limit("user"):
                await self.rate_limiter.wait_for_rate_limit("user", 60)
            
            response = await self.client.get(f"/users/{user_id}")
            return response.json()
        except Exception as e:
            await self.error_handler.handle_error(e, {
                "operation": "get_user",
                "user_id": user_id
            })
            raise
```

```python
# src/services/email_service.py
from typing import Dict, any, List
import logging
from msgraph.core import GraphClient
from ..utils.cache_manager import CacheManager
from ..utils.error_handler import ErrorHandler
from ..utils.rate_limiter import RateLimiter
from ..utils.batch_processor import BatchProcessor

class EmailService:
    def __init__(self, config: Config):
        self.logger = logging.getLogger(__name__)
        self.config = config
        self.credential = DefaultAzureCredential()
        self.client = GraphClient(credentials=self.credential)
        self.cache_manager = CacheManager()
        self.error_handler = ErrorHandler()
        self.rate_limiter = RateLimiter()
        self.batch_processor = BatchProcessor()

    @CacheManager.cached(ttl=300)
    async def get_emails(self, user_id: str) -> List[Dict[str, any]]:
        try:
            if not await self.rate_limiter.check_rate_limit("emails"):
                await self.rate_limiter.wait_for_rate_limit("emails", 60)
            
            response = await self.client.get(
                f"/users/{user_id}/messages"
            )
            return response.json()["value"]
        except Exception as e:
            await self.error_handler.handle_error(e, {
                "operation": "get_emails",
                "user_id": user_id
            })
            raise

    async def send_emails(self, 
                         user_id: str, 
                         emails: List[Dict[str, any]]):
        try:
            async def send_email(email: Dict[str, any]):
                if not await self.rate_limiter.check_rate_limit("send_email"):
                    await self.rate_limiter.wait_for_rate_limit("send_email", 60)
                
                response = await self.client.post(
                    f"/users/{user_id}/sendMail",
                    json={"message": email}
                )
                return response.json()
            
            await self.batch_processor.process_batch(emails, send_email)
        except Exception as e:
            await self.error_handler.handle_error(e, {
                "operation": "send_emails",
                "user_id": user_id,
                "email_count": len(emails)
            })
            raise
```

## Oefening 2: Performance Optimalisatie

### Doel
Optimaliseer de applicatie door caching, batch processing, en query optimalisatie toe te passen.

### Stappen

1. Voeg Redis caching toe:

```python
# src/utils/cache_manager.py
from typing import Dict, any, Optional
import logging
import json
from datetime import datetime, timedelta
import redis
import pickle

class CacheManager:
    def __init__(self, redis_url: str):
        self.logger = logging.getLogger(__name__)
        self.redis_client = redis.from_url(redis_url)

    async def get(self, key: str) -> Optional[Dict[str, any]]:
        try:
            data = self.redis_client.get(key)
            if data:
                return pickle.loads(data)
            return None
        except Exception as e:
            self.logger.error(f"Error getting from cache: {str(e)}")
            raise

    async def set(self, key: str, data: any, ttl: int = 300):
        try:
            serialized_data = pickle.dumps(data)
            self.redis_client.setex(key, ttl, serialized_data)
        except Exception as e:
            self.logger.error(f"Error setting cache: {str(e)}")
            raise
```

2. Implementeer batch email verwerking:

```python
# src/utils/batch_processor.py
from typing import List, Dict, any, Callable
import logging
import asyncio
from itertools import islice

class BatchProcessor:
    def __init__(self):
        self.logger = logging.getLogger(__name__)

    async def process_batch(self, 
                          items: List[Dict[str, any]], 
                          processor: Callable, 
                          batch_size: int = 10):
        try:
            for i in range(0, len(items), batch_size):
                batch = list(islice(items, i, i + batch_size))
                tasks = [processor(item) for item in batch]
                await asyncio.gather(*tasks)
                
                self.logger.debug(
                    f"Processed batch {i//batch_size + 1} "
                    f"({len(batch)} items)"
                )
        except Exception as e:
            self.logger.error(f"Error processing batch: {str(e)}")
            raise
```

3. Optimaliseer queries:

```python
# src/utils/query_optimizer.py
from typing import Dict, any, List
import logging

class QueryOptimizer:
    def __init__(self):
        self.logger = logging.getLogger(__name__)

    def optimize_query(self, query: str) -> str:
        try:
            # Verwijder onnodige whitespace
            query = " ".join(query.split())
            
            # Voeg select toe als ontbreekt
            if "select" not in query.lower():
                query = f"{query}&$select=id"
            
            # Voeg top toe als ontbreekt
            if "top" not in query.lower():
                query = f"{query}&$top=100"
            
            return query
        except Exception as e:
            self.logger.error(f"Error optimizing query: {str(e)}")
            raise
```

## Oefening 3: Error Handling en Retry Logic

### Doel
Implementeer robuuste error handling en retry logica voor API calls.

### Stappen

1. Implementeer een retry decorator:

```python
# src/utils/retry_handler.py
from typing import Callable, any
import logging
import asyncio
from functools import wraps

class RetryHandler:
    def __init__(self):
        self.logger = logging.getLogger(__name__)

    def retry(self, max_attempts: int = 3, delay: float = 1.0):
        def decorator(func: Callable) -> Callable:
            @wraps(func)
            async def wrapper(*args, **kwargs) -> any:
                attempts = 0
                while attempts < max_attempts:
                    try:
                        return await func(*args, **kwargs)
                    except Exception as e:
                        attempts += 1
                        if attempts == max_attempts:
                            self.logger.error(
                                f"Max retry attempts reached: {str(e)}"
                            )
                            raise
                        
                        self.logger.warning(
                            f"Retry attempt {attempts}/{max_attempts}: {str(e)}"
                        )
                        await asyncio.sleep(delay * attempts)
                return None
            return wrapper
        return decorator
```

2. Implementeer een circuit breaker:

```python
# src/utils/circuit_breaker.py
from typing import Dict, any, Callable
import logging
from datetime import datetime, timedelta
from enum import Enum
import asyncio

class CircuitState(Enum):
    CLOSED = "closed"
    OPEN = "open"
    HALF_OPEN = "half_open"

class CircuitBreaker:
    def __init__(self, 
                 failure_threshold: int = 5, 
                 reset_timeout: int = 60):
        self.logger = logging.getLogger(__name__)
        self.failure_threshold = failure_threshold
        self.reset_timeout = reset_timeout
        self.state = CircuitState.CLOSED
        self.failures = 0
        self.last_failure_time = None

    async def execute(self, func: Callable, *args, **kwargs) -> any:
        try:
            if self.state == CircuitState.OPEN:
                if self.should_reset():
                    self.state = CircuitState.HALF_OPEN
                else:
                    raise Exception("Circuit breaker is open")
            
            try:
                result = await func(*args, **kwargs)
                
                if self.state == CircuitState.HALF_OPEN:
                    self.reset()
                
                return result
            except Exception as e:
                await self.handle_failure(e)
                raise
        except Exception as e:
            self.logger.error(f"Error in circuit breaker: {str(e)}")
            raise
```

## Implementatie Tips

### Error Handling
- Gebruik try-except blocks voor alle API calls
- Log errors met context informatie
- Implementeer retry logica voor tijdelijke fouten
- Gebruik circuit breakers voor chronische problemen

### Performance Optimalisatie
- Cache veel gebruikte data
- Gebruik batch processing voor bulk operaties
- Optimaliseer queries met select en filter
- Implementeer rate limiting

### Security
- Gebruik environment variables voor gevoelige data
- Implementeer token rotatie
- Valideer alle input
- Gebruik HTTPS voor alle communicatie

### Testing
- Schrijf unit tests voor alle services
- Implementeer integratie tests
- Test error scenarios
- Monitor performance metrics

## Volgende Stap

Nu je de best practices hebt toegepast in praktische oefeningen, ben je klaar om je eigen robuuste Microsoft Graph API applicaties te bouwen. De volgende module zal kijken naar toekomstige ontwikkelingen en trends in de Microsoft Graph API. 