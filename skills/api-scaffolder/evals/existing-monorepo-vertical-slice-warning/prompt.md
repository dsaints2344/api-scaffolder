---
tags: [skill-creator]
max_turns: 60
timeout_seconds: 1800
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Add an Inventory service to this monorepo. Vertical slice with repository + unit of work, same stack as payments, Visual Studio.

Input files: Platform.slnx, global.json, Directory.Build.props, Directory.Packages.props, services/payments/scaffold.yaml, services/payments/src/Payments.Api/Payments.Api.csproj, .github/workflows/payments.yml, deploy/docker-compose.yml
