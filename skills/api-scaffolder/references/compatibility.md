# Compatibility

Check every pairing below. **Reject**: stop, explain, suggest the closest valid combination. **Warn**: list it in the plan and continue once the user accepts. Anything not listed is fine.

## Architecture x pattern

| Architecture | Pattern | Verdict | Why, and what to suggest |
|---|---|---|---|
| Vertical Slice | Repository + UoW | Warn | Slices normally use the DB context directly; a repository per slice adds indirection with little gain. Suggest dropping it, or repositories only for aggregates many slices share. |
| Vertical Slice | Specification | Warn | Same reason; specifications pay off with repositories. |
| Hexagonal | Mediator | Warn | Inbound ports already are the dispatch boundary, so a mediator duplicates it. Suggest ports only, or the mediator as an internal detail of UseCases. |
| Layered | CQRS | Warn | Layered groups code by entity, CQRS by use case, so files end up split two ways. Suggest Clean or Vertical Slice if CQRS matters. |
| Layered | Event Sourcing | Reject | A layered CRUD structure has no place for aggregates and projections. Suggest Clean or Hexagonal with CQRS. |
| Any | Event Sourcing without CQRS | Warn | Reading from event streams needs projections. Suggest adding CQRS. |
| Any | Specification without Repository | Warn | Repositories evaluate specifications. Suggest adding Repository or dropping Specification. |

## Pattern x stack

| Pattern | Needs | If missing |
|---|---|---|
| Outbox | a database and a message broker | Reject: ask which broker, or drop Outbox |
| Saga | a message broker | Reject: ask which broker |
| Event Sourcing | an event store (or a library on the existing database) | Warn: propose one from the stack reference |

## Repo mode x architecture

| Mode | Architecture | Verdict | Why |
|---|---|---|---|
| microservice | Modular Monolith | Warn | A modular monolith is one deployable holding several bounded contexts; for a single microservice that is usually more structure than one context needs. Suggest Clean or Vertical Slice, or confirm the service really spans several contexts. |

## Stack x IDE

| Combination | Verdict | Why |
|---|---|---|
| Visual Studio + non-.NET stack | Warn | Weak support for Java, Go and Python APIs. Suggest VS Code or the JetBrains IDE for that language. |
| Visual Studio on macOS | Warn | Visual Studio for Mac is retired. Suggest Rider or VS Code with C# Dev Kit. |
| .NET + IntelliJ IDEA / GoLand / PyCharm | Warn | Suggest Rider, the JetBrains IDE for .NET. |

## Library licensing
Some popular libraries moved to commercial licenses (details per stack in `references/stacks/`). Treat each as a warning: name the library and the free alternative, and let the user choose. Never add one silently.
