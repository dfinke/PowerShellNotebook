## 2.9.4

- Added `Get-DIBBlock` and `ConvertFrom-DIB' converts a dib to an ipynb
- Updated `Add-NotebookCode` to check `$DotNetInteractive` and gen the correct metadata
- Added `ConvertTo-Dib`. Converts an `ipynb` file to a `dib` file.

## DF 2.9.3

- Add `-DotNetInteractive` in `ConvertTo-PowerShellNoteBook`
- Add `vscode` `languageId` `dotnet-interactive.pwsh` to `New-PSNotebook`

## DF 6/12/2021

- Added
    - `New-InteractiveNotebook` - Create a new interactive notebook as a `dib` or `ipynb`, launching vscode
    - `Open-InteractiveNotebook` - Open a local notebook or from remote source

## Check out the 'How To Use' short video
[![PowerShellNotebook](http://img.youtube.com/vi/DAI77tPY-p0/1.jpg)](http://www.youtube.com/watch?v=DAI77tPY-p0 "PowerShellNotebook")

## JO'N May 2021
- Merged DF's code with my additions from late 2020 - see below ...
- Added Horizontal rules either side of output in `ConvertFrom-ipynb`
- Added `-AddLanguageLabels` to `ConvertFrom-ipynb` for polyglot notebooks in .net interactive
- Added improved html rendering for PowerShell and HTML code cells in `ConvertFrom-ipynb`
- Changed encoding in `New-PSNotebook` to UTFNoBOM, Byte order mark breaks in VS Code. Must check this is OK elsewhere

## DF 5/6/2021

- Added `Cell` number to ouput of `Get-NotebookContent`

```
Cell NoteBookName             Type     IsParameterCell Language                      Source
---- ------------             ----     --------------- --------                      ------
   1 UsedForCellNumbers.ipynb markdown           False C# (.NET Interactive)         ---…
   2 UsedForCellNumbers.ipynb code               False PowerShell (.NET Interactive) 'hello world'
   3 UsedForCellNumbers.ipynb markdown           False C# (.NET Interactive)         ---…
   4 UsedForCellNumbers.ipynb code               False PowerShell (.NET Interactive) 'hello world, again'
```

## DF 3/18/2021

- `Invoke-ExecuteNotebook` executes a notebook, headless. Using the `-DotNetInteractive` switch, add the correct metadata so the notebook works in VS Code with the .NET Notebook extension

```powershell
Invoke-ExecuteNotebook -InputNotebook .\PSInteractive.ipynb -OutputNotebook .\PSInteractiveOut.ipynb -Parameters @{max=15} -DotNetInteractive
```

## DF 3/07/2021

- Added support for .NET interactive notebooks, PowerShell, C#, F#, and SQL

![](/media/EnableLanguageForDSL.png)

## DF 2/25/2021

- Added `IsParameterCell` property to `Get-NotebookContent`. Shows what cell, if any, is a parameter cell

![](/media/IsParameterCell.png)


## JO'N Nov 20 2020
- Fixed a bug in ConvertTo-PowerShellNotebook (missing -raw)
- Fixed a bug in ConvertToPowerShellNotebookTests (test-pat with no H)
- Fixed a couple of other test issues, including skipping SQL tests if SQL server module is not present.
- Revamped New-GistNotebook - Accepts piped input. Takes -Public switch. Looks up Personal Access Token if Git is setup locally and has saved the PAT for Github in Windows Cred Manager.
- Added Set-NotebookToPS to convert a notebook from format used by the .Net Interactive add for VS code (C# notebook with #!Pwsh magic commands to turn cells into PowerShell ones. )
- Added Language and presence of parameterized cells to Get-Notebook results.
- Created a new ConvertFrom-IPYNB which incorporates the convertFrom-NotebookToMarkdown, and export-notebookToPowerShell script functionality and adds convert to html as well.
- In several places I've changed the name of "path to notebook" parameters to be `path` (with the old name and "fullname" as aliases) and added ValueFromPipelineByProperty name so items can be pipe items in, and also ensured path can be a list and contain wildcards.
- Added -Recurse to Get-Notebook.

## JO'N Oct  1 2020
- Export NotebookToPowerShellScript
    - Parameter change **BREAKING** Made IncludeTextCells a switch; added switch AsText, renamed Outpath to a more conventional Destination (keeping alias of outpath)
    - Removed different path split for URLs
    - Got date to output in local culture , and made the aligned header. (also did this for Export-NotebooktoSqlcript.)
    - Assume any type other than code will go in a comment block (i.e. if it isn't markdown, still put it in a comment if it isn't code), and insert a dummy comment between code adjacent codeblocks to prevent them merging
    - Return the file object created if there is one.
    - Added support for piping files in.
    - Fixed all the places I broke the test!
## JO'N Sept 29 2020
- Get-NotebookContent
    - parameter changes: gave `JustCode` an alias of `NoMarkdown` and `JustMarkdown` an alias of `NoCode` made them mutually exclusive. Added switch  `IncludeOutput`
    - `IncludeOutput` tries to return either the _stream_ output from Jupyter or the _data::Text/plain_ output from the vs code extension sensibly, and will also return _data::Text/html_ output / make reasonable sense of mixed outputs.
    -Also made sure that wildcards and piped input files are supported
- ConvertFrom-NotebookToMarkdown
    - parameter changes: gave `NoteBookName` an alias of `Path`, added `Destination` - defaulting to current dir,  and switch `IncludeOutput`
    - `IncludeOutput` is passed to `Get-NotebookContent`. If `Get-NotebookContent `returns output and it is a string we'll output it as preformatted block of markdown. If it is a single block of HTML we'll output that to into the MD.
    - If `destination` is a directory, use the source filename converted from .ipynb to .md, otherwise treat destination  as a file name. At the end, output the file object, not the name
- DSL/Add-NotebookCode
    - Gave function an **experimental** alias of `codecell`
    - parameter chanages: `-code` is now mandatory, also support non text-stream output through `-Displaydata`, allow the GUID for Azure data studio to be disabled with `-NoGUID`.
    - Add support for _magic commands_ - `about` and `time`, remove `pwsh` if present.
    - Ensure code isn't run if `DisplayData` is provided.
    - Change process for building the cell to allow `DisplayData` to work, and also to make the `azdata_cell_guid` optional
- DSL/Add-NotebookMarkdown
    - Gave function an **experimental** alias of `mdcell`
- DSL New-PSNotebook
     - Gave function an **experimental** alias of `PSNotebook`. The aliases allow writing `psnotebook {codecell $foo; mdcell $bar} file.ipynb`
     - parameter chanages: added `Runspace` and switches `DotNetInteractive` (alias DNI) and `SQL` to select templates **SQL IS UNTESTED**
     - if `Runspace` is passed, add members needed to allow `.Invoke()` to work as it does for a created runspace.
     - Moved the template for the Azure-data-studio/Windows-PowerShell notebook to the top of the file, and created a template for a .net interactive notebook. Selection is made by presence of the `-DotNetInteractive` switch.
     - Made `asText` redundant - no output name = "as text" , and add `.ipynb` to file name if it is not present.

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