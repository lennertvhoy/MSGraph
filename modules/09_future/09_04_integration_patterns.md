# Integration Patterns

In deze les gaan we kijken naar verschillende integratiepatronen en hoe we deze kunnen implementeren met de Microsoft Graph API. We behandelen microservices, serverless architectuur, en event-driven development.

## Microservices Architectuur

### Service Discovery

```python
# Voorbeeld van service discovery in microservices
class ServiceDiscoveryManager:
    def __init__(self, graph_client, discovery_client):
        self.graph_client = graph_client
        self.discovery_client = discovery_client

    async def register_service(self, service_info):
        """Registreert een nieuwe microservice."""
        try:
            # Registreer service bij discovery service
            registration = await self.discovery_client.register_service(
                service_info
            )

            # Update service status in Graph API
            await self.graph_client.post(
                '/services',
                json={
                    'serviceId': registration['id'],
                    'name': service_info['name'],
                    'endpoint': service_info['endpoint'],
                    'status': 'active'
                }
            )

            return registration
        except Exception as e:
            print(f"Error registering service: {e}")
            return None

    async def discover_service(self, service_name):
        """Vindt een specifieke microservice."""
        try:
            # Zoek service via discovery service
            service = await self.discovery_client.find_service(service_name)

            # Haal service details op via Graph API
            service_details = await self.graph_client.get(
                f'/services/{service["id"]}'
            )

            return service_details.json()
        except Exception as e:
            print(f"Error discovering service: {e}")
            return None
```

### Service Communication

```python
# Voorbeeld van service communicatie
class ServiceCommunicationManager:
    def __init__(self, graph_client, communication_client):
        self.graph_client = graph_client
        self.communication_client = communication_client

    async def send_message(self, from_service, to_service, message):
        """Stuurt een bericht tussen services."""
        try:
            # Stuur bericht via communication service
            message_id = await self.communication_client.send_message(
                from_service,
                to_service,
                message
            )

            # Log communicatie in Graph API
            await self.graph_client.post(
                '/communications',
                json={
                    'messageId': message_id,
                    'fromService': from_service,
                    'toService': to_service,
                    'timestamp': datetime.now().isoformat(),
                    'status': 'sent'
                }
            )

            return message_id
        except Exception as e:
            print(f"Error sending message: {e}")
            return None

    async def receive_message(self, service_id):
        """Ontvangt berichten voor een service."""
        try:
            # Ontvang bericht via communication service
            message = await self.communication_client.receive_message(service_id)

            # Update bericht status in Graph API
            await self.graph_client.patch(
                f'/communications/{message["id"]}',
                json={'status': 'received'}
            )

            return message
        except Exception as e:
            print(f"Error receiving message: {e}")
            return None
```

## Serverless Architectuur

### Function Management

```python
# Voorbeeld van serverless function management
class FunctionManager:
    def __init__(self, graph_client, function_client):
        self.graph_client = graph_client
        self.function_client = function_client

    async def deploy_function(self, function_config):
        """Deployt een nieuwe serverless function."""
        try:
            # Deploy function
            deployment = await self.function_client.deploy_function(
                function_config
            )

            # Update function status in Graph API
            await self.graph_client.post(
                '/functions',
                json={
                    'functionId': deployment['id'],
                    'name': function_config['name'],
                    'runtime': function_config['runtime'],
                    'status': 'active'
                }
            )

            return deployment
        except Exception as e:
            print(f"Error deploying function: {e}")
            return None

    async def invoke_function(self, function_id, payload):
        """Roept een serverless function aan."""
        try:
            # Roep function aan
            result = await self.function_client.invoke_function(
                function_id,
                payload
            )

            # Log function aanroep in Graph API
            await self.graph_client.post(
                f'/functions/{function_id}/invocations',
                json={
                    'timestamp': datetime.now().isoformat(),
                    'payload': payload,
                    'result': result
                }
            )

            return result
        except Exception as e:
            print(f"Error invoking function: {e}")
            return None
```

### Event Management

```python
# Voorbeeld van event management in serverless
class EventManager:
    def __init__(self, graph_client, event_client):
        self.graph_client = graph_client
        self.event_client = event_client

    async def publish_event(self, event_type, payload):
        """Publiceert een event."""
        try:
            # Publiceer event
            event_id = await self.event_client.publish_event(
                event_type,
                payload
            )

            # Log event in Graph API
            await self.graph_client.post(
                '/events',
                json={
                    'eventId': event_id,
                    'type': event_type,
                    'timestamp': datetime.now().isoformat(),
                    'status': 'published'
                }
            )

            return event_id
        except Exception as e:
            print(f"Error publishing event: {e}")
            return None

    async def subscribe_to_event(self, event_type, handler):
        """Abonneert op een specifiek type event."""
        try:
            # Abonneer op event
            subscription = await self.event_client.subscribe(
                event_type,
                handler
            )

            # Log subscription in Graph API
            await self.graph_client.post(
                '/subscriptions',
                json={
                    'subscriptionId': subscription['id'],
                    'eventType': event_type,
                    'status': 'active'
                }
            )

            return subscription
        except Exception as e:
            print(f"Error subscribing to event: {e}")
            return None
```

## Event-Driven Development

### Event Processing

```python
# Voorbeeld van event processing
class EventProcessor:
    def __init__(self, graph_client, processor_client):
        self.graph_client = graph_client
        self.processor_client = processor_client

    async def process_event(self, event_id):
        """Verwerkt een event."""
        try:
            # Haal event op
            event = await self.graph_client.get(f'/events/{event_id}')

            # Verwerk event
            result = await self.processor_client.process_event(
                event.json()
            )

            # Update event status
            await self.graph_client.patch(
                f'/events/{event_id}',
                json={
                    'status': 'processed',
                    'result': result
                }
            )

            return result
        except Exception as e:
            print(f"Error processing event: {e}")
            return None

    async def handle_event_error(self, event_id, error):
        """Verwerkt event errors."""
        try:
            # Log error
            await self.graph_client.post(
                f'/events/{event_id}/errors',
                json={
                    'error': str(error),
                    'timestamp': datetime.now().isoformat()
                }
            )

            # Implementeer error handling logica
            return True
        except Exception as e:
            print(f"Error handling event error: {e}")
            return False
```

### Event Routing

```python
# Voorbeeld van event routing
class EventRouter:
    def __init__(self, graph_client, router_client):
        self.graph_client = graph_client
        self.router_client = router_client

    async def route_event(self, event_id):
        """Route een event naar de juiste handler."""
        try:
            # Haal event op
            event = await self.graph_client.get(f'/events/{event_id}')

            # Route event
            routing_result = await self.router_client.route_event(
                event.json()
            )

            # Update routing status
            await self.graph_client.patch(
                f'/events/{event_id}',
                json={
                    'status': 'routed',
                    'handler': routing_result['handler']
                }
            )

            return routing_result
        except Exception as e:
            print(f"Error routing event: {e}")
            return None

    async def configure_routing(self, routing_config):
        """Configureert event routing regels."""
        try:
            # Configureer routing
            configuration = await self.router_client.configure_routing(
                routing_config
            )

            # Sla configuratie op
            await self.graph_client.post(
                '/routing/config',
                json=configuration
            )

            return configuration
        except Exception as e:
            print(f"Error configuring routing: {e}")
            return None
```

## Best Practices voor Integration Patterns

Bij het implementeren van integratiepatronen is het belangrijk om de volgende best practices te volgen:

1. **Microservices**
   - Implementeer service discovery
   - Gebruik API gateways
   - Implementeer circuit breakers
   - Monitor service health

2. **Serverless**
   - Optimaliseer function performance
   - Implementeer error handling
   - Gebruik cold start strategieën
   - Monitor resource usage

3. **Event-Driven**
   - Implementeer event sourcing
   - Gebruik event versioning
   - Implementeer retry mechanismen
   - Monitor event flow

4. **Algemeen**
   - Documenteer integraties
   - Implementeer logging
   - Gebruik monitoring tools
   - Plan voor scaling

## Volgende Stap

In de volgende les gaan we kijken naar praktische oefeningen waarbij we alle geleerde concepten in de praktijk toepassen. We bouwen een robuuste applicatie die gebruik maakt van de Microsoft Graph API met moderne integratiepatronen. 