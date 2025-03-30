#!/bin/bash

# Скрипт для настройки и деплоя приложения на сервер VK Cloud с GitHub
# Безопасная версия - чувствительные данные запрашиваются или берутся из переменных окружения

# Загрузка чувствительных данных из файла, если он существует
if [ -f ".env.deploy" ]; then
  source .env.deploy
fi

# Запрос данных, если они не определены
if [ -z "$SERVER_USER" ]; then
  read -p "Введите имя пользователя сервера: " SERVER_USER
fi

if [ -z "$SERVER_IP" ]; then
  read -p "Введите IP-адрес сервера: " SERVER_IP
fi

if [ -z "$SERVER_PORT" ]; then
  read -p "Введите порт SSH (по умолчанию 22): " SERVER_PORT
  SERVER_PORT=${SERVER_PORT:-22}
fi

if [ -z "$GITHUB_REPO" ]; then
  read -p "Введите URL GitHub репозитория: " GITHUB_REPO
fi

if [ -z "$REMOTE_DIR" ]; then
  read -p "Введите директорию на сервере (по умолчанию /home/$SERVER_USER/article-generator): " REMOTE_DIR
  REMOTE_DIR=${REMOTE_DIR:-/home/$SERVER_USER/article-generator}
fi

# Сохранение данных для будущего использования
read -p "Сохранить эти данные для будущих запусков? (y/n): " SAVE_DATA
if [ "$SAVE_DATA" = "y" ]; then
  echo "SERVER_USER=\"$SERVER_USER\"" > .env.deploy
  echo "SERVER_IP=\"$SERVER_IP\"" >> .env.deploy
  echo "SERVER_PORT=\"$SERVER_PORT\"" >> .env.deploy
  echo "GITHUB_REPO=\"$GITHUB_REPO\"" >> .env.deploy
  echo "REMOTE_DIR=\"$REMOTE_DIR\"" >> .env.deploy
  echo "# Добавлен в .gitignore, не коммитьте этот файл" >> .env.deploy
  
  # Добавляем файл в .gitignore, если его там еще нет
  if ! grep -q ".env.deploy" .gitignore; then
    echo ".env.deploy" >> .gitignore
  fi
fi

echo "🚀 Начинаем настройку и деплой на сервер"

# Подключение к серверу и настройка/обновление приложения
echo "🔄 Настройка на сервере..."
ssh -p $SERVER_PORT $SERVER_USER@$SERVER_IP << EOF
    # Проверяем установлен ли Git и Python
    command -v git >/dev/null 2>&1 || { echo "⚙️ Устанавливаем Git..."; sudo apt update && sudo apt install -y git; }
    command -v python3 >/dev/null 2>&1 || { echo "⚙️ Устанавливаем Python..."; sudo apt update && sudo apt install -y python3 python3-pip python3-venv; }
    
    # Создаем или обновляем репозиторий
    if [ ! -d "$REMOTE_DIR" ]; then
        echo "📁 Клонирование репозитория..."
        git clone $GITHUB_REPO $REMOTE_DIR
    else
        echo "🔄 Обновление репозитория..."
        cd $REMOTE_DIR
        git pull
    fi
    
    # Создаем виртуальное окружение если его нет
    cd $REMOTE_DIR
    if [ ! -d "venv" ]; then
        echo "🔧 Создание виртуальной среды Python..."
        python3 -m venv venv
    fi
    
    # Устанавливаем зависимости
    echo "📦 Установка зависимостей..."
    source venv/bin/activate
    pip install -r requirements.txt
    
    # Создаем директорию для логов
    mkdir -p logs
    
    # Копируем .env.example в .env если .env не существует
    if [ ! -f "config/.env" ] && [ -f "config/.env.example" ]; then
        echo "⚙️ Создание файла конфигурации из шаблона..."
        cp config/.env.example config/.env
        echo "❗ Не забудьте отредактировать config/.env для настройки API ключей!"
    fi
    
    # Создаем и настраиваем systemd сервис если его нет
    if [ ! -f "/etc/systemd/system/article-generator.service" ]; then
        echo "🔧 Настройка systemd сервиса..."
        sudo bash -c 'cat > /etc/systemd/system/article-generator.service << EOFSERVICE
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
EOFSERVICE'

        sudo systemctl daemon-reload
        sudo systemctl enable article-generator
    fi
    
    # Перезапускаем сервис
    echo "🔄 Перезапуск сервиса..."
    sudo systemctl restart article-generator
    echo "✅ Сервис перезапущен"
    sleep 2
    sudo systemctl status article-generator | grep "Active"
EOF

echo "✅ Деплой завершен успешно"
echo "📝 Не забудьте настроить переменные окружения на сервере в файле config/.env" 