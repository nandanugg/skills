# Oracle Quick Index

This file helps the agent quickly determine which oracle files to read for a given query.
Read this FIRST before diving into individual oracle files.

Oracle root: `/Users/nanda/Documents/projects/durianpay/oracle/durian-oracle`

## Keyword → File Mapping

### Payment & Transactions
- Payment creation, charge, capture → `flows/payment-in.md`, `services/payment_service.md`
- Payout, transfer, send money → `flows/payment-out.md`, `services/disbursement_service.md`
- Refund, reversal, chargeback → `flows/refund.md`, `services/refund_service.md`
- Order, checkout → `services/order_service.md`

### Settlement
- Settlement calculation, schedule, batch → `domains/settlement-mechanics.md`, `flows/settlement.md`, `services/settlement_service.md`
- Settlement routing, bank paths → `domains/settlement-paths.md`
- Settlement cron, scheduler → `services/settlement_scheduler_cron.md`
- Settlement email parsing → `services/settlement_email_reader.md`
- Large merchant settlement, fan-out → `decisions/adr-014-chunk-based-kafka-fan-out-for-large-merchant-settlement.md`

### Fees & Billing
- Fee calculation, MDR, platform fee → `domains/fee-mechanics.md`

### Disbursement
- Top-up, balance, disbursement pool → `domains/disbursement-topup-mechanics.md`, `services/disbursement_service.md`

### Auth & Merchant
- API keys, auth, identity, JWT → `flows/auth-and-identity.md`, `services/auth_service.md`
- Merchant setup, KYC, onboarding → `flows/merchant-onboarding.md`, `services/merchant_service.md`
- Customer data, PII, account binding → `services/customer_service.md`

### Order & Notification
- Order creation, status, payment links → `services/order_service.md`
- Email, WhatsApp, webhook notifications → `services/notification_service.md`

### Analytics, Reporting & Ops
- Merchant CRM, analytics, Mixpanel, HubSpot → `services/analytics_service.md`
- Report generation, export (orders, payments, settlements) → `services/report_service.md`
- Internal operations, KYB, promos, sweep-in → `services/ops_service.md`, `services/ops-console.md`, `platform/ops-console.md`

### Infrastructure & Patterns
- Kafka, events, topics, consumers → `architecture/kafka-topology.md`, `architecture/event-catalog.md`
- gRPC, API contracts, protobuf → `architecture/api-contracts.md`, `decisions/adr-001-grpc-for-internal-service-contracts.md`
- HTTP + gRPC dual entry → `decisions/adr-002-dual-http-and-grpc-entrypoints-per-service.md`
- Database schema, tables → `architecture/db-schema.md`
- Callbacks, webhooks, idempotency → `patterns/callback-and-idempotency.md`, `services/callback_service.md`
- Error handling → `patterns/error-handling.md`
- Retry, backoff, DLQ → `patterns/retry-strategy.md`, `decisions/adr-005-kafka-event-bus-with-dlq-and-republish-retries.md`
- Circuit breaker, routing resilience → `decisions/adr-011-custom-circuit-breaker-for-routing-resilience.md`
- Redis locks, deduplication → `decisions/adr-007-redis-setnx-locks-for-callback-deduplication.md`
- Background jobs, async tasks → `decisions/adr-006-asynq-on-redis-for-background-jobs.md`
- Feature flags, unleash → `decisions/adr-010-unleash-feature-flags-with-merchant-targeting.md`, `platform/dpay-unleash.md`, `services/dpay-unleash.md`
- Configuration, consul, viper → `decisions/adr-004-consul-and-viper-for-centralized-configuration.md`
- Observability, tracing, metrics → `decisions/adr-009-opentelemetry-plus-prometheus-observability-baseline.md`

### Platform & Shared Libraries
- dpay-common (shared lib) → `platform/dpay-common.md`, `services/dpay-common.md`, `decisions/adr-003-dpay-common-as-shared-platform-library.md`
- Core banking → `platform/dpay-core-banking.md`, `services/dpay-core-banking.md`
- Ops console → `platform/ops-console.md`, `services/ops-console.md`, `decisions/adr-013-openapi-generated-ops-console-client.md`
- SQL, sqlx, query files → `decisions/adr-008-sqlx-with-explicit-sql-query-files.md`

### Architecture Layers
- Domain layering (core/banking/app/infra) → `decisions/adr-012-core-banking-app-domain-infra-layering.md`
- Dual Kafka ack models → `decisions/adr-015-dual-kafka-acknowledgment-models.md`
- Callback ingress → `decisions/adr-016-callback-service-as-http-ingress-gateway.md`

### Testing & QA
- Test automation, API tests → `services/dpay_api_test_automation.md`, `services/dpay_test_automation.md`
- Test visibility → `domains/test-visibility.md`, `flows/test-visibility.md`, `services/test-visibility.md`

### Big Picture
- System overview, how services relate → `references/oracle-context-map.md`
- Notifications → `services/notification_service.md`
- Analytics, reporting → `services/analytics_service.md`, `services/report_service.md`
- Ops internal tools → `services/ops_service.md`
