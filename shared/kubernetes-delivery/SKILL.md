---
name: kubernetes-delivery
description: Prepare and validate repository-managed Kubernetes delivery changes involving Helm charts, manifests, container images, GitHub Actions, Azure Pipelines, deployment configuration, or rollout instructions. Use when the agent needs to modify Kubernetes delivery files and provide exact deployment and post-deployment verification commands without performing the live deployment.
---

# Kubernetes Delivery

Read `references/immutability-and-rollout.md` before changing a selector, a volume, an image reference, or anything a running object already owns. It lists what cannot change in place and what that costs.

Inspect applicable AGENTS.md files, repository conventions, chart structure, deployment workflows, image provenance, and existing validation commands before editing.

## Prepare the change

- Keep the change consistent with the repository's ownership, naming, namespace, values, secret-management, and image-tagging patterns.
- Prefer native Helm and Kubernetes mechanisms over custom wrappers.
- Preserve immutable selectors, stateful workload strategy, storage ownership, security context, and upgrade compatibility unless the request explicitly changes them.
- Update deployment workflows and operator documentation only when required by the requested behavior.
- Add tests only when they give useful evidence for the changed behavior. Use existing test conventions and tools. Avoid new wrappers, abstractions, and comments that do not explain a relevant constraint.

## Validate

Use the repository's commands first. When applicable, run focused checks such as:

- `helm lint` for each changed chart
- `helm template` with representative values and the intended namespace
- schema, YAML, Kustomize, policy, or container build checks already provided by the repository
- `git diff --check`

Follow the installed environment policy. Do not install missing tools or create substitute validators on the work machine. Continue preparing the change with available tests and inspection, and identify the normal testing or pipeline step needed for any remaining check. Do not claim cluster validation from local rendering or claim that future testing has run. Report missing tooling or credentials precisely.

## Hand off deployment

Do not deploy, dispatch a pipeline, or mutate a cluster. Provide exact commands or UI actions for the selected environment, followed by concrete verification commands for rollout status, workload image and revision, pods, events, services or ingress, storage, and application health as relevant. Include rollback commands when the repository defines a supported rollback path.
