# actionlint
Action wrapper for [rhysd/actionlint](https://github.com/rhysd/actionlint) to make using it easier.

This action will run your repository through actionlint and detect common errors like:
- Calling an `output` or `needs` object that has not been defined
- Run shell check on all `run` commands
- And more, check the [actionlint documentation](https://github.com/rhysd/actionlint) for more information

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
    - uses: devops-actions/actionlint@v0.1.0 
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
    - uses: devops-actions/actionlint@v0.1.0
      continue-on-error: true
      id: action-lint
    
    - uses: actions/upload-artifact@v3
      with:
        name: actionlint-results
        path: ${{ steps.action-lint.outputs.results-file }}
```

# Errors

## No projec was found in any parent directories
Error message: `no project was found in any parent directories of ".". check workflows directory is put correctly in your Git repository`
Solution: Add a `uses: actions/checkout@v3 # v3` to your workflow file, so the repository can be analyzed


