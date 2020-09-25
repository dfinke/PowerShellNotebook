. $PSScriptRoot\ConvertFromNotebookToMarkdown.ps1
. $PSScriptRoot\ConvertMarkdownToNoteBook.ps1
. $PSScriptRoot\ConvertToPowerShellNoteBook.ps1
. $PSScriptRoot\ExportNotebookToPowerShellScript.ps1
. $PSScriptRoot\GetNotebook.ps1
. $PSScriptRoot\GetNotebookContent.ps1
. $PSScriptRoot\InvokePowerShellNotebook.ps1
. $PSScriptRoot\PowerShellNotebookDSL.ps1
. $PSScriptRoot\ConvertToSQLNoteBook.ps1
. $PSScriptRoot\ExportNotebookToSqlScript.ps1


function New-GistNotebook {
    param(
        [Parameter(Mandatory)]
        $contents,
        [Parameter(Mandatory)]
        $fileName,
        $gistDescription = "PowerShell Notebook"
    )

    $header = @{"Authorization" = "token $($env:GITHUB_TOKEN)" }

    $gist = @{
        'description' = $gistDescription
        'public'      = $false
        'files'       = @{
            "$($fileName)" = @{
                'content' = "$($contents)"
            }
        }
    }

    Invoke-RestMethod -Method Post -Uri 'https://api.github.com/gists' -Headers $Header -Body ($gist | ConvertTo-Json)
}