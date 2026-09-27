# FUNDING ARBITRAGE ENGINE SPECIFICATION
## Dynamic Discovery, Yield Normalization, and Two-Leg Execution

---

## 1. Principles of Potential Funding Arbitrage

Perpetual contracts charge or pay funding fees periodically to tether contract prices to index spot prices:
- **Long pays Short** when funding rate is positive ($> 0$).
- **Short pays Long** when funding rate is negative ($< 0$).

When two exchanges (Delta Exchange India and CoinSwitch PRO) exhibit a persistent funding differential, a delta-neutral hedge can capture the cashflow spread while neutralizing underlying asset price movement:

$$\text{Strategy Direction}: \quad \text{SHORT the high-funding exchange} \quad / \quad \text{LONG the low-funding exchange}$$

> [!WARNING]
> Do NOT call funding arbitrage "risk-free" or "guaranteed profit". Execution risk, leg fill latency, funding rate volatility, exchange outages, liquidation risk, and exchange fee drag can cause losses. The platform strictly labels opportunities as **"Potential Funding Arbitrage"** and **"Estimated Net Edge"**.

---

## 2. Dynamic Contract Discovery & Normalization

The engine scans **ALL** compatible perpetual pairs dynamically (BTC, ETH, SOL, XRP, DOGE, ADA, AVAX, etc.), rather than hard-coding BTC only.

### 2.1 Funding Interval Normalization
Because exchanges may operate on different funding intervals (e.g. 8-hour vs 1-hour vs 4-hour):
$$\text{HourlyRate} = \frac{\text{FundingRate}}{\text{IntervalHours}}$$
$$\text{DailySpread} = \text{HourlyRate}_A \times 24 - \text{HourlyRate}_B \times 24$$
$$\text{AnnualizedGrossYield} = \text{DailySpread} \times 365$$

### 2.2 Cost Deductions & Net Estimated Yield
To calculate true net edge, trading fees, expected slippage, and spread drag are subtracted:
$$\text{TotalTradingFees} = (\text{TakerFee}_A + \text{TakerFee}_B) \times \text{Notional}$$
$$\text{SlippageCost} = 2 \times \text{Notional} \times \frac{\text{SlippagePct}}{2}$$
$$\text{NetEstimatedYield} = \text{AnnualizedGrossYield} - \frac{\text{ExecutionCosts}}{\text{Notional} \times \text{HoldingDays}} \times 365$$

---

## 3. The 17-Factor Opportunity Score

Each discovered opportunity is scored from `0.0` to `100.0` based on:
1. Gross funding spread magnitude
2. Funding frequency & next funding countdown
3. Estimated funding income cashflow
4. Exchange trading fees (maker/taker)
5. Bid/ask spread cost
6. Estimated order book slippage
7. 24-hour aggregate trading volume
8. Order book depth at target quantity
9. Required initial margin
10. Available account free margin
11. Selected leverage tier
12. Round-trip API latency
13. Contract specification mismatch risk
14. Funding rate historical stability (1h/4h/24h)
15. Historical funding spread mean reversion
16. Expected holding duration (days)
17. Liquidation price buffer

---

## 4. Two-Leg Execution Manager & Hedge Recovery

```
                     [ARBITRAGE TRIGGER DETECTED]
                                  │
                                  ▼
                     [Pre-Trade Risk Validations]
                     (Balance, Latency, Data Age)
                                  │
                  ┌───────────────┴───────────────┐
                  ▼                               ▼
               [PASS]                          [FAIL]
                  │                               │
                  ▼                               ▼
       [Submit Leg 1: Long Order]          [Order Blocked]
                  │
        ┌─────────┴─────────┐
        ▼                   ▼
    [Leg 1 FILLED]      [Leg 1 REJECTED]
        │                   │
        │                   ▼
        │             [Abort Strategy]
        │
        ▼
   [Submit Leg 2: Short Order]
        │
   ┌────┴───────────────────────────┐
   ▼                                ▼
[Leg 2 FILLED]               [Leg 2 FAILED]
   │                                │
   ▼                                ▼
[DELTA-NEUTRAL POSITION OPEN] [TRIGGER EMERGENCY UNWIND]
• Assign ARB-YYYYMMDD-XXXX    • Market close Leg 1 immediately
• Monitor Leg Imbalance       • Prevent directional price risk
• Track Net Arbitrage P&L     • Notify trader & audit log
```

### Position Imbalance Protection
If Leg 1 fills 0.01 BTC and Leg 2 fills only 0.006 BTC:
$$\text{Unhedged Exposure} = 0.01 - 0.006 = +0.004 \text{ BTC}$$
The terminal flags `UNHEDGED EXPOSURE`, sends an audio/visual alert, and attempts hedge recovery or partial reduction.
