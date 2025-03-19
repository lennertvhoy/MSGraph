# Resource Modellen

In deze les gaan we dieper in op de verschillende resource modellen die beschikbaar zijn in de Microsoft Graph API. We behandelen de belangrijkste resources en hoe we ermee kunnen werken.

## Gebruikers en Groepen

### Gebruikers Model

```python
class UserModel:
    def __init__(self, user_data: dict):
        self.id = user_data.get('id')
        self.display_name = user_data.get('displayName')
        self.user_principal_name = user_data.get('userPrincipalName')
        self.mail = user_data.get('mail')
        self.department = user_data.get('department')
        self.job_title = user_data.get('jobTitle')
        self.office_location = user_data.get('officeLocation')
        self.business_phones = user_data.get('businessPhones', [])
        self.mobile_phone = user_data.get('mobilePhone')
        self.account_enabled = user_data.get('accountEnabled', True)
        self.created_date_time = user_data.get('createdDateTime')
        self.last_sign_in_date_time = user_data.get('lastSignInDateTime')

    def to_dict(self) -> dict:
        return {
            'id': self.id,
            'displayName': self.display_name,
            'userPrincipalName': self.user_principal_name,
            'mail': self.mail,
            'department': self.department,
            'jobTitle': self.job_title,
            'officeLocation': self.office_location,
            'businessPhones': self.business_phones,
            'mobilePhone': self.mobile_phone,
            'accountEnabled': self.account_enabled,
            'createdDateTime': self.created_date_time,
            'lastSignInDateTime': self.last_sign_in_date_time
        }
```

### Groepen Model

```python
class GroupModel:
    def __init__(self, group_data: dict):
        self.id = group_data.get('id')
        self.display_name = group_data.get('displayName')
        self.description = group_data.get('description')
        self.group_types = group_data.get('groupTypes', [])
        self.mail = group_data.get('mail')
        self.mail_enabled = group_data.get('mailEnabled', False)
        self.security_enabled = group_data.get('securityEnabled', True)
        self.created_date_time = group_data.get('createdDateTime')
        self.members = group_data.get('members', [])

    def to_dict(self) -> dict:
        return {
            'id': self.id,
            'displayName': self.display_name,
            'description': self.description,
            'groupTypes': self.group_types,
            'mail': self.mail,
            'mailEnabled': self.mail_enabled,
            'securityEnabled': self.security_enabled,
            'createdDateTime': self.created_date_time,
            'members': self.members
        }
```

## Mail en Kalender

### Email Model

```python
class EmailModel:
    def __init__(self, email_data: dict):
        self.id = email_data.get('id')
        self.subject = email_data.get('subject')
        self.body_preview = email_data.get('bodyPreview')
        self.importance = email_data.get('importance')
        self.from_address = email_data.get('from', {}).get('emailAddress', {})
        self.to_recipients = email_data.get('toRecipients', [])
        self.cc_recipients = email_data.get('ccRecipients', [])
        self.bcc_recipients = email_data.get('bccRecipients', [])
        self.received_date_time = email_data.get('receivedDateTime')
        self.sent_date_time = email_data.get('sentDateTime')
        self.has_attachments = email_data.get('hasAttachments', False)
        self.attachments = email_data.get('attachments', [])

    def to_dict(self) -> dict:
        return {
            'id': self.id,
            'subject': self.subject,
            'bodyPreview': self.bodyPreview,
            'importance': self.importance,
            'from': self.from_address,
            'toRecipients': self.to_recipients,
            'ccRecipients': self.cc_recipients,
            'bccRecipients': self.bcc_recipients,
            'receivedDateTime': self.received_date_time,
            'sentDateTime': self.sent_date_time,
            'hasAttachments': self.has_attachments,
            'attachments': self.attachments
        }
```

### Kalender Model

```python
class CalendarModel:
    def __init__(self, calendar_data: dict):
        self.id = calendar_data.get('id')
        self.name = calendar_data.get('name')
        self.color = calendar_data.get('color')
        self.hex_color = calendar_data.get('hexColor')
        self.is_default = calendar_data.get('isDefaultCalendar', False)
        self.is_shared = calendar_data.get('isShared', False)
        self.owner = calendar_data.get('owner', {})
        self.events = calendar_data.get('events', [])

    def to_dict(self) -> dict:
        return {
            'id': self.id,
            'name': self.name,
            'color': self.color,
            'hexColor': self.hex_color,
            'isDefaultCalendar': self.is_default,
            'isShared': self.is_shared,
            'owner': self.owner,
            'events': self.events
        }
```

## Bestanden en SharePoint

### Drive Item Model

```python
class DriveItemModel:
    def __init__(self, item_data: dict):
        self.id = item_data.get('id')
        self.name = item_data.get('name')
        self.size = item_data.get('size')
        self.web_url = item_data.get('webUrl')
        self.created_date_time = item_data.get('createdDateTime')
        self.last_modified_date_time = item_data.get('lastModifiedDateTime')
        self.file = item_data.get('file', {})
        self.folder = item_data.get('folder', {})
        self.is_file = bool(self.file)
        self.is_folder = bool(self.folder)
        self.parent_reference = item_data.get('parentReference', {})
        self.shared = item_data.get('shared', {})

    def to_dict(self) -> dict:
        return {
            'id': self.id,
            'name': self.name,
            'size': self.size,
            'webUrl': self.web_url,
            'createdDateTime': self.created_date_time,
            'lastModifiedDateTime': self.last_modified_date_time,
            'file': self.file,
            'folder': self.folder,
            'parentReference': self.parent_reference,
            'shared': self.shared
        }
```

### SharePoint Site Model

```python
class SharePointSiteModel:
    def __init__(self, site_data: dict):
        self.id = site_data.get('id')
        self.display_name = site_data.get('displayName')
        self.name = site_data.get('name')
        self.root = site_data.get('root', {})
        self.sharepoint_ids = site_data.get('sharepointIds', {})
        self.site_collection = site_data.get('siteCollection', {})
        self.pages = site_data.get('pages', [])
        self.lists = site_data.get('lists', [])

    def to_dict(self) -> dict:
        return {
            'id': self.id,
            'displayName': self.display_name,
            'name': self.name,
            'root': self.root,
            'sharepointIds': self.sharepoint_ids,
            'siteCollection': self.site_collection,
            'pages': self.pages,
            'lists': self.lists
        }
```

## Teams en Chat

### Team Model

```python
class TeamModel:
    def __init__(self, team_data: dict):
        self.id = team_data.get('id')
        self.display_name = team_data.get('displayName')
        self.description = team_data.get('description')
        self.created_date_time = team_data.get('createdDateTime')
        self.members = team_data.get('members', [])
        self.channels = team_data.get('channels', [])
        self.installed_apps = team_data.get('installedApps', [])
        self.settings = team_data.get('settings', {})

    def to_dict(self) -> dict:
        return {
            'id': self.id,
            'displayName': self.display_name,
            'description': self.description,
            'createdDateTime': self.created_date_time,
            'members': self.members,
            'channels': self.channels,
            'installedApps': self.installed_apps,
            'settings': self.settings
        }
```

### Chat Model

```python
class ChatModel:
    def __init__(self, chat_data: dict):
        self.id = chat_data.get('id')
        self.chat_type = chat_data.get('chatType')
        self.created_date_time = chat_data.get('createdDateTime')
        self.last_updated_date_time = chat_data.get('lastUpdatedDateTime')
        self.topic = chat_data.get('topic')
        self.members = chat_data.get('members', [])
        self.messages = chat_data.get('messages', [])
        self.installed_apps = chat_data.get('installedApps', [])

    def to_dict(self) -> dict:
        return {
            'id': self.id,
            'chatType': self.chat_type,
            'createdDateTime': self.created_date_time,
            'lastUpdatedDateTime': self.last_updated_date_time,
            'topic': self.topic,
            'members': self.members,
            'messages': self.messages,
            'installedApps': self.installed_apps
        }
```

## Resource Verwerking

### Resource Factory

```python
class ResourceFactory:
    @staticmethod
    def create_resource(resource_type: str, data: dict):
        resource_map = {
            'user': UserModel,
            'group': GroupModel,
            'email': EmailModel,
            'calendar': CalendarModel,
            'drive_item': DriveItemModel,
            'site': SharePointSiteModel,
            'team': TeamModel,
            'chat': ChatModel
        }
        
        if resource_type not in resource_map:
            raise ValueError(f"Onbekend resource type: {resource_type}")
            
        return resource_map[resource_type](data)
```

### Resource Validator

```python
class ResourceValidator:
    @staticmethod
    def validate_user(user: UserModel) -> bool:
        required_fields = ['id', 'displayName', 'userPrincipalName']
        return all(getattr(user, field) for field in required_fields)

    @staticmethod
    def validate_group(group: GroupModel) -> bool:
        required_fields = ['id', 'displayName']
        return all(getattr(group, field) for field in required_fields)

    @staticmethod
    def validate_email(email: EmailModel) -> bool:
        required_fields = ['id', 'subject', 'from_address']
        return all(getattr(email, field) for field in required_fields)
```

## Best Practices

### 1. Resource Caching

```python
class ResourceCache:
    def __init__(self, ttl: int = 300):  # 5 minuten
        self.cache = {}
        self.ttl = ttl

    def get(self, resource_type: str, resource_id: str):
        key = f"{resource_type}:{resource_id}"
        if key in self.cache:
            data, timestamp = self.cache[key]
            if time.time() - timestamp < self.ttl:
                return data
        return None

    def set(self, resource_type: str, resource_id: str, data: dict):
        key = f"{resource_type}:{resource_id}"
        self.cache[key] = (data, time.time())
```

### 2. Resource Synchronisatie

```python
class ResourceSync:
    def __init__(self, graph_client):
        self.graph_client = graph_client
        self.cache = ResourceCache()

    async def sync_resource(self, resource_type: str, resource_id: str):
        # Haal resource op van Graph API
        resource_data = await self._fetch_resource(resource_type, resource_id)
        
        # Valideer resource
        if not self._validate_resource(resource_type, resource_data):
            raise ValueError(f"Ongeldige resource data voor {resource_type}")
        
        # Update cache
        self.cache.set(resource_type, resource_id, resource_data)
        
        return resource_data
```

## Volgende Stap

Nu je bekend bent met de verschillende resource modellen, gaan we in de volgende les kijken naar [geavanceerde API technieken](04_04_advanced_techniques.md). Daar leren we hoe we batch requests kunnen maken, delta queries kunnen gebruiken en change notifications kunnen implementeren. 