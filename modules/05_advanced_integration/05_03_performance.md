# Performance Optimalisatie

In deze les gaan we kijken naar verschillende technieken om de prestaties van onze Microsoft Graph API integratie te optimaliseren. We behandelen caching strategieën, batch processing, rate limiting en resource optimalisatie.

## Caching Strategieën

### Distributed Caching

```python
from azure.core.cache import DistributedCache
import json
from typing import Any, Optional

class GraphCache:
    def __init__(self, connection_string: str):
        self.cache = DistributedCache(connection_string)
        self.default_ttl = 300  # 5 minuten

    async def get(self, key: str) -> Optional[Any]:
        data = await self.cache.get(key)
        return json.loads(data) if data else None

    async def set(self, key: str, value: Any, ttl: int = None):
        await self.cache.set(
            key,
            json.dumps(value),
            ttl or self.default_ttl
        )

    async def delete(self, key: str):
        await self.cache.delete(key)

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
    def __init__(self, cache: GraphCache):
        self.cache = cache
        self.patterns = {}

    def register_pattern(self, pattern: str, keys: List[str]):
        self.patterns[pattern] = keys

    async def invalidate_by_pattern(self, pattern: str):
        if pattern not in self.patterns:
            return
        
        for key in self.patterns[pattern]:
            await self.cache.delete(key)

    async def invalidate_all(self):
        for pattern in self.patterns:
            await self.invalidate_by_pattern(pattern)
```

## Batch Processing

### Batch Request Manager

```python
class BatchRequestManager:
    def __init__(self, graph_client: GraphServiceClient):
        self.graph_client = graph_client
        self.max_batch_size = 20

    async def process_batch(self, requests: List[dict]):
        # Verdeel requests in batches
        batches = [requests[i:i + self.max_batch_size] 
                  for i in range(0, len(requests), self.max_batch_size)]
        
        results = []
        for batch in batches:
            batch_request = {
                "requests": [
                    {
                        "id": str(i),
                        "method": req["method"],
                        "url": req["url"],
                        "body": req.get("body"),
                        "headers": req.get("headers")
                    }
                    for i, req in enumerate(batch)
                ]
            }
            
            response = await self.graph_client.batch.post(batch_request)
            results.extend(response.responses)
        
        return results

    async def process_parallel_batches(self, requests: List[dict]):
        batches = [requests[i:i + self.max_batch_size] 
                  for i in range(0, len(requests), self.max_batch_size)]
        
        tasks = [self.process_batch(batch) for batch in batches]
        results = await asyncio.gather(*tasks)
        
        return [item for batch in results for item in batch]
```

### Batch Response Handler

```python
class BatchResponseHandler:
    def __init__(self):
        self.logger = logging.getLogger(__name__)

    def process_responses(self, responses: List[dict]):
        successful = []
        failed = []
        
        for response in responses:
            if response.status == 200:
                successful.append(response)
            else:
                failed.append(response)
                self.logger.error(
                    f"Batch request failed: {response.status} - {response.body}"
                )
        
        return {
            "successful": successful,
            "failed": failed
        }
```

## Rate Limiting

### Rate Limiter

```python
class RateLimiter:
    def __init__(self, max_requests: int = 100, time_window: int = 60):
        self.max_requests = max_requests
        self.time_window = time_window
        self.requests = []
        self.lock = asyncio.Lock()

    async def wait_if_needed(self):
        async with self.lock:
            now = time.time()
            # Verwijder oude requests
            self.requests = [req for req in self.requests 
                           if now - req < self.time_window]
            
            if len(self.requests) >= self.max_requests:
                wait_time = self.requests[0] + self.time_window - now
                await asyncio.sleep(wait_time)
            
            self.requests.append(now)

class AdaptiveRateLimiter(RateLimiter):
    def __init__(self, initial_max_requests: int = 100, 
                 time_window: int = 60):
        super().__init__(initial_max_requests, time_window)
        self.success_rate = 1.0
        self.min_requests = 10
        self.max_requests = initial_max_requests

    async def adjust_rate(self, success: bool):
        if success:
            self.success_rate = min(1.0, self.success_rate + 0.1)
            self.max_requests = min(200, self.max_requests + 10)
        else:
            self.success_rate = max(0.0, self.success_rate - 0.2)
            self.max_requests = max(self.min_requests, 
                                  self.max_requests - 20)
```

## Resource Optimalisatie

### Connection Pooling

```python
class ConnectionPool:
    def __init__(self, max_connections: int = 10):
        self.max_connections = max_connections
        self.connections = []
        self.lock = asyncio.Lock()

    async def get_connection(self):
        async with self.lock:
            if len(self.connections) < self.max_connections:
                connection = await self._create_connection()
                self.connections.append(connection)
            return self.connections.pop(0)

    async def release_connection(self, connection):
        async with self.lock:
            self.connections.append(connection)

    async def _create_connection(self):
        # Implementeer connection creatie logica
        pass
```

### Resource Manager

```python
class ResourceManager:
    def __init__(self, graph_client: GraphServiceClient):
        self.graph_client = graph_client
        self.resource_cache = {}
        self.lock = asyncio.Lock()

    async def get_resource(self, resource_id: str, resource_type: str):
        cache_key = f"{resource_type}:{resource_id}"
        
        async with self.lock:
            if cache_key in self.resource_cache:
                return self.resource_cache[cache_key]
            
            resource = await self._fetch_resource(resource_id, resource_type)
            self.resource_cache[cache_key] = resource
            return resource

    async def _fetch_resource(self, resource_id: str, resource_type: str):
        # Implementeer resource ophaal logica
        pass
```

## Performance Monitoring

### Performance Metrics

```python
class PerformanceMonitor:
    def __init__(self):
        self.metrics = {}
        self.logger = logging.getLogger(__name__)

    def track_metric(self, name: str, value: float):
        if name not in self.metrics:
            self.metrics[name] = []
        self.metrics[name].append(value)
        
        self.logger.info(
            f"Performance Metric: {name} = {value}",
            extra={"metric": name, "value": value}
        )

    def get_metric_stats(self, name: str):
        if name not in self.metrics:
            return None
        
        values = self.metrics[name]
        return {
            "min": min(values),
            "max": max(values),
            "avg": sum(values) / len(values),
            "count": len(values)
        }
```

### Performance Analyzer

```python
class PerformanceAnalyzer:
    def __init__(self):
        self.monitor = PerformanceMonitor()
        self.thresholds = {
            "response_time": 1.0,  # seconden
            "error_rate": 0.05,    # 5%
            "cache_hit_rate": 0.8  # 80%
        }

    async def analyze_performance(self):
        metrics = {
            "response_time": self.monitor.get_metric_stats("response_time"),
            "error_rate": self.monitor.get_metric_stats("error_rate"),
            "cache_hit_rate": self.monitor.get_metric_stats("cache_hit_rate")
        }
        
        issues = []
        for metric, stats in metrics.items():
            if not stats:
                continue
                
            if metric == "response_time" and stats["avg"] > self.thresholds[metric]:
                issues.append(f"Hoge response time: {stats['avg']}s")
            elif metric == "error_rate" and stats["avg"] > self.thresholds[metric]:
                issues.append(f"Hoge error rate: {stats['avg']*100}%")
            elif metric == "cache_hit_rate" and stats["avg"] < self.thresholds[metric]:
                issues.append(f"Lage cache hit rate: {stats['avg']*100}%")
        
        return {
            "metrics": metrics,
            "issues": issues
        }
```

## Best Practices

### 1. Query Optimalisatie

```python
class QueryOptimizer:
    def __init__(self):
        self.logger = logging.getLogger(__name__)

    def optimize_query(self, query: str) -> str:
        # Verwijder onnodige velden
        query = self._remove_unnecessary_fields(query)
        
        # Voeg filters toe waar mogelijk
        query = self._add_filters(query)
        
        # Optimaliseer sortering
        query = self._optimize_sorting(query)
        
        return query

    def _remove_unnecessary_fields(self, query: str) -> str:
        # Implementeer logica voor het verwijderen van onnodige velden
        pass

    def _add_filters(self, query: str) -> str:
        # Implementeer logica voor het toevoegen van filters
        pass

    def _optimize_sorting(self, query: str) -> str:
        # Implementeer logica voor het optimaliseren van sortering
        pass
```

### 2. Resource Cleanup

```python
class ResourceCleanup:
    def __init__(self):
        self.resources = []
        self.lock = asyncio.Lock()

    async def register_resource(self, resource: Any):
        async with self.lock:
            self.resources.append(resource)

    async def cleanup(self):
        async with self.lock:
            for resource in self.resources:
                try:
                    await self._cleanup_resource(resource)
                except Exception as e:
                    logging.error(f"Error cleaning up resource: {str(e)}")
            self.resources.clear()

    async def _cleanup_resource(self, resource: Any):
        # Implementeer resource cleanup logica
        pass
```

## Volgende Stap

Nu je bekend bent met performance optimalisatie, gaan we in de volgende les kijken naar [monitoring en logging](05_04_monitoring.md). Daar leren we hoe we onze integratie kunnen monitoren en debuggen. 