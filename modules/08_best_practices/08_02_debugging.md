# Debugging Technieken

In deze les gaan we kijken naar verschillende debugging technieken voor het werken met de Microsoft Graph API. We behandelen logging, tracing, en verschillende debugging tools.

## Logging en Tracing

### Request Logger

```python
# request_logger.py
from typing import Dict, any
import logging
import json
from datetime import datetime
from functools import wraps

class RequestLogger:
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        self.setup_logging()

    def setup_logging(self):
        try:
            logging.basicConfig(
                level=logging.DEBUG,
                format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
                handlers=[
                    logging.FileHandler('requests.log'),
                    logging.StreamHandler()
                ]
            )
        except Exception as e:
            print(f"Error setting up logging: {str(e)}")
            raise

    def log_request(self, func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            try:
                start_time = datetime.utcnow()
                request_data = {
                    "method": func.__name__,
                    "args": args,
                    "kwargs": kwargs
                }
                
                self.logger.debug(f"Request started: {json.dumps(request_data)}")
                
                result = await func(*args, **kwargs)
                
                end_time = datetime.utcnow()
                duration = (end_time - start_time).total_seconds()
                
                response_data = {
                    "duration": duration,
                    "result": result
                }
                
                self.logger.debug(f"Request completed: {json.dumps(response_data)}")
                return result
            except Exception as e:
                self.logger.error(f"Request failed: {str(e)}")
                raise
        return wrapper
```

### Trace Manager

```python
# trace_manager.py
from typing import Dict, any, List
import logging
import uuid
from datetime import datetime
import json

class TraceManager:
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        self.traces: Dict[str, List[Dict[str, any]]] = {}

    def start_trace(self, trace_id: str = None) -> str:
        try:
            if trace_id is None:
                trace_id = str(uuid.uuid4())
            
            self.traces[trace_id] = []
            return trace_id
        except Exception as e:
            self.logger.error(f"Error starting trace: {str(e)}")
            raise

    def add_trace_event(self, trace_id: str, 
                       event_type: str, 
                       data: Dict[str, any]):
        try:
            if trace_id not in self.traces:
                self.start_trace(trace_id)
            
            event = {
                "timestamp": datetime.utcnow().isoformat(),
                "type": event_type,
                "data": data
            }
            
            self.traces[trace_id].append(event)
            self.logger.debug(f"Trace event added: {json.dumps(event)}")
        except Exception as e:
            self.logger.error(f"Error adding trace event: {str(e)}")
            raise

    def get_trace(self, trace_id: str) -> List[Dict[str, any]]:
        try:
            return self.traces.get(trace_id, [])
        except Exception as e:
            self.logger.error(f"Error getting trace: {str(e)}")
            raise

    def export_trace(self, trace_id: str) -> str:
        try:
            return json.dumps(self.get_trace(trace_id), indent=2)
        except Exception as e:
            self.logger.error(f"Error exporting trace: {str(e)}")
            raise
```

## Debugging Tools

### Request Debugger

```python
# request_debugger.py
from typing import Dict, any
import logging
import json
from datetime import datetime
import aiohttp

class RequestDebugger:
    def __init__(self):
        self.logger = logging.getLogger(__name__)

    async def debug_request(self, 
                          method: str, 
                          url: str, 
                          headers: Dict[str, str] = None,
                          data: any = None):
        try:
            request_data = {
                "timestamp": datetime.utcnow().isoformat(),
                "method": method,
                "url": url,
                "headers": headers or {},
                "data": data
            }
            
            self.logger.debug(f"Request details: {json.dumps(request_data)}")
            
            async with aiohttp.ClientSession() as session:
                async with session.request(method, url, 
                                         headers=headers, 
                                         json=data) as response:
                    response_data = {
                        "status": response.status,
                        "headers": dict(response.headers),
                        "body": await response.text()
                    }
                    
                    self.logger.debug(f"Response details: {json.dumps(response_data)}")
                    return response_data
        except Exception as e:
            self.logger.error(f"Error debugging request: {str(e)}")
            raise

    async def validate_response(self, response: Dict[str, any]):
        try:
            if response["status"] >= 400:
                self.logger.error(f"Error response: {json.dumps(response)}")
                return False
            return True
        except Exception as e:
            self.logger.error(f"Error validating response: {str(e)}")
            raise
```

### Performance Profiler

```python
# performance_profiler.py
from typing import Dict, any, Callable
import logging
import cProfile
import pstats
import io
from functools import wraps
import time

class PerformanceProfiler:
    def __init__(self):
        self.logger = logging.getLogger(__name__)

    def profile(self, func: Callable):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            try:
                pr = cProfile.Profile()
                pr.enable()
                
                start_time = time.time()
                result = await func(*args, **kwargs)
                end_time = time.time()
                
                pr.disable()
                
                s = io.StringIO()
                ps = pstats.Stats(pr, stream=s).sort_stats('cumulative')
                ps.print_stats()
                
                profile_data = {
                    "function": func.__name__,
                    "duration": end_time - start_time,
                    "profile": s.getvalue()
                }
                
                self.logger.debug(f"Profile data: {json.dumps(profile_data)}")
                return result
            except Exception as e:
                self.logger.error(f"Error profiling function: {str(e)}")
                raise
        return wrapper

    async def analyze_performance(self, 
                                func: Callable, 
                                *args, 
                                **kwargs) -> Dict[str, any]:
        try:
            pr = cProfile.Profile()
            pr.enable()
            
            start_time = time.time()
            result = await func(*args, **kwargs)
            end_time = time.time()
            
            pr.disable()
            
            s = io.StringIO()
            ps = pstats.Stats(pr, stream=s).sort_stats('cumulative')
            ps.print_stats()
            
            return {
                "function": func.__name__,
                "duration": end_time - start_time,
                "profile": s.getvalue(),
                "result": result
            }
        except Exception as e:
            self.logger.error(f"Error analyzing performance: {str(e)}")
            raise
```

## Debugging Best Practices

### Debug Manager

```python
# debug_manager.py
from typing import Dict, any, List
import logging
import json
from datetime import datetime
import inspect

class DebugManager:
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        self.debug_data: Dict[str, List[Dict[str, any]]] = {}

    def start_debug_session(self, session_id: str = None) -> str:
        try:
            if session_id is None:
                session_id = str(uuid.uuid4())
            
            self.debug_data[session_id] = []
            return session_id
        except Exception as e:
            self.logger.error(f"Error starting debug session: {str(e)}")
            raise

    def add_debug_info(self, session_id: str, 
                      info_type: str, 
                      data: Dict[str, any]):
        try:
            if session_id not in self.debug_data:
                self.start_debug_session(session_id)
            
            debug_info = {
                "timestamp": datetime.utcnow().isoformat(),
                "type": info_type,
                "data": data,
                "stack": inspect.stack()[1:]
            }
            
            self.debug_data[session_id].append(debug_info)
            self.logger.debug(f"Debug info added: {json.dumps(debug_info)}")
        except Exception as e:
            self.logger.error(f"Error adding debug info: {str(e)}")
            raise

    def get_debug_session(self, session_id: str) -> List[Dict[str, any]]:
        try:
            return self.debug_data.get(session_id, [])
        except Exception as e:
            self.logger.error(f"Error getting debug session: {str(e)}")
            raise

    def analyze_debug_session(self, session_id: str) -> Dict[str, any]:
        try:
            session_data = self.get_debug_session(session_id)
            
            analysis = {
                "total_events": len(session_data),
                "event_types": {},
                "errors": [],
                "warnings": []
            }
            
            for event in session_data:
                event_type = event["type"]
                analysis["event_types"][event_type] = \
                    analysis["event_types"].get(event_type, 0) + 1
                
                if "error" in event_type.lower():
                    analysis["errors"].append(event)
                elif "warning" in event_type.lower():
                    analysis["warnings"].append(event)
            
            return analysis
        except Exception as e:
            self.logger.error(f"Error analyzing debug session: {str(e)}")
            raise
```

### Error Analyzer

```python
# error_analyzer.py
from typing import Dict, any, List
import logging
import json
from datetime import datetime
import traceback

class ErrorAnalyzer:
    def __init__(self):
        self.logger = logging.getLogger(__name__)

    async def analyze_error(self, error: Exception) -> Dict[str, any]:
        try:
            error_data = {
                "timestamp": datetime.utcnow().isoformat(),
                "error_type": type(error).__name__,
                "error_message": str(error),
                "stack_trace": traceback.format_exc(),
                "context": {}
            }
            
            self.logger.error(f"Error analyzed: {json.dumps(error_data)}")
            return error_data
        except Exception as e:
            self.logger.error(f"Error analyzing error: {str(e)}")
            raise

    async def suggest_solution(self, error_data: Dict[str, any]) -> str:
        try:
            # Implementeer oplossing suggestie logica
            return "Suggested solution"
        except Exception as e:
            self.logger.error(f"Error suggesting solution: {str(e)}")
            raise

    async def track_error_patterns(self, error_data: Dict[str, any]):
        try:
            # Implementeer error pattern tracking logica
            pass
        except Exception as e:
            self.logger.error(f"Error tracking error patterns: {str(e)}")
            raise
```

## Volgende Stap

Nu je bekend bent met debugging technieken, gaan we in de volgende les kijken naar [veelvoorkomende problemen](08_03_common_issues.md). Daar leren we hoe we deze problemen kunnen identificeren en oplossen. 