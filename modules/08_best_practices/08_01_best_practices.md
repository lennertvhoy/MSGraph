# Best Practices

In deze les gaan we kijken naar verschillende best practices voor het werken met de Microsoft Graph API. We behandelen code structuur, error handling, performance optimalisatie en security.

## Code Structuur en Organisatie

### Project Structuur

```python
# project_structure.py
from typing import Dict, List
import logging
from pathlib import Path

class ProjectStructure:
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        self.setup_project_structure()

    def setup_project_structure(self):
        try:
            # Maak basis project structuur
            directories = [
                "src",
                "src/api",
                "src/services",
                "src/models",
                "src/utils",
                "tests",
                "config",
                "docs"
            ]
            
            for directory in directories:
                Path(directory).mkdir(parents=True, exist_ok=True)
                
            self.create_base_files()
        except Exception as e:
            self.logger.error(f"Error setting up project structure: {str(e)}")
            raise

    def create_base_files(self):
        try:
            # Maak basis bestanden
            files = {
                "src/__init__.py": "",
                "src/api/__init__.py": "",
                "src/services/__init__.py": "",
                "src/models/__init__.py": "",
                "src/utils/__init__.py": "",
                "tests/__init__.py": "",
                "config/config.py": self.get_config_template(),
                "README.md": self.get_readme_template()
            }
            
            for file_path, content in files.items():
                Path(file_path).write_text(content)
        except Exception as e:
            self.logger.error(f"Error creating base files: {str(e)}")
            raise

    def get_config_template(self) -> str:
        return """
from typing import Dict, any
import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    def __init__(self):
        self.tenant_id = os.getenv("AZURE_TENANT_ID")
        self.client_id = os.getenv("AZURE_CLIENT_ID")
        self.client_secret = os.getenv("AZURE_CLIENT_SECRET")
        self.graph_api_url = "https://graph.microsoft.com/v1.0"
        
    @property
    def auth_config(self) -> Dict[str, any]:
        return {
            "tenant_id": self.tenant_id,
            "client_id": self.client_id,
            "client_secret": self.client_secret
        }
"""

    def get_readme_template(self) -> str:
        return """
# Microsoft Graph API Project

## Beschrijving
Beschrijf hier je project.

## Installatie
```bash
pip install -r requirements.txt
```

## Gebruik
Beschrijf hier hoe je het project gebruikt.

## Configuratie
Maak een `.env` bestand aan met de volgende variabelen:
```
AZURE_TENANT_ID=your_tenant_id
AZURE_CLIENT_ID=your_client_id
AZURE_CLIENT_SECRET=your_client_secret
```

## Tests
```bash
pytest
```
"""
```

### Dependency Management

```python
# dependency_manager.py
from typing import Dict, List
import logging
import pkg_resources

class DependencyManager:
    def __init__(self):
        self.logger = logging.getLogger(__name__)

    def check_dependencies(self) -> Dict[str, str]:
        try:
            required = {
                "msgraph-core": "1.0.0",
                "azure-identity": "1.0.0",
                "python-dotenv": "0.19.0"
            }
            
            installed = {
                pkg.key: pkg.version
                for pkg in pkg_resources.working_set
            }
            
            return {
                package: version
                for package, version in required.items()
                if package in installed and installed[package] >= version
            }
        except Exception as e:
            self.logger.error(f"Error checking dependencies: {str(e)}")
            raise

    def generate_requirements(self) -> str:
        try:
            return "\n".join([
                f"{pkg.key}=={pkg.version}"
                for pkg in pkg_resources.working_set
            ])
        except Exception as e:
            self.logger.error(f"Error generating requirements: {str(e)}")
            raise
```

## Error Handling en Logging

### Error Handler

```python
# error_handler.py
from typing import Dict, any
import logging
from datetime import datetime

class ErrorHandler:
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        self.setup_logging()

    def setup_logging(self):
        try:
            logging.basicConfig(
                level=logging.INFO,
                format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
                handlers=[
                    logging.FileHandler('app.log'),
                    logging.StreamHandler()
                ]
            )
        except Exception as e:
            print(f"Error setting up logging: {str(e)}")
            raise

    async def handle_error(self, error: Exception, context: Dict[str, any]):
        try:
            error_data = {
                "timestamp": datetime.utcnow().isoformat(),
                "error_type": type(error).__name__,
                "error_message": str(error),
                "context": context
            }
            
            self.logger.error(
                f"Error occurred: {error_data['error_type']}",
                extra=error_data
            )
            
            return await self.recover_from_error(error_data)
        except Exception as e:
            self.logger.error(f"Error handling error: {str(e)}")
            raise

    async def recover_from_error(self, error_data: Dict[str, any]):
        try:
            # Implementeer recovery logica
            pass
        except Exception as e:
            self.logger.error(f"Error in recovery process: {str(e)}")
            raise
```

### Retry Logic

```python
# retry_handler.py
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

## Performance Optimalisatie

### Cache Manager

```python
# cache_manager.py
from typing import Dict, any, Optional
import logging
import json
from datetime import datetime, timedelta

class CacheManager:
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        self.cache: Dict[str, Dict[str, any]] = {}

    async def get(self, key: str) -> Optional[Dict[str, any]]:
        try:
            if key in self.cache:
                cache_entry = self.cache[key]
                if datetime.fromisoformat(cache_entry["expires_at"]) > datetime.utcnow():
                    return cache_entry["data"]
                else:
                    del self.cache[key]
            return None
        except Exception as e:
            self.logger.error(f"Error getting from cache: {str(e)}")
            raise

    async def set(self, key: str, data: any, ttl: int = 300):
        try:
            self.cache[key] = {
                "data": data,
                "expires_at": (datetime.utcnow() + timedelta(seconds=ttl)).isoformat()
            }
        except Exception as e:
            self.logger.error(f"Error setting cache: {str(e)}")
            raise

    async def delete(self, key: str):
        try:
            if key in self.cache:
                del self.cache[key]
        except Exception as e:
            self.logger.error(f"Error deleting from cache: {str(e)}")
            raise
```

### Batch Processor

```python
# batch_processor.py
from typing import List, Dict, any, Callable
import logging
import asyncio

class BatchProcessor:
    def __init__(self):
        self.logger = logging.getLogger(__name__)

    async def process_batch(self, items: List[Dict[str, any]], 
                          processor: Callable, 
                          batch_size: int = 10):
        try:
            for i in range(0, len(items), batch_size):
                batch = items[i:i + batch_size]
                tasks = [processor(item) for item in batch]
                await asyncio.gather(*tasks)
        except Exception as e:
            self.logger.error(f"Error processing batch: {str(e)}")
            raise

    async def process_with_retry(self, items: List[Dict[str, any]], 
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

## Security Best Practices

### Security Manager

```python
# security_manager.py
from typing import Dict, any
import logging
from datetime import datetime, timedelta
import jwt
from azure.identity import DefaultAzureCredential

class SecurityManager:
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        self.credential = DefaultAzureCredential()

    async def validate_token(self, token: str) -> bool:
        try:
            # Implementeer token validatie logica
            return True
        except Exception as e:
            self.logger.error(f"Error validating token: {str(e)}")
            raise

    async def generate_token(self, claims: Dict[str, any]) -> str:
        try:
            # Implementeer token generatie logica
            return "token"
        except Exception as e:
            self.logger.error(f"Error generating token: {str(e)}")
            raise

    async def rotate_credentials(self):
        try:
            # Implementeer credential rotatie logica
            pass
        except Exception as e:
            self.logger.error(f"Error rotating credentials: {str(e)}")
            raise
```

### Rate Limiter

```python
# rate_limiter.py
from typing import Dict, any
import logging
import time
from datetime import datetime, timedelta

class RateLimiter:
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        self.requests: Dict[str, List[datetime]] = {}

    async def check_rate_limit(self, key: str, 
                             max_requests: int = 100, 
                             time_window: int = 60) -> bool:
        try:
            now = datetime.utcnow()
            
            if key not in self.requests:
                self.requests[key] = []
            
            # Verwijder oude requests
            self.requests[key] = [
                req_time for req_time in self.requests[key]
                if now - req_time < timedelta(seconds=time_window)
            ]
            
            if len(self.requests[key]) >= max_requests:
                return False
            
            self.requests[key].append(now)
            return True
        except Exception as e:
            self.logger.error(f"Error checking rate limit: {str(e)}")
            raise

    async def get_wait_time(self, key: str, 
                          max_requests: int = 100, 
                          time_window: int = 60) -> float:
        try:
            if key not in self.requests:
                return 0
            
            now = datetime.utcnow()
            old_requests = [
                req_time for req_time in self.requests[key]
                if now - req_time < timedelta(seconds=time_window)
            ]
            
            if len(old_requests) >= max_requests:
                return (old_requests[0] + timedelta(seconds=time_window) - now).total_seconds()
            
            return 0
        except Exception as e:
            self.logger.error(f"Error getting wait time: {str(e)}")
            raise
```

## Volgende Stap

Nu je bekend bent met best practices, gaan we in de volgende les kijken naar [debugging technieken](08_02_debugging.md). Daar leren we hoe we effectief kunnen debuggen en problemen kunnen oplossen. 