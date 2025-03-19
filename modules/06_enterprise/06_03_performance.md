# Performance en Schaalbaarheid

In deze les gaan we kijken naar verschillende aspecten van performance en schaalbaarheid voor enterprise-level applicaties met de Microsoft Graph API. We behandelen load balancing, caching, rate limiting en resource optimalisatie.

## Load Balancing

### Service Load Balancer

```python
from typing import List, Dict
import random
import asyncio

class ServiceLoadBalancer:
    def __init__(self):
        self.services: Dict[str, List[str]] = {}
        self.health_checks: Dict[str, bool] = {}
        self.logger = logging.getLogger(__name__)

    def add_service(self, service_type: str, endpoint: str):
        if service_type not in self.services:
            self.services[service_type] = []
        self.services[service_type].append(endpoint)
        self.health_checks[endpoint] = True
        self.logger.info(f"Added service endpoint: {endpoint}")

    async def get_healthy_endpoint(self, service_type: str) -> str:
        try:
            if service_type not in self.services:
                raise ValueError(f"Service type {service_type} not found")
            
            healthy_endpoints = [
                endpoint for endpoint in self.services[service_type]
                if self.health_checks.get(endpoint, False)
            ]
            
            if not healthy_endpoints:
                raise RuntimeError(f"No healthy endpoints found for {service_type}")
            
            return random.choice(healthy_endpoints)
        except Exception as e:
            self.logger.error(f"Error getting healthy endpoint: {str(e)}")
            raise

    async def check_health(self, endpoint: str):
        try:
            # Implementeer health check logica
            self.health_checks[endpoint] = True
        except Exception as e:
            self.health_checks[endpoint] = False
            self.logger.error(f"Health check failed for {endpoint}: {str(e)}")
```

### Request Distribution

```python
class RequestDistributor:
    def __init__(self, load_balancer: ServiceLoadBalancer):
        self.load_balancer = load_balancer
        self.request_counts: Dict[str, int] = {}
        self.logger = logging.getLogger(__name__)

    async def distribute_request(self, service_type: str, request_data: dict):
        try:
            endpoint = await self.load_balancer.get_healthy_endpoint(service_type)
            self.request_counts[endpoint] = self.request_counts.get(endpoint, 0) + 1
            
            # Implementeer request distribution logica
            self.logger.info(
                f"Distributed request to {endpoint}",
                service_type=service_type,
                request_count=self.request_counts[endpoint]
            )
        except Exception as e:
            self.logger.error(f"Error distributing request: {str(e)}")
            raise
```

## Caching Strategies

### Distributed Cache

```python
from redis import Redis
import json
from typing import Any, Optional

class DistributedCache:
    def __init__(self, redis_url: str):
        self.redis = Redis.from_url(redis_url)
        self.logger = logging.getLogger(__name__)

    async def get(self, key: str) -> Optional[Any]:
        try:
            data = self.redis.get(key)
            if data:
                return json.loads(data)
            return None
        except Exception as e:
            self.logger.error(f"Error getting from cache: {str(e)}")
            return None

    async def set(self, key: str, value: Any, ttl: int = 3600):
        try:
            self.redis.setex(
                key,
                ttl,
                json.dumps(value)
            )
        except Exception as e:
            self.logger.error(f"Error setting cache: {str(e)}")
            raise

    async def delete(self, key: str):
        try:
            self.redis.delete(key)
        except Exception as e:
            self.logger.error(f"Error deleting from cache: {str(e)}")
            raise
```

### Cache Manager

```python
class CacheManager:
    def __init__(self, cache: DistributedCache):
        self.cache = cache
        self.logger = logging.getLogger(__name__)

    async def get_or_set(self, key: str, getter_func, ttl: int = 3600) -> Any:
        try:
            cached_value = await self.cache.get(key)
            if cached_value is not None:
                return cached_value
            
            value = await getter_func()
            await self.cache.set(key, value, ttl)
            return value
        except Exception as e:
            self.logger.error(f"Error in get_or_set: {str(e)}")
            raise
```

## Rate Limiting

### Adaptive Rate Limiter

```python
from datetime import datetime, timedelta
from collections import defaultdict

class AdaptiveRateLimiter:
    def __init__(self, max_requests: int = 100, time_window: int = 60):
        self.max_requests = max_requests
        self.time_window = time_window
        self.requests = defaultdict(list)
        self.logger = logging.getLogger(__name__)

    async def check_rate_limit(self, client_id: str) -> bool:
        try:
            now = datetime.utcnow()
            window_start = now - timedelta(seconds=self.time_window)
            
            # Verwijder oude requests
            self.requests[client_id] = [
                req_time for req_time in self.requests[client_id]
                if req_time > window_start
            ]
            
            if len(self.requests[client_id]) >= self.max_requests:
                self.logger.warning(
                    f"Rate limit exceeded for client: {client_id}"
                )
                return False
            
            self.requests[client_id].append(now)
            return True
        except Exception as e:
            self.logger.error(f"Error checking rate limit: {str(e)}")
            return False
```

### Rate Limit Handler

```python
class RateLimitHandler:
    def __init__(self, rate_limiter: AdaptiveRateLimiter):
        self.rate_limiter = rate_limiter
        self.logger = logging.getLogger(__name__)

    async def handle_request(self, client_id: str, request_func):
        try:
            if not await self.rate_limiter.check_rate_limit(client_id):
                raise RuntimeError("Rate limit exceeded")
            
            return await request_func()
        except Exception as e:
            self.logger.error(f"Error handling rate-limited request: {str(e)}")
            raise
```

## Resource Optimization

### Connection Pooling

```python
from aiohttp import ClientSession, TCPConnector
from contextlib import asynccontextmanager

class ConnectionPool:
    def __init__(self, max_connections: int = 100):
        self.max_connections = max_connections
        self.connector = TCPConnector(limit=max_connections)
        self.logger = logging.getLogger(__name__)

    @asynccontextmanager
    async def get_session(self):
        session = None
        try:
            session = ClientSession(connector=self.connector)
            yield session
        finally:
            if session:
                await session.close()

    async def close(self):
        await self.connector.close()
```

### Resource Manager

```python
class ResourceManager:
    def __init__(self, connection_pool: ConnectionPool):
        self.connection_pool = connection_pool
        self.active_connections = 0
        self.logger = logging.getLogger(__name__)

    async def acquire_connection(self):
        try:
            if self.active_connections >= self.connection_pool.max_connections:
                raise RuntimeError("Maximum connections reached")
            
            self.active_connections += 1
            return await self.connection_pool.get_session()
        except Exception as e:
            self.logger.error(f"Error acquiring connection: {str(e)}")
            raise

    async def release_connection(self):
        self.active_connections -= 1
```

## Performance Monitoring

### Metrics Collector

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
        self.logger = logging.getLogger(__name__)

    def record_request(self, endpoint: str, method: str, status: int, duration: float):
        try:
            self.request_counter.labels(
                endpoint=endpoint,
                method=method,
                status=status
            ).inc()
            self.request_duration.labels(endpoint=endpoint).observe(duration)
        except Exception as e:
            self.logger.error(f"Error recording metrics: {str(e)}")

    def record_error(self, error_type: str):
        self.error_counter.labels(error_type=error_type).inc()

    def set_active_requests(self, count: int):
        self.active_requests.set(count)
```

### Performance Analyzer

```python
class PerformanceAnalyzer:
    def __init__(self, metrics_collector: MetricsCollector):
        self.metrics_collector = metrics_collector
        self.logger = logging.getLogger(__name__)

    async def analyze_performance(self):
        try:
            # Implementeer performance analyse logica
            pass
        except Exception as e:
            self.logger.error(f"Error analyzing performance: {str(e)}")
            raise
```

## Best Practices

### 1. Query Optimization

```python
class QueryOptimizer:
    def __init__(self):
        self.logger = logging.getLogger(__name__)

    def optimize_query(self, query: str) -> str:
        try:
            # Implementeer query optimalisatie logica
            return query
        except Exception as e:
            self.logger.error(f"Error optimizing query: {str(e)}")
            return query

    def add_expansion(self, query: str, expand: List[str]) -> str:
        try:
            if '?' in query:
                return f"{query}&$expand={','.join(expand)}"
            return f"{query}?$expand={','.join(expand)}"
        except Exception as e:
            self.logger.error(f"Error adding expansion: {str(e)}")
            return query
```

### 2. Resource Cleanup

```python
class ResourceCleanup:
    def __init__(self):
        self.resources = []
        self.logger = logging.getLogger(__name__)

    def register_resource(self, resource):
        self.resources.append(resource)
        self.logger.info(f"Registered resource: {resource}")

    async def cleanup(self):
        try:
            for resource in self.resources:
                if hasattr(resource, 'close'):
                    await resource.close()
                elif hasattr(resource, '__aenter__'):
                    await resource.__aexit__(None, None, None)
            self.resources.clear()
        except Exception as e:
            self.logger.error(f"Error during cleanup: {str(e)}")
            raise
```

## Volgende Stap

Nu je bekend bent met performance en schaalbaarheid, gaan we in de volgende les kijken naar [monitoring en logging](06_04_monitoring.md). Daar leren we hoe we onze enterprise applicaties kunnen monitoren en debuggen. 