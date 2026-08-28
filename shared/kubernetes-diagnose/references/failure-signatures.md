# Failure Signatures and Discriminating Checks

Each signature below has several plausible causes. The point of the table is
the *discriminating* check — the one that separates them — rather than a list
of everything worth looking at.

## Pod never starts

| Status | Likely causes | Discriminating check |
|---|---|---|
| `Pending`, no node assigned | Insufficient resources, taints, node selector or affinity, unbound PVC | `kubectl describe pod` — the scheduler writes the exact reason per node in events |
| `ImagePullBackOff` / `ErrImagePull` | Wrong tag, private registry, missing or wrong `imagePullSecrets`, rate limit | Event text distinguishes `not found` from `unauthorized` from `toomanyrequests` |
| `CreateContainerConfigError` | Missing ConfigMap or Secret, or a missing key in one | Event names the object; `kubectl get secret/configmap` confirms which |
| `CreateContainerError` | Bad command, bad mount path, read-only root conflict | Event carries the runtime's message verbatim |
| `Init:*` stuck | Init container blocked on a dependency | Logs of the *init* container: `kubectl logs <pod> -c <init>` |
| `ContainerCreating` for a long time | Volume attach or mount failing, CNI failing | Events on the pod, then on the PVC and the node |

## Pod starts then fails

| Signature | Read it as | Discriminating check |
|---|---|---|
| `CrashLoopBackOff` | The app exits or is killed repeatedly. Not a cause in itself | `kubectl logs <pod> --previous` — the current container is too young to have the error |
| Exit code 137, `OOMKilled` | Memory limit exceeded, killed hard, no graceful shutdown | `kubectl describe pod`, `lastState.terminated`; compare working set to the limit |
| Exit code 1 or 2 | Application error | Previous logs |
| Exit code 143 | SIGTERM, shut down as asked | Usually normal during a rollout |
| Restarts climbing, never `Ready` | Liveness probe failing while the app works | Probe config against actual startup time; consider a startup probe |
| Running but `0/1 Ready` | Readiness probe failing | Probe endpoint from inside the pod, then Service endpoints |

## Traffic does not arrive

Trace it in this order; stop at the first empty result, because everything
downstream is a consequence.

1. `kubectl get endpoints <svc>` — empty means no pod is Ready, or the Service
   selector matches nothing. This is the single most informative check for
   "service is down" and it is skipped most often.
2. Service selector against actual pod labels.
3. `targetPort` against the container's real listening port, and the container
   listening on `0.0.0.0` rather than `127.0.0.1`.
4. Ingress class, host, path, and TLS secret; then the controller's own logs.
5. NetworkPolicy: a default-deny in the namespace blocks traffic that every
   other layer says should work, and it produces no event anywhere.

## Rollout stuck

- `ProgressDeadlineExceeded` after ~10 minutes means new pods never became
  available. The Deployment does not roll back by itself.
- New ReplicaSet at 0 available with old one still serving: the new pods are
  failing readiness. Diagnose the new pods, not the Deployment.
- Nothing happening at all: check `spec.paused`, and check whether a PDB or
  node pressure is blocking eviction of the old pods.
- StatefulSet rollouts stop at the first unhealthy ordinal and wait
  indefinitely. Under `OnDelete`, they wait for you.

## Declared, rendered, live

Three states can disagree, and naming which pair disagrees identifies the
owner of the problem:

- **Declared ≠ rendered** — chart logic, values precedence, missing `--set`.
  Reproduce with `helm template` using the same values.
- **Rendered ≠ live** — the release never applied, an admission webhook
  mutated it, or another controller owns the field. `helm get manifest`
  against `kubectl get -o yaml`.
- **Live ≠ expected, and live matches the chart** — the configuration is doing
  what it says. The bug is in the declared intent.

Under GitOps, a live-only fix is reverted at the next reconcile. Establish who
owns the object before recommending a direct cluster change.

## Evidence discipline

`kubectl describe` events are namespaced and expire (default about an hour) —
absence of an event is not absence of the problem. Prefer
`kubectl get events --sort-by=.lastTimestamp` for ordering, and capture logs
before restarting anything, because a restart destroys `--previous`.

Warnings are not root causes. `FailedScheduling` that resolved thirty minutes
before the symptom began is noise. Tie every finding to the symptom's timeline
or drop it.
