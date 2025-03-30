# Генератор статей на базе ЛЛМ

Веб-приложение для автоматической генерации статей с использованием различных языковых моделей (OpenAI GPT, Yandex GPT и др.)

## Особенности

- Поддержка разных ЛЛМ (OpenAI и Yandex GPT)
- REST API для интеграции
- Настройка стиля, темы и целевой аудитории для статей
- Логирование всех запросов

## Требования

- Python 3.8+
- pip

## Локальная установка

1. Клонируйте репозиторий:
```bash
git clone [url_репозитория]
cd [директория_проекта]
```

2. Создайте и активируйте виртуальное окружение:
```bash
python -m venv venv
source venv/bin/activate  # Для Linux/Mac
# или
venv\Scripts\activate  # Для Windows
```

3. Установите зависимости:
```bash
pip install -r requirements.txt
```

4. Создайте файл с переменными окружения:
```bash
cp config/.env.example config/.env
```

5. Отредактируйте файл `config/.env` и добавьте ваши API ключи

## Запуск приложения

```bash
python src/main.py
```

Приложение будет доступно по адресу: http://localhost:8000

## API Endpoints

### `POST /generate-article`

Генерирует статью по заданным параметрам.

**Параметры запроса:**
```json
{
  "topic": "Искусственный интеллект в медицине",
  "style": "научно-популярный",
  "audience": "студенты медицинских вузов",
  "max_tokens": 1500,
  "llm_provider": "openai"
}
```

**Пример ответа:**
```json
{
  "success": true,
  "article": "Текст сгенерированной статьи..."
}
```

### `GET /health`

Проверка работоспособности сервиса.

## Деплой на VK Cloud

### Настройка сервера

1. Подключитесь к серверу VK Cloud по SSH:
```bash
ssh [пользователь]@[адрес_сервера]
```

2. Обновите систему и установите необходимые пакеты:
```bash
sudo apt update
sudo apt upgrade -y
sudo apt install -y python3-pip python3-venv git
```

3. Клонируйте репозиторий:
```bash
git clone [url_репозитория] /home/[пользователь]/article-generator
cd /home/[пользователь]/article-generator
```

4. Создайте виртуальное окружение и установите зависимости:
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

5. Настройте переменные окружения:
```bash
cp config/.env.example config/.env
nano config/.env  # отредактируйте файл и добавьте API ключи
```

### Запуск как системный сервис

1. Создайте файл сервиса:
```bash
sudo nano /etc/systemd/system/article-generator.service
```

2. Добавьте следующее содержимое:
```
[Unit]
Description=Article Generator Service
After=network.target

[Service]
User=[пользователь]
WorkingDirectory=/home/[пользователь]/article-generator
Environment="PATH=/home/[пользователь]/article-generator/venv/bin"
ExecStart=/home/[пользователь]/article-generator/venv/bin/python src/main.py
Restart=always

[Install]
WantedBy=multi-user.target
```

3. Активируйте и запустите сервис:
```bash
sudo systemctl daemon-reload
sudo systemctl enable article-generator
sudo systemctl start article-generator
```

4. Проверьте статус сервиса:
```bash
sudo systemctl status article-generator
```

### Настройка Nginx (опционально)

Если вы хотите настроить прокси-сервер Nginx:

1. Установите Nginx:
```bash
sudo apt install -y nginx
```

2. Создайте конфигурационный файл:
```bash
sudo nano /etc/nginx/sites-available/article-generator
```

3. Добавьте конфигурацию:
```
server {
    listen 80;
    server_name [ваш_домен_или_IP];

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

4. Активируйте сайт и перезапустите Nginx:
```bash
sudo ln -s /etc/nginx/sites-available/article-generator /etc/nginx/sites-enabled/
sudo systemctl restart nginx
```

## Локальная разработка и деплой

Для локальной разработки и последующего деплоя на VK Cloud:

1. Разрабатывайте и тестируйте приложение локально
2. Создайте репозиторий Git и коммитьте изменения
3. Подключитесь к серверу VK Cloud и обновите код:
```bash
ssh [пользователь]@[адрес_сервера]
cd /home/[пользователь]/article-generator
git pull
sudo systemctl restart article-generator
``` 