function ConvertFrom-NotebookToMarkdown {
    <#
        .SYNOPSIS
        Take an exiting PowerShell Notebook and convert it to markdown
    #>
    param(
        [Parameter(Mandatory,Position=0)]
        [Alias('NotebookName','NoteBookFullName','Fullname')]
        $Path,
        $Destination   = $pwd,
        [Switch]$AsText,
        [Switch]$Includeoutput
    )

    $NotebookProperties = Get-Notebook $Path
    $text = $(
        switch (Get-NotebookContent -Path $Path -Includeoutput:$Includeoutput) {
            { $_.Type -eq 'markdown' } { $_.Source }
            { $_.Type -eq 'code'     } {
                #if present Convert .NetInteractive magic commands into "linguist" Names by github to the render code in markup
                switch -Regex ($_.source) {
                    '^#!csharp|^#!c#'       {$format = 'C#'}
                    '^#!fsharp|^#!f#'       {$format = 'F#'}
                    '^#!pwsh|^#!PowerShell' {$format = 'PowerShell'}
                    '^#!js|^#!JavaScript'   {$format = 'JavaScript'}
                    '^#!html'               {$format = 'html'}
                    '^#!markdown'           {$format = 'MarkDown'}
                    default                 {$format = $NotebookProperties.FormatStyle}
                }
                '```'+ $format + "`n" + $_.Source + "`n" + '```' + "`n"
                #There will only be output if we specified the -IncludeOutput and we will ignore output which isn't a string or a single HTML block.
                if ($_.Output -is [string]) {
                    '```' + "`n" + $_.Output.trim() + "`n" + '```' + "`n"
                }
                elseif ($_.output.count -eq 1 -and $_.output.'text/html') {$_.output.'text/html' + "`n"}
            }
        }
    )

    if ($AsText) { return $text }

    if (Test-Path -PathType Container -Path $Destination) {
        $Destination = join-path $Destination -ChildPath( (Split-Path -Leaf $Path) -replace 'ipynb$', 'md')
    }
    $text | Set-Content -Encoding UTF8 $Destination

    Get-Item  -Path $Destination
}