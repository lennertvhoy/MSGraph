# Geavanceerde API Technieken

In deze les gaan we kijken naar geavanceerde technieken voor het werken met de Microsoft Graph API. We behandelen batch requests, delta queries, change notifications en andere geavanceerde functionaliteit.

## Batch Requests

### Basis Batch Request

```python
class BatchRequestHandler:
    def __init__(self, graph_client):
        self.graph_client = graph_client

    async def batch_get_users(self, user_ids: List[str]):
        requests = []
        for user_id in user_ids:
            requests.append({
                "id": user_id,
                "method": "GET",
                "url": f"/users/{user_id}"
            })
        
        batch = {
            "requests": requests
        }
        
        response = await self.graph_client.batch.post(batch)
        return response
```

### Geavanceerde Batch Request

```python
class AdvancedBatchHandler:
    def __init__(self, graph_client):
        self.graph_client = graph_client

    async def batch_mixed_operations(self, operations: List[dict]):
        requests = []
        for op in operations:
            request = {
                "id": op['id'],
                "method": op['method'],
                "url": op['url']
            }
            
            if 'body' in op:
                request['body'] = op['body']
            
            if 'headers' in op:
                request['headers'] = op['headers']
            
            requests.append(request)
        
        batch = {
            "requests": requests
        }
        
        response = await self.graph_client.batch.post(batch)
        return self._process_batch_response(response)
```

## Delta Queries

### Basis Delta Query

```python
class DeltaQueryHandler:
    def __init__(self, graph_client):
        self.graph_client = graph_client
        self.delta_tokens = {}

    async def get_user_changes(self, delta_token: str = None):
        url = "/users/delta"
        if delta_token:
            url += f"?$deltatoken={delta_token}"
        
        response = await self.graph_client.users.delta.get()
        return {
            'items': response.value,
            'next_link': response.odata_next_link,
            'delta_token': response.odata_delta_link
        }
```

### Geavanceerde Delta Query

```python
class AdvancedDeltaHandler:
    def __init__(self, graph_client):
        self.graph_client = graph_client
        self.state_store = {}

    async def track_changes(self, resource_type: str, delta_token: str = None):
        url = f"/{resource_type}/delta"
        if delta_token:
            url += f"?$deltatoken={delta_token}"
        
        response = await self.graph_client.request('GET', url)
        
        # Verwerk veranderingen
        changes = self._process_changes(response.value)
        
        # Update state
        self.state_store[resource_type] = {
            'delta_token': response.odata_delta_link,
            'last_sync': datetime.now()
        }
        
        return changes
```

## Change Notifications

### Basis Change Notification

```python
class ChangeNotificationHandler:
    def __init__(self, graph_client):
        self.graph_client = graph_client
        self.subscriptions = {}

    async def create_subscription(self, resource: str, expiration: datetime):
        subscription = {
            "changeType": "created,updated,deleted",
            "notificationUrl": "https://your-webhook-url.com/notifications",
            "resource": resource,
            "expirationDateTime": expiration.isoformat()
        }
        
        response = await self.graph_client.subscriptions.post(subscription)
        self.subscriptions[response.id] = response
        return response
```

### Geavanceerde Change Notification

```python
class AdvancedNotificationHandler:
    def __init__(self, graph_client):
        self.graph_client = graph_client
        self.subscriptions = {}
        self.notification_processor = NotificationProcessor()

    async def manage_subscriptions(self):
        # Haal bestaande subscriptions op
        subscriptions = await self.graph_client.subscriptions.get()
        
        # Verwerk verlopen subscriptions
        for sub in subscriptions.value:
            if datetime.fromisoformat(sub.expirationDateTime) < datetime.now():
                await self._renew_subscription(sub)
            else:
                self.subscriptions[sub.id] = sub
```

## Geavanceerde Query Technieken

### Filtering en Sortering

```python
class AdvancedQueryHandler:
    def __init__(self, graph_client):
        self.graph_client = graph_client

    async def complex_query(self, resource: str, filters: List[dict], sort_by: str = None):
        query = f"/{resource}"
        
        # Voeg filters toe
        if filters:
            filter_string = " and ".join([
                f"{f['field']} {f['operator']} '{f['value']}'"
                for f in filters
            ])
            query += f"?$filter={filter_string}"
        
        # Voeg sortering toe
        if sort_by:
            separator = "&" if "?" in query else "?"
            query += f"{separator}$orderby={sort_by}"
        
        response = await self.graph_client.request('GET', query)
        return response.value
```

### Paginering en Expansie

```python
class PaginationHandler:
    def __init__(self, graph_client):
        self.graph_client = graph_client

    async def get_all_items(self, resource: str, expand: str = None):
        items = []
        url = f"/{resource}"
        
        if expand:
            url += f"?$expand={expand}"
        
        response = await self.graph_client.request('GET', url)
        items.extend(response.value)
        
        while response.odata_next_link:
            response = await self.graph_client.request('GET', response.odata_next_link)
            items.extend(response.value)
        
        return items
```

## Best Practices

### 1. Rate Limiting

```python
class RateLimitHandler:
    def __init__(self, max_requests: int = 100, time_window: int = 60):
        self.max_requests = max_requests
        self.time_window = time_window
        self.requests = []
        self.lock = asyncio.Lock()

    async def wait_if_needed(self):
        async with self.lock:
            now = time.time()
            self.requests = [req for req in self.requests if now - req < self.time_window]
            
            if len(self.requests) >= self.max_requests:
                wait_time = self.requests[0] + self.time_window - now
                await asyncio.sleep(wait_time)
            
            self.requests.append(now)
```

### 2. Error Handling

```python
class AdvancedErrorHandler:
    def __init__(self):
        self.logger = logging.getLogger(__name__)

    async def handle_graph_error(self, error):
        if isinstance(error, ODataError):
            await self._handle_odata_error(error)
        elif isinstance(error, BatchRequestError):
            await self._handle_batch_error(error)
        else:
            await self._handle_general_error(error)

    async def _handle_odata_error(self, error):
        error_code = error.error.code
        error_message = error.error.message
        
        if error_code == "Authorization_RequestDenied":
            self.logger.error(f"Geen toegang: {error_message}")
        elif error_code == "Request_ResourceNotFound":
            self.logger.error(f"Resource niet gevonden: {error_message}")
        else:
            self.logger.error(f"Graph API Error: {error_message}")
```

### 3. Caching en State Management

```python
class StateManager:
    def __init__(self):
        self.state = {}
        self.lock = asyncio.Lock()

    async def update_state(self, key: str, value: Any):
        async with self.lock:
            self.state[key] = {
                'value': value,
                'timestamp': time.time()
            }

    async def get_state(self, key: str, ttl: int = 300):
        async with self.lock:
            if key in self.state:
                state = self.state[key]
                if time.time() - state['timestamp'] < ttl:
                    return state['value']
            return None
```

## Volgende Stap

Nu je bekend bent met de geavanceerde API technieken, gaan we in de volgende les kijken naar [praktische oefeningen](04_05_praktische_oefeningen.md). Daar ga je deze technieken in de praktijk toepassen door verschillende scenario's uit te werken. 