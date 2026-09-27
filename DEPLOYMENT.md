# PRODUCTION DEPLOYMENT GUIDE
## Docker, Systemd, Gunicorn/Uvicorn, PostgreSQL & Cloud Infrastructure

---

## 1. Containerized Deployment (Recommended)

The platform includes a production `Dockerfile` and `docker-compose.yml` orchestrating the FastAPI backend, static frontend, PostgreSQL database, and Redis cache.

### 1.1 Start the Complete Stack
```bash
# 1. Ensure .env is populated with encryption keys and parameters
cp .env.example .env

# 2. Build and launch services in background
docker compose up -d --build

# 3. Inspect logs and health checks
docker compose ps
docker compose logs -f trading-terminal
```

### 1.2 Service Architecture in Docker Compose
- `trading-terminal`: Python 3.13 image running Uvicorn workers on port `8000`.
- `db`: PostgreSQL 16 Alpine with persistent volume `postgres_data` and health checks.
- `redis`: Redis 7 Alpine cache and pub/sub broker on port `6379`.

---

## 2. Bare Metal / VPS Deployment (Ubuntu / Debian / RHEL)

### 2.1 System Dependencies
```bash
sudo apt-get update && sudo apt-get install -y \
    python3-pip python3-venv postgresql postgresql-contrib redis-server nginx
```

### 2.2 PostgreSQL Setup
```sql
CREATE DATABASE trading_platform;
CREATE USER trader WITH ENCRYPTED PASSWORD 'secure_production_password';
GRANT ALL PRIVILEGES ON DATABASE trading_platform TO trader;
```

### 2.3 Systemd Service Configuration
Create `/etc/systemd/system/antigravity-terminal.service`:
```ini
[Unit]
Description=Antigravity Multi-Exchange Crypto Terminal
After=network.target postgresql.service redis.service

[Service]
User=trader
WorkingDirectory=/opt/crypto_trading_platform
EnvironmentFile=/opt/crypto_trading_platform/.env
Environment=PYTHONPATH=/opt/crypto_trading_platform/backend
ExecStart=/opt/crypto_trading_platform/venv/bin/uvicorn app.main:app --host 127.0.0.1 --port 8000 --workers 4
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl daemon-reload
sudo systemctl enable antigravity-terminal
sudo systemctl start antigravity-terminal
```

### 2.4 Nginx Reverse Proxy with SSL (Let's Encrypt)
```nginx
server {
    listen 80;
    server_name terminal.yourdomain.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name terminal.yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/terminal.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/terminal.yourdomain.com/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

---

## 3. Production Health & Monitoring

The terminal exposes `/api/health` providing live telemetry across 13 system components:
```json
{
  "status": "HEALTHY",
  "services": {
    "backend": "HEALTHY",
    "database": "HEALTHY",
    "market_data_engine": "HEALTHY",
    "delta_rest": "CONNECTED",
    "delta_websocket": "CONNECTED",
    "coinswitch_rest": "CONNECTED",
    "coinswitch_websocket": "CONNECTED",
    "risk_engine": "HEALTHY",
    "strategy_engine": "RUNNING",
    "arbitrage_scanner": "ACTIVE",
    "reconciliation_service": "HEALTHY"
  }
}
```
Integrate with Prometheus, Datadog, or Grafana using standard HTTP probes.
