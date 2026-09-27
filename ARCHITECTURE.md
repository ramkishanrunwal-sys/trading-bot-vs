# ARCHITECTURE SPECIFICATION
## Antigravity Multi-Exchange Crypto Trading Terminal

---

## 1. Architectural Philosophy

The architecture separates market data ingestion, risk gating, order execution, and portfolio valuation into isolated, asynchronous components. It follows the **Adapter Pattern** to isolate exchange-specific protocol quirks behind unified domain models.

### Key Tenets:
1. **Safety over Speed**: No order reaches an exchange adapter without passing all 21 pre-trade risk checks.
2. **True Market Data Integrity**: Data freshness is tracked dynamically with millisecond precision (`LIVE`, `DEGRADED`, `STALE`). Stale data halts automated arbitrage.
3. **Delta-Neutral Atomicity**: Two-leg arbitrage positions are monitored for leg balance. If leg 2 fails to fill, emergency hedge recovery unwinds leg 1 to eliminate directional exposure.

---

## 2. Component Decomposition

### 2.1 API Gateway & Server (`app.main`, `app.api.routes`)
- Built on **FastAPI** with asynchronous concurrency (`asyncio`).
- Mounts REST endpoints for user interface controls and a persistent WebSocket endpoint (`/ws`) for market data streaming.
- Manages clean application lifespan events (starting background polling, initializing relational tables, and graceful shutdown without dumping user positions).

### 2.2 Exchange Adapters (`app.adapters`)
- **`ExchangeAdapter` (Base)**: Abstract contract defining standard methods:
  - Market data: `get_instruments()`, `get_ticker()`, `get_orderbook()`, `get_trades()`, `get_ohlcv()`, `get_funding_rate()`.
  - Account: `get_balance()`, `get_positions()`, `get_open_orders()`, `get_order_history()`.
  - Trading: `place_order()`, `cancel_order()`, `close_position()`, `set_leverage()`.
  - Options: `get_option_chain()`, `get_option_contracts()`.
- **`DeltaExchangeAdapter`**: Connects to `https://api.india.delta.exchange`. Signs requests via HMAC-SHA256 (`METHOD + TIMESTAMP + PATH + QUERY + BODY`). Full options and perpetuals support.
- **`CoinSwitchAdapter`**: Connects to `https://coinswitch.co/trade/api/v2` (Spot) and `https://coinswitch.co/trade/api/v2/futures` (Futures). Signs requests via Ed25519 (`METHOD + path_with_query + epoch`). Explicitly marks options as unsupported.
- **`PaperExchangeAdapter`**: Simulates realistic fills, slippage (0.01% - 0.05%), taker fees, and margin balances using real market data feeds.

### 2.3 Risk Engine (`app.services.risk_engine`)
A centralized safety gate enforcing 21 pre-trade validations before any live order is placed. Blocks duplicate client order IDs, checks price deviations against mark/index prices (> 5% rejected), and enforces platform leverage and order size limits.

### 2.4 Arbitrage & Two-Leg Execution Engine (`app.services.arbitrage_engine`, `app.services.two_leg_execution`)
- Dynamic cross-exchange perpetual scanner across all compatible symbols.
- Normalizes funding intervals to daily and annualized yields.
- Subtracts maker/taker fees, spread, and slippage to determine Net Estimated Yield.
- Computes a 17-factor Opportunity Score (0 to 100).
- Sequentially executes Leg 1 and Leg 2. Tracks unique Arbitrage Position IDs (`ARB-YYYYMMDD-XXXX`). Handles hedge recovery if one leg fails.

### 2.5 Market Data & Freshness Engine (`app.services.market_data_service`)
- Collects tickers and order books from exchange endpoints.
- Calculates data age in milliseconds:
  - Age < 3s: `LIVE`
  - 3s - 9s: `DEGRADED`
  - Age > 9s: `STALE` (automated strategies immediately paused)
- Broadcasts real-time tick updates over WebSockets to UI clients.

### 2.6 Strategy Engine & Condition Evaluator (`app.services.strategy_engine`)
- Visual condition builder supporting `AND`, `OR`, `NOT` gates.
- Enforces strict lifecycle state progression:
  `Draft` → `Backtest` → `Paper` → `Active` → `Paused` → `Stopped`

---

## 3. Data Flow Diagram

```
[Exchange APIs]
   │
   ├─► (Delta REST/WS: HMAC-SHA256) ────┐
   │                                     ▼
   └─► (CoinSwitch REST/WS: Ed25519) ─► [Exchange Adapters]
                                              │
                                              ▼
                                     [Market Data Engine]
                                              │
                    ┌─────────────────────────┼─────────────────────────┐
                    ▼                         ▼                         ▼
         [Funding Rate Monitor]     [Arbitrage Scanner]      [WebSocket Clients (UI)]
                    │                         │
                    └───────────┬─────────────┘
                                ▼
                        [Strategy Engine]
                                │
                                ▼
                       [21-Point Risk Engine]
                                │ (Pass / Fail)
                                ▼
                   [Two-Leg Execution Manager]
                    ├── Step 1: Leg A Order
                    ├── Step 2: Fill Confirmation
                    ├── Step 3: Leg B Order
                    └── Step 4: Delta-Neutral Verification
```
