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
        [switch]$AsText,
        [switch]$AddLanguageLabels,
        [switch]$Includeoutput
    )

    $NotebookProperties = Get-Notebook $Path
    $text = $(
        switch (Get-NotebookContent -Path $Path -Includeoutput:$Includeoutput) {
            { $_.Type -eq 'markdown' } { $_.Source }
            { $_.Type -eq 'code'    -and $_.Source } {
                #if present Convert .NetInteractive magic commands into "linguist" Names by github to the render code in markup
                if ($_.Language) {
                    switch ($_.Language) {
                        'csharp'                   {$format = 'C#' }
                        'fsharp'                   {$format = 'F#' }
                        'html'                     {$format = 'html' }
                        'javascript'               {$format = 'JavaScript' }
                        'pwsh'                     {$format = 'PowerShell' }
                        'sql'                      {$format = 'Sql' }
                         Default                   {$format = $NotebookProperties.FormatStyle}
                    }
                    if ($AddLanguageLabels -and $_.source -notmatch "^#!($_.Language)|^#!js|^#!c#|^#!f#|^#!PowerShell") {
                        "``$($_.Language)``"
                    }
                }
                else {
                    switch -Regex ($_.source) {
                        '^#!csharp|^#!c#'          {$format = 'C#'}
                        '^#!fsharp|^#!f#'          {$format = 'F#'}
                        '^#!html'                  {$format = 'html'}
                        '^#!js|^#!JavaScript'      {$format = 'JavaScript'}
                        '^#!markdown'              {$format = 'MarkDown'}
                        '^#!pwsh|^#!PowerShell'    {$format = 'PowerShell'}
                        '^#!sql'                   {$format = 'SQL'}
                        default                    {$format = $NotebookProperties.FormatStyle}
                    }
                }
                $marker = '```'
                while ($_.Source -match $marker) {$marker += '`'}
                ($marker + $format + "`n" + $_.Source + "`n" + $marker + "`n")
                #There will only be output if we specified the -IncludeOutput and we will ignore output which isn't a string or a single HTML block.
                if     ($_.HTMLOutput)             {"----`n`n" + ($_.HTMLOutput -replace  '\s*</?html>\s*','' -replace  '[\r\n]*$',"`n") +"`n----`n"}
                elseif ($_.Output -is [string])    {"----`n" + '```' + "`n" + $_.Output.trim() + "`n" + '```' + "`n----`n"}
                elseif ($_.output.count -eq 1 -and
                        $_.output.'text/html')     {"----`n" + ($_.output.'text/html' -replace  '</?html>','') + "`n`n----`n"}
                else {"----`n`n----`n"}
            }
        }
    )

    if ($AsText) { return $text }

    if (Test-Path -PathType Container -Path $Destination) {
        $Destination = Join-Path $Destination -ChildPath( (Split-Path -Leaf $Path) -replace 'ipynb$', 'md')
    }
    $text | Set-Content -Encoding UTF8 $Destination

    Get-Item  -Path $Destination
}


function ConvertFrom-NotebookToHTML {
    <#
        .SYNOPSIS
        Take an exiting PowerShell Notebook and convert it to HTML
    #>
    param(
        [Parameter(Mandatory,Position=0)]
        [Alias('NotebookName','NoteBookFullName','Fullname')]
        $Path,
        $Destination = $pwd,
        [switch]$AsText,
        [switch]$Includeoutput,
        [switch]$AddLanguageLabels,
        [switch]$Show
    )
    process {
        $markdown = (ConvertFrom-NotebookToMarkdown -Path $Path -Includeoutput:$Includeoutput -AddLanguageLabels:$AddLanguageLabels -AsText) -join "`n"
        $matches = @() +  [regex]::Matches($markdown,'(?s)(`{3,})PowerShell\r?\n(\s*\S+.*?)\1')
        if ($matches) {
            ($matches.Count -1)..0 | ForEach-Object  {
                $match    = $matches[$_]
                $before   = $markdown.Substring(0,$match.Index)
                $after    = $markdown.Substring($match.Index + $match.Length + 1)
                $psHTML   = Convert-PSToColorizedHTML  $match.Groups[2].value
                $markdown = $before + "<div style='background-color: #E0E0E0'>" + $psHTML +  "</div>`n" + $after
            }
        }

        $matches = @() +  [regex]::Matches($markdown,'(?s)(`{3,})html\r?\n(\s*\S+.*?)\1')
        if ($matches) {
            ($matches.Count -1)..0 | ForEach-Object  {
                $match    = $matches[$_]
                $before   = $markdown.Substring(0,$match.Index-1)
                $after    = $markdown.Substring($match.Index + $match.Length + 1)
                $rawHTML  = [System.Web.HttpUtility]::HtmlEncode($match.Groups[2].value)
                $markdown = $before + "`n<div style='background-color: #E0E0E0'><code>"  + $rawHTML + "</code></div>`n"  + $after
            }
        }


        $html = '<HTML>{0}</HTML>' -f  (($markdown | ConvertFrom-Markdown).Html -join "`n")
        $html = $html -replace '(?s)<pre><code class=(.*?)</code></pre>','<div style=''background-color: #E0E0E0''><pre><code class=$1</code></pre></div>'
        $html = $html -replace '(?<!\r)\n',"`r`n"
        if ($AsText) { return $html }

        if (Test-Path -PathType Container -Path $Destination) {
            $Destination = Join-Path $Destination -ChildPath( (Split-Path -Leaf $Path) -replace 'ipynb$', 'html')
        }
        $html    |  Set-Content      $Destination
        if ($Show) {Start-Process    $Destination}
        else       {Get-Item  -Path  $Destination}
    }
}


function Convert-PSToColorizedHTML {
    <#
    .Synopsis
        Writes PowerShell as colorized HTML
    .Description
        Outputs colorized HTML using the Windows PowerShell ISE colouring for tokens.
        The script is wrapped in <PRE> tags with <SPAN> tags defining color regions.
    .Example
        Write-ColoredHTML {Get-Process}
    #>
    param(
        # The Text to colorize
        [Parameter(Mandatory=$true,Position=0,ValueFromPipeline = $true)]
        [String]$Text
    )
    begin {
        $colour = @{
            'Attribute'          = '#00bfff'; 'Command'  = '#0000ff'; 'CommandArgument'  = '#8a2be2'
            'CommandParameter'   = '#000080'; 'Comment'  = '#006400'; 'GroupEnd'         = '#000000'
            'GroupStart'         = '#000000'; 'Keyword'  = '#00008b'; 'LineContinuation' = '#000000'
            'LoopLabel'          = '#00008b'; 'Member'   = '#000000'; 'NewLine'          = '#000000'
            'Number'             = '#800080'; 'Operator' = '#696969'; 'Position'         = '#000000'
            'StatementSeparator' = '#000000'; 'String'   = '#8b0000'; 'Type'             = '#006161'
            'Unknown'            = '#000000'; 'Variable' = '#a82d00'
        }
    }
    # Parse the text and report any errors...
    process {
        $parse_errs         = $null
        $tokens             = [Management.Automation.PsParser]::Tokenize($text, [ref]$parse_errs)
        if ($parse_errs)  {
            return $parse_errs
        }
        $stringBuilder      = New-Object Text.StringBuilder
        $null               = $stringBuilder.Append('<code>')
        $endOfPreviousToken = 0

        # iterate over the tokens & set the colors appropriately...

        foreach ($t in $tokens) {
            if  ($t.Type -eq "NewLine") { [void]$stringBuilder.Append("<br />") }
            else {
                $chunk      = "&nbsp;" * ($t.Start - $endOfPreviousToken ) +
                               [System.Web.HttpUtility]::HtmlEncode($text.SubString($t.start, $t.length) )
                if ($t.type -eq "Comment") {$chunk = $chunk -replace " ","&nbsp;" -replace "\r\n","<br />"}
                [void]$stringBuilder.Append(("<span style='color:{0}'>{1}</span>" -f $colour[$t.type.ToString()],$chunk))
            }
            $endOfPreviousToken = ($t.Start + $t.Length)
        }
        [void]$stringBuilder.Append("</code>")
        $stringBuilder.ToString()
    }
}