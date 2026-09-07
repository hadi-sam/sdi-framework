# Architecture Appendix — Web API / backend service

Insert these sections into ARCHITECTURE.md at §2 ("Type-specific architecture") of the core architecture template.

## §2.1 API surface

State the protocol and shape:

- **Protocol:** [REST] / [GraphQL] / [gRPC] / [tRPC] / [JSON-RPC] / [Hybrid]
- **Versioning:** [URL-based (`/v1/`)] / [Header-based] / [No versioning at MVP, single track]
- **Response envelope:** consistent shape (e.g. `{ data, error, meta }`) or bare resource bodies
- **Pagination:** [cursor-based] / [page+limit] / [since-token] — same scheme everywhere
- **Idempotency:** which write endpoints accept `Idempotency-Key`, with what TTL

### Endpoint catalog

| Method + path | Purpose | Auth | Idempotent |
|---|---|---|---|
| GET /resources | List resources | API key | yes |
| POST /resources | Create | API key | yes (with key) |
| ... | ... | ... | ... |

## §2.2 Auth model

- **Scheme:** [API key in header] / [JWT bearer] / [OAuth 2.0 client credentials] / [mTLS] / [HMAC-signed requests]
- **Key issuance:** how keys are generated, where they live (DB row with hash + last-used)
- **Scopes:** per-key permission flags or coarse role
- **Rotation:** soft rotation period, hard expiry, revocation flow
- **Tenant resolution:** how `organization_id` is derived from auth context on each request

## §2.3 Persistence

- **Primary DB:** [Postgres / MySQL / MongoDB / DynamoDB / etc.]
- **Schema management:** [migrations checked in] / [Prisma/Drizzle/SQLAlchemy/etc.]
- **Caching:** [Redis for read-heavy endpoints] / [edge cache for public reads] / [none at MVP]
- **Transaction strategy:** which write paths require transactions across multiple tables
- **Read replica policy:** when to read from replica vs primary

### Schema sketch

```
Table: api_keys
  id           uuid pk
  hash         text         -- bcrypt or argon2 of the actual key
  organization_id uuid
  scopes       text[]
  last_used_at timestamptz
  revoked_at   timestamptz nullable

Table: webhook_events
  id           uuid pk
  source       text         -- provider name
  event_id     text         -- upstream id, for dedup
  payload      jsonb
  signature_ok bool
  received_at  timestamptz
  processed_at timestamptz nullable
```

(Plus your domain entities.)

## §2.4 Incoming webhooks

For each provider:

- **Endpoint:** `POST /webhooks/{provider}`
- **Signature verification:** scheme (e.g. `HMAC-SHA256` over raw body using provider's secret), tolerance window
- **Replay protection:** dedupe on upstream `event_id` (stored in `webhook_events` table)
- **Processing model:** ack 200 immediately if signature ok + dedup miss → enqueue work; do heavy processing async
- **Retry posture upstream:** what the provider does on non-2xx; ensure handler is idempotent

## §2.5 Outgoing webhooks (if applicable)

- **Registration:** consumers register URLs + chosen events via API or UI
- **Delivery:** queue-based; worker picks events and delivers
- **Retry policy:** exponential backoff (e.g. 1m, 5m, 30m, 2h, 12h), max N attempts → DLQ
- **Signature for consumers:** HMAC over the body with consumer-specific secret
- **Failure surfacing:** dashboard for consumer to see failed deliveries, with manual retry

## §2.6 Rate limiting

- **Dimensions:** per-API-key + per-IP (defense in depth)
- **Algorithm:** token bucket (smooths bursts) or fixed window (simpler)
- **Tiers:** map plan → per-minute and per-day limits
- **State store:** Redis preferred for distributed; in-process if single node
- **429 response:** include `Retry-After` and `X-RateLimit-*` headers

## §2.7 Errors and status codes

Document the canonical error shape and the status code semantics.

```
{
  "error": {
    "code": "validation_error",
    "message": "Human-readable",
    "fields": { "email": "Invalid format" }   // for validation errors
  }
}
```

| Status | When |
|---|---|
| 400 | Validation error |
| 401 | Missing/invalid auth |
| 403 | Auth ok but action not permitted |
| 404 | Resource not found |
| 409 | Conflict (idempotency mismatch, version conflict) |
| 422 | Semantic error (well-formed but semantically invalid) |
| 429 | Rate limited |
| 5xx | Server error — never leak internals |

## §2.8 Observability

- **Logging:** structured JSON, request id propagated, PII redacted at log boundary
- **Metrics:** request rate, error rate, latency histogram per endpoint; webhook lag for incoming, delivery success rate for outgoing
- **Tracing:** OpenTelemetry spans on each handler + downstream call
- **SLA targets:** p95 latency per endpoint, error budget per period
