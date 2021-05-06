## 5/6/2021

- Added `Cell` number to ouput of `Get-NotebookContent`

```
Cell NoteBookName             Type     IsParameterCell Language                      Source
---- ------------             ----     --------------- --------                      ------
   1 UsedForCellNumbers.ipynb markdown           False C# (.NET Interactive)         ---…
   2 UsedForCellNumbers.ipynb code               False PowerShell (.NET Interactive) 'hello world'
   3 UsedForCellNumbers.ipynb markdown           False C# (.NET Interactive)         ---…
   4 UsedForCellNumbers.ipynb code               False PowerShell (.NET Interactive) 'hello world, again'
```

## 3/18/2021

- `Invoke-ExecuteNotebook` executes a notebook, headless. Using the `-DotNetInteractive` switch, add the correct metadata so the notebook works in VS Code with the .NET Notebook extension

```powershell
Invoke-ExecuteNotebook -InputNotebook .\PSInteractive.ipynb -OutputNotebook .\PSInteractiveOut.ipynb -Parameters @{max=15} -DotNetInteractive
```

## 3/07/2021

- Added support for .NET interactive notebooks, PowerShell, C#, F#, and SQL

![](/media/EnableLanguageForDSL.png)

## 2/25/2021

- Added `IsParameterCell` property to `Get-NotebookContent`. Shows what cell, if any, is a parameter cell

![](/media/IsParameterCell.png)

## 10/29/2020

- Refactored new functions to separate files
- Added short animation on parameterized a notebook using Azure Data Studio
- Added `Test-HasParameterizedCell`
- Added alias `xnb` for `Invoke-ExecuteNotebook`
- `Invoke-ExecuteNotebook` now has `Write-Progress`, percent done is based on each cell executed
- Added -ReturnAdObjects to `Invoke-ExecuteNotebook`. By default `Invoke-ExecuteNotebook` returns a string.

```powershell
Invoke-ExecuteNotebook -InputNotebook .\basic.ipynb -ReturnAdObjects
```


## 10/21/2020

- Added `Export-AsPowerShellNotebook` super useful for things like converting your PowerShell history into an interactive notebook.

You need to `Install-Module -Name Microsoft.PowerShell.ConsoleGuiTools`

```powershell
Get-History | % command* | Out-ConsoleGridView | Export-AsPowerShellNotebook -OutputNotebook .\temp\testthis.ipynb
```

- Added better handling of parameters to be injected into the notebook.
- This will inject the variable `$arr = 1, 2, 3` as the first cell in the notebook .\basic.ipynb and then execute all the cells in the notebook and output them to `stdout`.


```powershell
$params = @{
    arr = 1, 2, 3
}

Invoke-ExecuteNotebook -InputNotebook .\basic.ipynb -Parameters $params
```

## 10/17/2020

- Added features to `ConvertTo-PowerShellNotebook`
    - Pipe files to the function
    - Handles URLs with PowerShell files as endpoints
    - Handles any mix of Files and URLs for conversion    

## 10/15/2020

- Added `-PassThru` to `Get-NotebookContent` to get back all cell types beyond markdown and 
    - This enables extracting output types like display_data for things like JavaScript which can be saved to an `.html` file and then displayed in browser

- Added `Get-NotebookDisplayData`. Gets only cells with `display_data` for `output_type`. Helper function using the above function `Get-NotebookContent`.

## 10/14/2020

- `ConvertTo-PowerShellNoteBook` now supports reading a `.ps1` from a URL

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