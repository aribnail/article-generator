import os
import logging
from fastapi import FastAPI, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional

from llm_client import OpenAIClient, YandexGPTClient

# Настройка логирования
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("logs/app.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

app = FastAPI(title="Генератор статей", description="API для генерации статей на основе ЛЛМ")

# Модели данных
class ArticleRequest(BaseModel):
    topic: str
    style: str
    audience: str
    max_tokens: Optional[int] = 1500
    llm_provider: Optional[str] = "openai"  # openai или yandex


# Выбор провайдера ЛЛМ
def get_llm_client(provider: str = "openai"):
    if provider.lower() == "openai":
        return OpenAIClient()
    elif provider.lower() == "yandex":
        return YandexGPTClient()
    else:
        raise ValueError(f"Неподдерживаемый провайдер ЛЛМ: {provider}")


@app.post("/generate-article")
async def generate_article(request: ArticleRequest):
    try:
        logger.info(f"Запрос на генерацию статьи: {request.dict()}")
        
        # Получаем клиент ЛЛМ
        llm_client = get_llm_client(request.llm_provider)
        
        # Генерируем статью
        article = await llm_client.generate_article(
            topic=request.topic,
            style=request.style,
            audience=request.audience,
            max_tokens=request.max_tokens
        )
        
        return {"success": True, "article": article}
    
    except Exception as e:
        logger.error(f"Ошибка при генерации статьи: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Ошибка при генерации статьи: {str(e)}")


@app.get("/health")
def health_check():
    return {"status": "ok"}


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", "8000"))
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=True) 