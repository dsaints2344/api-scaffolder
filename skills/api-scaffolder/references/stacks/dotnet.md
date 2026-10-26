# .NET

Contents: Defaults · Licensing · Commands · Packages by concern · Pattern libraries · Architecture tests · Root config · Verify

## Defaults
Apply these unless the user or the existing repo says otherwise, and list the ones you applied in the plan.

| Concern | Default |
|---|---|
| SDK | latest LTS in `dotnet --list-sdks`, pinned in `global.json` |
| API style | Minimal APIs, one static class per feature with a `Map<Feature>Endpoints` extension (Controllers only if asked) |
| Data | EF Core + SQL Server |
| Validation | Data annotations on request types. On .NET 10+, the built-in Minimal API validation (`builder.Services.AddValidation()`); on older SDKs, an endpoint filter (or mediator behavior) running `Validator.TryValidateObject`. Use FluentValidation only if asked. |
| Results (Result pattern) | `OneOf` for discriminated results, mapped to ProblemDetails in the API layer |
| Errors | `AddProblemDetails()` + an `IExceptionHandler` + `app.UseExceptionHandler()` |
| Mapping | hand-written extension methods (`ToResponse()`), no mapping library |
| Package versions | Central Package Management (`Directory.Packages.props`) |
| Tests | xUnit (`dotnet new xunit`), `Microsoft.AspNetCore.Mvc.Testing` for integration tests, Testcontainers for the database when Docker is available |
| Architecture tests | NetArchTest.Rules (ArchUnitNET if the user prefers) |
| OpenAPI | the template's built-in OpenAPI document; offer a UI (Scalar or Swagger UI) rather than adding one |

## Licensing
Ask before adding these; offer the free alternative in the same question.

| Library | Status | Free alternative |
|---|---|---|
| MediatR | 13+ needs a commercial license key (12.x and earlier are Apache-2.0) | hand-written dispatcher (default), `Mediator` (source-generated), Wolverine |
| AutoMapper | commercial edition | hand-written mapping extensions |
| MassTransit | v9 is commercial; v8 is open source | MassTransit 8, Wolverine, or the broker's own client (`Confluent.Kafka`, `Azure.Messaging.ServiceBus`, `RabbitMQ.Client`) |
| FluentAssertions | 8+ is commercial | xUnit `Assert`, Shouldly |

## Commands (Clean example; adapt names and projects to the architecture)

```bash
# Solution (skip in an existing monorepo: add to the root solution instead)
dotnet new sln -n <Name> --format slnx || dotnet new sln -n <Name>

# Projects
dotnet new classlib -n <Name>.Domain         -o src/<Name>.Domain
dotnet new classlib -n <Name>.Application    -o src/<Name>.Application
dotnet new classlib -n <Name>.Infrastructure -o src/<Name>.Infrastructure
dotnet new webapi   -n <Name>.Api            -o src/<Name>.Api          # add --use-controllers for controllers
dotnet new xunit    -n <Name>.Application.UnitTests -o tests/<Name>.Application.UnitTests
dotnet new xunit    -n <Name>.Api.IntegrationTests  -o tests/<Name>.Api.IntegrationTests
dotnet new xunit    -n <Name>.ArchitectureTests     -o tests/<Name>.ArchitectureTests

# References = the dependency rule
dotnet add src/<Name>.Application    reference src/<Name>.Domain
dotnet add src/<Name>.Infrastructure reference src/<Name>.Application
dotnet add src/<Name>.Api            reference src/<Name>.Application src/<Name>.Infrastructure

# Register every project (solution folders mirror the paths by default)
dotnet sln <solution> add src/*/*.csproj tests/*/*.csproj
```

Then delete `Class1.cs` and the WeatherForecast sample, and add `public partial class Program;` at the end of the API's `Program.cs` so `WebApplicationFactory<Program>` can see it (harmless if the SDK already generates it). Create the initial EF Core migration if `dotnet ef` is installed; otherwise put the command in the README:
`dotnet ef migrations add Initial -p src/<Name>.Infrastructure -s src/<Name>.Api`

## Packages by concern

| Concern | Package (project) |
|---|---|
| SQL Server | `Microsoft.EntityFrameworkCore.SqlServer` (Infrastructure), `Microsoft.EntityFrameworkCore.Design` (Api) |
| PostgreSQL | `Npgsql.EntityFrameworkCore.PostgreSQL` |
| DB health check | `Microsoft.Extensions.Diagnostics.HealthChecks.EntityFrameworkCore` → `AddHealthChecks().AddDbContextCheck<AppDbContext>()` |
| Integration tests | `Microsoft.AspNetCore.Mvc.Testing`, `Testcontainers.MsSql` / `Testcontainers.PostgreSql` |
| Architecture tests | `NetArchTest.Rules` |
| Results | `OneOf` |
| Local orchestration | docker-compose by default; offer an Aspire AppHost if the user mentions Aspire |

## Pattern libraries

| Pattern | Choice |
|---|---|
| CQRS / Mediator | hand-written `ICommandHandler`/`IQueryHandler` + dispatcher by default; libraries per licensing table |
| Specification | `Ardalis.Specification` + `Ardalis.Specification.EntityFrameworkCore` |
| Domain events | EF Core `SaveChangesInterceptor` that dispatches after a successful save |
| Outbox | the messaging library's outbox (MassTransit EF outbox, Wolverine durable outbox); otherwise an outbox table + `BackgroundService` publisher |
| Saga | MassTransit state machine or Wolverine saga |
| Event sourcing | Marten (PostgreSQL) or KurrentDB (formerly EventStoreDB) |

## Architecture tests
One test per rule, named as the rule, with an assembly marker class per project (`public sealed class DomainAssemblyMarker;`):

```csharp
[Fact]
public void Domain_does_not_depend_on_any_other_layer()
{
    var result = Types.InAssembly(typeof(DomainAssemblyMarker).Assembly)
        .ShouldNot()
        .HaveDependencyOnAny("<Name>.Application", "<Name>.Infrastructure", "<Name>.Api")
        .GetResult();

    Assert.True(result.IsSuccessful, string.Join(", ", result.FailingTypeNames ?? Array.Empty<string>()));
}
```
Vertical Slice: for each feature namespace `<Name>.Api.Features.X`, assert no dependency on the other feature namespaces. Modular Monolith: assert each module depends on other modules' `.Contracts` only.

## Root config
New repo (monorepo root, or the standalone microservice root):
```bash
dotnet new globaljson --sdk-version <installed LTS> --roll-forward latestFeature
dotnet new buildprops       # Directory.Build.props: TargetFramework, Nullable, ImplicitUsings
dotnet new packagesprops    # Directory.Packages.props: ManagePackageVersionsCentrally=true
dotnet new editorconfig
dotnet new gitignore
```
Move `TargetFramework`, `Nullable` and `ImplicitUsings` into `Directory.Build.props` and remove them from the generated `.csproj` files so every project stays in sync. With central package management on, `dotnet add package` writes the version into `Directory.Packages.props`.

## Verify
```bash
dotnet build <solution>
dotnet test <solution>
```
Both must pass, architecture tests included.
