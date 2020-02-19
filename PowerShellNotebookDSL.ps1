class PSNotebookRunspace {
    <#
        .SYNOPSIS

        .Example
    #>
    $Runspace
    $PowerShell

    PSNotebookRunspace() {
        $this.Runspace = [runspacefactory]::CreateRunspace()
        $this.PowerShell = [powershell]::Create()
        $this.PowerShell.runspace = $this.Runspace
        $this.Runspace.Open()
    }

    [object]Invoke($code) {
        $this.PowerShell.AddScript([scriptblock]::Create($code))
        $null = $this.PowerShell.AddCommand("Out-String")
        return $this.PowerShell.Invoke()
    }

    [void]Close() {
        $this.Runspace.Close()
    }
}

function New-PSNotebookRunspace {
    <#
        .SYNOPSIS
        New-PSNotebookRunspace instantiates the PSNotebookRunspace

        .Example
        New-PSNotebookRunspace
    #>
    [PSNotebookRunspace]::new()
}

function Add-NotebookCode {
    <#
        .SYNOPSIS
        Add-NotebookCode adds PowerShell code to a code block

        .Description
        Add-NotebookCode is intended to be used in a New-PSNotebook scriptblock

        .Example
        New-PSNotebook -AsText {
            Add-NotebookCode -code 'Hello World'
        }

        "cells": [{
            "cell_type": "code",
            "source": "Hello World",
            "metadata": {
                "azdata_cell_guid": "4c8b5648-af44-433b-8bf9-f0b6ca975b2b"
            },
            "outputs": [{
                "name": "stdout",
                "output_type": "stream",
                "text": ""
            }]
        }]

    #>
    param(
        $code,
        $outputText = ""
    )

    $pattern = "^(?i)#(\s+)?exclude(\s+)?results(?-i)"
    if ($code -match $pattern) {
        # skip including code results
        $code = $code -replace $pattern, ""
    }
    else {
        if ($script:IncludeCodeResults) {
            $outputText = $Script:PSNotebookRunspace.Invoke($code)
        }
    }

    if ($script:TargetNotebookType -eq '') {
        $codeMetadata = @{
            'azdata_cell_guid' = '{0}' -f (New-Guid).Guid
        }
    }
    else {
        $codeMetadata = New-Object PSObject
    }

    $script:codeBlocks += [PSCustomObject][Ordered]@{
        'cell_type' = 'code'
        'source'    = @($code)
        'metadata'  = $codeMetadata
        'outputs'   = @(
            @{
                "output_type" = "stream"
                "name"        = "stdout"
                "text"        = $outputText
            }
        )
    } | ConvertTo-Json
}

function Add-NotebookMarkdown {
    <#
        .SYNOPSIS
        Add-NotebookMarkdown adds Markdown to a markdown block

        .Description
        Add-NotebookMarkdown is intended to be used in a New-PSNotebook scriptblock

        .Example

        New-PSNotebook -AsText {
            Add-NotebookMarkdown -markdown "# This is a H1 tag"
        }

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
            "cells": [{
                "cell_type": "markdown",
                "source": "# This is a H1 tag"
            }]
        }
    #>
    param($markdown)

    $script:codeBlocks += [PSCustomObject][Ordered]@{
        'cell_type' = 'markdown'
        'metadata'  = [PSCustomObject]@{ }
        'source'    = @($markdown)
    } | ConvertTo-Json -Compress
}

function New-PSNotebook {
    <#
        .SYNOPSIS
        Creates a new PowerShell Notebook that can be returned as text or saves as a `ipynb` file.

        .Description
        New-PSNotebook takes a script block in which these two functions can be be use to contstruct a PowerShell Notebook `Add-NotebookMarkdown`, `Add-NotebookCode`.
        Additionally, you can use the `-IncludeCodeResults` switch to execute the PowerSHell code and include the results in the notebook.

        .Example
        # creates a new notebook, and saves it as TestNotebook.ipynb

        New-PSNotebook -NoteBookName .\TestNotebook {
            Add-NotebookMarkdown -markdown "# This is a H1 tag"
            Add-NotebookCode -code 'Hello World'
        }

        .Example
        # creates a new notebook, executes the PowerShell then includes it the block, and saves it as TestNotebook.ipynb

        New-PSNotebook -NoteBookName .\TestNotebook -IncludeCodeResults {
            Add-NotebookMarkdown -markdown "# This is a H1 tag"
            Add-NotebookCode -code 'Hello World'
        }

        .Example
        # creates a new notebook, and returns it as text

        New-PSNotebook -AsText {
            Add-NotebookMarkdown -markdown "# This is a H1 tag"
            Add-NotebookCode -code 'Hello World'
        }

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
            "cells": [{
                "cell_type": "markdown",
                "source": "# This is a H1 tag"
            }, {
                "cell_type": "code",
                "source": "Hello World",
                "metadata": {
                    "azdata_cell_guid": "a7b91b6c-f57f-4d57-8cc4-7773d7f22756"
                },
                "outputs": [{
                    "name": "stdout",
                    "output_type": "stream",
                    "text": ""
                }]
            }]
        }
    #>
    param(
        [Scriptblock]$sb,
        $NoteBookName,
        [Switch]$AsText,
        [ValidateSet('AzureDataStudio', 'Jupyter')]
        $NotebookType = 'AzureDataStudio',
        [Switch]$IncludeCodeResults
    )

    $script:TargetNotebookType = $NotebookType

    $script:codeBlocks = @()
    if ($IncludeCodeResults) {
        $Script:IncludeCodeResults = $IncludeCodeResults
        $Script:PSNotebookRunspace = New-PSNotebookRunspace
    }

    &$sb

    if ($script:TargetNotebookType -eq 'AzureDataStudio') {
        $result = @"
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
        $($script:codeBlocks -join ',')
    ]
}
"@
    }
    elseif ($script:TargetNotebookType -eq 'Jupyter') {
        $result = @"
{
    "metadata": {
        "kernelspec": {
            "display_name": ".NET (PowerShell)",
            "language": "PowerShell",
            "name": ".net-powershell"
        },
        "language_info": {
            "file_extension": ".ps1",
            "mimetype": "text/x-powershell",
            "name": "PowerShell",
            "pygments_lexer": "powershell",
            "version": "7.0"
        }
    },
    "nbformat": 4,
    "nbformat_minor": 4,
    "cells": [
        $($script:codeBlocks -join ',')
    ]
}
"@
    }

    $Script:IncludeCodeResults = $false
    if ($Script:PSNotebookRunspace) {
        $Script:PSNotebookRunspace.Close()
        $Script:PSNotebookRunspace = $null
    }

    if ($AsText) {
        return $result
    }
    else {
        $result | Set-Content -Encoding UTF8 -Path $NoteBookName
    }

}
