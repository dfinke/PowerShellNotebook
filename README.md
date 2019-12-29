# PowerShell Notebook

This module includes the function `Invoke-PowerShellNotebook` which enables you to run the *cells* inside the PowerShell notebook.

## Integration Status

[![Build Status](https://dougfinke.visualstudio.com/PowerShellNotebook/_apis/build/status/dfinke.PowerShellNotebook?branchName=master)](https://dougfinke.visualstudio.com/PowerShellNotebook/_build/latest?definitionId=22&branchName=master)

# Convert a Markdown File to a PowerShell Notebook

## Check out the [Video Here](http://bit.ly/2SylBm4)

In a nutshell.

1. Author your markdown with `Chapter Start and End`, then use fence blocks ``` to indic
1. In Azure Data Studio PowerShell console, run `Convert-MarkdownToNoteBook .\demo.md -watch`
    - When you save the file, `Convert-MarkdownToNoteBook` detects and auto converts it to a `PowerShell Notebook`
1. The converted Interactive PowerShell Notebook. *Note*: `Convert-MarkdownToNoteBook` also runs the code from the markdown file and includes the results.

![](./media/CvtFromMarkdown.png)


# A PowerShell Notebook with Cells

Below is a PowerShell Notebook with three cells, each containing a PowerShell "script".

![](./media/ADSPowerShellNoteBook.png)

Notice the second cell has the results of running `get-process | select company, name, handles -first 10`

# Automate the PowerShell Notebook

![](./media/InvokePowerShellNotebook.png)

# Bonus Points: Using the `-AsExcel` switch

`Invoke-PowerShellNotebook` sports an `AsExcel` switch. This lets you execute each cell in the PowerShell notebook and the function exports the results to a separate sheet in an Excel file.

![](./media/InvokePowerShellNotebookAsExcel.png)

You need to have the PowerShell `ImportExcel` module installed. The module is on the PowerShell Gallery, use `Install-Module ImportExcel` to install it on you machine.

# A Little Language to Create PowerShell Notebooks
## PowerShell Little Language

### Create and Save a PowerShell Notebook

You can also create PowerShell Notebooks outside if Azure Data Studio with this module. Here is an example.
It creates two code blocks and a markdown block, and saves it to a file `C:\Temp\test.ipnyb`.

```powershell
New-PSNotebook -NoteBookName c:\temp\test.ipynb {
            Add-NotebookCode '$a=8'
            Add-NotebookCode '$a+12'
            Add-NotebookCode '$a+3'
            Add-NotebookMarkdown @'
## Math

- show addition
- show other
'@
}

```

### Open the PowerShell Notebook in Azure Data Studio

You can open `c:\temp\test.ipynb` in Azure Data Studio and click `Run Cells`

![image](./media/CreateNotebookUsingTheDSL.png)

### Convert a *demo.txt* file to a PowerShell Notebook

If you've used `start-demo.ps1` to setup PowerShell demos, this function will convert that format into a PowerShell Notebook.

```powershell
ConvertTo-PowerShellNoteBook .\demo.txt .\demo.ipynb
```

Converts this to a PowerShell Notebook.

```text
# Get first 10 process
ps | select -first 10

# Get first 10 services
gsv | select -first 10

# Create a function
function SayHello($p) {"Hello $p"}

# Use the function
SayHello World
```

#### Here it is in Azure Data Studio

![](./media/ConvertedFromDemoText.png)
