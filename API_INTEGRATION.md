# EXCHANGE API INTEGRATION GUIDE
## Delta Exchange India & CoinSwitch PRO

---

## 1. Delta Exchange India Integration

### 1.1 Base URLs
- **Production REST**: `https://api.india.delta.exchange`
- **Testnet REST**: `https://testnet-api.delta.exchange`
- **WebSocket Feed**: `wss://socket.india.delta.exchange`

### 1.2 Authentication Specification
Delta Exchange India uses **HMAC-SHA256** signatures. Every authenticated request requires:
- `api-key`: User's API key
- `timestamp`: Unix timestamp in seconds (integer string)
- `signature`: Hexadecimal HMAC-SHA256 hash
- `User-Agent`: Client identifier
- `Content-Type`: `application/json`

#### Prehash String Format:
```
METHOD + TIMESTAMP + REQUEST_PATH + QUERY_STRING + BODY
```
*Note: If query string or body is empty, it is omitted. When formatting JSON body, separators must strictly be `(‘,’, ‘:’)` to prevent whitespace mismatches.*

### 1.3 Key Endpoints
| Endpoint | Method | Purpose |
| :--- | :--- | :--- |
| `/v2/products` | `GET` | List all tradable instruments, strike prices, and expiries |
| `/v2/tickers` | `GET` | All real-time tickers, mark prices, 24h volumes, funding rates |
| `/v2/tickers/{symbol}` | `GET` | Specific symbol ticker |
| `/v2/l2orderbook/{symbol}`| `GET` | Level 2 order book depth |
| `/v2/trades/{symbol}` | `GET` | Recent public trade executions |
| `/v2/chart/history` | `GET` | OHLCV historical candlestick data |
| `/v2/wallet/balances` | `GET` | User balances and available margin |
| `/v2/positions/margined` | `GET` | Margined open futures/options positions |
| `/v2/orders` | `POST` | Submit limit, market, or stop order |
| `/v2/orders/{id}` | `DELETE`| Cancel specific order |
| `/v2/orders` | `DELETE`| Cancel all open orders |
| `/v2/products/{id}/orders/leverage` | `POST` | Update product leverage |

---

## 2. CoinSwitch PRO Integration

### 2.1 Base URLs
- **Spot API v2**: `https://coinswitch.co/trade/api/v2`
- **Futures API v2**: `https://coinswitch.co/trade/api/v2/futures`
- **WebSocket Feed**: `wss://ws.coinswitch.co/`

### 2.2 Authentication Specification
CoinSwitch PRO uses **Ed25519 asymmetric cryptography**.
Every authenticated request requires:
- `X-AUTH-APIKEY`: Hex-encoded Ed25519 public key
- `X-AUTH-SIGNATURE`: Hex-encoded Ed25519 signature
- `X-AUTH-EPOCH`: Current Unix epoch in milliseconds
- `Content-Type`: `application/json`

#### Signed Message Format:
```
METHOD + path_with_query + epoch
```
*Note: The request body is **not** included in the signed message. Signing is performed strictly over the UTF-8 bytes of `METHOD + path_with_query + epoch` using the Ed25519 private key seed.*

### 2.3 Key Endpoints
| Endpoint | Method | Surface | Purpose |
| :--- | :--- | :--- | :--- |
| `/instruments` | `GET` | Futures | Perpetual futures instruments and tick sizes |
| `/24hr/all-pairs/ticker?exchange=coinswitchx` | `GET` | Spot | **407 live spot tickers** from official CoinSwitch PRO API |
| `/ticker` | `GET` | Futures | Real-time mark price and funding rates (requires futures auth) |
| `/depth` | `GET` | Futures | Order book depth ladder |
| `/trades` | `GET` | Futures | Public trade stream |
| `/user/portfolio` | `GET` | Spot/Futures | Account balance and free margin |
| `/positions` | `GET` | Futures | Open perpetual positions |
| `/orders` | `POST` | Futures | Place market or limit order |
| `/orders/cancel` | `POST` | Futures | Cancel specific open order |
| `/orders/cancel-all` | `POST` | Futures | Bulk cancel orders |
| `/leverage` | `POST` | Futures | Set position leverage |

### 2.4 Unsupported & Restricted Features
1. **Options Trading**: As per official documentation, **Options Trading** is not supported on CoinSwitch PRO's public API surface. The terminal explicitly marks CoinSwitch Options as `"Not supported by this exchange/API (Private beta only)"` and prevents order submission.
2. **Dynamic Portfolio Margin**: Neither exchange supports dynamic order-level Portfolio Margin via self-serve API. (Delta Exchange treats Portfolio Margin as an institutional qualification requiring $100k+ balance). The platform enforces `cross` and `isolated` margin modes via Risk Engine Rule 12.
3. **CoinSwitch Unauthenticated Funding**: CoinSwitch futures endpoints require valid Ed25519 authentication. When unauthenticated, the platform returns explicit `status: "UNAVAILABLE"` with no fabricated synthetic rates.

---

## 3. Verified Compatibility Matrix

```
┌──────────────────────────────┬─────────────────────────┬─────────────────────────┐
│ Feature                      │ Delta Exchange India    │ CoinSwitch PRO          │
├──────────────────────────────┼─────────────────────────┼─────────────────────────┤
│ REST Public Tickers          │ 1,127 live pairs        │ 407 live pairs (spot)   │
│ WebSocket Streaming          │ Supported / Verified    │ Supported / Verified    │
│ Signature Type               │ HMAC-SHA256             │ Ed25519                 │
│ Perpetual Futures Trading    │ Supported / Verified    │ Supported / Verified    │
│ Options & Option Chains      │ Supported / Verified    │ Not supported on API    │
│ Greeks & Implied Volatility  │ LOCALLY_CALCULATED (BSM)│ Not supported on API    │
│ Funding Rate Frequency       │ 8-Hour Intervals        │ 8-Hour (Auth required)  │
│ Cross Margin                 │ Supported / Verified    │ Supported / Verified    │
│ Isolated Margin              │ Supported / Verified    │ Supported / Verified    │
│ Portfolio Margin             │ Institutional only      │ Not supported on API    │
│ Max Leverage                 │ Up to 100x              │ Up to 25x               │
│ Order Types                  │ Market, Limit, Stop     │ Market, Limit, Stop     │
└──────────────────────────────┴─────────────────────────┴─────────────────────────┘
```
