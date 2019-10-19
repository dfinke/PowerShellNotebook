function Add-NotebookCode {
    param($code)

    $script:codeBlocks += [PSCustomObject][Ordered]@{
        'cell_type' = 'code'
        'source'    = $code
    } | ConvertTo-Json
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
        $nbFileName,
        [Switch]$AsText
    )

    $script:codeBlocks = @()

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

    if ($AsText) {
        return $result
    }
    else {
        $result > $nbFileName
    }

}
