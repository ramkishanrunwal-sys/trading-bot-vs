# Antigravity Multi-Exchange Crypto Trading Platform
### Enterprise-Grade High-Performance Terminal for Delta Exchange India & CoinSwitch PRO

[![Python 3.13+](https://img.shields.io/badge/Python-3.13%2B-blue.svg)](https://www.python.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115%2B-009688.svg)](https://fastapi.tiangolo.com/)
[![Tests](https://img.shields.io/badge/Tests-22%2F22%20Passing-brightgreen.svg)]()
[![Live Safety](https://img.shields.io/badge/Live%20Trading-Locked%20(Paper%20Default)-orange.svg)]()

---

## 1. Project Overview

The **Antigravity Multi-Exchange Crypto Trading Platform** is a production-grade cryptocurrency trading terminal designed to connect directly with multiple licensed and regulated cryptocurrency exchanges, initially:
1. **Delta Exchange India** (`https://api.india.delta.exchange`)
2. **CoinSwitch PRO** (`https://coinswitch.co/trade/api/v2`)

The platform is designed under strict financial-grade requirements:
- **No Fabricated Data**: Displays real live market feeds (1,127 Delta tickers, 407 CoinSwitch tickers). Clearly identifies unsupported functionality as `"Not supported by this exchange/API"`.
- **Institutional Greeks & IV Engine**: Black-Scholes-Merton mathematical engine with Newton-Raphson / bisection IV solver (`greeks_engine.py`). Explicitly tagged as `LOCALLY_CALCULATED`.
- **9-Point Live Trading Safety Lock**: Real-money trading is locked by default (`LIVE_TRADING_ENABLED=False`), requiring explicit user confirmation, fresh data, verified credentials, and active kill-switch checks before orders can reach an exchange.
- **Two-Leg Arbitrage Execution & Recovery**: Sequential execution, dynamic sizing to Leg 1 filled quantity, and emergency Leg 1 unwinds if Leg 2 fails, eliminating unhedged directional exposure.
- **21-Point Risk Engine**: Validates every manual or automated order against balance, leverage, tick/step sizes, price sanity (deviation > 5% blocked), and Rule 12 margin mode validation (`cross` or `isolated`).
- **Triple-Mode Execution**: Clear separation between `PAPER TRADING`, `TESTNET`, and `LIVE TRADING`.
- **Background State Reconciliation**: Real-time cross-referencing between local SQLite database records and live exchange states.

---

## 2. Platform Architecture

```
                       ┌────────────────────────────────────────┐
                       │     Professional Trading Terminal      │
                       │     (HTML5 / Vanilla ES6 / Tailwind)   │
                       └───────────────────┬────────────────────┘
                                           │ HTTP & WebSocket
                       ┌───────────────────▼────────────────────┐
                       │        FastAPI Gateway / Router        │
                       └───────────────────┬────────────────────┘
                                           │
         ┌───────────────────┬─────────────┴───────┬───────────────────┐
         │                   │                     │                   │
┌────────▼────────┐ ┌────────▼────────┐   ┌────────▼────────┐ ┌────────▼────────┐
│  Market Engine  │ │   Risk Engine   │   │ Arbitrage Engine│ │ Strategy Engine │
│ 1,127+ Tickers  │ │ 21 Validations  │   │ 2-Leg Sequential│ │ Rule Condition  │
└────────┬────────┘ └────────┬────────┘   └────────┬────────┘ └────────┬────────┘
         │                   │                     │                   │
         └───────────────────┼─────────────────────┴───────────────────┘
                             │
               ┌─────────────▼─────────────┐
               │    Exchange Adapter Hub   │
               ├─────────────┬─────────────┤
               │             │             │
        ┌──────▼──────┐┌─────▼───────┐┌────▼────────┐
        │ Delta India ││ CoinSwitch  ││ Paper Engine│
        │ (HMAC-SHA256││  (Ed25519)  ││ (Real Data) │
        └─────────────┘└─────────────┘└─────────────┘
```

---

## 3. Quick Start & Local Run

### Prerequisites
- Python 3.11+ (Python 3.13 tested and verified)
- Windows / Linux / macOS

### 1. One-Click Launch (Windows)
Double-click `start.bat` or run:
```powershell
.\start.bat
```
*`start.bat` automatically sets up the Python virtual environment (`.venv`), installs all required dependencies (`greenlet`, `scipy`, `cryptography`, `fastapi`, etc.), sets `LIVE_TRADING_ENABLED=false` and `MODE=paper`, and launches the uvicorn server on port 8000.*

### 2. Manual Setup
```bash
# Setup virtual environment
python -m venv .venv
source .venv/bin/activate  # or .\.venv\Scripts\activate on Windows

# Install dependencies
pip install -r backend/requirements.txt

# Run all 22 automated tests
pytest -v

# Run the backend server
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Open your browser to: **`http://localhost:8000`**

---

## 4. Key Functional Capabilities

| Feature | Delta Exchange India | CoinSwitch PRO | Platform Status |
| :--- | :--- | :--- | :--- |
| **REST Market Data** | Supported (1,127 tickers) | Supported (407 tickers via coinswitchx) | `IMPLEMENTED & VERIFIED` |
| **WebSocket Stream** | Supported (v2) | Supported (Socket.IO/WS) | `IMPLEMENTED & VERIFIED` |
| **Authentication** | HMAC-SHA256 | Ed25519 Public/Private Key | `IMPLEMENTED BUT NOT VERIFIED LIVE` |
| **Perpetual Futures** | Supported | Supported | `IMPLEMENTED & VERIFIED` (Paper) |
| **Options Trading** | Supported (Calls/Puts) | Not supported by exchange/API | `IMPLEMENTED & VERIFIED` (Delta) |
| **Option Chain & Greeks** | Supported (BSM Local Engine) | Not supported by exchange/API | `IMPLEMENTED & VERIFIED` |
| **Funding Rate Feed** | Supported (8-hour) | Spot: UNAVAILABLE without futures key | `PARTIALLY IMPLEMENTED` |
| **Cross / Isolated Margin** | Supported | Supported | `IMPLEMENTED & VERIFIED` (Rule 12) |
| **Portfolio Margin** | Institutional only ($100k+) | Not supported by exchange/API | `NOT SUPPORTED BY EXCHANGE` |
| **Two-Leg Arbitrage** | Sequential Execution | Sequential Execution | `IMPLEMENTED & VERIFIED` |

---

## 5. Security & Safety Defenses

1. **Global Live Lock**: `LIVE_TRADING_ENABLED=false` in `.env` blocks all real order execution until explicitly enabled by the operator.
2. **Credential Encryption at Rest**: API secrets are encrypted using Fernet (AES-128-CBC with HMAC-SHA256).
3. **Audit Logging Sanitization**: Sensitive keys and tokens are automatically redacted from logs.
4. **Emergency Unwind**: Automated two-leg executions unwind Leg 1 immediately if Leg 2 fails, eliminating naked exposure.

---

## 6. Documentation Directory

- [`LIVE_READINESS.md`](LIVE_READINESS.md): **Live operational assessment & 6-state classification report.**
- [`PHASE2_AUDIT_RESULT.md`](PHASE2_AUDIT_RESULT.md): **Complete audit findings & Phase-2 remediation details.**
- [`ARCHITECTURE.md`](ARCHITECTURE.md): Micro-architecture and execution flows.
- [`API_INTEGRATION.md`](API_INTEGRATION.md): Exchange integration specifics and signing algorithms.
- [`RISK_MANAGEMENT.md`](RISK_MANAGEMENT.md): The 21 pre-trade risk validations & kill switches.
- [`TRADING_ENGINE.md`](TRADING_ENGINE.md): Order routing and position management.
- [`ARBITRAGE_ENGINE.md`](ARBITRAGE_ENGINE.md): Funding arbitrage formula, scoring, and hedge recovery.
- [`DATABASE_SCHEMA.md`](DATABASE_SCHEMA.md): Complete relational database schema.
- [`DEPLOYMENT.md`](DEPLOYMENT.md): Production deployment via Docker, PostgreSQL, and Redis.

