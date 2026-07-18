---
name: kubernetes-delivery
description: Prepare and validate repository-managed Kubernetes delivery changes involving Helm charts, manifests, container images, GitHub Actions, Azure Pipelines, deployment configuration, or rollout instructions. Use when the agent needs to modify Kubernetes delivery files and provide exact deployment and post-deployment verification commands without performing the live deployment.
---

# Kubernetes Delivery

Inspect applicable AGENTS.md files, repository conventions, chart structure, deployment workflows, image provenance, and existing validation commands before editing.

## Prepare the change

- Keep the change consistent with the repository's ownership, naming, namespace, values, secret-management, and image-tagging patterns.
- Prefer native Helm and Kubernetes mechanisms over custom wrappers.
- Preserve immutable selectors, stateful workload strategy, storage ownership, security context, and upgrade compatibility unless the request explicitly changes them.
- Update deployment workflows and operator documentation only when required by the requested behavior.
- Do not add tests, helper scripts, abstractions, or comments unless the approved task requires them or a non-obvious safety constraint needs explanation.

## Validate

Use the repository's commands first. When applicable, run focused checks such as:

- `helm lint` for each changed chart
- `helm template` with representative values and the intended namespace
- schema, YAML, Kustomize, policy, or container build checks already provided by the repository
- `git diff --check`

Do not claim cluster validation from local rendering. If required tooling or credentials are unavailable, report the exact limitation.

## Hand off deployment

Do not deploy, dispatch a pipeline, or mutate a cluster. Provide exact commands or UI actions for the selected environment, followed by concrete verification commands for rollout status, workload image and revision, pods, events, services or ingress, storage, and application health as relevant. Include rollback commands when the repository defines a supported rollback path.
