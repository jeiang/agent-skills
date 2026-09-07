# Work environment

Work uses Copilot Chat in VS Code for DevSecOps tasks, including Kubernetes,
Helm, Docker, and Azure Pipelines. Use the model and effort selected in VS
Code. The environment has no Nix and many commands are unavailable.

Do not invoke `devshell-preflight`, install or download missing tools, or
create substitute scripts to work around their absence. In particular, do
not replace a missing validator with an ad hoc Python script or another
runtime. This restriction also applies to delegated agents.

Use available tools and existing repository scripts when their dependencies
are already available. A missing validation tool does not block preparation
of the requested change. Run available tests, inspect the change, and state
which checks could not run. Testing in an approved environment or the normal
pipeline can supply the remaining evidence; identify the test or command
needed. Do not claim that inspection or a different test proves the omitted
check, or report future testing as completed.

Select Kubernetes diagnosis, Kubernetes delivery, or Azure Pipelines skills
when their specific task applies. Prepare reviewable edits and testing or
deployment instructions within the requested scope. Live operations require
the user's authorization and the tools already permitted in this environment.
