# Veelvoorkomende Problemen

In deze les gaan we kijken naar veelvoorkomende problemen bij het werken met de Microsoft Graph API en hoe we deze kunnen oplossen. We behandelen authenticatie problemen, rate limiting, en andere veelvoorkomende uitdagingen.

## Authenticatie Problemen

### Token Manager

```python
# token_manager.py
from typing import Dict, any, Optional
import logging
import json
from datetime import datetime, timedelta
from azure.identity import DefaultAzureCredential
from msgraph.core import GraphClient

class TokenManager:
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        self.credential = DefaultAzureCredential()
        self.token_cache: Dict[str, Dict[str, any]] = {}

    async def get_token(self, scope: str) -> Optional[str]:
        try:
            if scope in self.token_cache:
                token_data = self.token_cache[scope]
                if datetime.fromisoformat(token_data["expires_at"]) > datetime.utcnow():
                    return token_data["token"]
                else:
                    del self.token_cache[scope]
            
            token = await self.credential.get_token(scope)
            
            self.token_cache[scope] = {
                "token": token.token,
                "expires_at": (datetime.utcnow() + timedelta(seconds=token.expires_in)).isoformat()
            }
            
            return token.token
        except Exception as e:
            self.logger.error(f"Error getting token: {str(e)}")
            raise

    async def refresh_token(self, scope: str):
        try:
            if scope in self.token_cache:
                del self.token_cache[scope]
            return await self.get_token(scope)
        except Exception as e:
            self.logger.error(f"Error refreshing token: {str(e)}")
            raise

    async def validate_token(self, token: str) -> bool:
        try:
            # Implementeer token validatie logica
            return True
        except Exception as e:
            self.logger.error(f"Error validating token: {str(e)}")
            raise
```

### Permission Manager

```python
# permission_manager.py
from typing import Dict, any, List
import logging
import json
from datetime import datetime
from msgraph.core import GraphClient

class PermissionManager:
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        self.required_permissions = {
            "User.Read": "Read user profile",
            "Mail.Read": "Read user mail",
            "Mail.Send": "Send mail as user"
        }

    async def check_permissions(self, client: GraphClient) -> List[str]:
        try:
            response = await client.get("/oauth2PermissionGrants")
            granted_permissions = response.json()["value"]
            
            missing_permissions = [
                permission for permission in self.required_permissions
                if permission not in granted_permissions
            ]
            
            if missing_permissions:
                self.logger.warning(
                    f"Missing permissions: {json.dumps(missing_permissions)}"
                )
            
            return missing_permissions
        except Exception as e:
            self.logger.error(f"Error checking permissions: {str(e)}")
            raise

    async def request_permissions(self, 
                                client: GraphClient, 
                                permissions: List[str]):
        try:
            # Implementeer permission request logica
            pass
        except Exception as e:
            self.logger.error(f"Error requesting permissions: {str(e)}")
            raise
```

## Rate Limiting en Throttling

### Rate Limit Handler

```python
# rate_limit_handler.py
from typing import Dict, any, Optional
import logging
import json
from datetime import datetime, timedelta
import asyncio

class RateLimitHandler:
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        self.rate_limits: Dict[str, Dict[str, any]] = {}

    async def check_rate_limit(self, 
                             endpoint: str, 
                             max_requests: int = 100, 
                             time_window: int = 60) -> bool:
        try:
            now = datetime.utcnow()
            
            if endpoint not in self.rate_limits:
                self.rate_limits[endpoint] = []
            
            # Verwijder oude requests
            self.rate_limits[endpoint] = [
                req_time for req_time in self.rate_limits[endpoint]
                if now - req_time < timedelta(seconds=time_window)
            ]
            
            if len(self.rate_limits[endpoint]) >= max_requests:
                return False
            
            self.rate_limits[endpoint].append(now)
            return True
        except Exception as e:
            self.logger.error(f"Error checking rate limit: {str(e)}")
            raise

    async def handle_throttling(self, 
                              response: Dict[str, any], 
                              endpoint: str) -> Optional[float]:
        try:
            if response.get("status") == 429:  # Too Many Requests
                retry_after = float(response.get("headers", {}).get("Retry-After", 60))
                self.logger.warning(
                    f"Rate limit exceeded for {endpoint}. "
                    f"Waiting {retry_after} seconds."
                )
                return retry_after
            return None
        except Exception as e:
            self.logger.error(f"Error handling throttling: {str(e)}")
            raise

    async def wait_for_rate_limit(self, endpoint: str, wait_time: float):
        try:
            await asyncio.sleep(wait_time)
        except Exception as e:
            self.logger.error(f"Error waiting for rate limit: {str(e)}")
            raise
```

### Request Queue

```python
# request_queue.py
from typing import Dict, any, List, Callable
import logging
import json
from datetime import datetime
import asyncio
from collections import deque

class RequestQueue:
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        self.queue = deque()
        self.processing = False

    async def add_request(self, 
                         request_func: Callable, 
                         *args, 
                         **kwargs):
        try:
            request_data = {
                "timestamp": datetime.utcnow().isoformat(),
                "function": request_func.__name__,
                "args": args,
                "kwargs": kwargs
            }
            
            self.queue.append(request_data)
            self.logger.debug(f"Request added to queue: {json.dumps(request_data)}")
            
            if not self.processing:
                await self.process_queue()
        except Exception as e:
            self.logger.error(f"Error adding request to queue: {str(e)}")
            raise

    async def process_queue(self):
        try:
            self.processing = True
            
            while self.queue:
                request_data = self.queue.popleft()
                try:
                    await request_data["function"](*request_data["args"], 
                                                 **request_data["kwargs"])
                except Exception as e:
                    self.logger.error(
                        f"Error processing request: {str(e)}"
                    )
                    # Voeg request toe aan einde van queue voor retry
                    self.queue.append(request_data)
                
                # Wacht kort tussen requests
                await asyncio.sleep(0.1)
            
            self.processing = False
        except Exception as e:
            self.logger.error(f"Error processing queue: {str(e)}")
            raise
```

## Error Handling en Recovery

### Error Recovery Manager

```python
# error_recovery_manager.py
from typing import Dict, any, List, Callable
import logging
import json
from datetime import datetime
import asyncio
from functools import wraps

class ErrorRecoveryManager:
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        self.recovery_strategies: Dict[str, Callable] = {}

    def register_recovery_strategy(self, 
                                 error_type: str, 
                                 strategy: Callable):
        try:
            self.recovery_strategies[error_type] = strategy
        except Exception as e:
            self.logger.error(f"Error registering recovery strategy: {str(e)}")
            raise

    async def handle_error(self, error: Exception, context: Dict[str, any]):
        try:
            error_type = type(error).__name__
            error_data = {
                "timestamp": datetime.utcnow().isoformat(),
                "error_type": error_type,
                "error_message": str(error),
                "context": context
            }
            
            self.logger.error(f"Error occurred: {json.dumps(error_data)}")
            
            if error_type in self.recovery_strategies:
                return await self.recovery_strategies[error_type](error, context)
            
            return None
        except Exception as e:
            self.logger.error(f"Error handling error: {str(e)}")
            raise

    def retry_on_error(self, max_attempts: int = 3, delay: float = 1.0):
        def decorator(func: Callable) -> Callable:
            @wraps(func)
            async def wrapper(*args, **kwargs):
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

### Circuit Breaker

```python
# circuit_breaker.py
from typing import Dict, any, Callable
import logging
import json
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

    async def handle_failure(self, error: Exception):
        try:
            self.failures += 1
            self.last_failure_time = datetime.utcnow()
            
            if self.failures >= self.failure_threshold:
                self.state = CircuitState.OPEN
                self.logger.error(
                    f"Circuit breaker opened after {self.failures} failures"
                )
        except Exception as e:
            self.logger.error(f"Error handling failure: {str(e)}")
            raise

    def should_reset(self) -> bool:
        try:
            if not self.last_failure_time:
                return False
            
            return (datetime.utcnow() - self.last_failure_time) > \
                   timedelta(seconds=self.reset_timeout)
        except Exception as e:
            self.logger.error(f"Error checking reset condition: {str(e)}")
            raise

    def reset(self):
        try:
            self.state = CircuitState.CLOSED
            self.failures = 0
            self.last_failure_time = None
        except Exception as e:
            self.logger.error(f"Error resetting circuit breaker: {str(e)}")
            raise
```

## Volgende Stap

Nu je bekend bent met veelvoorkomende problemen en hun oplossingen, gaan we in de volgende les kijken naar [performance optimalisatie](08_04_performance.md). Daar leren we hoe we de prestaties van onze applicaties kunnen verbeteren. 