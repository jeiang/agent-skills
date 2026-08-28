---
name: diagram
description: Draw a Mermaid diagram of a system, request path, lifecycle, or data model, derived from the repository and committed into its docs so it renders in GitHub, GitLab, and Azure DevOps. Use when the user asks for an architecture diagram, sequence diagram, flow chart, or to visualize, map, or draw how something works.
argument-hint: "[target or question]"
---

# Diagram

A diagram earns its place when the relationship between parts is the thing
that is hard to hold in your head. If prose or a list says it as well, write
that instead and say why.

## Derive it, do not recall it

Read the repository before drawing: manifests, charts, pipeline YAML, entry
points, route tables, client constructors, queue and topic names. Every node
and edge must come from something you actually read.

Never draw the architecture the stack implies. The value of a repository
diagram is precisely that it shows what is there rather than what should be.
If a component is inferred rather than verified, either leave it out or mark
it and say so in the surrounding text. Do not silently invent a cache, a load
balancer, or a retry that no code performs.

## Pick the type from the question

| Question | Diagram |
|---|---|
| What talks to what? | `flowchart` (`graph` for Azure DevOps) |
| What happens, in what order, on one request? | `sequenceDiagram` |
| What states can this thing be in? | `stateDiagram-v2` |
| How is the data shaped and related? | `erDiagram` |
| What runs when, across stages? | `flowchart LR` or `gitGraph` for branches |

One question per diagram. Five to fifteen nodes. Past that, split by
altitude — a context diagram whose boxes each expand into their own
diagram — rather than shrinking the text until nobody reads it.

## Draw it

- Label edges with what actually flows: protocol, payload, trigger,
  or auth mode. Bare arrows carry almost no information.
- Use `subgraph` for real boundaries — namespace, cluster, trust zone, VPC —
  not for visual tidiness. A boundary drawn where none exists misleads more
  than a missing one.
- Give nodes stable, meaningful ids so future diffs are readable. Ids are the
  diagram's API.
- Direction: `LR` for pipelines and request paths, `TB` for hierarchy and
  ownership.

Mermaid specifics worth knowing before you hit them:

- Quote any label containing `(`, `)`, `:`, `,`, `-`, or `#` — `A["auth-svc (v2)"]`.
- `end` is a parser keyword. A node id of `end` breaks the diagram; use `End`
  or a real name.
- `<br/>` is the only line break inside a label. `\n` renders literally.
  Azure DevOps wikis reject most HTML, so keep labels single-line there.
- In `sequenceDiagram`, declare `participant` explicitly to control order;
  otherwise order follows first mention.
- Comments are `%%` at line start.
- Edge labels use `-->|like this|`, and the pipes are not optional.

## Place it and verify it

Write the diagram into a Markdown file next to what it describes — the
service's own `docs/`, its README, the chart directory — inside a fenced
` ```mermaid ` block. GitHub, GitLab, and Azure DevOps wikis all render that
natively, and a diagram that lives beside its subject rots visibly instead of
silently. Do not deliver architecture documentation only as chat output.

Azure DevOps wikis support a reduced Mermaid dialect. When the diagram is
destined for one, verify against its current documented limits rather than
assuming parity: at the time of writing it requires `graph` instead of
`flowchart`, rejects most HTML tags and Font Awesome, and does not accept the
long arrow `---->`. It accepts either the ` ```mermaid ` fence or its own
`::: mermaid ... :::` container.

Include one or two sentences above the diagram stating the question it
answers, and below it the paths you derived it from, so the next reader can
check it against the code.

Confirm the diagram parses before handing it over. If a renderer is
available, render it; otherwise re-read it against the syntax rules above.
Shipping a diagram that fails to render is worse than shipping none.
