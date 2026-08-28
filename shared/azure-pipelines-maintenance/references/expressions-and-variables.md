# Expressions, Variables, and Output Variables

Verified against Microsoft's Azure Pipelines documentation (expressions and
set-variables-scripts pages, retrieved 2026-08-28). Re-check before relying on
a detail that has to be exact.

## The three syntaxes

| Syntax | Evaluated | Has access to |
|---|---|---|
| `${{ }}` | Compile time, when YAML is expanded into a plan | `parameters`, statically defined `variables` |
| `$[ ]` | Runtime | More variables. **No parameters** |
| `$(var)` | Macro, substituted before the task runs | Variables only |

The distinction is not stylistic. `${{ }}` is gone before the run starts, so it
cannot see anything a previous job produced. `$(var)` is substituted before a
task executes, so it cannot carry a value computed during that same task.

Conditional insertion (`${{ if }}`, `${{ elseif }}`, `${{ else }}`,
`${{ each }}`) is template syntax only — it works nowhere else.

Variables are always strings. Use `parameters` when you need a typed value.

## Setting an output variable

The step must have a `name`. Without one there is nothing to qualify the
variable with and it is unreachable.

```yaml
- bash: echo "##vso[task.setvariable variable=myVar;isOutput=true]someValue"
  name: setOutput
```

PowerShell is the same command through `Write-Host`:

```yaml
- powershell: Write-Host "##vso[task.setvariable variable=myVar;isOutput=true]someValue"
  name: setOutput
```

Properties: `variable` (required), `isSecret`, `isOutput`, `isReadOnly`.

## Reading it back

The syntax changes with the distance between producer and consumer. This is
the single most common source of "my output variable is empty".

| Producer → consumer | Reference |
|---|---|
| Same job, no `isOutput` | `$(myVar)` |
| Same job, with `isOutput` | `$(setOutput.myVar)` |
| Job → job, same stage | `dependencies.<job>.outputs['<step>.<var>']` |
| Job → job, across stages | `stageDependencies.<stage>.<job>.outputs['<step>.<var>']` |
| Job → stage `condition` | `dependencies.<stage>.outputs['<job>.<step>.<var>']` |

Mapping one into a later job, noting the runtime `$[ ]`:

```yaml
- job: B
  dependsOn: A
  variables:
    myVarFromJobA: $[ dependencies.A.outputs['passOutput.myOutputVar'] ]
```

## Where this goes wrong

- **`isOutput=true` is not visible in the same job under its bare name.**
  Once you add `isOutput`, `$(myVar)` stops resolving; it is
  `$(stepName.myVar)` from then on.
- **A newly set variable is not available in the task that set it.** Only in
  later steps.
- **The consumer must `dependsOn` the producer.** Output variables reach only
  the next downstream job or stage, and only across a declared dependency. If
  several stages need the value, each needs the dependency.
- **Extra whitespace around `isOutput=true` silently breaks it.**
- **Deployment jobs repeat the job name.** A stage condition reading a
  deployment job's output is
  `dependencies.build.outputs['build_job.build_job.setRunTests.runTests']` —
  `build_job` twice. With an environment resource, the second segment becomes
  `Deploy_<resourceName>` instead:
  `dependencies.build.outputs['build_job.Deploy_winVM2.setRunTests.runTests']`.
- **A matrix strategy changes the generated variable name.** Print it before
  depending on it.
- **Macro syntax cannot set an output variable's value**, because `$(var)` is
  substituted before the task runs. Use `$[ ]`.
- **Variables defined as expressions must not depend on other expression
  variables.** Evaluation order is not guaranteed. Order them by hand.

## Conditions

`condition` replaces the default `succeeded()` entirely — it does not add to
it. Any condition you write must re-state the success requirement, which is
why the documented examples are `and(succeeded(), ...)`.

- `succeeded()` on a job means all dependencies succeeded or partially
  succeeded, and is `False` when the pipeline is canceled.
- `succeededOrFailed()` is `False` on cancellation. When upstream jobs may be
  *skipped*, `not(canceled())` is usually what you meant.
- `always()` runs even when canceled.
- A skipped upstream stage is neither success nor failure. To proceed through
  one: `in(dependencies.A.result, 'Succeeded', 'SucceededWithIssues', 'Skipped')`.
- `counter()` is only valid where a variable is defined, never in a condition.

Each stage depends on the one textually before it unless `dependsOn` says
otherwise. `dependsOn: []` removes the dependency and starts the stage
immediately.

## Debugging

Dump the whole dependency context rather than guessing at the path:

```yaml
- job: B
  dependsOn: A
  variables:
    deps: $[ convertToJson(dependencies) ]
  steps:
  - powershell: Write-Host "$(deps)"
```

`- script: env` prints every variable available to a step.
