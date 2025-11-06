# Deployment Instructions

## На продакшн сервере нужно выполнить:

### 1. Обновить код
```bash
cd /var/www/vibespeak
git pull origin claude/discord-clone-screen-share-011CUq4HgQ2XrpyNqyaR4tZr
```

### 2. Применить миграцию базы данных
```bash
cd /var/www/vibespeak/server
mysql -u vibespeak_user -p vibespeak < database/migrations/add_last_activity_to_rooms.sql
```
Введите пароль от MySQL при запросе.

### 3. Обновить зависимости
```bash
cd /var/www/vibespeak/server
composer dump-autoload --optimize
```

### 4. Перезапустить WebSocket сервер
```bash
# Остановить текущий сервер
pkill -f "php.*websocket/server.php"

# Или если используется systemd:
systemctl restart vibespeak-websocket

# Или запустить вручную:
cd /var/www/vibespeak/server
nohup php websocket/server.php > /dev/null 2>&1 &
```

### 5. Проверить что WebSocket сервер работает
```bash
ps aux | grep "websocket/server.php"
```

Должна быть видна запущенная процесса.

## Что было исправлено:

### 1. Автоматическое удаление комнат
- Комнаты автоматически удаляются через 3 минуты после того как последний участник покинет комнату
- Добавлено поле `last_activity` в таблицу `rooms`
- WebSocket сервер теперь отслеживает пустые комнаты и удаляет их из базы данных

### 2. Обновление количества участников
- Список комнат обновляется автоматически каждые 5 секунд
- Количество участников отображается в реальном времени

### 3. Компактные блоки комнат
- Уменьшен размер блоков комнат в боковой панели
- Улучшен дизайн с иконками и компактным отображением

### 4. Скрытие кода комнаты
- Код комнаты теперь показывается только участникам этой комнаты
- В общем списке код скрыт от посторонних пользователей

### 5. Исправлены ошибки
- Исправлена ошибка 500 при переключении микрофона/камеры (использовался peerId вместо userId)
- Добавлена поддержка screen sharing в Electron desktop app
