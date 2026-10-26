#!/usr/bin/env bash
# detect_repo.sh — report what the api-scaffolder skill needs to know about a target directory.
# Usage: bash detect_repo.sh [target-dir]   (default: current directory)
# Read-only. Compatible with the bash 3.2 that ships with macOS.

TARGET="${1:-.}"

section() { printf '\n## %s\n' "$1"; }
has() { command -v "$1" >/dev/null 2>&1; }

# find, skipping heavy or generated folders
findq() {
  find "$TARGET" -maxdepth "$1" \
    \( -name node_modules -o -name .git -o -name bin -o -name obj -o -name dist \
       -o -name build -o -name target -o -name .venv -o -name .idea -o -name .vs \) -prune \
    -o "${@:2}" -print 2>/dev/null
}

if [ ! -d "$TARGET" ]; then
  echo "target: $TARGET (does not exist; it will be created)"
  echo "state: new"
  exit 0
fi

TARGET="$(cd "$TARGET" && pwd)"
echo "target: $TARGET"

if [ -z "$(ls -A "$TARGET" 2>/dev/null)" ]; then
  echo "state: empty"
else
  echo "state: not empty"
fi

if has git && git -C "$TARGET" rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "git root: $(git -C "$TARGET" rev-parse --show-toplevel)"
else
  echo "git root: none"
fi

section "Repo markers (root)"
found=0
for f in global.json Directory.Build.props Directory.Packages.props nx.json turbo.json \
         pnpm-workspace.yaml lerna.json nest-cli.json settings.gradle settings.gradle.kts \
         pom.xml go.work go.mod pyproject.toml package.json .editorconfig; do
  if [ -f "$TARGET/$f" ]; then
    echo "- $f"
    found=1
  fi
done
for f in "$TARGET"/*.sln "$TARGET"/*.slnx "$TARGET"/*.code-workspace; do
  [ -f "$f" ] && { echo "- $(basename "$f")"; found=1; }
done
[ "$found" -eq 0 ] && echo "- none"

section "Monorepo signals"
signals=0
if [ -f "$TARGET/package.json" ] && grep -q '"workspaces"' "$TARGET/package.json"; then
  echo "- npm/yarn workspaces in package.json"; signals=1
fi
[ -f "$TARGET/pnpm-workspace.yaml" ] && { echo "- pnpm workspace"; signals=1; }
[ -f "$TARGET/turbo.json" ] && { echo "- Turborepo"; signals=1; }
[ -f "$TARGET/nx.json" ] && { echo "- Nx"; signals=1; }
if [ -f "$TARGET/nest-cli.json" ] && grep -q '"monorepo"[[:space:]]*:[[:space:]]*true' "$TARGET/nest-cli.json"; then
  echo "- NestJS monorepo mode"; signals=1
fi
[ -f "$TARGET/go.work" ] && { echo "- Go workspace (go.work)"; signals=1; }
if [ -f "$TARGET/pyproject.toml" ] && grep -q 'tool.uv.workspace' "$TARGET/pyproject.toml"; then
  echo "- uv workspace"; signals=1
fi
if [ -f "$TARGET/pom.xml" ] && grep -q '<modules>' "$TARGET/pom.xml"; then
  echo "- Maven multi-module"; signals=1
fi
for f in settings.gradle settings.gradle.kts; do
  if [ -f "$TARGET/$f" ] && grep -q 'include' "$TARGET/$f"; then
    echo "- Gradle multi-project ($f)"; signals=1
  fi
done
if [ -f "$TARGET/Directory.Packages.props" ]; then
  echo "- .NET central package management"; signals=1
fi
csproj_count=$(findq 6 -name '*.csproj' | wc -l | tr -d ' ')
root_sln=0
for f in "$TARGET"/*.sln "$TARGET"/*.slnx; do [ -f "$f" ] && root_sln=1; done
if [ "$csproj_count" -gt 0 ]; then
  echo "- .NET projects: $csproj_count"
  # Project count and a root solution alone don't prove a monorepo: one Clean
  # service already has ~7 projects in one solution. Report them as context only.
  [ "$root_sln" -eq 1 ] && echo "- root solution present (context only; one service also has one)"
fi
for d in services apps; do
  if [ -d "$TARGET/$d" ] && [ -n "$(ls -A "$TARGET/$d" 2>/dev/null)" ]; then
    echo "- $d/ folder with entries"; signals=1
  fi
done
[ "$signals" -eq 0 ] && echo "- none"

# A parent folder holding several independent git repos is not a monorepo.
nested_repos=$(find "$TARGET" -mindepth 2 -maxdepth 2 -name .git 2>/dev/null | wc -l | tr -d ' ')
if [ ! -d "$TARGET/.git" ] && [ "$nested_repos" -gt 1 ]; then
  echo "verdict: folder of $nested_repos separate repos, not a monorepo (ask which repo to use, or create a new folder here)"
elif [ "$signals" -eq 1 ]; then
  echo "verdict: existing monorepo (follow its conventions; additive changes only)"
elif [ "$(ls -A "$TARGET" 2>/dev/null)" ]; then
  echo "verdict: not a monorepo (an existing single project or loose files; confirm the target with the user)"
else
  echo "verdict: empty (new repo)"
fi

section "Service and library folders"
any=0
for d in services apps src packages libs building-blocks modules gateways; do
  if [ -d "$TARGET/$d" ]; then
    any=1
    children=$(ls -1 "$TARGET/$d" 2>/dev/null | head -20 | tr '\n' ' ')
    echo "- $d/: ${children:-(empty)}"
  fi
done
[ "$any" -eq 0 ] && echo "- none"

if [ "$csproj_count" -gt 0 ]; then
  section ".NET projects (first 15)"
  findq 6 -name '*.csproj' | head -15 | sed "s|^$TARGET/|- |"
fi

section "Earlier scaffold.yaml files"
sy=$(findq 5 -name scaffold.yaml)
if [ -n "$sy" ]; then
  echo "$sy" | while read -r f; do
    echo "### ${f#$TARGET/}"
    sed 's/^/    /' "$f"
  done
else
  echo "- none"
fi

section "CI and containers"
ci=0
[ -d "$TARGET/.github/workflows" ] && { echo "- GitHub Actions: $(ls -1 "$TARGET/.github/workflows" | tr '\n' ' ')"; ci=1; }
for f in "$TARGET"/azure-pipelines*.yml "$TARGET"/.azure-pipelines/*.yml "$TARGET"/azure-pipelines/*.yml; do
  [ -f "$f" ] && { echo "- Azure Pipelines: ${f#$TARGET/}"; ci=1; }
done
[ -f "$TARGET/.gitlab-ci.yml" ] && { echo "- GitLab CI"; ci=1; }
for f in docker-compose.yml docker-compose.yaml compose.yml compose.yaml \
         deploy/docker-compose.yml deploy/compose.yml; do
  [ -f "$TARGET/$f" ] && { echo "- compose: $f"; ci=1; }
done
[ "$ci" -eq 0 ] && echo "- none"

section "Toolchains"
has dotnet  && echo "- dotnet SDKs: $(dotnet --list-sdks 2>/dev/null | awk '{print $1}' | tr '\n' ' ')"
has dotnet  && dotnet ef --version >/dev/null 2>&1 && echo "- dotnet-ef: installed"
has node    && echo "- node: $(node --version 2>/dev/null)"
has pnpm    && echo "- pnpm: $(pnpm --version 2>/dev/null)"
has npm     && echo "- npm: $(npm --version 2>/dev/null)"
has yarn    && echo "- yarn: $(yarn --version 2>/dev/null)"
has java    && echo "- java: $(java -version 2>&1 | grep -i 'version' | head -1)"
has gradle  && echo "- gradle: installed"
has mvn     && echo "- maven: installed"
has go      && echo "- go: $(go version 2>/dev/null | awk '{print $3}')"
has python3 && echo "- python3: $(python3 --version 2>/dev/null | awk '{print $2}')"
has uv      && echo "- uv: $(uv --version 2>/dev/null | awk '{print $2}')"
has docker  && echo "- docker: $(docker --version 2>/dev/null)"
true
