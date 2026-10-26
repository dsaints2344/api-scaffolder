# API Scaffolder

A Claude Code plugin that scaffolds API projects from four choices:

| Input | Examples |
|---|---|
| Repo mode | `monorepo` (a service inside a shared repo) or `microservice` (standalone repo) |
| Architecture | Clean, Onion, Hexagonal, Vertical Slice, Layered/N-Tier, Modular Monolith, DDD |
| Pattern (optional) | CQRS, Mediator, Repository + Unit of Work, Specification, Result, Domain Events, Outbox, Saga, Event Sourcing |
| Stack | .NET, Node/NestJS, Java/Spring Boot, Go, Python, or any other |
| IDE | Visual Studio, Rider, VS Code, Cursor, IntelliJ IDEA, GoLand, PyCharm |

## What you get

- Layer folders and projects with references that follow the architecture's dependency rule
- One sample feature named after your domain, showing where each piece of the architecture and pattern lives
- Architecture tests that fail the build when a layer breaks the rule
- IDE files for your editor (`.run/` for Rider, `.vscode/` for VS Code, solution folders for Visual Studio)
- Repo wiring: root solution or workspace, central package versions, path-filtered CI, docker-compose
- A README, an ADR and a `scaffold.yaml` that later runs reuse, so the next service in the monorepo starts from the same choices
- A build and test run at the end, reported honestly

Before writing anything it inspects the target folder, asks only for missing inputs, flags incompatible combinations (for example Vertical Slice + Repository) and libraries that now need a commercial license, and shows you the plan.

## Install

```bash
claude plugin marketplace add <your-github-user>/api-scaffolder
claude plugin install api-scaffolder@david-tools
```

Update later with `claude plugin update api-scaffolder@david-tools`.

## Use

Ask in plain words; the skill triggers on its own:

> Create a new monorepo called Banking.Platform with a Payments service: Clean Architecture + CQRS, .NET 10, EF Core with SQL Server, Rider.

> Spin up a standalone notifications microservice: hexagonal, NestJS + Prisma + Postgres, VS Code.

> Add an Inventory service to this monorepo, vertical slice, same stack as payments.

Or call it directly: `/api-scaffolder:api-scaffolder`.

## Layout

```
.claude-plugin/
├── plugin.json            # plugin manifest
└── marketplace.json       # makes this repo installable as a marketplace
skills/api-scaffolder/
├── SKILL.md               # workflow and rules
├── references/            # architectures, patterns, compatibility, repo modes, IDEs, stacks/
├── scripts/detect_repo.sh # read-only inspection of the target folder
└── evals/                 # test cases for `claude plugin eval`
```

## Develop

```bash
claude plugin validate --strict .                         # check the manifests
claude --plugin-dir .                                     # try it in a session without installing
cd skills/api-scaffolder && claude plugin eval . --allow-tools Write,Edit,Bash --scaffold   # run the test cases
```

Bump `version` in `.claude-plugin/plugin.json` on every release; users only receive a new copy when the version changes.

## License

MIT, see [LICENSE](LICENSE).
