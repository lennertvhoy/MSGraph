# Security en Compliance

In deze les gaan we kijken naar verschillende aspecten van beveiliging en compliance voor enterprise-level applicaties met de Microsoft Graph API. We behandelen geavanceerde authenticatie, role-based access control, data protection en compliance requirements.

## Geavanceerde Authenticatie

### Multi-Factor Authentication

```python
from msal import ConfidentialClientApplication
from azure.identity import DefaultAzureCredential
from typing import Optional

class MFAHandler:
    def __init__(self, tenant_id: str, client_id: str, client_secret: str):
        self.tenant_id = tenant_id
        self.client_id = client_id
        self.client_secret = client_secret
        self.msal_app = ConfidentialClientApplication(
            client_id=client_id,
            authority=f"https://login.microsoftonline.com/{tenant_id}",
            client_credential=client_secret
        )
        self.logger = logging.getLogger(__name__)

    async def authenticate_with_mfa(self, username: str, password: str) -> Optional[str]:
        try:
            result = await self.msal_app.acquire_token_by_username_password(
                username=username,
                password=password,
                scopes=["https://graph.microsoft.com/.default"]
            )
            
            if "access_token" in result:
                self.logger.info(f"Successfully authenticated user: {username}")
                return result["access_token"]
            else:
                self.logger.error(f"Authentication failed for user: {username}")
                return None
        except Exception as e:
            self.logger.error(f"Error during MFA authentication: {str(e)}")
            raise
```

### Certificate-Based Authentication

```python
from azure.identity import CertificateCredential
from cryptography.x509 import load_pem_x509_certificate
from cryptography.hazmat.primitives import serialization

class CertificateAuth:
    def __init__(self, tenant_id: str, client_id: str, certificate_path: str):
        self.tenant_id = tenant_id
        self.client_id = client_id
        self.certificate_path = certificate_path
        self.logger = logging.getLogger(__name__)

    async def get_certificate_credential(self) -> CertificateCredential:
        try:
            with open(self.certificate_path, 'rb') as cert_file:
                certificate_data = cert_file.read()
                certificate = load_pem_x509_certificate(certificate_data)
                
                private_key = certificate.private_bytes(
                    encoding=serialization.Encoding.PEM,
                    format=serialization.PrivateFormat.PKCS8,
                    encryption_algorithm=serialization.NoEncryption()
                )

            return CertificateCredential(
                tenant_id=self.tenant_id,
                client_id=self.client_id,
                certificate_data=certificate_data,
                private_key=private_key
            )
        except Exception as e:
            self.logger.error(f"Error loading certificate: {str(e)}")
            raise
```

## Role-Based Access Control (RBAC)

### Permission Manager

```python
from typing import List, Dict
from pydantic import BaseModel

class Role(BaseModel):
    name: str
    permissions: List[str]
    description: str

class PermissionManager:
    def __init__(self):
        self.roles: Dict[str, Role] = {}
        self.logger = logging.getLogger(__name__)

    def define_role(self, role: Role):
        self.roles[role.name] = role
        self.logger.info(f"Defined role: {role.name}")

    def assign_role(self, user_id: str, role_name: str):
        if role_name not in self.roles:
            raise ValueError(f"Role {role_name} not found")
        
        # Implementeer role assignment logica
        self.logger.info(f"Assigned role {role_name} to user {user_id}")

    def check_permission(self, user_id: str, permission: str) -> bool:
        # Implementeer permission check logica
        pass
```

### Permission Validator

```python
class PermissionValidator:
    def __init__(self, permission_manager: PermissionManager):
        self.permission_manager = permission_manager
        self.logger = logging.getLogger(__name__)

    async def validate_access(self, user_id: str, required_permissions: List[str]) -> bool:
        try:
            for permission in required_permissions:
                if not self.permission_manager.check_permission(user_id, permission):
                    self.logger.warning(
                        f"Access denied for user {user_id}",
                        permission=permission
                    )
                    return False
            return True
        except Exception as e:
            self.logger.error(f"Error validating permissions: {str(e)}")
            raise
```

## Data Protection

### Encryption Service

```python
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
import base64

class EncryptionService:
    def __init__(self, key: str):
        self.key = key.encode()
        self.fernet = Fernet(self.key)
        self.logger = logging.getLogger(__name__)

    def encrypt_data(self, data: str) -> str:
        try:
            encrypted_data = self.fernet.encrypt(data.encode())
            return base64.urlsafe_b64encode(encrypted_data).decode()
        except Exception as e:
            self.logger.error(f"Error encrypting data: {str(e)}")
            raise

    def decrypt_data(self, encrypted_data: str) -> str:
        try:
            decrypted_data = self.fernet.decrypt(
                base64.urlsafe_b64decode(encrypted_data)
            )
            return decrypted_data.decode()
        except Exception as e:
            self.logger.error(f"Error decrypting data: {str(e)}")
            raise
```

### Data Masking

```python
class DataMasking:
    def __init__(self):
        self.logger = logging.getLogger(__name__)

    def mask_email(self, email: str) -> str:
        try:
            username, domain = email.split('@')
            masked_username = username[0] + '*' * (len(username) - 1)
            return f"{masked_username}@{domain}"
        except Exception as e:
            self.logger.error(f"Error masking email: {str(e)}")
            return email

    def mask_phone(self, phone: str) -> str:
        try:
            return '*' * (len(phone) - 4) + phone[-4:]
        except Exception as e:
            self.logger.error(f"Error masking phone: {str(e)}")
            return phone
```

## Compliance Requirements

### Audit Logger

```python
from azure.monitor.opentelemetry import AzureMonitorTraceExporter
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider

class AuditLogger:
    def __init__(self, connection_string: str):
        self.tracer_provider = TracerProvider()
        self.exporter = AzureMonitorTraceExporter(connection_string)
        self.tracer_provider.add_span_processor(
            BatchSpanProcessor(self.exporter)
        )
        trace.set_tracer_provider(self.tracer_provider)
        self.tracer = trace.get_tracer(__name__)
        self.logger = logging.getLogger(__name__)

    async def log_operation(self, operation: str, user_id: str, details: dict):
        try:
            with self.tracer.start_as_current_span(operation) as span:
                span.set_attribute("user_id", user_id)
                for key, value in details.items():
                    span.set_attribute(key, str(value))
                
                self.logger.info(
                    f"Audit log: {operation}",
                    user_id=user_id,
                    details=details
                )
        except Exception as e:
            self.logger.error(f"Error logging audit: {str(e)}")
            raise
```

### Compliance Checker

```python
class ComplianceChecker:
    def __init__(self):
        self.logger = logging.getLogger(__name__)

    async def check_data_retention(self, data_type: str) -> bool:
        try:
            # Implementeer data retention check logica
            return True
        except Exception as e:
            self.logger.error(f"Error checking data retention: {str(e)}")
            return False

    async def check_access_rights(self, user_id: str, resource_id: str) -> bool:
        try:
            # Implementeer access rights check logica
            return True
        except Exception as e:
            self.logger.error(f"Error checking access rights: {str(e)}")
            return False

    async def check_data_classification(self, data: dict) -> str:
        try:
            # Implementeer data classification check logica
            return "confidential"
        except Exception as e:
            self.logger.error(f"Error checking data classification: {str(e)}")
            return "unknown"
```

## Best Practices

### 1. Secure Configuration

```python
class SecureConfig:
    def __init__(self):
        self.settings = {}
        self.logger = logging.getLogger(__name__)

    def load_from_env(self):
        self.settings = {
            "AZURE_TENANT_ID": os.getenv("AZURE_TENANT_ID"),
            "AZURE_CLIENT_ID": os.getenv("AZURE_CLIENT_ID"),
            "AZURE_CLIENT_SECRET": os.getenv("AZURE_CLIENT_SECRET"),
            "ENCRYPTION_KEY": os.getenv("ENCRYPTION_KEY"),
            "AUDIT_CONNECTION_STRING": os.getenv("AUDIT_CONNECTION_STRING"),
            "MFA_ENABLED": os.getenv("MFA_ENABLED", "true").lower() == "true"
        }
        self.logger.info("Secure configuration loaded")

    def get(self, key: str, default: Any = None) -> Any:
        return self.settings.get(key, default)
```

### 2. Security Monitoring

```python
class SecurityMonitor:
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        self.suspicious_activities = []

    async def monitor_login_attempts(self, user_id: str, success: bool):
        try:
            if not success:
                self.suspicious_activities.append({
                    "type": "failed_login",
                    "user_id": user_id,
                    "timestamp": datetime.utcnow().isoformat()
                })
                
                if len([a for a in self.suspicious_activities 
                       if a["type"] == "failed_login" and 
                       a["user_id"] == user_id]) > 5:
                    self.logger.warning(
                        f"Multiple failed login attempts for user: {user_id}"
                    )
        except Exception as e:
            self.logger.error(f"Error monitoring login attempts: {str(e)}")

    async def detect_suspicious_activity(self, activity: dict):
        try:
            # Implementeer suspicious activity detection logica
            pass
        except Exception as e:
            self.logger.error(f"Error detecting suspicious activity: {str(e)}")
```

## Volgende Stap

Nu je bekend bent met security en compliance, gaan we in de volgende les kijken naar [performance en schaalbaarheid](06_03_performance.md). Daar leren we hoe we onze enterprise applicaties kunnen optimaliseren voor grootschalig gebruik. 