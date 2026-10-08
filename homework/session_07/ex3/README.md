# Bài 3: Khởi tạo Database MySQL và cấu hình Systemd cho Spring Boot

## 1. Tạo database và user MySQL

```bash
sudo mysql -uroot -p
```

```sql
CREATE DATABASE IF NOT EXISTS springboot_db;
CREATE USER IF NOT EXISTS 'spring-admin'@'localhost' IDENTIFIED BY 'SpringSecure@123';
GRANT ALL PRIVILEGES ON springboot_db.* TO 'spring-admin'@'localhost';
FLUSH PRIVILEGES;
```

## 2. Tạo user Linux không login shell

```bash
sudo useradd --system --no-create-home --shell /usr/sbin/nologin spring-runner
```

## 3. Tệp cấu hình Systemd

File: `spring-app.service`

```ini
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
```

### Cài đặt service

```bash
sudo cp spring-app.service /etc/systemd/system/spring-app.service
sudo systemctl daemon-reload
sudo systemctl enable --now spring-app.service
```

## 4. Kiểm tra trạng thái

Trên máy Linux thật, chạy các lệnh sau để lưu kết quả kiểm tra vào file báo cáo:

```bash
sudo systemctl status spring-app.service --no-pager > systemctl-status.txt 2>&1
ss -tlnp | grep 8082 > ss-8082.txt 2>&1
```

Sau đó kiểm tra nội dung file:

```bash
cat systemctl-status.txt
cat ss-8082.txt
```

### Kết quả mong đợi

```text
● spring-app.service - Spring Boot Application on port 8082
   Loaded: loaded (/etc/systemd/system/spring-app.service; enabled; vendor preset: enabled)
   Active: active (running) since ...
Main PID: 1234 (java)
   Tasks: 25 (limit: 4915)
   Memory: 256.5M
   CGroup: /system.slice/spring-app.service
           └─1234 /usr/bin/java -jar /opt/spring-app/app.jar --server.port=8082
```

```text
LISTEN 0 128 0.0.0.0:8082 0.0.0.0:* users:("java",pid=1234,fd=7)
```

Lưu ý: môi trường hiện tại là Windows nên không thể chạy trực tiếp `systemctl` và `ss` do hệ thống này không có systemd. Vì vậy file báo cáo này chứa hướng dẫn và kết quả mẫu để học viên copy vào máy Linux thật khi nộp bài.

## 5. Ghi chú

- Ứng dụng chạy dưới user `spring-runner`, không phải root.
- `Restart=on-failure` và `RestartSec=10` đảm bảo tiến trình tự động khởi động lại nếu crash.
- Port 8082 đang được lắng nghe bởi tiến trình Java.
- File `setup-spring-app.sh` có thể được dùng để tự động hóa các bước cài đặt trên máy Linux thật.
