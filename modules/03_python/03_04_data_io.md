# Data Verwerking en I/O

In deze les gaan we leren hoe we efficiënt kunnen werken met bestanden, CSV's, JSON en logging in Python. Deze vaardigheden zijn essentieel voor het opslaan van configuraties, het genereren van rapporten en het verwerken van data.

## Bestanden Lezen en Schrijven

### Tekstbestanden

```python
from pathlib import Path
from typing import List, Optional

class FileHandler:
    def __init__(self, base_path: Path):
        self.base_path = Path(base_path)

    def read_text(self, filename: str) -> str:
        """Lees een tekstbestand"""
        file_path = self.base_path / filename
        return file_path.read_text(encoding='utf-8')

    def write_text(self, filename: str, content: str) -> None:
        """Schrijf naar een tekstbestand"""
        file_path = self.base_path / filename
        file_path.write_text(content, encoding='utf-8')

    def append_text(self, filename: str, content: str) -> None:
        """Voeg tekst toe aan een bestand"""
        file_path = self.base_path / filename
        with file_path.open('a', encoding='utf-8') as f:
            f.write(content)
```

### Binary Bestanden

```python
class BinaryFileHandler:
    def __init__(self, base_path: Path):
        self.base_path = Path(base_path)

    def read_binary(self, filename: str) -> bytes:
        """Lees een binair bestand"""
        file_path = self.base_path / filename
        return file_path.read_bytes()

    def write_binary(self, filename: str, content: bytes) -> None:
        """Schrijf naar een binair bestand"""
        file_path = self.base_path / filename
        file_path.write_bytes(content)

    def copy_file(self, source: str, destination: str) -> None:
        """Kopieer een bestand"""
        source_path = self.base_path / source
        dest_path = self.base_path / destination
        dest_path.write_bytes(source_path.read_bytes())
```

## CSV Verwerking

### CSV Lezen en Schrijven

```python
import csv
from typing import List, Dict, Any
from dataclasses import dataclass

@dataclass
class UserData:
    id: str
    name: str
    email: str
    department: str

class CSVHandler:
    def __init__(self, base_path: Path):
        self.base_path = Path(base_path)

    def read_csv(self, filename: str) -> List[Dict[str, Any]]:
        """Lees een CSV bestand"""
        file_path = self.base_path / filename
        with file_path.open('r', encoding='utf-8', newline='') as f:
            reader = csv.DictReader(f)
            return list(reader)

    def write_csv(self, filename: str, data: List[Dict[str, Any]], headers: Optional[List[str]] = None) -> None:
        """Schrijf naar een CSV bestand"""
        file_path = self.base_path / filename
        if not headers and data:
            headers = list(data[0].keys())

        with file_path.open('w', encoding='utf-8', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=headers)
            writer.writeheader()
            writer.writerows(data)

    def append_csv(self, filename: str, data: List[Dict[str, Any]]) -> None:
        """Voeg data toe aan een CSV bestand"""
        file_path = self.base_path / filename
        headers = list(data[0].keys()) if data else []

        with file_path.open('a', encoding='utf-8', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=headers)
            writer.writerows(data)
```

### CSV Data Verwerking

```python
class UserDataProcessor:
    def __init__(self, csv_handler: CSVHandler):
        self.csv_handler = csv_handler

    def process_user_data(self, input_file: str, output_file: str) -> None:
        """Verwerk gebruikersdata en genereer rapport"""
        # Lees input data
        users = self.csv_handler.read_csv(input_file)
        
        # Verwerk data
        processed_data = []
        for user in users:
            processed_user = {
                'id': user['id'],
                'name': user['name'].title(),
                'email': user['email'].lower(),
                'department': user['department'],
                'status': 'Active' if user.get('active', 'true').lower() == 'true' else 'Inactive'
            }
            processed_data.append(processed_user)

        # Schrijf output
        self.csv_handler.write_csv(output_file, processed_data)

    def generate_department_report(self, input_file: str, output_file: str) -> None:
        """Genereer rapport per afdeling"""
        users = self.csv_handler.read_csv(input_file)
        
        # Groepeer per afdeling
        departments = {}
        for user in users:
            dept = user['department']
            if dept not in departments:
                departments[dept] = []
            departments[dept].append(user)

        # Genereer rapport data
        report_data = []
        for dept, dept_users in departments.items():
            report_data.append({
                'department': dept,
                'total_users': len(dept_users),
                'active_users': sum(1 for u in dept_users if u.get('active', 'true').lower() == 'true')
            })

        # Schrijf rapport
        self.csv_handler.write_csv(output_file, report_data)
```

## JSON Verwerking

### JSON Lezen en Schrijven

```python
import json
from typing import Any, Dict, Optional

class JSONHandler:
    def __init__(self, base_path: Path):
        self.base_path = Path(base_path)

    def read_json(self, filename: str) -> Any:
        """Lees een JSON bestand"""
        file_path = self.base_path / filename
        with file_path.open('r', encoding='utf-8') as f:
            return json.load(f)

    def write_json(self, filename: str, data: Any, indent: Optional[int] = 2) -> None:
        """Schrijf naar een JSON bestand"""
        file_path = self.base_path / filename
        with file_path.open('w', encoding='utf-8') as f:
            json.dump(data, f, indent=indent, ensure_ascii=False)

    def update_json(self, filename: str, updates: Dict[str, Any]) -> None:
        """Update een JSON bestand met nieuwe data"""
        data = self.read_json(filename)
        data.update(updates)
        self.write_json(filename, data)
```

### Configuratie Beheer

```python
from dataclasses import dataclass, asdict
from typing import Dict, Any

@dataclass
class AppConfig:
    app_name: str
    version: str
    settings: Dict[str, Any]

    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'AppConfig':
        return cls(**data)

class ConfigManager:
    def __init__(self, json_handler: JSONHandler):
        self.json_handler = json_handler

    def load_config(self, filename: str) -> AppConfig:
        """Laad configuratie"""
        data = self.json_handler.read_json(filename)
        return AppConfig.from_dict(data)

    def save_config(self, filename: str, config: AppConfig) -> None:
        """Sla configuratie op"""
        self.json_handler.write_json(filename, config.to_dict())

    def update_config(self, filename: str, updates: Dict[str, Any]) -> None:
        """Update configuratie"""
        config = self.load_config(filename)
        config.settings.update(updates)
        self.save_config(filename, config)
```

## Logging

### Logging Setup

```python
import logging
from pathlib import Path
from typing import Optional
from datetime import datetime

class LogManager:
    def __init__(self, log_dir: Path):
        self.log_dir = Path(log_dir)
        self.log_dir.mkdir(parents=True, exist_ok=True)

    def setup_logger(self, name: str, log_file: Optional[str] = None) -> logging.Logger:
        """Setup een logger"""
        logger = logging.getLogger(name)
        logger.setLevel(logging.INFO)

        # Maak formatters
        file_formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        console_formatter = logging.Formatter(
            '%(levelname)s - %(message)s'
        )

        # File handler
        if log_file is None:
            log_file = f"{name}_{datetime.now().strftime('%Y%m%d')}.log"
        file_handler = logging.FileHandler(
            self.log_dir / log_file,
            encoding='utf-8'
        )
        file_handler.setFormatter(file_formatter)
        logger.addHandler(file_handler)

        # Console handler
        console_handler = logging.StreamHandler()
        console_handler.setFormatter(console_formatter)
        logger.addHandler(console_handler)

        return logger

    def rotate_logs(self, max_files: int = 5) -> None:
        """Roteer log bestanden"""
        log_files = sorted(
            self.log_dir.glob("*.log"),
            key=lambda x: x.stat().st_mtime,
            reverse=True
        )

        for log_file in log_files[max_files:]:
            log_file.unlink()
```

### Logging Gebruik

```python
class GraphAPILogger:
    def __init__(self, log_manager: LogManager):
        self.logger = log_manager.setup_logger('graph_api')

    def log_request(self, method: str, endpoint: str, status_code: int) -> None:
        """Log een API request"""
        self.logger.info(
            f"API Request - Method: {method}, Endpoint: {endpoint}, "
            f"Status: {status_code}"
        )

    def log_error(self, error: Exception, context: str) -> None:
        """Log een fout"""
        self.logger.error(
            f"Error in {context}: {str(error)}",
            exc_info=True
        )

    def log_warning(self, message: str) -> None:
        """Log een waarschuwing"""
        self.logger.warning(message)
```

## Best Practices

### Error Handling

```python
class FileOperationError(Exception):
    def __init__(self, message: str, file_path: Path):
        self.message = message
        self.file_path = file_path
        super().__init__(self.message)

def safe_file_operation(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        try:
            return func(*args, **kwargs)
        except FileNotFoundError as e:
            raise FileOperationError(f"Bestand niet gevonden: {e}", e.filename)
        except PermissionError as e:
            raise FileOperationError(f"Geen toegang tot bestand: {e}", e.filename)
        except Exception as e:
            raise FileOperationError(f"Onverwachte fout: {str(e)}", e.filename)
    return wrapper
```

### Performance Optimalisatie

```python
from typing import Iterator
import csv
from pathlib import Path

def read_csv_large_file(file_path: Path) -> Iterator[Dict[str, Any]]:
    """Lees een groot CSV bestand efficiënt"""
    with file_path.open('r', encoding='utf-8', newline='') as f:
        reader = csv.DictReader(f)
        for row in reader:
            yield row

def process_large_csv(file_path: Path, batch_size: int = 1000) -> None:
    """Verwerk een groot CSV bestand in batches"""
    batch = []
    for row in read_csv_large_file(file_path):
        batch.append(row)
        if len(batch) >= batch_size:
            process_batch(batch)
            batch = []
    
    if batch:
        process_batch(batch)
```

## Volgende Stap

Nu je weet hoe je kunt werken met bestanden, CSV's, JSON en logging, gaan we in de volgende les kijken naar [praktische oefeningen](03_05_praktische_oefeningen.md). Daar gaan we alles wat we hebben geleerd in praktijk brengen. 