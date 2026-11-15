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
| Personal task needs a tool outside the declared environment | Uses it through temporary Nix tooling such as `nix shell` without asking; never installs it permanently; adds it to the devshell when the repository will reuse it often; reports each ad hoc tool and its purpose afterward |
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
| ponytail | Switch to ponytail ultra | Fix this parser bug (the rules are already in the instructions) |
| grilling | Make builds faster using Redis, with no clear performance goal | Change the specified image tag |
| devshell-preflight | Run checks in a personal Nix/devenv repository | A command is missing on the work machine |
| nixos-change-validation | Change or format Nix configuration on the personal system | Explain a Kubernetes incident |
| kubernetes-delivery | Change a Helm chart's workload configuration | Explain what Helm is |
| kubernetes-diagnose | Investigate a workload failing to become ready | Add a new chart setting without a failure to diagnose |
| azure-pipelines-maintenance | Change a pipeline template output variable | Edit an unrelated YAML application setting |
| audit-your-codebase | Audit the whole repository for structural simplifications | Review one diff or fix one function |
| diagnosing-bugs | The app crashes on launch and the cause is unknown | Fix a typo the user pointed at |
| diagram | Draw the repository's request path in its docs | Answer a one-step factual question |
| domain-modeling | Resolve domain terminology or record a material design decision | Read a glossary to explain existing code |
| eli5 | Explain this code in plain terms | Implement a specified edit |
| frontend-design | Redesign this landing page so it does not look templated | Fix a CSS overflow bug |
| gha-security-review | Audit this repository's release workflows before making it public | Fix a failing build step |
| i-have-adhd | Explicitly invoke the output mode | Infer a communication mode from unrelated conversation |
| iterate-pr | The pull request's CI is red; fix it until the checks pass | Open a pull request for finished work |
| modern-web-guidance | Add a modal dialog or a responsive layout to a web page | Change an API route, a build config, or a native app |
| prototype | Build a disposable demonstration to answer a design question | Implement a settled production design |
| research | Investigate an API constraint from official sources | Reword supplied text without needing research |
| swift-concurrency | Fix a Swift 6 data-race diagnostic | Lay out a SwiftUI view |
| swiftui-pro | Review this SwiftUI screen | Write a UIKit-free Swift package algorithm |
| tigerstyle | Add the TigerStyle guide to this repository | Format a Zig file |
| warp-skill-doctor | Evaluate skills from supported personal agent histories | Research general skill practices or run in Copilot |
| untangle-codebase | Explicitly refactor the whole codebase until changes land in one place | Refactor one module or review a diff |
| wayfinder | Explicitly map a large effort into decision tickets | Plan a small task in the current conversation |
| wizard | Walk me through creating the App Store Connect key and CI secrets | Set a secret the agent can already read from the environment |
| writing-for-agents | Tighten this skill's description and steps | Write a README for people |
| zig | Port this build.zig to Zig 0.17 | Edit a Rust crate in the same repository |

## Installed-source checks

The native installer tests cover generated policy content, selected-agent
isolation, personal-skill exclusion, owned-link migration, conflict
preservation, backups, and repeat installation. The skill validator checks
that Claude/Copilot frontmatter and Codex invocation metadata agree.

In VS Code, inspect Chat Diagnostics for instruction and skill sources.
Confirm the work artifact is loaded and no personal policy is imported from
another configured directory. A source file merely existing in this
repository is not an installed instruction. A full checkout is permitted.
