# Установка VibeSpeak на сервер Ubuntu 24.04

Это руководство по автоматической установке VibeSpeak на чистый сервер Ubuntu 24.04.

## Информация о сервере

- **IP адрес**: 79.174.77.181
- **ОС**: Ubuntu 24.04 LTS
- **Требования**: Чистый сервер, root доступ

## Способ 1: Автоматическая установка (Рекомендуется)

### Шаг 1: Подключитесь к серверу

```bash
ssh root@79.174.77.181
```

### Шаг 2: Скачайте проект

```bash
# Установите git (если еще не установлен)
apt-get update
apt-get install -y git

# Клонируйте репозиторий
cd /var/www
git clone https://github.com/your-username/vibespeak.git
cd vibespeak
```

### Шаг 3: Запустите установку

```bash
chmod +x install.sh
./install.sh
```

Скрипт спросит:
1. **MySQL root пароль** - установите надежный пароль
2. **Наличие домена** - введите ваш домен или нажмите 'n' для использования IP
3. **SSL сертификаты** - рекомендуется для production

### Шаг 4: Сохраните учетные данные

После установки учетные данные будут сохранены в:
```bash
cat /root/vibespeak-credentials.txt
```

**ВАЖНО**: Сохраните эти данные и удалите файл!

## Способ 2: Загрузка с локальной машины

### Шаг 1: На локальной машине

```bash
# Перейдите в директорию проекта
cd vibespeak

# Сделайте скрипт исполняемым
chmod +x deploy-to-server.sh

# Загрузите файлы на сервер
./deploy-to-server.sh
```

### Шаг 2: На сервере

```bash
ssh root@79.174.77.181
cd /var/www/vibespeak
chmod +x install.sh
./install.sh
```

## Что устанавливает скрипт

- ✅ PHP 8.3 + расширения
- ✅ MySQL 8.0
- ✅ Node.js 20
- ✅ Nginx
- ✅ Composer
- ✅ Все зависимости проекта
- ✅ Systemd сервисы для WebSocket и API
- ✅ Firewall (UFW)
- ✅ SSL сертификаты (опционально)

## После установки

### Доступ к приложению

**С доменом:**
- Frontend: https://yourdomain.com
- API: https://api.yourdomain.com
- WebSocket: wss://ws.yourdomain.com

**Без домена (только IP):**
- Frontend: http://79.174.77.181
- API: http://79.174.77.181:8000
- WebSocket: ws://79.174.77.181:8080

### Тестовый аккаунт

```
Username: demo
Password: password
```

### Проверка статуса сервисов

```bash
# Проверить все сервисы
systemctl status vibespeak-websocket
systemctl status vibespeak-api
systemctl status nginx
systemctl status mysql

# Посмотреть логи
journalctl -u vibespeak-websocket -f
journalctl -u vibespeak-api -f
tail -f /var/log/nginx/error.log
```

### Управление сервисами

```bash
# Перезапустить сервисы
systemctl restart vibespeak-websocket
systemctl restart vibespeak-api
systemctl restart nginx

# Остановить сервисы
systemctl stop vibespeak-websocket
systemctl stop vibespeak-api

# Запустить сервисы
systemctl start vibespeak-websocket
systemctl start vibespeak-api
```

## Настройка DNS (если используется домен)

Настройте A-записи для вашего домена:

```
yourdomain.com      A    79.174.77.181
www.yourdomain.com  A    79.174.77.181
api.yourdomain.com  A    79.174.77.181
ws.yourdomain.com   A    79.174.77.181
```

Подождите 5-10 минут для распространения DNS.

## SSL Сертификаты

Скрипт автоматически установит SSL сертификаты от Let's Encrypt если вы укажете домен.

### Ручная установка SSL:

```bash
certbot --nginx -d yourdomain.com -d www.yourdomain.com -d api.yourdomain.com -d ws.yourdomain.com
```

### Автообновление сертификатов:

```bash
# Проверить автообновление
certbot renew --dry-run

# Сертификаты автоматически обновляются через systemd timer
systemctl status certbot.timer
```

## Обновление приложения

### Обновить код:

```bash
cd /var/www/vibespeak
git pull origin main

# Обновить backend
cd server
composer install --no-dev
systemctl restart vibespeak-websocket
systemctl restart vibespeak-api

# Обновить frontend
cd ../client
npm install
npm run build
systemctl restart nginx
```

## Резервное копирование

### База данных:

```bash
# Создать backup
mysqldump -u root -p vibespeak > /root/vibespeak_backup_$(date +%Y%m%d).sql

# Восстановить backup
mysql -u root -p vibespeak < /root/vibespeak_backup_20240101.sql
```

### Автоматический backup (cron):

```bash
# Добавить в crontab
crontab -e

# Добавить строку (backup каждый день в 2 AM)
0 2 * * * mysqldump -u root -pYOUR_PASSWORD vibespeak > /root/backups/vibespeak_$(date +\%Y\%m\%d).sql
```

### Файлы приложения:

```bash
# Backup всего приложения
tar -czf /root/vibespeak_backup_$(date +%Y%m%d).tar.gz /var/www/vibespeak

# Восстановить
tar -xzf /root/vibespeak_backup_20240101.tar.gz -C /
```

## Troubleshooting

### WebSocket не подключается

```bash
# Проверить статус
systemctl status vibespeak-websocket

# Проверить логи
journalctl -u vibespeak-websocket -f

# Проверить порт
netstat -tlnp | grep 8080

# Перезапустить
systemctl restart vibespeak-websocket
```

### API не отвечает

```bash
# Проверить статус
systemctl status vibespeak-api

# Проверить логи
journalctl -u vibespeak-api -f

# Тест API
curl http://localhost:8000/health
```

### База данных

```bash
# Проверить подключение
mysql -u vibespeak_user -p vibespeak

# Проверить статус MySQL
systemctl status mysql

# Логи MySQL
tail -f /var/log/mysql/error.log
```

### Nginx ошибки

```bash
# Тест конфигурации
nginx -t

# Перезапустить Nginx
systemctl restart nginx

# Логи
tail -f /var/log/nginx/error.log
tail -f /var/log/nginx/access.log
```

### Firewall блокирует доступ

```bash
# Проверить правила
ufw status

# Открыть порты
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 8080/tcp
```

## Мониторинг

### Использование ресурсов:

```bash
# CPU и память
htop

# Диск
df -h

# Сеть
netstat -tlnp
```

### Логи в реальном времени:

```bash
# Все сервисы
journalctl -f

# Конкретный сервис
journalctl -u vibespeak-websocket -f
```

## Безопасность

### Рекомендации:

1. **Смените пароль MySQL root**
2. **Используйте SSH ключи вместо паролей**
3. **Настройте fail2ban для защиты от bruteforce**
4. **Регулярно обновляйте систему**
5. **Используйте SSL/TLS (HTTPS)**
6. **Настройте автоматические backup'ы**

### Установка fail2ban:

```bash
apt-get install -y fail2ban
systemctl enable fail2ban
systemctl start fail2ban
```

### Смена SSH порта:

```bash
# Редактировать /etc/ssh/sshd_config
nano /etc/ssh/sshd_config

# Изменить строку
Port 2222  # вместо 22

# Перезапустить SSH
systemctl restart sshd

# Обновить firewall
ufw allow 2222/tcp
```

## Удаление

Если нужно полностью удалить VibeSpeak:

```bash
# Остановить сервисы
systemctl stop vibespeak-websocket
systemctl stop vibespeak-api
systemctl disable vibespeak-websocket
systemctl disable vibespeak-api

# Удалить файлы
rm -rf /var/www/vibespeak

# Удалить базу данных
mysql -u root -p -e "DROP DATABASE vibespeak; DROP USER 'vibespeak_user'@'localhost';"

# Удалить конфигурации
rm /etc/systemd/system/vibespeak-*.service
rm /etc/nginx/sites-enabled/vibespeak
rm /etc/nginx/sites-available/vibespeak

# Перезагрузить systemd
systemctl daemon-reload

# Перезапустить nginx
systemctl restart nginx
```

## Поддержка

Для получения помощи:
- Документация: [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)
- User Guide: [docs/USER_GUIDE.md](docs/USER_GUIDE.md)
- GitHub Issues: создайте issue в репозитории

## Полезные команды

```bash
# Проверить все порты
netstat -tulpn

# Проверить использование диска
du -sh /var/www/vibespeak

# Очистить логи
journalctl --vacuum-time=7d

# Перезагрузить сервер
reboot

# Посмотреть версии
php -v
mysql --version
node -v
nginx -v
```
