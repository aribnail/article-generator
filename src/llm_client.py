from abc import ABC, abstractmethod
import os
import requests
import openai
from dotenv import load_dotenv

# Загружаем переменные окружения
load_dotenv()

class LLMClient(ABC):
    """Абстрактный класс для работы с ЛЛМ API"""
    
    @abstractmethod
    async def generate_article(self, topic, style, audience, max_tokens=1500):
        """
        Генерация статьи по заданным параметрам
        
        Args:
            topic (str): Тема статьи
            style (str): Стиль написания (формальный, разговорный и т.д.)
            audience (str): Целевая аудитория
            max_tokens (int): Максимальное количество токенов в ответе
            
        Returns:
            str: Сгенерированный текст статьи
        """
        pass


class OpenAIClient(LLMClient):
    """Клиент для работы с API OpenAI"""
    
    def __init__(self, model="gpt-3.5-turbo"):
        self.api_key = os.getenv("OPENAI_API_KEY")
        if not self.api_key:
            raise ValueError("OPENAI_API_KEY не найден в переменных окружения")
        
        self.client = openai.AsyncOpenAI(api_key=self.api_key)
        self.model = model
    
    async def generate_article(self, topic, style, audience, max_tokens=1500):
        prompt = f"""
        Напиши статью на тему "{topic}".
        Стиль написания: {style}.
        Целевая аудитория: {audience}.
        """
        
        response = await self.client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": "Ты - профессиональный копирайтер, пишущий качественные статьи."},
                {"role": "user", "content": prompt}
            ],
            max_tokens=max_tokens
        )
        
        return response.choices[0].message.content


class YandexGPTClient(LLMClient):
    """Клиент для работы с API Yandex GPT"""
    
    def __init__(self, model="yandexgpt"):
        self.api_key = os.getenv("YANDEX_API_KEY")
        if not self.api_key:
            raise ValueError("YANDEX_API_KEY не найден в переменных окружения")
        
        self.api_url = "https://llm.api.cloud.yandex.net/foundationModels/v1/completion"
        self.model = model
    
    async def generate_article(self, topic, style, audience, max_tokens=1500):
        prompt = f"""
        Напиши статью на тему "{topic}".
        Стиль написания: {style}.
        Целевая аудитория: {audience}.
        """
        
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Api-Key {self.api_key}"
        }
        
        data = {
            "modelUri": f"gpt://{self.model}/latest",
            "completionOptions": {
                "maxTokens": max_tokens,
                "temperature": 0.7,
            },
            "messages": [
                {"role": "system", "text": "Ты - профессиональный копирайтер, пишущий качественные статьи."},
                {"role": "user", "text": prompt}
            ]
        }
        
        async with requests.post(self.api_url, headers=headers, json=data) as response:
            response_json = await response.json()
            return response_json["result"]["alternatives"][0]["message"]["text"] 