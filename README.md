# actionlint
Action wrapper for [rhysd/actionlint](https://github.com/rhysd/actionlint) to make using it easier.

This action will run your repository through actionlint and detect common errors like:
- Calling an `output` or `needs` object that has not been defined
- Run shell check on all `run` commands
- And more, check the [actionlint documentation](https://github.com/rhysd/actionlint) for more information

## Results
If there are no errors from actionlint, this action will succeed. If there are errors, this action will fail and output the errors in the logs.

If running in a Pull Request context, then the action will also annotate the **changed** files with the errors. This is useful to see what errors were introduced by the Pull Request.

## Usage:
```yaml
  steps: 
  # checkout the source code to analyze
  - uses: actions/checkout@v3 # v3

  # run the actionlinter
  - uses: devops-actions/actionlint@main # vx
```

# Errors

## No projec was found in any parent directories
Error message: `no project was found in any parent directories of ".". check workflows directory is put correctly in your Git repository`
Solution: Add a `uses: actions/checkout@v3 # v3` to your workflow file, so the repository can be analyzed