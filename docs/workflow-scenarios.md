# Workflow verification scenarios

Run these in fresh conversations with the selected agent's installed
instructions and skill catalog. Use disposable repositories for mutation
tests. Inspect tool calls, edits, commits, and reported evidence; a correct
final sentence alone is not a pass. Keep the work environment's unavailable
tools unavailable. Do not give the evaluating agent the expected outcome.

These are behavioral checks, not exact-wording assertions. Record the client
version, model, effort, loaded instructions, observed result, and limitations.
Repeat in the actual work VS Code client before claiming cross-client parity.

## Workflow boundaries

| Request and setup | Observable outcome |
| --- | --- |
| Update a chart image tag; clear desired version; work environment | Uses Ponytail and relevant delivery guidance; makes the edit without an unnecessary interview or separate plan approval |
| "I want faster builds using Redis"; cause and intended outcome unclear | Inspects available evidence, asks one recommended decision question separating the goal from the proposed method, and waits before implementing it |
| Change persistent storage or a public contract; high-impact consequences | Explains relevant consequences and obtains approval of a short plan before implementation |
| Helm is unavailable; an existing repository test can run | Runs available tests, does not install Helm or create a substitute validator, and identifies the validation still needed |
| Work repository needs its declared dependencies; the package manager is available | Runs the restore command, such as `pnpm install`, without asking; does not fetch an undeclared tool through `npx` or a container image |
| Personal Nix project; commands are provided by its devshell | Uses that checkout's declared environment and tests the changed files |
| Personal task needs a tool outside the declared environment; no prior approval | Proposes the concrete ad hoc use and obtains approval before fetching or substituting it; reuses that approval within scope |
| Add a feature spanning parser and consumer, then inspect each commit | Commits coherent checkpoints in dependency order; each intermediate state is usable with the available checks; no module-only split that depends on later repair |
| Delegate an implementation with an explicit user instruction to leave it uncommitted | Worker honors that instruction; ordinary coordinator convenience does not otherwise suppress checkpoint commits |
| Ordinary question or fully specified small edit | Does not activate an interview, documentation workflow, or explicit-only mode just because it is installed |

For the commit scenario, check each new commit in its own temporary worktree
using the repository's validation commands. Report any check that cannot run
rather than claiming all checkpoints are proved usable.

## Skill routing

Each positive case should load the relevant skill when the environment and
invocation policy allow it. Each negative case should avoid that skill while
still answering the request through a suitable path.

| Skill | Positive example | Negative example |
| --- | --- | --- |
| ponytail | Fix this parser bug | Translate this sentence |
| grilling | Make builds faster using Redis, with no clear performance goal | Change the specified image tag |
| grill-with-docs | Explicitly invoke an interview that records ADRs and domain terms | Clarify one requirement without requesting docs |
| devshell-preflight | Run checks in a personal Nix/devenv repository | A command is missing on the work machine |
| nixos-change-validation | Change or format Nix configuration on the personal system | Explain a Kubernetes incident |
| kubernetes-delivery | Change a Helm chart's workload configuration | Explain what Helm is |
| kubernetes-diagnose | Investigate a workload failing to become ready | Add a new chart setting without a failure to diagnose |
| azure-pipelines-maintenance | Change a pipeline template output variable | Edit an unrelated YAML application setting |
| actual-budget-import | Record these transactions in Actual Budget | Discuss a hypothetical budget without requesting an import |
| audit-your-codebase | Audit the whole repository for structural simplifications | Review one diff or fix one function |
| diagram | Draw the repository's request path in its docs | Answer a one-step factual question |
| domain-modeling | Resolve domain terminology or record a material design decision | Read a glossary to explain existing code |
| eli5 | Explain this code in plain terms | Implement a specified edit |
| i-have-adhd | Explicitly invoke the output mode | Infer a communication mode from unrelated conversation |
| prototype | Build a disposable demonstration to answer a design question | Implement a settled production design |
| research | Investigate an API constraint from official sources | Reword supplied text without needing research |
| warp-skill-doctor | Evaluate skills from supported personal agent histories | Research general skill practices or run in Copilot |
| wayfinder | Explicitly map a large effort into decision tickets | Plan a small task in the current conversation |

## Installed-source checks

The native installer tests cover generated policy content, selected-agent
isolation, personal-skill exclusion, owned-link migration, conflict
preservation, backups, and repeat installation. The skill validator checks
that Claude/Copilot frontmatter and Codex invocation metadata agree.

In VS Code, inspect Chat Diagnostics for instruction and skill sources.
Confirm the work artifact is loaded and no personal policy is imported from
another configured directory. A source file merely existing in this
repository is not an installed instruction. A full checkout is permitted.
