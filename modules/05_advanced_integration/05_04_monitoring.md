# Monitoring en Logging

In deze les gaan we kijken naar verschillende technieken om onze Microsoft Graph API integratie te monitoren en te loggen. We behandelen logging strategieën, monitoring tools, en hoe we problemen kunnen opsporen en oplossen.

## Logging Strategieën

### Structured Logging

```python
import structlog
from typing import Any, Dict

class GraphLogger:
    def __init__(self):
        self.logger = structlog.get_logger()
        self.setup_logging()

    def setup_logging(self):
        structlog.configure(
            processors=[
                structlog.processors.TimeStamper(fmt="iso"),
                structlog.processors.JSONRenderer()
            ]
        )

    def log_request(self, method: str, url: str, params: Dict[str, Any] = None):
        self.logger.info(
            "graph_api_request",
            method=method,
            url=url,
            params=params
        )

    def log_response(self, status_code: int, duration: float, error: Exception = None):
        self.logger.info(
            "graph_api_response",
            status_code=status_code,
            duration=duration,
            error=str(error) if error else None
        )

    def log_error(self, error: Exception, context: Dict[str, Any] = None):
        self.logger.error(
            "graph_api_error",
            error=str(error),
            error_type=type(error).__name__,
            context=context
        )
```

### Log Aggregation

```python
from azure.monitor.opentelemetry import AzureMonitorTraceExporter
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider

class LogAggregator:
    def __init__(self, connection_string: str):
        self.tracer_provider = TracerProvider()
        self.exporter = AzureMonitorTraceExporter(connection_string)
        self.tracer_provider.add_span_processor(
            BatchSpanProcessor(self.exporter)
        )
        trace.set_tracer_provider(self.tracer_provider)
        self.tracer = trace.get_tracer(__name__)

    def start_operation(self, name: str, attributes: Dict[str, Any] = None):
        with self.tracer.start_as_current_span(name, attributes=attributes) as span:
            return span

    def log_metric(self, name: str, value: float, attributes: Dict[str, Any] = None):
        self.exporter.export_metric(name, value, attributes)
```

## Monitoring Tools

### Health Monitoring

```python
class HealthMonitor:
    def __init__(self):
        self.health_checks = {}
        self.logger = logging.getLogger(__name__)

    def register_check(self, name: str, check_func: callable):
        self.health_checks[name] = check_func

    async def check_health(self):
        results = {}
        for name, check in self.health_checks.items():
            try:
                status = await check()
                results[name] = {
                    "status": "healthy" if status else "unhealthy",
                    "timestamp": datetime.utcnow().isoformat()
                }
            except Exception as e:
                results[name] = {
                    "status": "error",
                    "error": str(e),
                    "timestamp": datetime.utcnow().isoformat()
                }
                self.logger.error(f"Health check failed for {name}: {str(e)}")
        
        return results

    async def get_health_status(self):
        results = await self.check_health()
        overall_status = all(
            result["status"] == "healthy" 
            for result in results.values()
        )
        return {
            "status": "healthy" if overall_status else "unhealthy",
            "checks": results
        }
```

### Metrics Collection

```python
from prometheus_client import Counter, Histogram, Gauge

class MetricsCollector:
    def __init__(self):
        self.request_counter = Counter(
            'graph_api_requests_total',
            'Total number of Graph API requests',
            ['method', 'endpoint', 'status']
        )
        
        self.request_duration = Histogram(
            'graph_api_request_duration_seconds',
            'Duration of Graph API requests',
            ['method', 'endpoint']
        )
        
        self.error_counter = Counter(
            'graph_api_errors_total',
            'Total number of Graph API errors',
            ['error_type']
        )
        
        self.active_requests = Gauge(
            'graph_api_active_requests',
            'Number of active Graph API requests'
        )

    def record_request(self, method: str, endpoint: str, status: int, duration: float):
        self.request_counter.labels(
            method=method,
            endpoint=endpoint,
            status=status
        ).inc()
        
        self.request_duration.labels(
            method=method,
            endpoint=endpoint
        ).observe(duration)

    def record_error(self, error_type: str):
        self.error_counter.labels(error_type=error_type).inc()

    def track_active_requests(self, count: int):
        self.active_requests.set(count)
```

## Alerting

### Alert Manager

```python
class AlertManager:
    def __init__(self):
        self.alerts = []
        self.thresholds = {
            "error_rate": 0.05,  # 5%
            "response_time": 2.0,  # 2 seconds
            "availability": 0.99  # 99%
        }
        self.logger = logging.getLogger(__name__)

    def check_metrics(self, metrics: Dict[str, Any]):
        alerts = []
        
        if metrics["error_rate"] > self.thresholds["error_rate"]:
            alerts.append({
                "type": "error_rate",
                "message": f"Error rate {metrics['error_rate']*100}% exceeds threshold",
                "severity": "high"
            })
        
        if metrics["avg_response_time"] > self.thresholds["response_time"]:
            alerts.append({
                "type": "response_time",
                "message": f"Response time {metrics['avg_response_time']}s exceeds threshold",
                "severity": "medium"
            })
        
        if metrics["availability"] < self.thresholds["availability"]:
            alerts.append({
                "type": "availability",
                "message": f"Availability {metrics['availability']*100}% below threshold",
                "severity": "high"
            })
        
        return alerts

    async def send_alerts(self, alerts: List[Dict[str, Any]]):
        for alert in alerts:
            self.logger.warning(
                f"Alert: {alert['message']}",
                extra={
                    "alert_type": alert["type"],
                    "severity": alert["severity"]
                }
            )
            # Implementeer hier de logica voor het versturen van alerts
            # (bijvoorbeeld via email, Slack, etc.)
```

## Debugging Tools

### Request Debugger

```python
class RequestDebugger:
    def __init__(self):
        self.logger = logging.getLogger(__name__)

    def debug_request(self, request: Dict[str, Any]):
        self.logger.debug(
            "Request details",
            extra={
                "method": request["method"],
                "url": request["url"],
                "headers": request.get("headers"),
                "body": request.get("body")
            }
        )

    def debug_response(self, response: Dict[str, Any]):
        self.logger.debug(
            "Response details",
            extra={
                "status_code": response["status_code"],
                "headers": response.get("headers"),
                "body": response.get("body")
            }
        )

    def debug_error(self, error: Exception, context: Dict[str, Any] = None):
        self.logger.error(
            "Error details",
            extra={
                "error_type": type(error).__name__,
                "error_message": str(error),
                "context": context
            }
        )
```

### Performance Profiler

```python
import cProfile
import pstats
from io import StringIO

class PerformanceProfiler:
    def __init__(self):
        self.profiler = cProfile.Profile()
        self.logger = logging.getLogger(__name__)

    def start_profiling(self):
        self.profiler.enable()

    def stop_profiling(self):
        self.profiler.disable()
        
        # Analyseer de resultaten
        s = StringIO()
        stats = pstats.Stats(self.profiler, stream=s).sort_stats('cumulative')
        stats.print_stats()
        
        # Log de resultaten
        self.logger.info(
            "Performance profile",
            extra={"profile": s.getvalue()}
        )
        
        return s.getvalue()
```

## Best Practices

### 1. Logging Best Practices

```python
class LoggingBestPractices:
    def __init__(self):
        self.logger = logging.getLogger(__name__)

    def setup_logging(self):
        # Configureer logging niveau
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        
        # Voeg file handler toe
        file_handler = logging.FileHandler('graph_api.log')
        file_handler.setFormatter(
            logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
        )
        self.logger.addHandler(file_handler)

    def log_with_context(self, message: str, context: Dict[str, Any]):
        self.logger.info(
            message,
            extra=context
        )

    def log_exception(self, error: Exception, context: Dict[str, Any] = None):
        self.logger.exception(
            "Exception occurred",
            extra=context
        )
```

### 2. Monitoring Best Practices

```python
class MonitoringBestPractices:
    def __init__(self):
        self.metrics = {}
        self.alerts = []
        self.logger = logging.getLogger(__name__)

    def track_metric(self, name: str, value: float, tags: Dict[str, str] = None):
        self.metrics[name] = {
            "value": value,
            "timestamp": datetime.utcnow(),
            "tags": tags or {}
        }
        
        self.logger.info(
            f"Metric recorded: {name}",
            extra={
                "metric_name": name,
                "value": value,
                "tags": tags
            }
        )

    def check_thresholds(self):
        for name, data in self.metrics.items():
            if self._exceeds_threshold(name, data["value"]):
                self._create_alert(name, data)

    def _exceeds_threshold(self, name: str, value: float) -> bool:
        # Implementeer threshold checking logica
        pass

    def _create_alert(self, name: str, data: Dict[str, Any]):
        alert = {
            "name": name,
            "value": data["value"],
            "timestamp": data["timestamp"],
            "tags": data["tags"]
        }
        self.alerts.append(alert)
        
        self.logger.warning(
            f"Alert created for metric: {name}",
            extra=alert
        )
```

## Volgende Stap

Nu je bekend bent met monitoring en logging, gaan we in de volgende les kijken naar [praktische oefeningen](05_05_praktische_oefeningen.md). Daar gaan we alles wat we hebben geleerd in de praktijk brengen. 