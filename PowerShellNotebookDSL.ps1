class PSNotebookRunspace {
    <#
        .SYNOPSIS

        .Example
    #>
    $Runspace
    $PowerShell
    [Boolean]$ReturnAsObjects

    PSNotebookRunspace() {
        $this.Runspace = [runspacefactory]::CreateRunspace()
        $this.PowerShell = [powershell]::Create()
        $this.PowerShell.runspace = $this.Runspace
        $this.Runspace.Open()
    }

    [object]Invoke($code) {
        $this.PowerShell.AddScript(($code -join "`r`n"))
        if (!$this.ReturnAsObjects) {
            $null = $this.PowerShell.AddCommand("Out-String")
        }
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
    param(
        [Switch]$ReturnAsObjects
    )

    $obj = [PSNotebookRunspace]::new()
    $obj.ReturnAsObjects = $ReturnAsObjects

    $obj
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
        $outputText = "",
        [ValidateSet('PowerShell', 'SQL', 'F#', 'C#')]
        $language
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

    # $script:codeBlocks += [PSCustomObject][Ordered]@{
    #     'cell_type' = 'code'
    #     'source'    = @($code)
    #     'metadata'  = @{
    #         'azdata_cell_guid' = '{0}' -f (New-Guid).Guid
    #     }
    #     'outputs'   = @(
    #         @{
    #             "output_type" = "stream"
    #             "name"        = "stdout"
    #             "text"        = $outputText
    #         }
    #     )
    # } | ConvertTo-Json -Depth 2

    $targetCodeBlock += [PSCustomObject][Ordered]@{
        'cell_type' = 'code'
        'source'    = @($code)
        'metadata'  = @{
            'azdata_cell_guid' = '{0}' -f (New-Guid).Guid
        }
        'outputs'   = @(
            @{
                "output_type" = "stream"
                "name"        = "stdout"
                "text"        = $outputText
            }
        )
    }

    switch ($language) {
        'PowerShell' { $targetCodeBlock.metadata.'dotnet_interactive' = @{language = 'pwsh' } }
        'C#' { $targetCodeBlock.metadata.'dotnet_interactive' = @{language = 'csharp' } }
        'F#' { $targetCodeBlock.metadata.'dotnet_interactive' = @{language = 'fsharp' } }
        'SQL' { $targetCodeBlock.metadata.'dotnet_interactive' = @{language = 'sql' } }
        default {}
    }
    
    $script:codeBlocks += $targetCodeBlock | ConvertTo-Json -Depth 2
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
        [Switch]$IncludeCodeResults
    )

    $script:codeBlocks = @()
    if ($IncludeCodeResults) {
        $Script:IncludeCodeResults = $IncludeCodeResults
        $Script:PSNotebookRunspace = New-PSNotebookRunspace
    }

    &$sb

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
function New-SQLNotebook {
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
        [Switch]$IncludeCodeResults
    )

    $script:codeBlocks = @()
    if ($IncludeCodeResults) {
        $Script:IncludeCodeResults = $IncludeCodeResults
        $Script:PSNotebookRunspace = New-PSNotebookRunspace
    }

    &$sb

    $result = @"
{
    "metadata": {
        "kernelspec": {
            "name": "sql",
            "display_name": "SQL"
        },
        "language_info": {
            "name": "sql",
            "codemirror_mode": "shell",
            "mimetype": "text/x-sh",
            "file_extension": ".sql"
        }
    },
    "nbformat_minor": 2,
    "nbformat": 4,
    "cells": [
        $($script:codeBlocks -join ',')
    ]
}
"@

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
