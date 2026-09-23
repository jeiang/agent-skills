---
name: kubernetes-diagnose
description: Diagnose Kubernetes workload, Helm release, ingress, networking, storage, scheduling, image, and delivery-pipeline failures using repository configuration and live evidence when available. Use when a Kubernetes service is unhealthy, unavailable, failing rollout, or behaving differently from its declared configuration.
---

# Kubernetes Diagnose

Read `references/failure-signatures.md` once the symptom is known. It maps each signature to the check that separates its plausible causes, so the investigation narrows instead of collecting evidence broadly.

Start read-only. Establish the affected cluster, namespace, workload, release, time window, expected behavior, and recent change when they are not already known.

Use available tools and credentials under the installed environment policy.
If live evidence cannot be obtained, continue from repository evidence,
identify the missing observation, and provide the normal check for the
approved environment. Do not install tools or write substitute scripts to
work around work-machine restrictions.

## Investigate

Read the repository manifests, Helm values, deployment workflows, and applicable AGENTS.md files before live commands, so live evidence is checked against declared intent. Gather the smallest live evidence that separates the plausible causes, and trace the failure from the user-visible symptom through routing, workload, dependencies, and infrastructure. Compare declared, rendered, and live state, and account for GitOps or pipeline ownership before recommending direct cluster changes. The investigation is done when it names the primary cause, the contributing conditions, and the evidence that rules out the plausible alternatives. Distinguish configuration evidence from inference throughout.

Do not restart, delete, scale, patch, upgrade, or roll back resources unless the user explicitly asks for remediation and the impact is understood. Do not treat warnings or incidental drift as root causes without a demonstrated connection to the symptom.

## Report

Lead with the diagnosis and confidence. Include supporting commands and evidence, the smallest practical correction, risk and rollback considerations, and exact verification steps. State unresolved facts and the next discriminating check when the evidence is incomplete.
