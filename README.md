[![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/devops-actions/actionlint/badge)](https://api.securityscorecards.dev/projects/github.com/devops-actions/actionlint)

# actionlint
Action wrapper that lints your GitHub Actions workflows the easy way: one `uses:` line, with automatic and checksum-pinned version updates of the linter.

Since v2 this action runs [jdx/jactionlint](https://github.com/jdx/jactionlint), an actively maintained fork of [rhysd/actionlint](https://github.com/rhysd/actionlint). It covers the checks of actionlint and adds support for newer GitHub Actions features such as parallel steps, the `$/` self-repository `uses:` syntax and the Actions lock file. See [Coming from v1](#coming-from-v1) for what changed.

This action will run your repository through actionlint and detect common errors like:
- Calling an `output` or `needs` object that has not been defined: also prevents typos
- Run shell check on all `run` commands
- And more, check the [jactionlint documentation](https://jactionlint.jdx.dev) for more information

> [!NOTE]
> Actionlint does _not_ check for external output, like usage of ${{ input.name }} into the shell commands. The reasoning is that to be able to inject something, you need to have **write** access to the repo (inputs come either from workflow files or workflow_dispatch events).

> [!NOTE]
> Composite action definition files (`action.yml`) and `.github/dependabot.yml` are checked as well.

## How it runs
The action downloads the pinned jactionlint release binary for the runner's OS and architecture, verifies its SHA256 checksum against the value stored in [settings.json](settings.json) and runs it directly: no Docker needed. It works on Linux, macOS and Windows runners and needs `bash`, `curl` and `jq` on the runner (all present on GitHub-hosted runners).

jactionlint uses [shellcheck](https://github.com/koalaman/shellcheck) and [pyflakes](https://github.com/PyCQA/pyflakes) to check `run:` scripts when it finds them on the `PATH`, and skips those checks otherwise (the action logs a notice when a tool is missing). GitHub-hosted Ubuntu runners ship with shellcheck. Install pyflakes first (`pip install pyflakes`) if you want Python scripts checked.

## Results
If there are no errors from actionlint, this action will succeed. If there are errors, this action will fail and output the errors in the logs.

If running in a Pull Request context, then the action will also annotate the **changed** files with the errors. This is useful to see what errors were introduced by the Pull Request.

## Usage:
```yaml
jobs:
  run-actionlint:
    runs-on: ubuntu-latest
    permissions:
      # needed for the checkout action
      contents: read
    steps: 
    # checkout the source code to analyze
    - uses: actions/checkout@v4 # v4

    # run the actionlinter, will fail on errors
    - uses: devops-actions/actionlint@e7ee33fbf5aa8c9f9ee1145137f3e52e25d6a35b #v0.1.3
```

## Usage with results file:
If you want to pick up the results file and use its contents somewhere else, then use it as follows:
```yaml
on:
  push: 

  workflow_dispatch:

permissions:
  contents: read

jobs:
  job-1:
    runs-on: ubuntu-latest
    steps:       
    - uses: actions/checkout@v4

    - uses: devops-actions/actionlint@e7ee33fbf5aa8c9f9ee1145137f3e52e25d6a35b #v0.1.3
      continue-on-error: true
      id: action-lint
    
    - uses: actions/upload-artifact@v4
      with:
        name: actionlint-results
        path: ${{ steps.action-lint.outputs.results-file }}
```

## Profiles
The `profile` input selects which rules run:

| Profile | What it checks |
| --- | --- |
| `correctness` (default) | The checks of actionlint (syntax, expressions, `needs` and outputs, shellcheck and more) plus extra bug detectors |
| `default` | `correctness` plus security and policy rules, such as unpinned actions, missing `permissions`, missing timeouts and dangerous triggers |
| `pedantic` | `default` plus the noisy and opinionated rules |

``` yaml
    - uses: devops-actions/actionlint@v2
      with:
        profile: default
```

Set `profile: ''` to use the profile from a `.github/jactionlint.yaml` config file in your repository instead. See the [rule list](https://jactionlint.jdx.dev/rules) for every rule and the profile it belongs to.

## Coming from v1
v1 ran rhysd/actionlint, v2 runs jactionlint with the `correctness` profile to stay close to that behavior. Differences to expect:
- Some new findings: jactionlint has checks that actionlint does not have, and it also checks composite actions and `dependabot.yml`
- Some findings disappear: newer syntax that actionlint rejected (for example parallel steps) is accepted
- Some messages are reworded, and the label at the end of a finding in the log is the rule ID. The results file keeps the `kind` field and adds fields such as `id` (the rule ID) and `severity`
- Findings in expressions and scripts point at the exact line and column of the problem, where actionlint pointed at the `run:` key of the step
- Only workflow files directly in `.github/workflows` are checked, not those in subdirectories
- An existing `.github/actionlint.yaml` config file keeps working

The full comparison is in the [jactionlint documentation](https://jactionlint.jdx.dev/actionlint).

# Errors

## No project was found in any parent directories
Error message: `no project was found in any parent directories of ".". check workflows directory is put correctly in your Git repository`
Solution: Add a `uses: actions/checkout@v4 # v4` to your workflow file, so the repository can be analyzed

# Configuration

If you want to hide certain warnings from shellcheck, then you can use the directives as shown in [their docs here](https://github.com/koalaman/shellcheck/wiki/Directive): 
``` shell
# shellcheck disable=code
```

Another option is to pass in extra `shellcheck_opts` for the warnings you want to skip:

``` yaml
  steps:       
    - uses: actions/checkout@v4

    - uses: devops-actions/actionlint@e7ee33fbf5aa8c9f9ee1145137f3e52e25d6a35b #v0.1.3
      continue-on-error: true
      id: action-lint
      with:
        shellcheck_opts: '-e SC2129'
```

In some cases the directives are not picked up (might be depending on the shell it is checking. It can then help to add the `shell: your-shell-here` specification to your workflow file. I've seen this confusion happening with PowerShell code on a Windows based runner. Shellcheck was analyzing the script of the `run` step as if it where bash. The `shell` keyword was not needed for the workflow to run, as the default shell on the Windows runner was PowerShell already. Shellcheck cannot handle that. Specifying the keyword stopped the 'errors' from being reported.
