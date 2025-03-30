#!/bin/bash

# Скрипт для деплоя приложения на сервер VK Cloud через SCP (без Git)

# Конфигурация
SERVER_USER="ubuntu"
SERVER_IP="94.139.245.225" 
SERVER_PORT="22"
REMOTE_DIR="/home/$SERVER_USER/article-generator"
LOCAL_DIR="$(pwd)"

echo "🚀 Начинаем деплой на сервер VK Cloud через SCP"

# Создание директории на удаленном сервере если её нет
echo "📁 Проверка удаленной директории..."
ssh -p $SERVER_PORT $SERVER_USER@$SERVER_IP "mkdir -p $REMOTE_DIR"

# Копирование файлов на сервер
echo "📤 Копирование файлов на сервер..."
scp -P $SERVER_PORT -r "$LOCAL_DIR/src" "$LOCAL_DIR/config" "$LOCAL_DIR/requirements.txt" "$SERVER_USER@$SERVER_IP:$REMOTE_DIR/"

# Создание директории для логов если её нет
ssh -p $SERVER_PORT $SERVER_USER@$SERVER_IP "mkdir -p $REMOTE_DIR/logs"

# Настройка и запуск приложения на сервере
echo "🔧 Настройка и запуск приложения на сервере..."
ssh -p $SERVER_PORT $SERVER_USER@$SERVER_IP << EOF
    cd $REMOTE_DIR
    
    # Создание виртуальной среды если её нет
    if [ ! -d "venv" ]; then
        echo "🔧 Создание виртуальной среды Python..."
        python3 -m venv venv
    fi
    
    # Активация виртуальной среды и установка зависимостей
    source venv/bin/activate
    pip install -r requirements.txt
    
    # Копирование .env.example в .env если .env не существует
    if [ ! -f "config/.env" ] && [ -f "config/.env.example" ]; then
        echo "⚙️ Создание файла конфигурации из шаблона..."
        cp config/.env.example config/.env
        echo "❗ Не забудьте отредактировать config/.env для настройки API ключей!"
    fi
    
    # Создание и настройка systemd сервиса если его нет
    if [ ! -f "/etc/systemd/system/article-generator.service" ]; then
        echo "🔧 Настройка systemd сервиса..."
        cat << 'EOFSERVICE' | sudo tee /etc/systemd/system/article-generator.service
[Unit]
Description=Article Generator Service
After=network.target

[Service]
User=$USER
WorkingDirectory=$REMOTE_DIR
Environment="PATH=$REMOTE_DIR/venv/bin"
ExecStart=$REMOTE_DIR/venv/bin/python src/main.py
Restart=always

[Install]
WantedBy=multi-user.target
EOFSERVICE

        sudo systemctl daemon-reload
        sudo systemctl enable article-generator
    fi
    
    # Перезапуск сервиса
    sudo systemctl restart article-generator
    echo "✅ Сервис перезапущен"
    sleep 2
    sudo systemctl status article-generator | grep "Active"
EOF

echo "✅ Деплой завершен успешно"
echo "📝 Не забудьте настроить переменные окружения на сервере в файле config/.env" 