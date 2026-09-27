# TRADING ENGINE SPECIFICATION
## Order Routing, Execution Lifecycles, and Portfolio Accounting

---

## 1. Execution Modes

The platform supports three mutually exclusive operational execution modes:

```
[MODE SELECTOR]
       ├── PAPER TRADING   ──► Real market data feed, simulated order book execution,
       │                       simulated fees (0.05%), zero real capital risk.
       ├── TESTNET         ──► Routes to exchange sandbox APIs (e.g. testnet-api.delta.exchange).
       └── LIVE TRADING    ──► Real exchange order transmission, real capital, requiring
                               explicit multi-step user confirmation before activation.
```

---

## 2. Order Ticket Pre-Submission Calculation

Before any order is placed, the terminal performs a real-time mathematical review:
1. **Estimated Notional Value**: $\text{Notional} = \text{Price} \times \text{Quantity}$
2. **Required Initial Margin**: $\text{Margin} = \frac{\text{Notional}}{\text{Leverage}}$
3. **Estimated Taker/Maker Fee**: $\text{Fee} = \text{Notional} \times \text{FeeRate}$
4. **Estimated Liquidation Price**:
   - For Long: $\text{LiqPrice} = \text{EntryPrice} \times \left(1 - \frac{1}{\text{Leverage}} + \text{MMR}\right)$
   - For Short: $\text{LiqPrice} = \text{EntryPrice} \times \left(1 + \frac{1}{\text{Leverage}} - \text{MMR}\right)$
   *(where MMR = Maintenance Margin Ratio, default 0.5%)*

---

## 3. Options Trading & Option Chain Architecture

### 3.1 Delta Exchange India Options Pipeline
- Fetches all active options contracts from `GET /v2/products`.
- Matches underlying assets (`BTC`, `ETH`) and groups by settlement expiry date.
- Normalizes Call and Put contracts by Strike Price:
  $$\text{Layout}: \quad \text{CALLS} \quad | \quad \text{STRIKE} \quad | \quad \text{PUTS}$$
- Automatically calculates and assigns moneyness tags:
  - **ATM (At-The-Money)**: $| \text{Strike} - \text{Spot} | / \text{Spot} < 1\%$
  - **ITM (In-The-Money)**: Strike < Spot (Call) or Strike > Spot (Put)
  - **OTM (Out-of-The-Money)**: Strike > Spot (Call) or Strike < Spot (Put)
- Calculates Greeks (Delta, Gamma, Theta, Vega) and Implied Volatility (IV) using an institutional Black-Scholes-Merton engine with Newton-Raphson / bisection IV solver (`backend/app/services/greeks_engine.py`), explicitly tagged with provenance:
  `"LOCALLY_CALCULATED (Black-Scholes-Merton)"`.

### 3.2 CoinSwitch PRO Handling
CoinSwitch PRO does not support options trading on its public API. The platform enforces architectural integrity by labeling CoinSwitch Options as:
`"Not supported by this exchange/API (Private beta only)"`
No simulated or fabricated option contracts are presented as real CoinSwitch data.

---

## 4. Database Order & State Synchronization

Every order placed via `/api/orders/place` is persisted to SQLite using async SQLAlchemy:
1. **Order Model**: Stores `client_order_id`, `exchange_order_id`, `exchange`, `symbol`, `side`, `order_type`, `price`, `quantity`, `filled_quantity`, `status`, `leverage`, and timestamps.
2. **OrderFill Model**: Records trade execution timestamps, executed size, fill price, and fees.
3. **Background Reconciliation**: `ReconciliationService` periodically cross-references database `Order` and `Position` records with exchange open orders and positions to detect:
   - `POSITION_MISMATCH`: Quantity/side divergence
   - `ORDER_LOCAL_ONLY`: Database records missing from exchange
   - `POSITION_EXCHANGE_ONLY`: Untracked exchange positions
