# Oracle Context Map

Use these definitions to keep the refresh consistent.

## Update Order

1. `services`
2. `flows`, `architecture`, `shared`, `domains`, `platform`, `patterns` after `services`

`services` is the baseline phase. Refresh it first, checkpoint it, then use the updated service ownership and boundaries to drive the remaining areas. The remaining areas do not need a fixed strict order and may run in parallel if they do not conflict.

## Section Meanings

### `services`

Service-specific documentation. Capture what each service owns, its main responsibilities, important dependencies, inbound and outbound interfaces, and operational caveats.

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
