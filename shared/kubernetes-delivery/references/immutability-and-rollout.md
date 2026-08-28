# Immutable Fields and Rollout Mechanics

What breaks when a manifest or chart change reaches a cluster that already has
the object. Items marked *(verified)* were checked against kubernetes.io on
2026-08-28; the rest are stable long-standing behavior — confirm against the
API reference for your cluster version when a detail must be exact.

## Fields you cannot change in place

An apply that touches these fails, or silently does nothing, until the object
is deleted and recreated. On a production workload that is an outage, so plan
it deliberately rather than discovering it in the pipeline.

- **`Deployment.spec.selector`** — immutable. Changing a label that feeds the
  selector means delete and recreate. This is the usual cause of
  `field is immutable` on an otherwise innocuous label refactor.
- **`StatefulSet`** — only a small set of fields updates in place
  (`.spec.replicas`, `.spec.template`, and depending on version
  `.spec.ordinals`, `.spec.updateStrategy`,
  `.spec.persistentVolumeClaimRetentionPolicy`, `.spec.minReadySeconds`).
  Everything else, including `selector`, `serviceName`, and
  `volumeClaimTemplates`, requires delete and recreate *(verified: updates
  outside the allowed set need deletion and recreation; confirm the exact
  allowed list against the API reference for your version)*.
- **`Service.spec.clusterIP`** — immutable once assigned.
- **`Job.spec.template`** and `Job.spec.selector` — immutable. A changed Job
  must be recreated, which is why Helm hooks usually carry
  `before-hook-creation` deletion policies.
- **PersistentVolumeClaim capacity** — can grow when the StorageClass sets
  `allowVolumeExpansion: true`. It cannot shrink. Some volume plugins need a
  pod restart to complete the filesystem resize.

Deleting a StatefulSet or scaling it down does **not** delete its volumes by
default *(verified)* — data safety over cleanup. `persistentVolumeClaimRetentionPolicy`
(`whenDeleted`, `whenScaled`) changes that, and turning it on is a data-loss
decision, not a tidiness one.

## Image pull policy defaults

Set when the object is **first created**, and *not* updated if the tag or
digest later changes *(verified)*. With `imagePullPolicy` omitted:

| Image reference | Default |
|---|---|
| Digest specified | `IfNotPresent` |
| Tag `:latest` | `Always` |
| No tag | `Always` |
| Any other tag | `IfNotPresent` |

The consequence: a mutable tag like `:prod` defaults to `IfNotPresent`, so
pushing a new image under the same tag does not redeploy anything, and pods
that restart may run different code from their siblings. Deploy by digest, or
by a tag that changes every build.

## Rollout

- `maxUnavailable` and `maxSurge` both default to 25%.
- `progressDeadlineSeconds` defaults to 600. Past it the Deployment reports
  `ProgressDeadlineExceeded`. It does **not** roll back on its own.
- `minReadySeconds` defaults to 0, so a pod counts as available the instant it
  is ready. Under a readiness probe that passes before the app is warm, a
  rollout can complete while every replica is still cold.
- A failed rollout leaves both ReplicaSets in place. `kubectl rollout undo`
  is the supported reversal; deleting pods is not.

## Probes

- **Readiness** failing removes the pod from Service endpoints. Traffic stops;
  the container keeps running.
- **Liveness** failing restarts the container. A liveness probe pointed at a
  dependency turns that dependency's outage into a crash loop.
- **Startup** gates the other two while it runs. Slow-booting apps need this
  rather than a long liveness `initialDelaySeconds`.

## Resources

Requests drive scheduling; limits drive enforcement. Exceeding a CPU limit
throttles the container. Exceeding a memory limit kills it — `OOMKilled`, exit
code 137, with no graceful shutdown. A pod with limits and no requests gets
requests set equal to its limits.

## Helm

- `helm template` renders locally and never contacts the cluster. The `lookup`
  function returns empty and `.Capabilities` falls back to defaults, so a
  chart whose logic depends on either renders differently than it will
  install. Local rendering is not cluster validation — never report it as
  such.
- `helm upgrade` deletes resources that the new revision no longer renders.
  A conditional that silently stops emitting a resource is a deletion.
- Helm 3 does a three-way merge, so it reconciles changes made directly to the
  cluster. Fields an admission controller or another operator owns will fight
  the chart on every upgrade.
- `--atomic` rolls back on failure and implies `--wait`. Without `--wait`,
  a successful `helm upgrade` means the API accepted the manifests, not that
  anything became ready.

## Before handing off

State which of the above the change crosses. A diff that alters a selector,
shrinks a PVC, or changes a mutable tag's meaning needs the recreate or
migration path spelled out in the deployment instructions, not discovered
during the rollout.
