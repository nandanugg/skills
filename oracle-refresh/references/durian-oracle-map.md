# Durian Oracle Map

Use these definitions to keep the refresh consistent.

## Update Order

1. `services` — parallelized into three lanes: svc-core, svc-support, svc-platform
2. `flows`, `architecture`, `shared`, `domains`, `platform`, `patterns` after all services lanes checkpoint
3. service-led validation of the non-service results (routed to the relevant services lane(s))
4. final `services` reference pass back into validated downstream docs

`services` is the baseline phase. **Always parallelize it** into three lanes by service grouping:
- `svc-core` — core payment services (payment-link, checkout, orders, invoices, settlements, disbursements, refunds)
- `svc-support` — supporting services (merchants, customers, promos, exports, notifications)
- `svc-platform` — platform services (callbacks, scheduler, feature-flags, audit, integrations)

Refresh all three services lanes in parallel, checkpoint each independently, then use the combined updated service ownership and boundaries to drive the remaining areas. The downstream areas do not need a fixed strict order and may run in parallel if they do not conflict. After the downstream draft is done, route it back through the relevant services lane(s) for critical review. Only after the services lanes sign off should they add explicit references back into the validated downstream docs.

Use `git diff` first to estimate how large the combined `services` update is. If the combined update is small, keep the downstream non-service refresh in one lane. If the combined update is large, split the downstream non-service refresh across multiple lanes.

## Section Meanings

### `services`

Service-specific documentation. Capture what each service owns, its main responsibilities, important dependencies, inbound and outbound interfaces, and operational caveats. After downstream docs are validated, this area should also carry explicit references into the relevant downstream flows, architecture views, shared facts, domain rules, platform surfaces, and reusable patterns.

### `flows`

End-to-end business or operational journeys that cross services. Explain the sequence of events, main actors, critical handoffs, and failure points.

### `architecture`

Cross-cutting technical structure. Use this area for system-wide contracts, data shape, topology, storage, messaging, and other structural views that are broader than one service or one flow.

### `shared`

Canonical facts reused across multiple documents. Keep material here when it should be referenced by several sections instead of being duplicated in each one.

### `domains`

Business rules and mechanics. Document concepts such as fees, settlement rules, disbursement behavior, and other domain logic that explains why the system behaves the way it does.

### `platform`

Shared platform dependencies and common building blocks used across the estate, such as common libraries, core-banking integration surfaces, feature-flag systems, or operational consoles.

### `patterns`

Reusable engineering patterns and standard approaches. Use this section for recurring implementation rules such as idempotency, retries, callbacks, or error-handling conventions.
