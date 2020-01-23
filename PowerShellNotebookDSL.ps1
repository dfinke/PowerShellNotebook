class PSNotebookRunspace {
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
    [PSNotebookRunspace]::new()
}

function Add-NotebookCode {
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

    $script:codeBlocks += [PSCustomObject][Ordered]@{
        'cell_type' = 'code'
        'source'    = $code
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
    } | ConvertTo-Json -Depth 2
}

function Add-NotebookMarkdown {
    param($markdown)

    $script:codeBlocks += [PSCustomObject][Ordered]@{
        'cell_type' = 'markdown'
        'source'    = $markdown
    } | ConvertTo-Json -Compress
}

function New-PSNotebook {
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
        #$result > $NoteBookName
        $result | Set-Content -Encoding UTF8 -Path $NoteBookName
    }

}
