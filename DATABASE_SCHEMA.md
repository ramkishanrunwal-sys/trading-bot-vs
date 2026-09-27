# DATABASE SCHEMA SPECIFICATION
## Relational Data Models (PostgreSQL & SQLite Compatible)

---

## 1. Schema Overview

The database is built using **SQLAlchemy 2.0 Async** declarative models. It natively supports **PostgreSQL** in production environments and local **SQLite** (via `aiosqlite`) for zero-configuration testing.

---

## 2. Table Definitions

### 2.1 `users`
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `INTEGER` | Primary Key, Index | Unique user ID |
| `username` | `VARCHAR(64)` | Unique, Not Null | Username |
| `email` | `VARCHAR(128)`| Unique, Not Null | User email address |
| `hashed_password` | `VARCHAR(256)`| Not Null | Bcrypt/Argon2 password hash |
| `role` | `VARCHAR(32)` | Default: 'trader' | User role permissions |
| `created_at` | `DATETIME` | Default: UTC Now | Account creation timestamp |

### 2.2 `exchange_accounts`
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `INTEGER` | Primary Key | Account connection ID |
| `user_id` | `INTEGER` | Foreign Key (`users.id`) | Owning user |
| `exchange_name` | `VARCHAR(32)`| Not Null | `delta` or `coinswitch` |
| `account_label` | `VARCHAR(64)`| Not Null | Friendly label (e.g. "Primary Delta") |
| `api_key` | `VARCHAR(256)`| Not Null | Exchange API public key |
| `encrypted_secret`| `TEXT` | Not Null | Fernet AES-128-CBC encrypted secret |
| `is_testnet` | `BOOLEAN` | Default: `False` | Testnet vs production switch |
| `is_live_enabled` | `BOOLEAN` | Default: `False` | Guard for live execution |
| `latency_ms` | `FLOAT` | Default: `0.0` | Last measured API round-trip latency |
| `connection_status`| `VARCHAR(32)`| Default: `DISCONNECTED` | `CONNECTED`, `DISCONNECTED`, `ERROR` |

### 2.3 `instruments`
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `INTEGER` | Primary Key | Catalog instrument ID |
| `exchange` | `VARCHAR(32)`| Not Null, Index | Exchange name |
| `symbol` | `VARCHAR(64)`| Not Null, Index | Exchange-specific symbol (`BTCUSD`) |
| `canonical_symbol`| `VARCHAR(32)`| Not Null, Index | Normalized underlying asset (`BTC`) |
| `contract_type` | `VARCHAR(32)`| Not Null | `perpetual`, `futures`, `call_option`, `put_option` |
| `strike_price` | `FLOAT` | Nullable | Strike for options |
| `expiry` | `DATETIME` | Nullable | Expiry date for dated contracts |
| `tick_size` | `FLOAT` | Default: `0.01` | Minimum price increment |
| `step_size` | `FLOAT` | Default: `0.001`| Minimum quantity increment |
| `max_leverage` | `INTEGER` | Default: `20` | Exchange maximum leverage |

### 2.4 `orders`
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `INTEGER` | Primary Key | Platform order ID |
| `client_order_id`| `VARCHAR(64)`| Unique, Index | Unique idempotency ID (`ORD-UUID`) |
| `exchange_order_id`| `VARCHAR(64)`| Index, Nullable | Exchange returned order ID |
| `exchange` | `VARCHAR(32)`| Not Null | Destination exchange |
| `symbol` | `VARCHAR(64)`| Not Null | Traded symbol |
| `side` | `VARCHAR(16)`| Not Null | `buy`, `sell` |
| `order_type` | `VARCHAR(32)`| Not Null | `market`, `limit`, `stop_loss` |
| `price` | `FLOAT` | Nullable | Order limit price |
| `quantity` | `FLOAT` | Not Null | Order size |
| `filled_quantity` | `FLOAT` | Default: `0.0` | Executed quantity |
| `status` | `VARCHAR(32)`| Default: `NEW` | `NEW`, `OPEN`, `FILLED`, `CANCELLED` |
| `is_live` | `BOOLEAN` | Default: `False` | Real order vs paper trade |
| `arbitrage_position_id`| `VARCHAR(64)`| Nullable | Associated arbitrage position ID |

### 2.5 `arbitrage_positions`
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `VARCHAR(64)`| Primary Key | `ARB-YYYYMMDD-XXXX` |
| `canonical_symbol`| `VARCHAR(32)`| Not Null | Arbitrage asset (`BTC`, `ETH`) |
| `status` | `VARCHAR(32)`| Default: `OPEN` | `OPEN`, `CLOSED`, `PARTIAL`, `UNHEDGED` |
| `entry_time` | `DATETIME` | Default: UTC Now | Entry timestamp |
| `exit_time` | `DATETIME` | Nullable | Exit timestamp |
| `funding_spread_entry`| `FLOAT` | Not Null | Daily funding spread at entry |
| `net_pnl` | `FLOAT` | Default: `0.0` | Cumulative net P&L |
| `unhedged_exposure`| `FLOAT` | Default: `0.0` | Directional leg mismatch quantity |
| `execution_latency_ms`| `FLOAT` | Default: `0.0` | Round-trip two-leg execution latency |

### 2.6 `audit_logs`
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `INTEGER` | Primary Key | Log sequence ID |
| `timestamp` | `DATETIME` | Default: UTC Now | Millisecond precision timestamp |
| `category` | `VARCHAR(64)`| Not Null | `USER`, `SYSTEM`, `RISK_ENGINE`, `DELTA`, `COINSWITCH` |
| `user` | `VARCHAR(64)`| Not Null | Action initiator |
| `action` | `VARCHAR(128)`| Not Null | Action description |
| `symbol` | `VARCHAR(32)`| Nullable | Affected asset |
| `exchange` | `VARCHAR(32)`| Nullable | Target exchange |
| `details` | `JSON` | Nullable | Sanitized details (secrets redacted) |
| `latency_ms` | `FLOAT` | Default: `0.0` | Execution latency |
| `status` | `VARCHAR(32)`| Default: `SUCCESS` | Result status |
