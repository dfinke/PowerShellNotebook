## 10/06/2020

- Invoke-ExecuteNotebook supports `-Force` to overwrite `-OutputNotebook` if it exists locally

## 10/01/2020

- Invoke-ExecuteNotebook supports the following for output paths:
    - Local file system: `c:\temp\test.ipynb`
    - GitHub gist: `gist://`
    - Azure Blob Store: `abs://`

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
- Invoke-ExecuteNotebook supports reading a notebook from a URL

```powershell
Invoke-ExecuteNotebook https://raw.githubusercontent.com/dfinke/PowerShellNotebook/master/__tests__/NotebooksForUseWithInvokeOutfile/parameters.ipynb 
```
- Plus, after reading it from a url you can save out to a `gist`

```powershell
Invoke-ExecuteNotebook https://raw.githubusercontent.com/dfinke/PowerShellNotebook/master/__tests__/NotebooksForUseWithInvokeOutfile/parameters.ipynb -OutputNotebook gist://testout.ipynb
```
### How parameters work

The parameters cell is assumed to specify default values which may be overridden by values specified at execution time.

- `Invoke-ExecuteNotebook` inserts a new cell tagged `injected-parameters` after the parameters cell
- `injected-parameters` contains only the overridden parameters
subsequent cells are treated as normal cells, even if also tagged parameters
- If no cell is tagged parameters, the `injected-parameters` cell is inserted at the top of the notebook

## 09/12/2020

- Added `-Outfile` to `Invoke-PowerShellNotebook`. It creates a new _notebook_, copies the old one, and executes each `code cell`, updating the new notebook with the results.