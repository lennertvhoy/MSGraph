# Geavanceerde Python Concepten

In deze les gaan we dieper in op geavanceerde Python concepten die je helpen om krachtigere en efficiëntere code te schrijven. Deze concepten zijn vooral nuttig bij het werken met de Microsoft Graph API.

## Object-Oriented Programming

### Classes en Objects

```python
from dataclasses import dataclass
from datetime import datetime
from typing import List, Optional

@dataclass
class User:
    id: str
    display_name: str
    email: str
    department: Optional[str] = None
    last_login: Optional[datetime] = None
    is_active: bool = True

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "displayName": self.display_name,
            "email": self.email,
            "department": self.department,
            "lastLogin": self.last_login.isoformat() if self.last_login else None,
            "isActive": self.is_active
        }

    @classmethod
    def from_graph(cls, graph_user: dict) -> 'User':
        return cls(
            id=graph_user["id"],
            display_name=graph_user["displayName"],
            email=graph_user["userPrincipalName"],
            department=graph_user.get("department"),
            last_login=datetime.fromisoformat(graph_user["lastSignInDateTime"]) if "lastSignInDateTime" in graph_user else None,
            is_active=graph_user.get("accountEnabled", True)
        )
```

### Inheritance

```python
class GraphUser(User):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.graph_id = kwargs.get('graph_id')
        self.manager = None

    def set_manager(self, manager: 'GraphUser'):
        self.manager = manager

    def get_direct_reports(self) -> List['GraphUser']:
        # Implementatie voor het ophalen van direct reports
        pass

class AdminUser(GraphUser):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.admin_roles = kwargs.get('admin_roles', [])

    def has_role(self, role: str) -> bool:
        return role in self.admin_roles
```

## Decorators

### Function Decorators

```python
from functools import wraps
import time
import logging

def log_execution(func):
    @wraps(func)
    async def wrapper(*args, **kwargs):
        start_time = time.time()
        try:
            result = await func(*args, **kwargs)
            execution_time = time.time() - start_time
            logging.info(f"{func.__name__} executed in {execution_time:.2f} seconds")
            return result
        except Exception as e:
            logging.error(f"Error in {func.__name__}: {str(e)}")
            raise
    return wrapper

# Gebruik
@log_execution
async def get_user_details(user_id: str):
    # Implementatie
    pass
```

### Class Decorators

```python
def singleton(cls):
    instances = {}
    
    def get_instance(*args, **kwargs):
        if cls not in instances:
            instances[cls] = cls(*args, **kwargs)
        return instances[cls]
    
    return get_instance

@singleton
class GraphClient:
    def __init__(self):
        # Initialisatie code
        pass
```

## Generators

### Basis Generators

```python
def user_generator(users: List[dict]):
    for user in users:
        yield User.from_graph(user)

# Gebruik
async def process_users():
    users = await get_users()
    for user in user_generator(users):
        print(f"Processing user: {user.display_name}")
```

### Async Generators

```python
async def async_user_generator():
    users = await get_users()
    for user in users:
        yield User.from_graph(user)
        await asyncio.sleep(0.1)  # Rate limiting

# Gebruik
async def process_users_async():
    async for user in async_user_generator():
        print(f"Processing user: {user.display_name}")
```

## Asynchrone Programmering

### Async/Await

```python
import asyncio
from typing import List

async def get_user_details_parallel(user_ids: List[str]) -> List[User]:
    tasks = [get_user(user_id) for user_id in user_ids]
    users = await asyncio.gather(*tasks)
    return [User.from_graph(user) for user in users]

async def process_user_batches(user_ids: List[str], batch_size: int = 10):
    for i in range(0, len(user_ids), batch_size):
        batch = user_ids[i:i + batch_size]
        users = await get_user_details_parallel(batch)
        # Verwerk batch
        await asyncio.sleep(1)  # Rate limiting
```

### Async Context Managers

```python
class AsyncGraphClient:
    def __init__(self):
        self.client = None

    async def __aenter__(self):
        self.client = await create_graph_client()
        return self.client

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.client:
            await self.client.close()

# Gebruik
async def process_with_client():
    async with AsyncGraphClient() as client:
        users = await client.users.get()
        return users.value
```

## Type Hints en Annotations

### Geavanceerde Type Hints

```python
from typing import TypeVar, Generic, Optional, Union, Dict, List, Any
from datetime import datetime

T = TypeVar('T')

class GraphResponse(Generic[T]):
    def __init__(self, data: T):
        self.data = data
        self.timestamp = datetime.now()

    def get_data(self) -> T:
        return self.data

class UserManager:
    def __init__(self):
        self.users: Dict[str, User] = {}
        self.cache: Optional[Dict[str, Any]] = None

    def get_user(self, user_id: str) -> Optional[User]:
        return self.users.get(user_id)

    def add_user(self, user: User) -> None:
        self.users[user.id] = user
```

## Best Practices

### Code Organisatie

```python
# project_structure.py
from pathlib import Path
from typing import List

class ProjectStructure:
    def __init__(self, root_dir: Path):
        self.root_dir = root_dir
        self.config_dir = root_dir / "config"
        self.logs_dir = root_dir / "logs"
        self.data_dir = root_dir / "data"

    def setup(self) -> None:
        """Create project directory structure"""
        for directory in [self.config_dir, self.logs_dir, self.data_dir]:
            directory.mkdir(parents=True, exist_ok=True)

    def get_config_files(self) -> List[Path]:
        """Get all config files"""
        return list(self.config_dir.glob("*.json"))
```

### Error Handling

```python
class GraphAPIError(Exception):
    def __init__(self, message: str, status_code: int, details: dict):
        self.message = message
        self.status_code = status_code
        self.details = details
        super().__init__(self.message)

async def handle_graph_error(func):
    @wraps(func)
    async def wrapper(*args, **kwargs):
        try:
            return await func(*args, **kwargs)
        except Exception as e:
            if hasattr(e, 'status_code'):
                raise GraphAPIError(
                    message=str(e),
                    status_code=e.status_code,
                    details=getattr(e, 'details', {})
                )
            raise
    return wrapper
```

## Volgende Stap

Nu je de geavanceerde Python concepten kent, gaan we in de volgende les kijken naar [data verwerking en I/O](03_04_data_io.md). Daar leren we hoe we efficiënt kunnen werken met bestanden, CSV's, JSON en logging. 