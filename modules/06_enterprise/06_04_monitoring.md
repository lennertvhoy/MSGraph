# Monitoring en Logging

In deze les gaan we kijken naar verschillende aspecten van monitoring en logging voor enterprise-level applicaties met de Microsoft Graph API. We behandelen logging strategieën, monitoring tools, alerting en debugging.

## Logging Strategieën

### Structured Logging

```python
import structlog
from typing import Any, Dict
import json

class GraphLogger:
    def __init__(self):
        self.logger = structlog.get_logger()
        self.logger = structlog.configure(
            processors=[
                structlog.processors.TimeStamper(fmt="iso"),
                structlog.processors.JSONRenderer()
            ]
        )

    def log_request(self, method: str, endpoint: str, params: Dict[str, Any] = None):
        self.logger.info(
            "graph_api_request",
            method=method,
            endpoint=endpoint,
            params=params
        )

    def log_response(self, method: str, endpoint: str, status: int, duration: float):
        self.logger.info(
            "graph_api_response",
            method=method,
            endpoint=endpoint,
            status=status,
            duration=duration
        )

    def log_error(self, error: Exception, context: Dict[str, Any] = None):
        self.logger.error(
            "graph_api_error",
            error_type=type(error).__name__,
            error_message=str(error),
            context=context
        )
```

### Log Aggregation

```python
from azure.monitor.opentelemetry import AzureMonitorTraceExporter
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider, BatchSpanProcessor

class LogAggregator:
    def __init__(self, connection_string: str):
        self.tracer_provider = TracerProvider()
        self.exporter = AzureMonitorTraceExporter(connection_string)
        self.tracer_provider.add_span_processor(
            BatchSpanProcessor(self.exporter)
        )
        trace.set_tracer_provider(self.tracer_provider)
        self.tracer = trace.get_tracer(__name__)
        self.logger = logging.getLogger(__name__)

    async def log_trace(self, name: str, attributes: Dict[str, Any] = None):
        try:
            with self.tracer.start_as_current_span(name) as span:
                if attributes:
                    for key, value in attributes.items():
                        span.set_attribute(key, str(value))
        except Exception as e:
            self.logger.error(f"Error logging trace: {str(e)}")

    async def log_metric(self, name: str, value: float, attributes: Dict[str, Any] = None):
        try:
            # Implementeer metric logging logica
            pass
        except Exception as e:
            self.logger.error(f"Error logging metric: {str(e)}")
```

## Monitoring Tools

### Health Monitoring

```python
from aiohttp import web
from prometheus_client import Counter, Gauge

class HealthMonitor:
    def __init__(self):
        self.health_checks = {}
        self.health_status = Gauge(
            'service_health_status',
            'Health status of the service',
            ['check_name']
        )
        self.health_check_duration = Counter(
            'health_check_duration_seconds',
            'Duration of health checks',
            ['check_name']
        )
        self.logger = logging.getLogger(__name__)

    def register_health_check(self, name: str, check_func):
        self.health_checks[name] = check_func
        self.logger.info(f"Registered health check: {name}")

    async def check_health(self) -> Dict[str, Any]:
        results = {}
        for name, check_func in self.health_checks.items():
            try:
                start_time = time.time()
                is_healthy = await check_func()
                duration = time.time() - start_time
                
                self.health_status.labels(check_name=name).set(1 if is_healthy else 0)
                self.health_check_duration.labels(check_name=name).inc(duration)
                
                results[name] = {
                    "healthy": is_healthy,
                    "duration": duration
                }
            except Exception as e:
                self.logger.error(f"Health check failed for {name}: {str(e)}")
                results[name] = {
                    "healthy": False,
                    "error": str(e)
                }
        return results
```

### Metrics Collection

```python
from prometheus_client import Counter, Histogram, Gauge

class MetricsCollector:
    def __init__(self):
        self.request_counter = Counter(
            'graph_api_requests_total',
            'Total number of Graph API requests',
            ['endpoint', 'method', 'status']
        )
        self.request_duration = Histogram(
            'graph_api_request_duration_seconds',
            'Request duration in seconds',
            ['endpoint']
        )
        self.error_counter = Counter(
            'graph_api_errors_total',
            'Total number of Graph API errors',
            ['error_type']
        )
        self.active_requests = Gauge(
            'graph_api_active_requests',
            'Number of active requests'
        )
        self.logger = logging.getLogger(__name__)

    def record_request(self, endpoint: str, method: str, status: int, duration: float):
        try:
            self.request_counter.labels(
                endpoint=endpoint,
                method=method,
                status=status
            ).inc()
            self.request_duration.labels(endpoint=endpoint).observe(duration)
        except Exception as e:
            self.logger.error(f"Error recording metrics: {str(e)}")

    def record_error(self, error_type: str):
        self.error_counter.labels(error_type=error_type).inc()

    def set_active_requests(self, count: int):
        self.active_requests.set(count)
```

## Alerting

### Alert Manager

```python
from typing import Dict, List
import asyncio

class AlertManager:
    def __init__(self):
        self.alerts: List[Dict[str, Any]] = []
        self.thresholds = {
            "error_rate": 0.05,
            "response_time": 2.0,
            "availability": 0.99
        }
        self.logger = logging.getLogger(__name__)

    async def check_metrics(self, metrics: Dict[str, float]):
        try:
            if metrics["error_rate"] > self.thresholds["error_rate"]:
                await self.create_alert(
                    "high_error_rate",
                    f"Error rate {metrics['error_rate']:.2%} exceeds threshold"
                )
            
            if metrics["response_time"] > self.thresholds["response_time"]:
                await self.create_alert(
                    "high_response_time",
                    f"Response time {metrics['response_time']:.2f}s exceeds threshold"
                )
            
            if metrics["availability"] < self.thresholds["availability"]:
                await self.create_alert(
                    "low_availability",
                    f"Availability {metrics['availability']:.2%} below threshold"
                )
        except Exception as e:
            self.logger.error(f"Error checking metrics: {str(e)}")

    async def create_alert(self, alert_type: str, message: str):
        alert = {
            "type": alert_type,
            "message": message,
            "timestamp": datetime.utcnow().isoformat()
        }
        self.alerts.append(alert)
        self.logger.warning(f"Created alert: {message}")
```

## Debugging Tools

### Request Debugger

```python
class RequestDebugger:
    def __init__(self):
        self.logger = logging.getLogger(__name__)

    async def debug_request(self, request: dict):
        try:
            self.logger.debug(
                "Request details",
                method=request.get("method"),
                url=request.get("url"),
                headers=request.get("headers"),
                body=request.get("body")
            )
        except Exception as e:
            self.logger.error(f"Error debugging request: {str(e)}")

    async def debug_response(self, response: dict):
        try:
            self.logger.debug(
                "Response details",
                status=response.get("status"),
                headers=response.get("headers"),
                body=response.get("body")
            )
        except Exception as e:
            self.logger.error(f"Error debugging response: {str(e)}")
```

### Performance Profiler

```python
import cProfile
import pstats
import io

class PerformanceProfiler:
    def __init__(self):
        self.profiler = cProfile.Profile()
        self.logger = logging.getLogger(__name__)

    def start_profiling(self):
        self.profiler.enable()
        self.logger.info("Started performance profiling")

    def stop_profiling(self):
        self.profiler.disable()
        self.logger.info("Stopped performance profiling")

    def get_stats(self) -> str:
        try:
            s = io.StringIO()
            ps = pstats.Stats(self.profiler, stream=s).sort_stats('cumulative')
            ps.print_stats()
            return s.getvalue()
        except Exception as e:
            self.logger.error(f"Error getting profiling stats: {str(e)}")
            return ""
```

## Best Practices

### 1. Logging Best Practices

```python
class LoggingBestPractices:
    def __init__(self):
        self.logger = logging.getLogger(__name__)

    def setup_logging(self):
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        self.logger.info("Logging configured")

    def log_exception(self, exception: Exception, context: Dict[str, Any] = None):
        self.logger.error(
            f"Exception occurred: {str(exception)}",
            exc_info=True,
            context=context
        )
```

### 2. Monitoring Best Practices

```python
class MonitoringBestPractices:
    def __init__(self):
        self.logger = logging.getLogger(__name__)

    async def track_metrics(self, metrics: Dict[str, float]):
        try:
            for name, value in metrics.items():
                self.logger.info(f"Metric {name}: {value}")
        except Exception as e:
            self.logger.error(f"Error tracking metrics: {str(e)}")

    async def check_thresholds(self, metrics: Dict[str, float], thresholds: Dict[str, float]):
        try:
            for name, value in metrics.items():
                if name in thresholds:
                    if value > thresholds[name]:
                        self.logger.warning(
                            f"Threshold exceeded for {name}: {value} > {thresholds[name]}"
                        )
        except Exception as e:
            self.logger.error(f"Error checking thresholds: {str(e)}")
```

## Volgende Stap

Nu je bekend bent met monitoring en logging, gaan we in de volgende les kijken naar [praktische oefeningen](06_05_praktische_oefeningen.md). Daar gaan we een enterprise-level applicatie ontwikkelen met alle geleerde concepten. 