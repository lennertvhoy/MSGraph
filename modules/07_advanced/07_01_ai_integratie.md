# AI Integratie

In deze les gaan we kijken naar verschillende manieren om AI-functionaliteit te integreren met de Microsoft Graph API. We behandelen Azure Cognitive Services, Natural Language Processing, Computer Vision en custom AI modellen.

## Azure Cognitive Services Integratie

### Text Analytics

```python
from azure.cognitiveservices.language.textanalytics import TextAnalyticsClient
from msrest.authentication import CognitiveServicesCredentials
from typing import List, Dict
import logging

class TextAnalyticsService:
    def __init__(self, subscription_key: str, endpoint: str):
        self.client = TextAnalyticsClient(
            endpoint=endpoint,
            credentials=CognitiveServicesCredentials(subscription_key)
        )
        self.logger = logging.getLogger(__name__)

    async def analyze_sentiment(self, text: str) -> Dict[str, float]:
        try:
            result = await self.client.sentiment(text)
            return {
                "positive": result.sentiment_scores.positive,
                "neutral": result.sentiment_scores.neutral,
                "negative": result.sentiment_scores.negative
            }
        except Exception as e:
            self.logger.error(f"Error analyzing sentiment: {str(e)}")
            raise

    async def extract_key_phrases(self, text: str) -> List[str]:
        try:
            result = await self.client.key_phrases(text)
            return result.key_phrases
        except Exception as e:
            self.logger.error(f"Error extracting key phrases: {str(e)}")
            raise
```

### Computer Vision

```python
from azure.cognitiveservices.vision.computervision import ComputerVisionClient
from msrest.authentication import CognitiveServicesCredentials
from typing import List, Dict
import logging

class ComputerVisionService:
    def __init__(self, subscription_key: str, endpoint: str):
        self.client = ComputerVisionClient(
            endpoint=endpoint,
            credentials=CognitiveServicesCredentials(subscription_key)
        )
        self.logger = logging.getLogger(__name__)

    async def analyze_image(self, image_url: str) -> Dict[str, any]:
        try:
            result = await self.client.analyze_image(
                image_url,
                visual_features=["Categories", "Description", "Tags"]
            )
            return {
                "categories": result.categories,
                "description": result.description,
                "tags": result.tags
            }
        except Exception as e:
            self.logger.error(f"Error analyzing image: {str(e)}")
            raise

    async def detect_objects(self, image_url: str) -> List[Dict[str, any]]:
        try:
            result = await self.client.detect_objects(image_url)
            return [
                {
                    "object": obj.object_property,
                    "confidence": obj.confidence,
                    "rectangle": obj.rectangle
                }
                for obj in result.objects
            ]
        except Exception as e:
            self.logger.error(f"Error detecting objects: {str(e)}")
            raise
```

## Natural Language Processing

### Email Analysis

```python
class EmailAnalyzer:
    def __init__(self, text_analytics: TextAnalyticsService):
        self.text_analytics = text_analytics
        self.logger = logging.getLogger(__name__)

    async def analyze_email_content(self, email_content: str) -> Dict[str, any]:
        try:
            sentiment = await self.text_analytics.analyze_sentiment(email_content)
            key_phrases = await self.text_analytics.extract_key_phrases(email_content)
            
            return {
                "sentiment": sentiment,
                "key_phrases": key_phrases,
                "summary": await self.generate_summary(email_content)
            }
        except Exception as e:
            self.logger.error(f"Error analyzing email: {str(e)}")
            raise

    async def generate_summary(self, content: str) -> str:
        try:
            # Implementeer samenvattingslogica
            return "Email summary"
        except Exception as e:
            self.logger.error(f"Error generating summary: {str(e)}")
            raise
```

### Document Processing

```python
class DocumentProcessor:
    def __init__(self, text_analytics: TextAnalyticsService):
        self.text_analytics = text_analytics
        self.logger = logging.getLogger(__name__)

    async def process_document(self, document_content: str) -> Dict[str, any]:
        try:
            entities = await self.extract_entities(document_content)
            sentiment = await self.text_analytics.analyze_sentiment(document_content)
            
            return {
                "entities": entities,
                "sentiment": sentiment,
                "language": await self.detect_language(document_content)
            }
        except Exception as e:
            self.logger.error(f"Error processing document: {str(e)}")
            raise

    async def extract_entities(self, content: str) -> List[Dict[str, any]]:
        try:
            # Implementeer entity extractie logica
            return []
        except Exception as e:
            self.logger.error(f"Error extracting entities: {str(e)}")
            raise

    async def detect_language(self, content: str) -> str:
        try:
            # Implementeer taal detectie logica
            return "en"
        except Exception as e:
            self.logger.error(f"Error detecting language: {str(e)}")
            raise
```

## Computer Vision Toepassingen

### Image Analysis

```python
class ImageAnalyzer:
    def __init__(self, computer_vision: ComputerVisionService):
        self.computer_vision = computer_vision
        self.logger = logging.getLogger(__name__)

    async def analyze_profile_picture(self, image_url: str) -> Dict[str, any]:
        try:
            analysis = await self.computer_vision.analyze_image(image_url)
            objects = await self.computer_vision.detect_objects(image_url)
            
            return {
                "analysis": analysis,
                "objects": objects,
                "content_moderation": await self.check_content(image_url)
            }
        except Exception as e:
            self.logger.error(f"Error analyzing profile picture: {str(e)}")
            raise

    async def check_content(self, image_url: str) -> Dict[str, bool]:
        try:
            # Implementeer content moderatie logica
            return {
                "is_appropriate": True,
                "contains_text": False,
                "is_blurry": False
            }
        except Exception as e:
            self.logger.error(f"Error checking content: {str(e)}")
            raise
```

### Document OCR

```python
class DocumentOCR:
    def __init__(self, computer_vision: ComputerVisionService):
        self.computer_vision = computer_vision
        self.logger = logging.getLogger(__name__)

    async def extract_text(self, image_url: str) -> str:
        try:
            result = await self.computer_vision.recognize_printed_text(image_url)
            return result.text
        except Exception as e:
            self.logger.error(f"Error extracting text: {str(e)}")
            raise

    async def analyze_layout(self, image_url: str) -> Dict[str, any]:
        try:
            result = await self.computer_vision.analyze_layout(image_url)
            return {
                "lines": result.lines,
                "words": result.words,
                "paragraphs": result.paragraphs
            }
        except Exception as e:
            self.logger.error(f"Error analyzing layout: {str(e)}")
            raise
```

## Custom AI Modellen

### Model Training

```python
from azureml.core import Workspace, Experiment, Run
from azureml.core.compute import ComputeTarget
from azureml.core.model import Model
import logging

class ModelTrainer:
    def __init__(self, workspace: Workspace):
        self.workspace = workspace
        self.logger = logging.getLogger(__name__)

    async def train_model(self, training_data: str, model_name: str):
        try:
            experiment = Experiment(self.workspace, name=f"train_{model_name}")
            run = experiment.start_logging()
            
            # Implementeer model training logica
            model = await self._train(training_data)
            
            # Registreer het model
            model.register(
                workspace=self.workspace,
                model_name=model_name,
                model_path="model.pkl"
            )
            
            run.complete()
        except Exception as e:
            self.logger.error(f"Error training model: {str(e)}")
            raise

    async def _train(self, data: str):
        try:
            # Implementeer specifieke training logica
            pass
        except Exception as e:
            self.logger.error(f"Error in training process: {str(e)}")
            raise
```

### Model Deployment

```python
class ModelDeployer:
    def __init__(self, workspace: Workspace):
        self.workspace = workspace
        self.logger = logging.getLogger(__name__)

    async def deploy_model(self, model_name: str, compute_target: ComputeTarget):
        try:
            model = Model(self.workspace, name=model_name)
            
            # Maak een deployment configuratie
            deployment_config = {
                "compute_type": compute_target.type,
                "memory_gb": 2,
                "cpu_cores": 1
            }
            
            # Deploy het model
            service = model.deploy(
                name=f"{model_name}_service",
                deployment_config=deployment_config
            )
            
            return service
        except Exception as e:
            self.logger.error(f"Error deploying model: {str(e)}")
            raise

    async def test_deployment(self, service, test_data: dict):
        try:
            result = await service.run(test_data)
            return result
        except Exception as e:
            self.logger.error(f"Error testing deployment: {str(e)}")
            raise
```

## Best Practices

### 1. Error Handling

```python
class AIErrorHandler:
    def __init__(self):
        self.logger = logging.getLogger(__name__)

    async def handle_ai_error(self, error: Exception, context: dict):
        try:
            error_type = type(error).__name__
            error_message = str(error)
            
            self.logger.error(
                f"AI service error: {error_type}",
                error=error_message,
                context=context
            )
            
            # Implementeer error recovery logica
            return await self.recover_from_error(error_type, context)
        except Exception as e:
            self.logger.error(f"Error handling AI error: {str(e)}")
            raise

    async def recover_from_error(self, error_type: str, context: dict):
        try:
            # Implementeer recovery logica
            pass
        except Exception as e:
            self.logger.error(f"Error in recovery process: {str(e)}")
            raise
```

### 2. Performance Optimization

```python
class AIOptimizer:
    def __init__(self):
        self.logger = logging.getLogger(__name__)

    async def optimize_model(self, model: any):
        try:
            # Implementeer model optimalisatie logica
            pass
        except Exception as e:
            self.logger.error(f"Error optimizing model: {str(e)}")
            raise

    async def cache_results(self, key: str, result: any):
        try:
            # Implementeer caching logica
            pass
        except Exception as e:
            self.logger.error(f"Error caching results: {str(e)}")
            raise
```

## Volgende Stap

Nu je bekend bent met AI integratie, gaan we in de volgende les kijken naar [real-time communicatie](07_02_realtime.md). Daar leren we hoe we real-time updates en notificaties kunnen implementeren in onze applicaties. 