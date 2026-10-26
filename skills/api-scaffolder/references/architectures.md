# Architectures

Contents: Layered · Clean · Onion · Hexagonal · Vertical Slice · Modular Monolith · DDD layout · Mapping layers to a stack

Each entry gives what it's for, the layers, the dependency rule (which the architecture tests must enforce), the tree, and where the sample feature goes. Trees use .NET-style names (`<Name>.Domain`); "Mapping layers to a stack" at the end translates them for other stacks.

---

## Layered (N-Tier)
**Best for:** simple CRUD APIs, small teams, short-lived services. Easiest to read; business logic tends to leak into data access over time.

**Layers:** Api (presentation) → Business (services, rules) → DataAccess (ORM, repositories).

**Dependency rule:** each layer references only the layer directly below it. Api never touches the database context.

```
src/
├── <Name>.Api/              # endpoints/controllers, request/response DTOs, Program.cs, DI
├── <Name>.Business/         # I<Entity>Service + implementations, business rules, models
└── <Name>.DataAccess/       # DB context, entity configurations, migrations, repositories
tests/
├── <Name>.Business.UnitTests/
├── <Name>.Api.IntegrationTests/
└── <Name>.ArchitectureTests/
```
**Sample feature:** `<Entity>Endpoints` → `I<Entity>Service` → repository / DB context.

---

## Clean Architecture
**Best for:** services with real business rules that should outlive frameworks. The default when the user is unsure.

**Layers:** Domain (center) ← Application ← Infrastructure, with Api as the composition root.

**Dependency rule:**
- Domain references nothing (no framework packages).
- Application references Domain only, and declares the interfaces (ports) it needs: `I<Entity>Repository`, `IUnitOfWork`, `IClock`, `IEmailSender`...
- Infrastructure references Application and Domain and implements Application's interfaces.
- Api references Application, and Infrastructure only to call its DI registration (`AddInfrastructure()`). Endpoints talk to Application only.

```
src/
├── <Name>.Domain/
│   ├── <Aggregate>/           # entity, value objects, domain events, errors, grouped by aggregate
│   └── Common/                # base Entity, ValueObject, IDomainEvent
├── <Name>.Application/
│   ├── <Feature>/             # use cases by feature (Commands/ and Queries/ with CQRS)
│   ├── Abstractions/          # ports: persistence, messaging, clock, current user
│   └── DependencyInjection.cs
├── <Name>.Infrastructure/
│   ├── Persistence/           # DB context, configurations, migrations, repositories
│   ├── <ExternalSystem>/      # one folder per integration (HTTP clients, brokers)
│   └── DependencyInjection.cs
└── <Name>.Api/
    ├── Endpoints/             # or Controllers/
    ├── Middleware/
    └── Program.cs
tests/
├── <Name>.Domain.UnitTests/
├── <Name>.Application.UnitTests/
├── <Name>.Api.IntegrationTests/
└── <Name>.ArchitectureTests/
```
**Sample feature:** entity in Domain/<Aggregate>, use case in Application/<Feature>, repository in Infrastructure/Persistence, endpoint in Api/Endpoints.

---

## Onion
**Best for:** teams that think in rings, or want domain services kept apart from application services. Same spirit as Clean with one more inner ring.

**Rings (inside → out):** Domain Model → Domain Services → Application Services → Infrastructure and Api (outermost).

**Dependency rule:** a ring references only rings inside it. Repository interfaces live in Domain Services.

```
src/
├── <Name>.Domain/             # entities, value objects
├── <Name>.Domain.Services/    # domain services + repository interfaces
├── <Name>.Application/        # application services orchestrating use cases, DTOs
├── <Name>.Infrastructure/     # persistence, external services
└── <Name>.Api/                # endpoints, Program.cs (composition root)
tests/                         # same shape as Clean
```
**Sample feature:** entity in Domain, repository interface in Domain.Services, application service in Application, implementation in Infrastructure, endpoint in Api.

---

## Hexagonal (Ports & Adapters)
**Best for:** services with several ways in (HTTP, messages, scheduled jobs) and several ways out (DB, other services, brokers). Swapping an adapter is cheap.

**Units:** Core (domain, ports, use cases), inbound (driving) adapters, outbound (driven) adapters, Host.

**Dependency rule:**
- Core references nothing outside itself.
- Inbound adapters call inbound ports (use-case interfaces) and never touch outbound adapters.
- Outbound adapters implement outbound ports.
- Adapters never reference each other. Host wires everything together.

```
src/
├── <Name>.Core/
│   ├── Domain/
│   ├── Ports/
│   │   ├── Inbound/           # I<Action><Entity>UseCase
│   │   └── Outbound/          # I<Entity>Repository, I<External>Gateway, IEventPublisher
│   └── UseCases/              # implementations of inbound ports
├── <Name>.Adapters.Http/          # inbound: endpoints → inbound ports
├── <Name>.Adapters.Messaging/     # only when the stack has a broker
├── <Name>.Adapters.Persistence/   # outbound: DB implementation of repository ports
└── <Name>.Host/                   # Program.cs, configuration, DI wiring
tests/
├── <Name>.Core.UnitTests/         # use cases tested with fake outbound ports
├── <Name>.Adapters.Persistence.IntegrationTests/
├── <Name>.Host.IntegrationTests/
└── <Name>.ArchitectureTests/
```
**Sample feature:** `ICreate<Entity>UseCase` + implementation, `I<Entity>Repository` + persistence adapter, HTTP endpoint in Adapters.Http.

---

## Vertical Slice
**Best for:** feature-heavy APIs and teams that ship feature by feature, with minimal ceremony. Each request is a self-contained slice.

**Units:** Features (slices), a thin shared Common, optional Domain.

**Dependency rule:** slices never reference other slices. Shared code lives in Common or Domain. Slices may use the DB context directly.

Usually one API project plus tests. Split Domain into its own project only if the user asks or the domain is rich.

```
src/
└── <Name>.Api/
    ├── Features/
    │   └── <Feature>/                 # e.g. Orders
    │       ├── Create<Entity>/
    │       │   ├── Create<Entity>Endpoint
    │       │   ├── Create<Entity>Request / Response
    │       │   └── Create<Entity>Handler
    │       └── Get<Entity>ById/
    ├── Domain/                         # entities shared by slices
    ├── Common/
    │   ├── Persistence/                # DB context, configurations, migrations
    │   └── Behaviors/                  # cross-cutting: validation, logging (filters or pipeline)
    └── Program.cs                      # discovers and maps every slice's endpoint
tests/
├── <Name>.Api.IntegrationTests/       # slices tested through HTTP
└── <Name>.ArchitectureTests/          # no slice references another slice
```
**Sample feature:** two slices of one feature (create + get by id).

---

## Modular Monolith
**Best for:** one deployable that should be splittable later, holding several bounded contexts.

**Units:** Host (bootstrapper); Modules, each a small application with its own internal architecture (Clean by default, Vertical Slice if the user prefers); Shared.

**Dependency rule:**
- A module's internals are invisible to other modules. Modules talk only through another module's `Contracts` (public interfaces, integration events) or an in-process event bus.
- Each module owns its data (its own schema and DB context); no cross-module joins.
- Shared holds cross-cutting code only (abstractions, base types), never business logic.

```
src/
├── Host/<Name>.Host/                         # Program.cs: registers each module
├── Modules/
│   └── <Module>/                             # one per bounded context
│       ├── <Name>.Modules.<Module>.Contracts/       # public API: interfaces, integration events, DTOs
│       ├── <Name>.Modules.<Module>.Domain/
│       ├── <Name>.Modules.<Module>.Application/
│       ├── <Name>.Modules.<Module>.Infrastructure/  # own DB context + schema
│       └── <Name>.Modules.<Module>.Endpoints/
└── Shared/
    ├── <Name>.Shared.Abstractions/
    └── <Name>.Shared.Infrastructure/         # event bus, outbox, common middleware
tests/
├── Modules/<Module>/...
└── <Name>.ArchitectureTests/                 # module isolation rules
```
If the user didn't name the modules, ask; default to two modules so the isolation rules have something to enforce. **Sample feature:** one use case in module A that publishes an integration event handled by module B.

---

## DDD layout (when the user says "DDD")
DDD is a design approach, not a folder layout. Use Clean (or Onion if asked) with a richer Domain, and pair it with the domain-events pattern by default:

```
<Name>.Domain/
├── <Aggregate>/
│   ├── <Aggregate>              # aggregate root: invariants enforced in methods, private setters
│   ├── <Aggregate>Id            # strongly typed id
│   ├── ValueObjects/
│   ├── Events/                  # domain events raised by the aggregate
│   ├── I<Aggregate>Repository   # one repository per aggregate root; the interface lives in Domain here
│   └── <Aggregate>Errors
├── Services/                    # domain services spanning aggregates
└── SharedKernel/                # Entity, AggregateRoot, ValueObject, IDomainEvent
```

---

## Mapping layers to a stack

| Stack | One layer is | How the dependency rule is enforced |
|---|---|---|
| .NET | a project (.csproj) | project references + NetArchTest/ArchUnitNET tests |
| Java (Spring) | a Gradle/Maven module, or a package in a single module | module dependencies + ArchUnit |
| TypeScript (NestJS, Express, Fastify) | a top-level folder in the service package; shared libs are workspace packages | dependency-cruiser rules |
| Go | a package under `internal/` | import direction checked by go-arch-lint |
| Python | a package under `src/<pkg>/` | import-linter contracts |

In every stack, Vertical Slice collapses the layers into feature folders, and Modular Monolith maps each module to the stack's largest unit (project group, Gradle module, workspace package, Go package tree, Python package).
