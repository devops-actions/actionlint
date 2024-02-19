[![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/devops-actions/actionlint/badge)](https://api.securityscorecards.dev/projects/github.com/devops-actions/actionlint)

# actionlint
Action wrapper for [rhysd/actionlint](https://github.com/rhysd/actionlint) to make using it easier (using an action with automatic version updates instead of manual link + manual update process).

This action will run your repository through actionlint and detect common errors like:
- Calling an `output` or `needs` object that has not been defined: also prevents typos
- Run shell check on all `run` commands
- And more, check the [actionlint documentation](https://github.com/rhysd/actionlint) for more information

> [!NOTE]
> Actionlint does _not_ check for external output, like usage of ${{ input.name }} into the shell commands. The reasoning is that to be able to inject something, you need to have write access to the repo (inputs come either from workflow files or workflow_dispatch events.

> [!NOTE]
> Actionlint unfortunately does **not** support (composite) action definition files.

## Results
If there are no errors from actionlint, this action will succeed. If there are errors, this action will fail and output the errors in the logs.

If running in a Pull Request context, then the action will also annotate the **changed** files with the errors. This is useful to see what errors were introduced by the Pull Request. Note: this only works if you include the `pull-requests: write` permission in your workflow file.

## Usage:
```yaml
jobs:
  run-actionlint:
    runs-on: ubuntu-latest
    permissions:
      # needed for the checkout action
      contents: read
      # needed to annotate the files in a pull request with comments
      pull-requests: write
    steps: 
    # checkout the source code to analyze
    - uses: actions/checkout@v3 # v3

    # run the actionlinter, will fail on errors
    - uses: devops-actions/actionlint@c0ee017f8abef55d843a647cd737b87a1976eb69 #v0.1.1
```

## Usage with results file:
If you want to pick up the results file and use its contents somewhere else, then use it as follows:
```yaml
on:
  push: 

  workflow_dispatch:

permissions:
  contents: read
  pull-requests: write

jobs:
  job-1:
    runs-on: ubuntu-latest
    steps:       
    - uses: actions/checkout@v3
    - uses: devops-actions/actionlint@c0ee017f8abef55d843a647cd737b87a1976eb69 #v0.1.1
      continue-on-error: true
      id: action-lint
    
    - uses: actions/upload-artifact@v3
      with:
        name: actionlint-results
        path: ${{ steps.action-lint.outputs.results-file }}
```

# Errors

## No project was found in any parent directories
Error message: `no project was found in any parent directories of ".". check workflows directory is put correctly in your Git repository`
Solution: Add a `uses: actions/checkout@v3 # v3` to your workflow file, so the repository can be analyzed

# Configuration
If you want to hide certain warnings from shellcheck, then you can use the directives as shown in [their docs here](https://github.com/koalaman/shellcheck/wiki/Directive): 
``` shell
# shellcheck disable=code
```

In some cases the directives are not picked up (might be depending on the shell it is checking. It can then help to add the `shell: your-shell-here` specification to your workflow file. I've seen this confusion happening with PowerShell code on a Windows based runner. Shellcheck was analyzing the script of the `run` step as if it where bash. The `shell` keyword was not needed for the workflow to run, as the default shell on the Windows runner was PowerShell already. Shellcheck cannot handle that. Specifying the keyword stopped the 'errors' from being reported.
