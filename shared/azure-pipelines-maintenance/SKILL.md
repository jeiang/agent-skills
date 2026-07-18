---
name: azure-pipelines-maintenance
description: Maintain and validate Azure Pipelines YAML, templates, variables, conditions, stages, jobs, artifacts, container builds, environments, and deployment definitions. Use when the agent needs to change or diagnose azure-pipelines.yml or repository-managed Azure DevOps pipeline templates.
---

# Azure Pipelines Maintenance

Inspect the entry pipeline, template graph, parameter and variable flow, service connections, environments, branch and path triggers, artifact contracts, deployment ownership, and applicable AGENTS.md files before editing.

## Maintain the pipeline

- Preserve template interfaces and caller compatibility unless the request explicitly changes them.
- Use compile-time parameters and runtime variables in their correct evaluation contexts.
- Keep conditions explicit about success, branch, dependency, and cancellation behavior.
- Apply least privilege to credentials, tokens, service connections, and environment access. Never print secret values.
- Prefer existing task and template patterns over new wrappers or generalized frameworks.
- Avoid unrelated formatting, comments, tests, and cleanup. Comment only non-obvious Azure evaluation or operational constraints.

## Validate

Run repository-provided YAML, template, shell, PowerShell, container, or application checks. Trace each changed parameter, output variable, dependency, artifact, and condition from producer to consumer. Where local tooling cannot compile Azure templates, state that limitation and provide the exact pipeline run or preview needed for validation.

Do not queue a pipeline or deploy automatically. Provide the exact pipeline, parameters, branch or commit, expected stages, approval points, verification checks, and rollback or redeploy path.
