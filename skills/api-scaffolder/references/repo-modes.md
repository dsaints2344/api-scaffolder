# Repo modes

Contents: Monorepo (new) · Monorepo (existing) · Per-service CI · Microservice (standalone repo)

## Monorepo
Several services, plus shared libraries, in one repository.

### New monorepo (target directory empty)
```
<repo>/
├── services/
│   └── <service>/              # the architecture's src/ and tests/ live here
├── building-blocks/            # shared libs (abstractions, contracts, observability); create only what the first service uses
├── deploy/
│   └── docker-compose.yml      # every service + infrastructure (database, broker)
├── .github/workflows/          # or azure-pipelines/: one path-filtered pipeline per service
├── docs/adr/
├── <root solution or workspace file>
├── <root build config>         # per stack reference: Directory.Build.props, pnpm-workspace.yaml, settings.gradle.kts, go.work...
├── .editorconfig
├── .gitignore
└── README.md                   # index of services and how to run everything
```
Ask for the repo name if the user didn't give one; it names the root solution or workspace.

### Existing monorepo
- Follow what `detect_repo.sh` found: the services folder name (`services/`, `src/`, `apps/`), naming and namespace root, the solution or workspace format, how package versions are managed, the CI system.
- Add the service folder, then register it: root solution or workspace, a pipeline for it, an entry in the root compose file, a line in the root README.
- Reuse existing building blocks rather than generating copies. If the service needs something shared that doesn't exist yet, put it in the service and mention in the report that it could move to building-blocks.
- Take package versions from central package management and add a package there only when it's new to the repo.

### Per-service CI (path-filtered)
Trigger on `services/<service>/**` plus any shared folder the service references. Steps: restore → build → test (including architecture tests) → container build. Use the CI system the repo already uses; in a new repo default to GitHub Actions unless the user names Azure DevOps or another system.

## Microservice (standalone repo)
One service in its own repository, deployable on its own.

```
<service>/
├── src/ and tests/             # per architecture
├── Dockerfile                  # multi-stage, runs as non-root
├── .dockerignore
├── docker-compose.yml          # the service + its infrastructure for local development
├── .github/workflows/ci.yml    # build, test, container build
├── docs/adr/0001-architecture.md
├── <stack root config>         # e.g. global.json, Directory.Build.props
├── .editorconfig
├── .gitignore
└── README.md
```
Include the production basics: liveness and readiness health checks, structured logging, configuration from environment variables, graceful shutdown, and the OpenAPI document. Contracts that other services consume (integration events, client DTOs) go in a small separate `<Name>.Contracts` project or package so they can be published on their own.
