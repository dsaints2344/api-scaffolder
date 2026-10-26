---
name: api-scaffolder
description: Scaffold new API projects, either a standalone microservice repo or a service inside a monorepo, from a named architecture (Clean, Onion, Hexagonal, Vertical Slice, Layered/N-Tier, Modular Monolith, DDD), an optional pattern (CQRS, Mediator, Repository/Unit of Work, Specification, Result, Domain Events, Outbox, Saga, Event Sourcing), a tech stack (.NET, Node/NestJS, Java/Spring, Go, Python or any other) and the target IDE (Visual Studio, Rider, VS Code, Cursor, IntelliJ). Generates the layer folders, projects and references, one sample feature showing the pattern, IDE files, architecture tests, and verifies the build. Use it whenever the user wants to create, bootstrap, scaffold, set up or start a new API, backend, microservice or monorepo service with a given architecture or pattern, even without the word "scaffold", e.g. "spin up a Payments service with clean architecture", "new NestJS hexagonal API", "add an Inventory microservice to our monorepo".
---

# API Scaffolder

Turns a handful of choices into an API skeleton a team would actually keep: real layers with an enforced dependency rule, one small working feature that shows where everything goes, IDE files for the user's editor, and a green build. Empty folders with a README are not the goal.

| Input | Required | Examples |
|---|---|---|
| Repo mode | yes | `monorepo` (a service inside a shared repo) or `microservice` (standalone repo for one service) |
| Name | yes | `Payments` (service), plus the repo name for a new monorepo |
| Architecture | yes | clean, onion, hexagonal, vertical-slice, layered, modular-monolith, ddd |
| Pattern(s) | no | cqrs, mediator, repository-uow, specification, result, domain-events, outbox, saga, event-sourcing |
| Stack | yes | .NET 10 + EF Core + SQL Server · NestJS + Prisma + PostgreSQL · Spring Boot + JPA · Go + pgx · FastAPI + SQLAlchemy |
| IDE | yes | Visual Studio, Rider, VS Code, Cursor, IntelliJ IDEA, GoLand, PyCharm |

## Workflow

### 1. Read the target directory
Run `bash scripts/detect_repo.sh <target-dir>` from this skill's folder (target defaults to the current directory). Its `verdict:` line says whether the directory is empty, an existing monorepo, a single project, or a parent folder of separate repos (then ask which repo, or create a new folder there). It also reports which repo tooling is present (.NET solution, central package management, Nx, Turborepo, pnpm/npm workspaces, Gradle/Maven multi-module, go.work, uv workspace), existing services, CI, compose files, installed toolchains, and any `scaffold.yaml` files from earlier runs.

Why this comes first: in an existing repo, its conventions beat this skill's defaults (folder names, namespaces, solution format, package versions), and earlier `scaffold.yaml` files tell you what the user already chose, so you can reuse those choices instead of asking again. If the script can't run (no bash), do the same checks with Glob/Read.

### 2. Collect the inputs
Use everything the user already said and ask only for what's missing, in a single message (use AskUserQuestion when available). Pattern is optional: if the user named none, don't ask, just state in the plan that no pattern is applied. "Same as the other services" means: copy the stack and IDE from an existing `scaffold.yaml`.

Map synonyms before looking anything up: "ports and adapters" = hexagonal; "n-tier", "3-layer" = layered; "feature folders", "REPR" = vertical-slice; "DDD" = clean with the DDD domain layout; "MediatR" = mediator (and see licensing in the stack reference); "microservices monorepo" = monorepo mode.

Fill stack gaps from the stack reference's defaults and list every default you applied in the plan so the user can override it.

Write the plan and the final report in the language the user writes in.

### 3. Load only the references that apply
- `references/architectures.md`: the section for the chosen architecture, plus "Mapping layers to a stack"
- `references/patterns.md`: the section for each chosen pattern
- `references/compatibility.md`: always
- `references/repo-modes.md`: the section for the mode (new vs existing monorepo, or microservice)
- `references/ides.md`: the section for the IDE
- `references/stacks/<stack>.md`: `dotnet.md`, `node-typescript.md`, `java-spring.md`, `go.md`, `python.md`. For any other stack, follow "Stacks without a reference" below.

If the user names an architecture or pattern that has no entry, build it from your own knowledge in the same shape as the entries (purpose, layers, dependency rule, tree, sample feature location) and mark it in the plan as "not from the reference, please confirm".

### 4. Check compatibility
Check every pairing listed in `compatibility.md` (architecture x pattern, pattern x stack, mode x architecture, stack x IDE, library licensing). A rejection stops the run: explain why and suggest the closest valid combination. A warning goes in the plan; continue once the user accepts it.

### 5. Present the plan and wait for a yes
Scaffolding writes dozens of files and edits shared repo files, which is tedious to undo, so show the plan first:

```
## Scaffold plan: Payments
Mode: monorepo (existing; .NET, Platform.slnx, central package management)
Architecture: Clean · Patterns: CQRS, Result · IDE: Rider
Stack: .NET 10 · Minimal APIs · EF Core + SQL Server · xUnit · NetArchTest
Defaults applied: Minimal APIs, data annotations validation, OneOf results
Warnings: none

services/payments/
├── src/
│   ├── Payments.Domain/
│   ├── Payments.Application/
│   ├── Payments.Infrastructure/
│   └── Payments.Api/
└── tests/ ...
References: Api → Application, Infrastructure (DI only) · Infrastructure → Application · Application → Domain
Sample feature: Payments/CreatePayment (command) + GetPaymentById (query)
Outside the service folder: Platform.slnx, Directory.Packages.props, .github/workflows/payments.yml, deploy/docker-compose.yml
```

If the user already said "no need to confirm", "just build it", or nobody is there to answer (scheduled or unattended run), go ahead and put the plan at the top of the final report instead.

### 6. Generate, from the inside out
1. **Projects or modules via the stack's official CLI** (`dotnet new`, `nest new`, Spring Initializr, `go mod init`, `uv init`...). The CLI produces current, correct project files and versions; project files written from memory drift (stale SDK versions, renamed packages).
2. **Layer folders and references** following the architecture's tree and dependency rule.
3. **Pattern plumbing** from `patterns.md` (dispatcher, pipeline behaviors, base types, outbox table...).
4. **One sample feature, end to end**, named after the service's domain (Payments gets CreatePayment and GetPaymentById, not WeatherForecast). It is the user's map of where each piece of the architecture and pattern lives. Apply every chosen pattern to it. Delete the CLI's sample code (WeatherForecast, Class1, app.controller samples).
5. **Cross-cutting basics**: health endpoint, OpenAPI document, structured logging, configuration from settings files and environment, and global error handling that returns RFC 7807 ProblemDetails (or the stack's equivalent).
6. **Tests**: unit tests for the sample feature, one integration test that calls the sample endpoint over HTTP, and architecture tests that encode the dependency rule (tool per stack in the stack reference). The architecture tests are what keep the layers honest after a few months of feature work, so treat them as part of the scaffold, not an extra.
7. **IDE files** from `ides.md`.
8. **Repo-mode wiring** from `repo-modes.md`: solution or workspace registration, root config, CI, compose file.
9. **Docs**: the service `README.md` (run, test, layer map, where to add the next feature) and `docs/adr/0001-architecture.md` recording the architecture, patterns, stack and the reasons given.
10. **`scaffold.yaml`** at the service root (format below) so later runs in the same repo can reuse the choices.

### 7. Verify
Run the build, the tests and the architecture tests with the commands in the stack reference, and fix until green. If the toolchain isn't installed where you are running, say so plainly and give the user the exact commands to run. Never report a build or test run as passing unless you ran it.

### 8. Report
Keep it short:
- The plan as executed (tree summary, not a file list)
- Verification: build, tests, architecture tests (pass/fail, or "not run" and why)
- How to open it in the chosen IDE and run it (one or two commands)
- Two or three next steps at most (e.g. "set the connection string with user-secrets", "add the first real aggregate")

## scaffold.yaml

```yaml
schemaVersion: 1
name: Payments
mode: monorepo            # monorepo | microservice
architecture: clean
patterns: [cqrs, result]
ide: rider
stack:
  language: csharp
  runtime: net10.0
  web: minimal-api
  data: efcore
  database: sqlserver
  messaging: none
  validation: data-annotations
  tests: [xunit, netarchtest]
paths:
  service: services/payments
```

## Rules
- **Additive only in existing repos.** Never edit another service's files. Outside the new service's folder, touch only registration points (solution or workspace file, central package versions, root compose file, CI config, root README index) and list each one in the plan.
- **Existing conventions win** over this skill's defaults: namespace root, services folder name (`services/`, `apps/`, `src/`), solution format, package versions, CI system.
- **Never write into a non-empty target folder.** Stop and ask.
- **Every dependency earns its place.** Prefer framework built-ins (DI, health checks, ProblemDetails, validation) over extra packages, and check the licensing notes before adding a library.
- **No secrets in generated files.** Use placeholders, user-secrets or environment variables, and a `.env.example` where the stack uses `.env` files.

## Stacks without a reference
1. Create projects with the stack's official generator or package manager.
2. Map each layer to the smallest unit the stack can enforce boundaries on: a module/package where the language has one, otherwise a folder plus an import-lint rule.
3. Use the stack's architecture or import-rule testing tool if one exists; otherwise write a test that scans imports and fails on a forbidden direction.
4. Follow the stack's dominant conventions for layout, config and tests, and say in the plan which ones you chose.
