# Security en Authenticatie

In deze les gaan we dieper in op de beveiliging en authenticatie van onze Microsoft Graph API integratie. We behandelen verschillende authenticatiemethoden, role-based access control, en best practices voor security.

## Geavanceerde Authenticatie

### Multi-Factor Authentication

```python
from msal import PublicClientApplication
from azure.identity import InteractiveBrowserCredential

class MFAHandler:
    def __init__(self, client_id: str, tenant_id: str):
        self.client_id = client_id
        self.tenant_id = tenant_id
        self.msal_app = PublicClientApplication(
            client_id=client_id,
            authority=f"https://login.microsoftonline.com/{tenant_id}"
        )

    async def authenticate_with_mfa(self):
        scopes = ["https://graph.microsoft.com/.default"]
        
        # Probeer eerst silent authentication
        accounts = self.msal_app.get_accounts()
        if accounts:
            result = await self.msal_app.acquire_token_silent(
                scopes=scopes,
                account=accounts[0]
            )
            if result:
                return result
        
        # Als silent auth faalt, gebruik interactive browser
        credential = InteractiveBrowserCredential(
            client_id=self.client_id,
            tenant_id=self.tenant_id
        )
        
        return await credential.get_token(scopes[0])
```

### Certificate-Based Authentication

```python
from azure.identity import CertificateCredential
from cryptography.x509 import load_pem_x509_certificate
from cryptography.hazmat.primitives import serialization

class CertificateAuth:
    def __init__(self, client_id: str, tenant_id: str, cert_path: str):
        self.client_id = client_id
        self.tenant_id = tenant_id
        self.cert_path = cert_path

    async def get_certificate_credential(self):
        with open(self.cert_path, 'rb') as cert_file:
            cert_data = cert_file.read()
            cert = load_pem_x509_certificate(cert_data)
            
            private_key = cert.private_bytes(
                encoding=serialization.Encoding.PEM,
                format=serialization.PrivateFormat.PKCS8,
                encryption_algorithm=serialization.NoEncryption()
            )
        
        return CertificateCredential(
            tenant_id=self.tenant_id,
            client_id=self.client_id,
            certificate_string=cert_data,
            private_key=private_key
        )
```

## Role-Based Access Control (RBAC)

### Permission Manager

```python
class PermissionManager:
    def __init__(self, graph_client: GraphServiceClient):
        self.graph_client = graph_client
        self.role_definitions = {
            "admin": [
                "User.ReadWrite.All",
                "Group.ReadWrite.All",
                "Mail.ReadWrite"
            ],
            "user": [
                "User.Read",
                "Mail.Read"
            ],
            "guest": [
                "User.Read"
            ]
        }

    async def assign_role(self, user_id: str, role: str):
        if role not in self.role_definitions:
            raise ValueError(f"Onbekende rol: {role}")
        
        permissions = self.role_definitions[role]
        app_role_assignments = []
        
        for permission in permissions:
            app_role_assignments.append({
                "principalId": user_id,
                "resourceId": self.graph_client.applications.id,
                "appRoleId": self._get_role_id(permission)
            })
        
        await self.graph_client.users.by_user_id(user_id).app_role_assignments.post(app_role_assignments)

    def _get_role_id(self, permission: str) -> str:
        # Implementeer logica om role ID op te halen
        pass
```

### Permission Validator

```python
class PermissionValidator:
    def __init__(self, graph_client: GraphServiceClient):
        self.graph_client = graph_client

    async def validate_permissions(self, user_id: str, required_permissions: List[str]):
        assignments = await self.graph_client.users.by_user_id(user_id).app_role_assignments.get()
        user_permissions = [assignment.app_role_id for assignment in assignments.value]
        
        missing_permissions = [
            permission for permission in required_permissions
            if permission not in user_permissions
        ]
        
        if missing_permissions:
            raise PermissionError(
                f"Ontbrekende permissies: {', '.join(missing_permissions)}"
            )
```

## Security Best Practices

### Token Management

```python
class TokenManager:
    def __init__(self, cache: GraphCache):
        self.cache = cache
        self.token_key_prefix = "token:"

    async def get_token(self, user_id: str):
        cache_key = f"{self.token_key_prefix}{user_id}"
        token = await self.cache.get(cache_key)
        
        if not token or self._is_token_expired(token):
            token = await self._refresh_token(user_id)
            await self.cache.set(cache_key, token, ttl=3600)  # 1 uur
        
        return token

    def _is_token_expired(self, token: dict) -> bool:
        expiry = datetime.fromtimestamp(token['exp'])
        return expiry < datetime.now()

    async def _refresh_token(self, user_id: str):
        # Implementeer token refresh logica
        pass
```

### Security Headers

```python
class SecurityHeaders:
    @staticmethod
    def get_security_headers():
        return {
            "X-Content-Type-Options": "nosniff",
            "X-Frame-Options": "DENY",
            "X-XSS-Protection": "1; mode=block",
            "Strict-Transport-Security": "max-age=31536000; includeSubDomains",
            "Content-Security-Policy": "default-src 'self'",
            "Referrer-Policy": "strict-origin-when-cross-origin"
        }

class SecureMiddleware:
    def __init__(self, app):
        self.app = app

    async def __call__(self, scope, receive, send):
        async def secure_send(message):
            if message["type"] == "http.response.start":
                message["headers"].extend(
                    SecurityHeaders.get_security_headers().items()
                )
            await send(message)
        
        await self.app(scope, receive, secure_send)
```

## Compliance en Auditing

### Audit Logger

```python
class AuditLogger:
    def __init__(self, graph_client: GraphServiceClient):
        self.graph_client = graph_client
        self.logger = logging.getLogger(__name__)

    async def log_operation(self, operation: dict):
        audit_entry = {
            "activityDateTime": datetime.now().isoformat(),
            "activityType": operation['type'],
            "actor": operation['actor'],
            "target": operation['target'],
            "details": operation['details']
        }
        
        # Log naar Azure Monitor
        self.logger.info(
            "Audit Log Entry",
            extra=audit_entry
        )
        
        # Log naar Graph API audit log
        await self.graph_client.auditLogs.directoryAudits.post(audit_entry)

class ComplianceChecker:
    def __init__(self, graph_client: GraphServiceClient):
        self.graph_client = graph_client

    async def check_compliance(self, resource_id: str):
        # Controleer data retention policies
        retention = await self._check_retention_policies(resource_id)
        
        # Controleer toegangsrechten
        access = await self._check_access_rights(resource_id)
        
        # Controleer data classificatie
        classification = await self._check_data_classification(resource_id)
        
        return {
            "retention": retention,
            "access": access,
            "classification": classification
        }
```

## Best Practices

### 1. Secure Configuration

```python
class SecureConfig:
    def __init__(self):
        self.settings = {
            "auth": {
                "token_expiry": 3600,
                "refresh_threshold": 300,
                "max_retries": 3
            },
            "security": {
                "min_password_length": 12,
                "require_special_chars": True,
                "session_timeout": 1800
            },
            "audit": {
                "log_level": "INFO",
                "retention_days": 90,
                "alert_threshold": 5
            }
        }

    def get_secure_setting(self, key: str, default: Any = None):
        return self.settings.get(key, default)
```

### 2. Security Monitoring

```python
class SecurityMonitor:
    def __init__(self):
        self.alerts = []
        self.metrics = {}
        self.logger = logging.getLogger(__name__)

    async def monitor_security_events(self, event: dict):
        # Controleer op verdachte activiteit
        if self._is_suspicious(event):
            await self._create_alert(event)
        
        # Update metrics
        self._update_metrics(event)
        
        # Log event
        self.logger.info(
            "Security Event",
            extra=event
        )

    def _is_suspicious(self, event: dict) -> bool:
        # Implementeer logica voor detectie van verdachte activiteit
        pass
```

## Volgende Stap

Nu je bekend bent met security en authenticatie, gaan we in de volgende les kijken naar [performance optimalisatie](05_03_performance.md). Daar leren we hoe we de prestaties van onze integratie kunnen verbeteren. 