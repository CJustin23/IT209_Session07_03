#!/usr/bin/env bash
set -euo pipefail

if ! id -u spring-runner >/dev/null 2>&1; then
  sudo useradd --system --no-create-home --shell /usr/sbin/nologin spring-runner
fi

sudo mkdir -p /opt/spring-app
sudo chown -R spring-runner:spring-runner /opt/spring-app

sudo mysql -uroot -p <<'SQL'
CREATE DATABASE IF NOT EXISTS springboot_db;
CREATE USER IF NOT EXISTS 'spring-admin'@'localhost' IDENTIFIED BY 'SpringSecure@123';
GRANT ALL PRIVILEGES ON springboot_db.* TO 'spring-admin'@'localhost';
FLUSH PRIVILEGES;
SQL

sudo tee /etc/systemd/system/spring-app.service >/dev/null <<'SERVICE'
[Unit]
Description=Spring Boot Application on port 8082
After=network.target mysql.service

[Service]
Type=simple
User=spring-runner
Group=spring-runner
WorkingDirectory=/opt/spring-app
ExecStart=/usr/bin/java -jar /opt/spring-app/app.jar --server.port=8082
Restart=on-failure
RestartSec=10
SuccessExitStatus=143
Environment="SPRING_DATASOURCE_URL=jdbc:mysql://localhost:3306/springboot_db?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC"
Environment="SPRING_DATASOURCE_USERNAME=spring-admin"
Environment="SPRING_DATASOURCE_PASSWORD=SpringSecure@123"

[Install]
WantedBy=multi-user.target
SERVICE

sudo systemctl daemon-reload
sudo systemctl enable --now spring-app.service
sudo systemctl status spring-app.service --no-pager
ss -tlnp | grep 8082 || true

