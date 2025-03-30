#!/bin/bash

# Скрипт для деплоя приложения на сервер VK Cloud

# Конфигурация
SERVER_USER="ubuntu"
SERVER_IP="94.139.245.225"
SERVER_PORT="22"
REMOTE_DIR="/home/$SERVER_USER/article-generator"

echo "🚀 Начинаем деплой на сервер VK Cloud"

# Проверка наличия локальных изменений Git
if [[ $(git status --porcelain) ]]; then
    echo "❌ Есть незакоммиченные изменения. Сначала выполните коммит."
    exit 1
fi

# Отправка изменений в удаленный репозиторий
echo "📤 Отправка изменений в Git репозиторий..."
git push origin main || { echo "❌ Ошибка при отправке изменений в Git"; exit 1; }

# Подключение к серверу и обновление кода
echo "🔄 Обновление кода на сервере..."
ssh -p $SERVER_PORT $SERVER_USER@$SERVER_IP << EOF
    cd $REMOTE_DIR
    git pull
    source venv/bin/activate
    pip install -r requirements.txt
    sudo systemctl restart article-generator
    echo "✅ Сервис перезапущен"
    sleep 2
    sudo systemctl status article-generator | grep "Active"
EOF

echo "✅ Деплой завершен успешно" 