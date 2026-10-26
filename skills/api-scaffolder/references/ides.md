# IDEs

Generate only what the chosen IDE uses, plus `.editorconfig` and a `.gitignore` that covers both the stack and the IDE. Shared run configurations are committed; personal IDE state is ignored.

## Visual Studio (Windows)
- Solution: `.slnx` when the installed SDK supports it (`dotnet new sln --format slnx` succeeds), otherwise `.sln`. In an existing repo keep its format.
- Solution folders that mirror the folders on disk (`src`, `tests`, and `services/<service>` in a monorepo), so Solution Explorer matches the file system. `dotnet sln add` does this by default.
- `Properties/launchSettings.json` in the host project with `http` and `https` profiles, plus a container profile when the service has a Dockerfile.
- In a monorepo, offer (don't add unasked) a docker-compose project for debugging several services together.
- Ignore: `.vs/`, `*.user`, `bin/`, `obj/`.

## JetBrains Rider
- Uses the same `.sln`/`.slnx` as Visual Studio.
- Shared run configurations as `.run/<Name>.run.xml`: one for the API, and in a monorepo a compound configuration that starts every service.
- Ignore `.idea/` (`.run/` sits outside it, so shared configurations stay committed).

## VS Code, Cursor and other VS Code forks
- `.vscode/extensions.json` recommending the stack's extensions (.NET: C# Dev Kit · TypeScript: ESLint, Prettier · Java: Extension Pack for Java · Go: Go · Python: Python, Ruff).
- `.vscode/launch.json` to debug the API and `.vscode/tasks.json` for build, test and watch.
- `.vscode/settings.json` only for repo-wide settings (formatter, test discovery), nothing personal.
- Monorepo: a `<repo>.code-workspace` multi-root workspace with one folder per service plus building-blocks.
- .NET: still generate the solution file, because C# Dev Kit uses it.
- Commit the files above; ignore anything else under `.vscode/`.

## IntelliJ IDEA, GoLand, PyCharm, WebStorm
- The build tool is the source of truth (Gradle/Maven, `go.mod`/`go.work`, `pyproject.toml`, `package.json`); don't generate `.idea/` project files.
- Shared run configurations in `.run/`.
- Ignore `.idea/` and `out/`.

## Neovim, Zed and others
- Rely on the build tool and the language server: generate `.editorconfig` and, for .NET, the solution file. Name the language server to use in the report.
