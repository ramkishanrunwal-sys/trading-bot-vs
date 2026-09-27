# RISK MANAGEMENT ENGINE SPECIFICATION
## Comprehensive 21-Point Pre-Trade Safety Gate

---

## 1. Risk Philosophy
No financial order—whether initiated manually by a user or triggered automatically by a strategy—is ever transmitted to an exchange without executing and passing all 21 validations in the `RiskEngine`. If even a single validation fails, the order is blocked immediately and a normalized audit log and user alert are generated.

---

## 2. The 21 Pre-Trade Risk Validations

| Rule # | Validation Check | Description | Failure Action |
| :---: | :--- | :--- | :--- |
| **0** | **Emergency Kill Switch** | Checks if `emergency_stop_new_orders` is active. | Order Blocked: Emergency Stop Active. |
| **1** | **API Connection Health** | Verifies active TCP/TLS connection to target exchange. | Order Blocked: Exchange Disconnected. |
| **2** | **Exchange Latency Check** | Rejects if round-trip REST latency > `MAX_API_LATENCY_MS` (800ms). | Order Blocked: Latency Exceeded. |
| **3** | **Account Credential Check** | Verifies non-empty, decrypted API key/secret in non-paper mode. | Order Blocked: Credentials Missing. |
| **4** | **Sufficient Balance Check** | Verifies free wallet balance exceeds order initial margin. | Order Blocked: Insufficient Balance. |
| **5** | **Sufficient Margin Check** | Rejects if account margin ratio would exceed liquidation risk bounds. | Order Blocked: Margin Capacity Exhausted. |
| **6** | **Instrument Status Check** | Verifies contract is marked `active` or `live` by exchange. | Order Blocked: Contract Inactive/Halted. |
| **7** | **Quantity Sanity Check** | Rejects if quantity <= 0 or NaN. | Order Blocked: Invalid Quantity. |
| **8** | **Tick Size Precision** | Rejects limit orders where price is not an exact multiple of tick size. | Order Blocked: Tick Size Mismatch. |
| **9** | **Step Size Precision** | Rejects orders where quantity is not a multiple of step size. | Order Blocked: Step Size Mismatch. |
| **10** | **Minimum Order Size** | Rejects orders below exchange minimum notional/contract size. | Order Blocked: Below Minimum Size. |
| **11** | **Leverage Limit** | Enforces `leverage <= min(PLATFORM_MAX, INSTRUMENT_MAX)`. | Order Blocked: Leverage Exceeded. |
| **12** | **Margin Mode Validation** | Ensures margin mode (`cross`/`isolated`) is supported by instrument. | Order Blocked: Invalid Margin Mode. |
| **13** | **Maximum Exposure Limit** | Rejects if order notional > `MAX_ORDER_VALUE` (₹500,000 / $500,000). | Order Blocked: Exposure Limit Exceeded. |
| **14** | **Maximum Daily Loss** | Halts all trading if cumulative daily loss >= `MAX_DAILY_LOSS`. | Order Blocked: Daily Loss Circuit Breaker. |
| **15** | **Strategy Capital Limit** | Enforces that active strategy does not exceed assigned capital allocation. | Order Blocked: Strategy Allocation Exceeded. |
| **16** | **Maximum Slippage Limit** | Verifies expected slippage from order book depth <= `MAX_SLIPPAGE`. | Order Blocked: Slippage Exceeded. |
| **17** | **Price Sanity Check** | Rejects if proposed price deviates > 5% from Mark/Index/LTP. | Order Blocked: Price Sanity Failed. |
| **18** | **Stale Data Protection** | Rejects automated execution if market tick age > `MAX_DATA_AGE` (3s). | Order Blocked: Stale Data Detected. |
| **19** | **Duplicate Order Check** | Enforces idempotency via unique `client_order_id`. | Order Blocked: Duplicate Order Detected. |
| **20** | **Rate Limit Capacity** | Token-bucket checks prevent exceeding exchange rate limits. | Order Blocked: Throttled by Rate Limiter. |
| **21** | **Position Limits Check** | Rejects if resulting position size exceeds `MAX_POSITION_SIZE`. | Order Blocked: Position Limit Exceeded. |

---

## 3. Global Emergency Stop Mechanisms

The terminal provides two clearly distinguished emergency actions:

### 1. `STOP NEW ORDERS`
- Automatically pauses all active automated strategies.
- Cancels all pending unfilled limit orders across Delta Exchange and CoinSwitch PRO.
- Prevents submission of any new orders.
- **Does NOT market-close existing positions**, protecting the trader from adverse slippage during volatile markets.

### 2. `CLOSE ALL POSITIONS`
- Explicit confirmation required.
- Immediately dispatches market orders with `reduce_only=True` to close ALL open positions on both exchanges.
- Used in catastrophic black swan events or mandatory portfolio liquidation.

---

## 4. Multi-Condition Live Trading Safety Lock

In addition to the 21 pre-trade rules, the platform enforces a **9-Point Live Trading Safety Gate** before any real-money order or arbitrage execution can reach an exchange:

1. **Global Configuration Gate**: `LIVE_TRADING_ENABLED` must be explicitly set to `True` in `.env`. Defaults to `False`. All live attempts return HTTP 403 Forbidden when disabled.
2. **Intentional Confirmation**: Request payload must contain `is_live_confirmed: True`.
3. **Emergency Stop Inactive**: System kill switch must be inactive.
4. **Exchange Credentials**: Valid API keys must be loaded for the target exchange.
5. **Fresh Market Data**: Ticker age must not exceed `MAX_DATA_AGE_SECONDS` (10s).
6. **Latency Health**: Exchange latency must not exceed `MAX_API_LATENCY_MS` (3,000ms).
7. **Rule 12 Margin Mode**: Must strictly be `"cross"` or `"isolated"`. Dynamic `"portfolio_margin"` is rejected.
8. **Pre-Trade Risk Engine**: All 21 pre-trade validations must pass.
9. **Two-Leg Sequential Unwind**: Automated arbitrage sequentially verifies Leg 1 fills and unwinds immediately if Leg 2 fails, eliminating naked exposure.

