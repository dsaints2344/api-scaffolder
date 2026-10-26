# Patterns

Contents: CQRS · Mediator · Repository + Unit of Work · Specification · Result · Domain Events · Outbox · Saga · Event Sourcing · Combining patterns

Each entry says what to generate, where it lives per architecture, and what the sample feature should show. Library choices and licensing per stack live in `references/stacks/`.

---

## CQRS
Separate writes (commands) from reads (queries). Start with one database; a separate read store is a later decision, so don't generate one unless asked.

**Generate:**
- A command + handler for the sample write; a query + handler + read DTO for the sample read.
- Queries return DTOs or projections directly (no domain entities, no change tracking). Commands go through the domain model.
- Marker interfaces `ICommand<TResult>`, `IQuery<TResult>`, `ICommandHandler<,>`, `IQueryHandler<,>`, unless a mediator library already provides them.

| Architecture | Where |
|---|---|
| Clean / Onion | `Application/<Feature>/Commands/<Action>/` and `Application/<Feature>/Queries/<Action>/` |
| Hexagonal | inbound ports split into `Ports/Inbound/Commands` and `Ports/Inbound/Queries`; handlers in `UseCases/` |
| Vertical Slice | each slice is one command or one query; the slice is the pattern |
| Layered | `Business/<Feature>/Commands` and `Queries` (works; see compatibility) |
| Modular Monolith | inside each module's Application |

---

## Mediator
An in-process dispatcher: endpoints send a request object, and the mediator finds its handler and runs pipeline behaviors (validation, logging, transactions) around it.

**Generate:** the dispatcher registration, a validation behavior and a logging behavior (plus a transaction behavior for commands when Unit of Work is chosen), and endpoints that only send requests.

**Where:** the dispatcher abstraction and behaviors in Application (Clean, Onion), `Common/Behaviors` (Vertical Slice), Shared (Modular Monolith).

Pairs naturally with CQRS. Check the stack reference's licensing notes before picking a library; a hand-written dispatcher of about 60 lines is always an option, and is the default when no library is free to use.

---

## Repository + Unit of Work
Repository: collection-like access per aggregate root. Unit of Work: one commit for everything a use case changed.

**Generate:**
- `I<Aggregate>Repository` with only the methods the sample feature needs. Skip the generic `IRepository<T>` with fifteen methods: it leaks ORM concerns and most of it goes unused.
- `IUnitOfWork` with `SaveChangesAsync`. When the ORM already tracks changes (EF Core DbContext, Hibernate session), implement it with that context; otherwise write a real implementation.

**Where:** interfaces in `Application/Abstractions` (Clean), in Domain (DDD layout), in `Domain.Services` (Onion), in `Ports/Outbound` (Hexagonal). Implementations in `Infrastructure/Persistence` or `Adapters.Persistence`.

---

## Specification
Query criteria as reusable objects that repositories evaluate.

**Generate:** a base `Specification<T>`, one example (`Active<Entity>sSpec` or `<Entity>ByIdSpec`), and the evaluator in the persistence layer. Specifications live next to their aggregate in Domain (or in Application for read-only specs). Requires Repository.

---

## Result
Return success-or-failure values for expected failures (not found, validation, conflict) instead of throwing. Exceptions stay for truly exceptional cases.

**Generate:** a Result type (or the stack's library), an `Error` model with a kind (Validation, NotFound, Conflict, Failure), and a single mapping point in the API layer from error kind to HTTP status plus ProblemDetails. Use it in the sample feature's "not found" path so the mapping is exercised by a test.

---

## Domain Events
Aggregates raise events (`<Entity>Created`) when their state changes; handlers react in the same process after the save succeeds.

**Generate:** `IDomainEvent`, an event list on the aggregate root base class, dispatch after a successful commit (EF Core: a SaveChanges interceptor; elsewhere: the unit-of-work commit), and one handler (e.g. writes an audit log entry).

---

## Outbox
Guarantees an integration event is published if and only if the database transaction commits. Needs a database and a message broker in the stack (see compatibility).

**Generate:** an outbox table or entity written in the same transaction as the business change, a background publisher that reads, publishes and marks rows, and a README note that consumers must be idempotent. Prefer the messaging library's built-in outbox when it has one.

**Where:** `Infrastructure/Messaging`, or `Shared.Infrastructure` in a Modular Monolith.

---

## Saga (Process Manager)
Coordinates a multi-step business process across services, with compensation on failure. Needs a message broker.

**Generate:** one orchestrator or state machine for the sample process (e.g. Order: Submitted → PaymentRequested → Completed or Cancelled), its persisted state, and the commands and events it exchanges. It lives in Infrastructure when the library couples to the broker (the usual case), otherwise in `Application/Sagas`.

---

## Event Sourcing
State is derived from a stream of events instead of stored rows. High complexity: confirm the user wants it (audit-heavy domains, temporal queries) before generating.

**Generate:** an aggregate with `Apply(event)` methods, an event store abstraction and implementation, one projection that builds the sample read model, and a TODO note on snapshotting. Pair it with CQRS: the projections are the read side.

---

## Combining patterns
Sets that work well together:
- **CQRS + Mediator + Result** (+ validation behavior): the common "Clean + CQRS" setup.
- **Repository/UoW + Domain Events + Outbox**: reliable writes that publish integration events.
- **Event Sourcing + CQRS**: event store for writes, projections for reads.

Apply every requested pattern to the same sample feature so the user sees how they interact.
