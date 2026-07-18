---
name: kubernetes-diagnose
description: Diagnose Kubernetes workload, Helm release, ingress, networking, storage, scheduling, image, and delivery-pipeline failures using repository configuration and live evidence when available. Use when a Kubernetes service is unhealthy, unavailable, failing rollout, or behaving differently from its declared configuration.
---

# Kubernetes Diagnose

Start read-only. Establish the affected cluster, namespace, workload, release, time window, expected behavior, and recent change when they are not already known.

## Investigate

1. Inspect repository manifests, Helm values, deployment workflows, and applicable AGENTS.md files.
2. Gather the smallest useful live evidence: workload and pod status, events, logs, rollout history, rendered release values, services, endpoints, ingress, policies, volumes, and node scheduling data as relevant.
3. Trace the failure from the user-visible symptom through routing, workload, dependencies, and infrastructure. Distinguish configuration evidence from inference.
4. Compare declared, rendered, and live state. Account for GitOps or pipeline ownership before recommending direct cluster changes.
5. Identify the primary cause, contributing conditions, and evidence that rules out plausible alternatives.

Do not restart, delete, scale, patch, upgrade, or roll back resources unless the user explicitly asks for remediation and the impact is understood. Do not treat warnings or incidental drift as root causes without a demonstrated connection to the symptom.

## Report

Lead with the diagnosis and confidence. Include supporting commands and evidence, the smallest practical correction, risk and rollback considerations, and exact verification steps. State unresolved facts and the next discriminating check when the evidence is incomplete.
