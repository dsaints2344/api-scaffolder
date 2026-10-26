# Java / Spring Boot

## Defaults
| Concern | Default |
|---|---|
| JDK | latest LTS installed (`java -version`) |
| Build | Gradle with Kotlin DSL (Maven if named or already in the repo) |
| Web | Spring Web (MVC); WebFlux only if asked |
| Data | Spring Data JPA + PostgreSQL, Flyway for migrations |
| Validation | Jakarta Bean Validation (`spring-boot-starter-validation`) |
| Ops | Spring Boot Actuator (health, readiness, liveness), springdoc-openapi |
| Tests | JUnit 5, Spring Boot Test, Testcontainers |
| Architecture tests | ArchUnit |

## Commands
Generate from Spring Initializr (needs network access to start.spring.io; use the `spring init` CLI if installed):
```bash
curl https://start.spring.io/starter.zip \
  -d type=gradle-project-kotlin -d language=java \
  -d dependencies=web,data-jpa,postgresql,validation,actuator,flyway,testcontainers \
  -d groupId=<group> -d artifactId=<name> -d name=<Name> -o <name>.zip
```
If the network blocks it, write the Gradle build by hand from the user's installed versions and say so in the report.

## Mapping layers
Multi-module Gradle build, one module per layer (`domain`, `application`, `infrastructure`, `api`); only `api` applies the Spring Boot plugin and is bootable. For a small service the user may prefer one module with packages per layer; ArchUnit then enforces the rule.

## Pattern libraries
| Pattern | Choice |
|---|---|
| CQRS / Mediator | hand-written command and query handler interfaces as Spring beans |
| Result | sealed interfaces + records |
| Domain events | Spring `ApplicationEventPublisher` with `@TransactionalEventListener(phase = AFTER_COMMIT)` |
| Outbox | Spring Modulith event publication registry, or an outbox table + scheduled publisher |
| Modular Monolith | Spring Modulith (module verification test included) |
| Saga / Event sourcing | ask; Axon Framework only if the user wants it |

## Architecture tests
ArchUnit has ready-made rules: `Architectures.layeredArchitecture()` for Layered and Clean, `Architectures.onionArchitecture()` for Onion and Hexagonal (domain models, domain services, application services, adapters).

## Monorepo
Root `settings.gradle.kts` including `services:<service>:*` modules, shared code under `libs/`, version catalog in `gradle/libs.versions.toml`.

## Verify
```bash
./gradlew build    # compiles and runs all tests, ArchUnit included
```
