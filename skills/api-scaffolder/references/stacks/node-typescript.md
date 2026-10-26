# Node.js / TypeScript

## Defaults
| Concern | Default |
|---|---|
| Framework | NestJS (its modules and DI fit layered architectures). Express or Fastify only if named. |
| Package manager | pnpm; in an existing repo, whatever its lockfile says |
| Data | Prisma + PostgreSQL (Drizzle or TypeORM if named) |
| Validation | `class-validator` + `class-transformer` with a global `ValidationPipe` (zod if the user prefers) |
| Tests | Jest (NestJS default) + Supertest for HTTP integration tests |
| Architecture tests | dependency-cruiser |
| Lint/format | ESLint + Prettier (from the Nest template) |
| Monorepo tooling | pnpm workspaces + Turborepo for a new repo; follow Nx or Nest monorepo mode if the repo uses them |

## Commands
```bash
npx @nestjs/cli new <name> --package-manager pnpm --skip-git --strict
pnpm add @prisma/client && pnpm add -D prisma dependency-cruiser
npx prisma init --datasource-provider postgresql
```
Delete `app.controller.ts`, `app.service.ts` and their spec after creating the sample feature.

## Mapping layers
Top-level folders under `src/` per the architecture (`domain/`, `application/`, `infrastructure/`, `presentation/`), and one Nest module per feature that binds ports to adapters with injection tokens:

```ts
// application/ports/payment-repository.port.ts
export const PAYMENT_REPOSITORY = Symbol('PAYMENT_REPOSITORY');
export interface PaymentRepository { save(p: Payment): Promise<void>; }

// presentation/payments/payments.module.ts
providers: [{ provide: PAYMENT_REPOSITORY, useClass: PrismaPaymentRepository }]
```
Domain stays free of Nest decorators and Prisma types.

## Pattern libraries
| Pattern | Choice |
|---|---|
| CQRS / Mediator | `@nestjs/cqrs` (CommandBus, QueryBus, EventBus) |
| Result | a small hand-written `Result<T, E>` type, or `neverthrow` |
| Domain events | `@nestjs/cqrs` EventBus, published after the Prisma transaction commits |
| Outbox | outbox table written in the same `prisma.$transaction`, plus a polling worker |
| Messaging | `kafkajs`, `amqplib`, or `@azure/service-bus` as the user's broker requires |
| Event sourcing | ask; no default library |

## Architecture tests
`.dependency-cruiser.cjs` with `forbidden` rules matching the dependency rule, for example:
```js
{ name: 'domain-is-independent', severity: 'error',
  from: { path: '^src/domain' }, to: { path: '^src/(application|infrastructure|presentation)' } }
```
Add a `pnpm arch` script running `depcruise src --config .dependency-cruiser.cjs`.

## Monorepo
`apps/<service>` for services, `packages/<lib>` for shared code, `pnpm-workspace.yaml` listing both, `turbo.json` with `build`, `test`, `lint` and `arch` tasks.

## Verify
```bash
pnpm build && pnpm test && pnpm lint && pnpm arch
```
