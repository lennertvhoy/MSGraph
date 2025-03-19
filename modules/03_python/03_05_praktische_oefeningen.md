# Praktische Oefeningen

In deze les gaan we de kennis die we hebben opgedaan in praktijk brengen met een aantal oefeningen. Deze oefeningen zijn ontworpen om je te helpen met het ontwikkelen van praktische vaardigheden in Python, specifiek gericht op het werken met de Microsoft Graph API.

## Oefening 1: User Management Systeem

### Doel
Ontwikkel een systeem voor het beheren van gebruikersgegevens met de Microsoft Graph API, inclusief het opslaan van data in verschillende formaten en het implementeren van logging.

### Stappen

1. **Maak een nieuwe Python module `user_management.py`**:
   ```python
   from dataclasses import dataclass
   from datetime import datetime
   from typing import List, Optional
   from pathlib import Path
   import json
   import csv
   import logging
   from msgraph import GraphServiceClient
   from azure.identity import ClientSecretCredential

   @dataclass
   class User:
       id: str
       display_name: str
       email: str
       department: Optional[str] = None
       created_at: datetime = datetime.now()
       last_login: Optional[datetime] = None

   class UserManagementSystem:
       def __init__(self, config_path: Path):
           self.config = self._load_config(config_path)
           self.graph_client = self._setup_graph_client()
           self.logger = self._setup_logger()

       def _load_config(self, config_path: Path) -> dict:
           """Laad configuratie uit JSON bestand"""
           with config_path.open('r') as f:
               return json.load(f)

       def _setup_graph_client(self) -> GraphServiceClient:
           """Setup Microsoft Graph client"""
           credentials = ClientSecretCredential(
               tenant_id=self.config['tenant_id'],
               client_id=self.config['client_id'],
               client_secret=self.config['client_secret']
           )
           return GraphServiceClient(credentials=credentials)

       def _setup_logger(self) -> logging.Logger:
           """Setup logging"""
           logger = logging.getLogger('user_management')
           logger.setLevel(logging.INFO)
           
           # File handler
           fh = logging.FileHandler('user_management.log')
           fh.setFormatter(logging.Formatter(
               '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
           ))
           logger.addHandler(fh)
           
           return logger

       async def get_users(self) -> List[User]:
           """Haal gebruikers op van Microsoft Graph"""
           try:
               users = await self.graph_client.users.get()
               return [
                   User(
                       id=user.id,
                       display_name=user.display_name,
                       email=user.mail,
                       department=user.department
                   )
                   for user in users.value
               ]
           except Exception as e:
               self.logger.error(f"Fout bij ophalen gebruikers: {str(e)}")
               raise

       def export_users_csv(self, users: List[User], output_path: Path) -> None:
           """Exporteer gebruikers naar CSV"""
           try:
               with output_path.open('w', newline='') as f:
                   writer = csv.DictWriter(f, fieldnames=[
                       'id', 'display_name', 'email', 'department',
                       'created_at', 'last_login'
                   ])
                   writer.writeheader()
                   writer.writerows([vars(user) for user in users])
               self.logger.info(f"Gebruikers geëxporteerd naar {output_path}")
           except Exception as e:
               self.logger.error(f"Fout bij exporteren CSV: {str(e)}")
               raise

       def export_users_json(self, users: List[User], output_path: Path) -> None:
           """Exporteer gebruikers naar JSON"""
           try:
               with output_path.open('w') as f:
                   json.dump(
                       [vars(user) for user in users],
                       f,
                       indent=2,
                       default=str
                   )
               self.logger.info(f"Gebruikers geëxporteerd naar {output_path}")
           except Exception as e:
               self.logger.error(f"Fout bij exporteren JSON: {str(e)}")
               raise
   ```

2. **Maak een script `main.py` om het systeem te testen**:
   ```python
   import asyncio
   from pathlib import Path
   from user_management import UserManagementSystem

   async def main():
       # Initialiseer het systeem
       config_path = Path('config.json')
       system = UserManagementSystem(config_path)

       try:
           # Haal gebruikers op
           users = await system.get_users()
           
           # Exporteer naar verschillende formaten
           system.export_users_csv(users, Path('users.csv'))
           system.export_users_json(users, Path('users.json'))
           
           print(f"Succesvol {len(users)} gebruikers verwerkt")
       except Exception as e:
           print(f"Fout: {str(e)}")

   if __name__ == '__main__':
       asyncio.run(main())
   ```

3. **Maak een configuratiebestand `config.json`**:
   ```json
   {
       "tenant_id": "your-tenant-id",
       "client_id": "your-client-id",
       "client_secret": "your-client-secret"
   }
   ```

### Verificatie
1. Controleer of het script succesvol draait
2. Verifieer dat de CSV en JSON bestanden correct worden aangemaakt
3. Controleer de logbestanden voor eventuele fouten
4. Valideer de geëxporteerde data

## Oefening 2: Asynchrone Data Verwerking

### Doel
Ontwikkel een systeem voor het asynchroon verwerken van grote datasets met de Microsoft Graph API.

### Stappen

1. **Maak een nieuwe Python module `async_processor.py`**:
   ```python
   from typing import List, Dict, Any, AsyncIterator
   import asyncio
   from pathlib import Path
   import json
   import logging
   from msgraph import GraphServiceClient
   from azure.identity import ClientSecretCredential

   class AsyncDataProcessor:
       def __init__(self, config_path: Path):
           self.config = self._load_config(config_path)
           self.graph_client = self._setup_graph_client()
           self.logger = self._setup_logger()

       def _load_config(self, config_path: Path) -> dict:
           """Laad configuratie"""
           with config_path.open('r') as f:
               return json.load(f)

       def _setup_graph_client(self) -> GraphServiceClient:
           """Setup Graph client"""
           credentials = ClientSecretCredential(
               tenant_id=self.config['tenant_id'],
               client_id=self.config['client_id'],
               client_secret=self.config['client_secret']
           )
           return GraphServiceClient(credentials=credentials)

       def _setup_logger(self) -> logging.Logger:
           """Setup logging"""
           logger = logging.getLogger('async_processor')
           logger.setLevel(logging.INFO)
           fh = logging.FileHandler('async_processor.log')
           fh.setFormatter(logging.Formatter(
               '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
           ))
           logger.addHandler(fh)
           return logger

       async def get_users_batch(self, batch_size: int = 100) -> AsyncIterator[List[Dict[str, Any]]]:
           """Haal gebruikers op in batches"""
           try:
               users = await self.graph_client.users.get()
               current_batch = []
               
               for user in users.value:
                   current_batch.append({
                       'id': user.id,
                       'display_name': user.display_name,
                       'email': user.mail,
                       'department': user.department
                   })
                   
                   if len(current_batch) >= batch_size:
                       yield current_batch
                       current_batch = []
               
               if current_batch:
                   yield current_batch
           except Exception as e:
               self.logger.error(f"Fout bij ophalen gebruikers: {str(e)}")
               raise

       async def process_user_batch(self, batch: List[Dict[str, Any]]) -> None:
           """Verwerk een batch gebruikers"""
           try:
               # Simuleer verwerking
               await asyncio.sleep(0.1)
               
               # Log verwerking
               self.logger.info(f"Verwerkt batch van {len(batch)} gebruikers")
               
               # Hier kun je extra verwerking toevoegen
               for user in batch:
                   if not user['email']:
                       self.logger.warning(
                           f"Gebruiker {user['display_name']} heeft geen email"
                       )
           except Exception as e:
               self.logger.error(f"Fout bij verwerken batch: {str(e)}")
               raise

       async def process_all_users(self, max_concurrent: int = 5) -> None:
           """Verwerk alle gebruikers met beperkt aantal gelijktijdige taken"""
           try:
               semaphore = asyncio.Semaphore(max_concurrent)
               
               async def process_with_semaphore(batch):
                   async with semaphore:
                       await self.process_user_batch(batch)

               tasks = []
               async for batch in self.get_users_batch():
                   tasks.append(process_with_semaphore(batch))

               await asyncio.gather(*tasks)
               self.logger.info("Alle gebruikers verwerkt")
           except Exception as e:
               self.logger.error(f"Fout bij verwerken alle gebruikers: {str(e)}")
               raise
   ```

2. **Maak een script `process_users.py` om de asynchrone verwerking te testen**:
   ```python
   import asyncio
   from pathlib import Path
   from async_processor import AsyncDataProcessor

   async def main():
       # Initialiseer de processor
       config_path = Path('config.json')
       processor = AsyncDataProcessor(config_path)

       try:
           # Verwerk alle gebruikers
           await processor.process_all_users(max_concurrent=5)
           print("Verwerking voltooid")
       except Exception as e:
           print(f"Fout: {str(e)}")

   if __name__ == '__main__':
       asyncio.run(main())
   ```

### Verificatie
1. Controleer of de asynchrone verwerking correct werkt
2. Verifieer dat het aantal gelijktijdige taken wordt beperkt
3. Controleer de logbestanden voor de verwerking
4. Meet de prestaties met verschillende batch groottes

## Oefening 3: Error Handling en Retry Logica

### Doel
Implementeer robuuste error handling en retry logica voor API calls.

### Stappen

1. **Maak een nieuwe Python module `retry_handler.py`**:
   ```python
   from typing import TypeVar, Callable, Any
   import asyncio
   import logging
   from functools import wraps
   from tenacity import retry, stop_after_attempt, wait_exponential

   T = TypeVar('T')

   class APIError(Exception):
       """Basis exception voor API fouten"""
       pass

   class RateLimitError(APIError):
       """Exception voor rate limiting"""
       pass

   class AuthenticationError(APIError):
       """Exception voor authenticatie fouten"""
       pass

   def handle_api_errors(func: Callable[..., Any]) -> Callable[..., Any]:
       """Decorator voor het afhandelen van API fouten"""
       @wraps(func)
       async def wrapper(*args, **kwargs):
           try:
               return await func(*args, **kwargs)
           except Exception as e:
               if 'rate limit' in str(e).lower():
                   raise RateLimitError(f"Rate limit bereikt: {str(e)}")
               elif 'unauthorized' in str(e).lower():
                   raise AuthenticationError(f"Authenticatie fout: {str(e)}")
               else:
                   raise APIError(f"Onverwachte API fout: {str(e)}")
       return wrapper

   @retry(
       stop=stop_after_attempt(3),
       wait=wait_exponential(multiplier=1, min=4, max=10),
       reraise=True
   )
   @handle_api_errors
   async def make_api_call(func: Callable[..., Any]) -> Callable[..., Any]:
       """Decorator voor het maken van API calls met retry logica"""
       @wraps(func)
       async def wrapper(*args, **kwargs):
           try:
               return await func(*args, **kwargs)
           except RateLimitError:
               logging.warning("Rate limit bereikt, wacht op retry")
               raise
           except AuthenticationError:
               logging.error("Authenticatie fout, geen retry")
               raise
           except APIError:
               logging.warning("API fout, probeer opnieuw")
               raise
       return wrapper

   class APIClient:
       def __init__(self):
           self.logger = logging.getLogger('api_client')

       @make_api_call
       async def get_user(self, user_id: str) -> dict:
           """Haal gebruiker op met retry logica"""
           # Simuleer API call
           await asyncio.sleep(1)
           if user_id == 'error':
               raise APIError("Test error")
           return {'id': user_id, 'name': 'Test User'}

       @make_api_call
       async def update_user(self, user_id: str, data: dict) -> dict:
           """Update gebruiker met retry logica"""
           # Simuleer API call
           await asyncio.sleep(1)
           if user_id == 'rate_limit':
               raise RateLimitError("Rate limit bereikt")
           return {'id': user_id, **data}
   ```

2. **Maak een script `test_retry.py` om de error handling te testen**:
   ```python
   import asyncio
   import logging
   from retry_handler import APIClient, APIError, RateLimitError, AuthenticationError

   async def main():
       # Setup logging
       logging.basicConfig(level=logging.INFO)
       logger = logging.getLogger(__name__)

       # Initialiseer client
       client = APIClient()

       try:
           # Test normale call
           user = await client.get_user('123')
           logger.info(f"Gebruiker opgehaald: {user}")

           # Test error handling
           try:
               await client.get_user('error')
           except APIError as e:
               logger.error(f"Verwachte API fout: {str(e)}")

           # Test rate limiting
           try:
               await client.update_user('rate_limit', {'name': 'New Name'})
           except RateLimitError as e:
               logger.error(f"Verwachte rate limit fout: {str(e)}")

       except Exception as e:
           logger.error(f"Onverwachte fout: {str(e)}")

   if __name__ == '__main__':
       asyncio.run(main())
   ```

### Verificatie
1. Controleer of de retry logica correct werkt
2. Verifieer dat verschillende soorten fouten correct worden afgehandeld
3. Controleer de logging output
4. Test met verschillende scenario's (normaal, error, rate limit)

## Bonus Oefening: Performance Monitoring

### Doel
Implementeer performance monitoring voor API calls en data verwerking.

### Stappen

1. **Maak een nieuwe Python module `performance_monitor.py`**:
   ```python
   from typing import Dict, Any, Optional
   import time
   import logging
   from functools import wraps
   from dataclasses import dataclass
   from datetime import datetime

   @dataclass
   class PerformanceMetrics:
       operation: str
       start_time: datetime
       end_time: Optional[datetime] = None
       duration: Optional[float] = None
       success: bool = True
       error: Optional[str] = None

   class PerformanceMonitor:
       def __init__(self):
           self.metrics: List[PerformanceMetrics] = []
           self.logger = logging.getLogger('performance_monitor')

       def measure(self, operation: str):
           """Decorator voor het meten van performance"""
           def decorator(func):
               @wraps(func)
               async def wrapper(*args, **kwargs):
                   start_time = datetime.now()
                   metrics = PerformanceMetrics(
                       operation=operation,
                       start_time=start_time
                   )
                   
                   try:
                       result = await func(*args, **kwargs)
                       metrics.end_time = datetime.now()
                       metrics.duration = (
                           metrics.end_time - metrics.start_time
                       ).total_seconds()
                       metrics.success = True
                       return result
                   except Exception as e:
                       metrics.end_time = datetime.now()
                       metrics.duration = (
                           metrics.end_time - metrics.start_time
                       ).total_seconds()
                       metrics.success = False
                       metrics.error = str(e)
                       raise
                   finally:
                       self.metrics.append(metrics)
                       self._log_metrics(metrics)
               return wrapper
           return decorator

       def _log_metrics(self, metrics: PerformanceMetrics) -> None:
           """Log performance metrics"""
           if metrics.success:
               self.logger.info(
                   f"Operation {metrics.operation} completed in "
                   f"{metrics.duration:.2f} seconds"
               )
           else:
               self.logger.error(
                   f"Operation {metrics.operation} failed after "
                   f"{metrics.duration:.2f} seconds: {metrics.error}"
               )

       def get_summary(self) -> Dict[str, Any]:
           """Genereer performance samenvatting"""
           successful = [m for m in self.metrics if m.success]
           failed = [m for m in self.metrics if not m.success]
           
           return {
               'total_operations': len(self.metrics),
               'successful_operations': len(successful),
               'failed_operations': len(failed),
               'average_duration': (
                   sum(m.duration for m in successful) / len(successful)
                   if successful else 0
               ),
               'max_duration': max(
                   (m.duration for m in successful),
                   default=0
               ),
               'min_duration': min(
                   (m.duration for m in successful),
                   default=0
               )
           }
   ```

2. **Maak een script `test_performance.py` om de monitoring te testen**:
   ```python
   import asyncio
   import logging
   from performance_monitor import PerformanceMonitor

   class MonitoredAPIClient:
       def __init__(self):
           self.monitor = PerformanceMonitor()
           self.logger = logging.getLogger('monitored_client')

       @PerformanceMonitor().measure('get_user')
       async def get_user(self, user_id: str) -> dict:
           # Simuleer API call
           await asyncio.sleep(1)
           return {'id': user_id, 'name': 'Test User'}

       @PerformanceMonitor().measure('update_user')
       async def update_user(self, user_id: str, data: dict) -> dict:
           # Simuleer API call
           await asyncio.sleep(0.5)
           return {'id': user_id, **data}

   async def main():
       # Setup logging
       logging.basicConfig(level=logging.INFO)
       logger = logging.getLogger(__name__)

       # Initialiseer client
       client = MonitoredAPIClient()

       try:
           # Test verschillende operaties
           user = await client.get_user('123')
           logger.info(f"Gebruiker opgehaald: {user}")

           updated = await client.update_user('123', {'name': 'New Name'})
           logger.info(f"Gebruiker bijgewerkt: {updated}")

           # Toon performance samenvatting
           summary = client.monitor.get_summary()
           logger.info("Performance Samenvatting:")
           for key, value in summary.items():
               logger.info(f"{key}: {value}")

       except Exception as e:
           logger.error(f"Fout: {str(e)}")

   if __name__ == '__main__':
       asyncio.run(main())
   ```

### Verificatie
1. Controleer of de performance metrics correct worden verzameld
2. Verifieer dat de logging output de juiste informatie bevat
3. Controleer de performance samenvatting
4. Test met verschillende scenario's (snelle en langzame operaties)

## Volgende Stap

Nu je deze praktische oefeningen hebt voltooid, heb je een goede basis voor het werken met Python en de Microsoft Graph API. Je kunt nu doorgaan naar [Module 4: Microsoft Graph API Basics](../04_graph_basics/README.md), waar we dieper ingaan op de API zelf. 