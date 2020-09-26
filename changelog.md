## 09/26/2020

- Added Invoke-ExecuteNotebook lets you:

    - parameterize notebooks
    - execute notebooks

    This opens up new opportunities for how notebooks can be used. For example:

    - Perhaps you have a financial report that you wish to run with different values on the first or last day of a month or at the beginning or end of the year, using parameters makes this task easier.
    - Do you want to run a notebook and depending on its results, choose a particular notebook to run next? You can now programmatically execute a workflow without having to copy and paste from notebook to notebook manually.

    - Lets you save the execution to a new notebook using `-OutputNoteBook`
    - Lets you save the execution to a to a `GitHub gist` `-OutputNoteBook gist://test.ipynb`
        - Requires you to set `$env:GITHUB_TOKEN` to a GitHub PAT

## 09/12/2020

- Added `-Outfile` to `Invoke-PowerShellNotebook`. It creates a new _notebook_, copies the old one, and executes each `code cell`, updating the new notebook with the results.