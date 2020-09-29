function ConvertFrom-NotebookToMarkdown {
    <#
        .SYNOPSIS
        Take and exiting PowerShell Notebook and convert it to markdown
    #>
    param(
        [Parameter(Mandatory,Position=0)]
        [Alias("Path")]
        $NotebookName,
        $Destination   = $pwd,
        [Switch]$AsText,
        [Switch]$Includeoutput
    )

    $text = $(switch (Get-NotebookContent -NoteBookFullName $NotebookName -Includeoutput:$Includeoutput) {
            { $_.Type -eq 'markdown' } { $_.Source }
            { $_.Type -eq 'code' } {
                '```powershell' + "`n" + $_.Source + "`n" + '```' + "`n"
                #There will only be output if we specified the -IncludeOutput and we will ignore output which isn't a string or a single HTML block.
                if ($_.Output -is [string]) {
                    '```' + "`n" + $_.Output.trim() + "`n" + '```' + "`n"
                }
                elseif ($_.output.count -eq 1 -and $_.output.'text/html') {$_.output.'text/html' + "`n"}
            }
    })

    if ($AsText) { return $text }

    if (Test-Path -PathType Container -Path $Destination) {
        $Destination = join-path $Destination -ChildPath( (Split-Path -Leaf $NotebookName) -replace 'ipynb$', 'md')
    }
    $text | Set-Content -Encoding UTF8 $Destination

    Get-Item  -Path $Destination
}