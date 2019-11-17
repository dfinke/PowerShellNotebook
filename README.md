# PowerShell Notebook

This module includes the function `Invoke-PowerShellNotebook` which enables you to run the *cells* inside the PowerShell notebook.

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
            Add-NotebookCode "8+12"
            Add-NotebookCode "8+3"
            Add-NotebookMarkdown @'
## Math

- show addition
- show other
'@
}

```

## Result - A PowerShell Notebook

You can do a `Get-Content c:\temp\test.ipynb`, here is the result.

```json
{
    "metadata": {
        "kernelspec": {
            "name": "powershell",
            "display_name": "PowerShell"
        },
        "language_info": {
            "name": "powershell",
            "codemirror_mode": "shell",
            "mimetype": "text/x-sh",
            "file_extension": ".ps1"
        }
    },
    "nbformat_minor": 2,
    "nbformat": 4,
    "cells": [
        {
            "cell_type": "code",
            "source": "8+12"
        },
        {
            "cell_type": "code",
            "source": "8+3"
        },
        {
            "cell_type": "markdown",
            "source": "## Math\n\n- show addition\n- show other"
        }
    ]
}
```