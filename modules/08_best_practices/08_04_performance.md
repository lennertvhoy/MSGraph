# Performance Optimalisatie

In deze les gaan we kijken naar verschillende technieken om de prestaties van onze Microsoft Graph API applicaties te optimaliseren. We behandelen caching, batch processing, en andere optimalisatie strategieën.

## Caching Strategieën

### Distributed Cache

```python
# distributed_cache.py
from typing import Dict, any, Optional
import logging
import json
from datetime import datetime, timedelta
import redis
import pickle

class DistributedCache:
    def __init__(self, redis_url: str = "redis://localhost:6379"):
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

    async def delete(self, key: str):
        try:
            self.redis_client.delete(key)
        except Exception as e:
            self.logger.error(f"Error deleting from cache: {str(e)}")
            raise

    async def clear_pattern(self, pattern: str):
        try:
            keys = self.redis_client.keys(pattern)
            if keys:
                self.redis_client.delete(*keys)
        except Exception as e:
            self.logger.error(f"Error clearing cache pattern: {str(e)}")
            raise
```

### Cache Manager

```python
# cache_manager.py
from typing import Dict, any, Optional, Callable
import logging
import json
from datetime import datetime, timedelta
from functools import wraps
from .distributed_cache import DistributedCache

class CacheManager:
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        self.cache = DistributedCache()

    def cached(self, ttl: int = 300):
        def decorator(func: Callable) -> Callable:
            @wraps(func)
            async def wrapper(*args, **kwargs):
                try:
                    # Genereer cache key
                    cache_key = f"{func.__name__}:{str(args)}:{str(kwargs)}"
                    
                    # Probeer uit cache te halen
                    cached_result = await self.cache.get(cache_key)
                    if cached_result is not None:
                        return cached_result
                    
                    # Voer functie uit en cache resultaat
                    result = await func(*args, **kwargs)
                    await self.cache.set(cache_key, result, ttl)
                    
                    return result
                except Exception as e:
                    self.logger.error(f"Error in cache decorator: {str(e)}")
                    raise
            return wrapper
        return decorator

    async def invalidate_pattern(self, pattern: str):
        try:
            await self.cache.clear_pattern(pattern)
        except Exception as e:
            self.logger.error(f"Error invalidating cache pattern: {str(e)}")
            raise
```

## Batch Processing

### Batch Processor

```python
# batch_processor.py
from typing import List, Dict, any, Callable
import logging
import json
from datetime import datetime
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

    async def process_with_retry(self, 
                               items: List[Dict[str, any]], 
                               processor: Callable, 
                               max_retries: int = 3):
        try:
            for item in items:
                attempts = 0
                while attempts < max_retries:
                    try:
                        await processor(item)
                        break
                    except Exception as e:
                        attempts += 1
                        if attempts == max_retries:
                            self.logger.error(
                                f"Max retries reached for item: {str(e)}"
                            )
                            raise
                        await asyncio.sleep(1 * attempts)
        except Exception as e:
            self.logger.error(f"Error processing with retry: {str(e)}")
            raise
```

### Batch Request Manager

```python
# batch_request_manager.py
from typing import List, Dict, any
import logging
import json
from datetime import datetime
import asyncio
from msgraph.core import GraphClient

class BatchRequestManager:
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        self.batch_size = 20  # Microsoft Graph API batch limit

    async def execute_batch(self, 
                          client: GraphClient, 
                          requests: List[Dict[str, any]]):
        try:
            batch_requests = []
            for i, request in enumerate(requests):
                batch_requests.append({
                    "id": str(i),
                    "method": request.get("method", "GET"),
                    "url": request["url"],
                    "headers": request.get("headers", {}),
                    "body": request.get("body")
                })
            
            batch_body = {
                "requests": batch_requests
            }
            
            response = await client.post("/$batch", json=batch_body)
            return response.json()
        except Exception as e:
            self.logger.error(f"Error executing batch request: {str(e)}")
            raise

    async def process_batch_responses(self, 
                                    responses: Dict[str, any]) -> List[Dict[str, any]]:
        try:
            results = []
            for response in responses.get("responses", []):
                if response.get("status") == 200:
                    results.append(response.get("body"))
                else:
                    self.logger.warning(
                        f"Batch request failed: {json.dumps(response)}"
                    )
            return results
        except Exception as e:
            self.logger.error(f"Error processing batch responses: {str(e)}")
            raise
```

## Query Optimalisatie

### Query Optimizer

```python
# query_optimizer.py
from typing import Dict, any, List
import logging
import json
from datetime import datetime

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

    def add_expansions(self, query: str, expansions: List[str]) -> str:
        try:
            if not expansions:
                return query
            
            expand_param = "&$expand=" + ",".join(expansions)
            return f"{query}{expand_param}"
        except Exception as e:
            self.logger.error(f"Error adding expansions: {str(e)}")
            raise

    def add_filters(self, query: str, filters: List[str]) -> str:
        try:
            if not filters:
                return query
            
            filter_param = "&$filter=" + " and ".join(filters)
            return f"{query}{filter_param}"
        except Exception as e:
            self.logger.error(f"Error adding filters: {str(e)}")
            raise
```

### Resource Manager

```python
# resource_manager.py
from typing import Dict, any, List
import logging
import json
from datetime import datetime
import asyncio
from contextlib import asynccontextmanager

class ResourceManager:
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        self.active_resources: Dict[str, List[Dict[str, any]]] = {}

    @asynccontextmanager
    async def acquire_resource(self, resource_type: str):
        try:
            resource = await self._create_resource(resource_type)
            self._track_resource(resource_type, resource)
            
            try:
                yield resource
            finally:
                await self._release_resource(resource_type, resource)
        except Exception as e:
            self.logger.error(f"Error acquiring resource: {str(e)}")
            raise

    async def _create_resource(self, resource_type: str) -> Dict[str, any]:
        try:
            # Implementeer resource creatie logica
            return {"id": "resource_id", "type": resource_type}
        except Exception as e:
            self.logger.error(f"Error creating resource: {str(e)}")
            raise

    def _track_resource(self, resource_type: str, resource: Dict[str, any]):
        try:
            if resource_type not in self.active_resources:
                self.active_resources[resource_type] = []
            self.active_resources[resource_type].append(resource)
        except Exception as e:
            self.logger.error(f"Error tracking resource: {str(e)}")
            raise

    async def _release_resource(self, resource_type: str, resource: Dict[str, any]):
        try:
            if resource_type in self.active_resources:
                self.active_resources[resource_type].remove(resource)
        except Exception as e:
            self.logger.error(f"Error releasing resource: {str(e)}")
            raise
```

## Volgende Stap

Nu je bekend bent met performance optimalisatie, gaan we in de volgende les kijken naar [praktische oefeningen](08_05_praktische_oefeningen.md). Daar kunnen we de geleerde concepten in de praktijk toepassen. 