# Institutional Staking Console

A Rails 7.1 JSON API and React/TypeScript console for portfolio balances, daily reward reporting, idempotent reward synchronization, and stake/unstake operations through a mock chain adapter.

## Features

- Per-network portfolio balances and cumulative rewards
- Daily rewards with network and inclusive date filters
- Stake and unstake requests with `pending` → `submitted` transitions
- Idempotent reward synchronization through `MockChainClient`
- Organization-scoped API-key authentication
- Shared loading, empty, and error states
- Exact integer-string handling for token amounts

## Requirements

- Ruby 3.2 or newer and Bundler
- Node.js 20 or newer and npm
- SQLite for local development and tests

Docker can run the backend when a compatible Ruby installation is unavailable.

## Run locally

### Backend

```bash
cd backend
bundle install
bin/rails db:prepare
bin/rails db:seed
bin/rails server -p 3000
```

The API is available at `http://127.0.0.1:3000`. Check it with:

```bash
curl http://127.0.0.1:3000/health
```

### Backend with Docker

From the repository root:

```bash
docker run --rm \
  -v assessment_rails_gems:/usr/local/bundle \
  -v "$PWD/backend:/app" \
  -w /app ruby:3.3-bookworm bundle install

docker run --rm -p 127.0.0.1:3000:3000 \
  -v assessment_rails_gems:/usr/local/bundle \
  -v "$PWD/backend:/app" \
  -w /app ruby:3.3-bookworm \
  sh -lc 'bin/rails db:prepare && bin/rails db:seed && bin/rails server -b 0.0.0.0 -p 3000'
```

### Frontend

In a separate terminal:

```bash
cd frontend
cp .env.example .env.local
npm install
npm run dev
```

Open `http://127.0.0.1:5173`. Vite proxies `/api` to `http://127.0.0.1:3000` during local development.

## Seed data and authentication

Run seeds with:

```bash
cd backend
bin/rails db:seed
```

This creates:

- Organization: `Demo Institution`
- API key: `demo-key`
- Ethereum validator balance: `32000000000000000000`
- Solana validator balance: `100000000000`

Protected requests require:

```text
X-Api-Key: demo-key
```

The frontend reads `VITE_API_KEY` and uses `demo-key` as its local fallback. The provided environment template contains:

```env
VITE_API_BASE=
VITE_API_KEY=demo-key
```

Do not use the demo key or commit real secrets in production.

## Populate rewards

Seeds create validators but no reward events. Trigger a sync after starting Rails:

```bash
curl -X POST http://127.0.0.1:3000/api/v1/sync/rewards \
  -H 'Content-Type: application/json' \
  -H 'X-Api-Key: demo-key' \
  -d '{"start":"2026-10-30","end":"2026-11-06"}'
```

Both date bounds are optional and inclusive. Without them, the job synchronizes the previous seven days through today.

## API summary

| Method | Endpoint | Purpose |
|---|---|---|
| `GET` | `/health` | Public health check |
| `GET` | `/api/v1/portfolio` | Per-network balances and cumulative rewards |
| `GET` | `/api/v1/rewards` | Daily rewards with `network`, `start`, and `end` filters |
| `GET` | `/api/v1/stake_operations` | List the authenticated organization's operations |
| `POST` | `/api/v1/stake_operations` | Create and submit a stake or unstake operation |
| `POST` | `/api/v1/sync/rewards` | Enqueue an idempotent rewards sync |

All `/api/v1` endpoints require `X-Api-Key`.

## Aggregation formulas

Amounts are raw smallest-unit integer strings. Ruby integers are used only for exact arithmetic, and results are serialized back to strings. Floating-point arithmetic is never used.

```text
portfolio balance = Σ validator.balance, grouped by network
total rewards received = Σ reward_event.amount, grouped by network
daily rewards = Σ reward_event.amount, grouped by network and reward_date
```

- Only records belonging to the authenticated organization are included.
- Portfolio networks are derived from that organization's validators and reward events.
- `last_synced_at` is the latest `finished_at` from a successfully completed rewards sync.
- `start` and `end` reward filters include events on the boundary dates.
- Reward rows are ordered by date and then network for a stable response.

## Idempotency and operation rules

- Mock rewards have deterministic `external_id` values.
- Sync uses the unique `external_id` index and `upsert_all`; replaying a range updates existing events instead of double-counting them.
- Stake operations accept `stake` or `unstake` and require a positive integer-string amount.
- A valid operation is saved as `pending`, submitted through `MockChainClient`, and updated to `submitted` with an external ID.
- Chain-specific behavior remains behind the chain client rather than in controllers.

## Tests and verification

Backend:

```bash
cd backend
RAILS_ENV=test bin/rails db:prepare
bundle exec rspec
```

Frontend:

```bash
cd frontend
npm run build
```

Verified results:

- Backend: 10 examples, 0 failures
- Frontend: TypeScript and Vite production build passed

## Assumptions and tradeoffs

- Amounts represent chain-native smallest units; display conversion is left to future product requirements.
- One API key belongs to one organization, and every data query is organization-scoped.
- `MockChainClient` is deterministic for rewards but generates mock external IDs for stake operations.
- Active Job uses the in-process asynchronous adapter in development; a durable production queue is out of scope.
- SQLite is used locally and in tests; production configuration expects PostgreSQL.
- Real RPC, signing/custody, confirmation polling, multi-org administration, GraphQL, deployment, and observability are out of scope.
- The frontend offers Ethereum and Solana because those are the seeded networks.

## Time spent

Approximately 1.5 hours of active implementation and validation was spent on backend endpoints, synchronization, tests, frontend wiring and shared states, local runtime setup, browser verification, and documentation. Production infrastructure and real chain integrations would require additional time.
