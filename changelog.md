## JO'N Sept 29 2020
- Get-NotebookContent
    - parameter changes: gave `JustCode` an alias of `NoMarkdown` and `JustMarkdown` an alias of `NoCode` made them mutually exclusive. Added switch  `IncludeOutput`
    - `IncludeOutput` tries to return either the _stream_ output from Jupyter or the _data::Text/plain_ output from the vs code extension sensibly, and will also return _data::Text/html_ output / make reasonable sense of mixed outputs.
- ConvertFrom-NotebookToMarkdown
    - parameter changes: gave `NoteBookName` an alias of `Path`, added `Destination` - defaulting to current dir,  and switch `IncludeOutput`
    - `IncludeOutput` is passed to `Get-NotebookContent`. If `Get-NotebookContent `returns output and it is a string we'll output it as preformatted block of markdown. If it is a single block of HTML we'll output that to into the MD.
    - If `destination` is a directory, use the source filename converted from .ipynb to .md, otherwise treat destination  as a file name. At the end, output the file object, not the name
- DSL/Add-NotebookCode
    - Gave function an **experimental** alias of `code`
    - parameter chanages: `-code` is now mandatory, also support non text-stream output through `-Displaydata`, allow the GUID for Azure data studio to be disabled with `-NoGUID`.
    - Add support for _magic commands_ - `about` and `time`, remove `pwsh` if present.
    - Ensure code isn't run if `DisplayData` is provided.
    - Change process for building the cell to allow `DisplayData` to work, and also to make the `azdata_cell_guid` optional
- DSL/Add-NotebookMarkdown
    - Gave function an **experimental** alias of `markdown`
- DSL New-PSNotebook
     - Gave function an **experimental** alias of `Notebook`. The aliases allow writing `notebook {code $foo; markdown $bar} file.ipynb`
     - parameter chanages: added `Runspace` and switch `DotNetInteractive` (alias DNI)
     - if `Runspace` is passed, add members needed to allow `.Invoke()` to work as it does for a created runspace.
     - Moved the template for the Azure-data-studio/Windows-PowerShell notebook to the top of the file, and created a template for a .net interactive notebook. Selection is made by presence of the `-DotNetInteractive` switch.
     - Made `asText` redundant - no output name = "as text" , and add `.ipynb` to file name if it is not present.

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