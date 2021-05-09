using namespace System.Management.Automation
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
function ConvertFrom-IPYNB {
    <#
      .SYNOPSIS
        Take an existing Jupyter Notebook and convert it to markdown. Optimized for .Net interactive/PowerShell
      .Example
       PS C:\> ConvertFrom-IPYNB *.ipynb -Destination $env:TEMP

       Converts all notebooks in the current folder to markdown and saves the results in the "temp" folder.
       The output will be one .md file for each .ipynb file, using the original file name.
       In this example the output from code cells is discarded

      .Example
       PS C:\> ConvertFrom-IPYNB *.ipynb -includeOutput > giant.md

       Converts all notebooks in the current folder to markdown, and includes the output from code cells.
       Because no destination is specified the resulting markdown is output, and the output is
       redirected to a single file named "giant.md"

      .Example
       PS C:\> Get-Notebook | where kernelname -match "powershell" | ConvertFrom-IPYNB -AsScript -JustCode -Destination $env:temp

       The first command in the pipeline gets all notebooks in the current directory, with their path and Kernel.
       The second command discards any which are not PowerShell-based.
       The last command converts these into script (.ps1) files using the original name and storing thm in the temp directory.
       When -AsScript is specified -JustCode can be used to discard any markdown cells and -includeoutput is not available

     .Example
       PS C:\> ConvertFrom-IPYNB  .\changelog.ipynb -AsHTML -Title "Recent changes" -Destination recent.html

       Converts a named notebook file to HTML format, and saves the result to "recent.html".
       When -AsHtml is specified, the HTML <head> block or the CssUri, META tags and/or Title to create a <head> block
       may be specified, as can pre-content and post-content. These work in a similar way to the ConvertTo-Html command.
    #>
    [cmdletbinding(DefaultParameterSetName='MD')]
    param(
        #Notebook File to convert
        [Parameter(Position=0,ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [Alias('FullName')]
        [string]$Path,
        #Destination for output file - defaults to source_file_name with appropriate extension
        [Alias('Outpath')]
        $Destination ,
        #Output is only included in the markdown if explicitly requested
        [Parameter(ParameterSetName="MD")]
        [Parameter(ParameterSetName="Html")]
        [Switch]$Includeoutput,
        #If specified outputs a PowerShell script instead of a .MD file
        [Parameter(ParameterSetName="Script")]
        [Switch]$AsScript,
        #If specified, labels cells with their language
        [Parameter(ParameterSetName="MD")]
        [Parameter(ParameterSetName="Html")]
        [Switch]$AddLanguageLabels
    )
    # Add "JustCode" parameter if -AsScript is specified, and Parameters from ConvertTo-HTML if -AsHtml is
    dynamicParam {
        $paramDictionary     = New-Object RuntimeDefinedParameterDictionary
        $paramAttribute      = New-Object ParameterAttribute
        $attributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $attributeCollection.Add($paramAttribute)
        if ($AsScript.IsPresent) {$paramDictionary.Add('JustCode', (New-Object RuntimeDefinedParameter -ArgumentList 'JustCode',([switch]),$attributeCollection))}
        elseif (Get-Command ConvertFrom-Markdown -ErrorAction SilentlyContinue) {
            $attributeCollection[0].ParameterSetName = 'Html'
            $paramDictionary.Add('AsHTML', (New-Object RuntimeDefinedParameter -ArgumentList 'AsHTML',([switch]),$attributeCollection))
            $params= @{ 'CssUri'      = [uri]
                        'Meta'        = [hashtable]
                        'Title'       = [String]
                        'Head'        = [string[]]
                        'PreContent'  = [string[]]
                        'PostContent' = [string[]]}
            foreach ($k in $params.keys) {
                $paramDictionary.Add($k, (New-Object RuntimeDefinedParameter -ArgumentList $k,$params[$k],$attributeCollection ))
            }
            if ($Destination) {$paramDictionary.Add('Show', (New-Object RuntimeDefinedParameter -ArgumentList 'Show',([switch]),$attributeCollection))}
        }
        return $paramDictionary
    }
    process {
        #Allow path to contain more than one item; if it is wild card, call the function recursively.
        foreach ($p in $path) {
            if (-not [System.Uri]::IsWellFormedUriString($p, [System.UriKind]::Absolute) -and (Resolve-Path $p).count -gt 1)  {
                [void]$PSBoundParameters.Remove('Path')
                Get-ChildItem $p |ConvertFrom-IPYNB @PSBoundParameters
                continue
            }
            $NotebookProperties = Get-Notebook $P
            $cells = Get-NotebookContent -Path $P -Includeoutput:$Includeoutput -JustCode:($PSBoundParameters['justcode'])
            $text  = switch ($cells) {
                {$_.Type -eq 'markdown' -and      $AsScript} {"<#`n" + $_.Source + "`n#>`n"}
                {$_.Type -eq 'markdown' -and -not $AsScript} {$_.Source  + "`n"}
                {$_.Type -eq 'code'     -and      $AsScript} {$_.Source}
                {$_.Type -eq 'code'     -and -not $AsScript} {
                    #if present use langauge or .NetInteractive magic commands into "linguist" Names by github to the render code in markup
                    if ($_.Language -and $_.source -notmatch "^#!([cf]sharp|[cf]#|JavaScript|js|html|markdown|PowerShell|pwsh|sql)") {
                        switch  -Regex ($_.Language) {
                            'csharp|C#'                {$format = 'C#'         ; continue}
                            'fsharp|F#'                {$format = 'F#'         ; continue}
                            'javascript'               {$format = 'JavaScript' ; continue}
                            'pwsh|PowerShell'          {$format = 'PowerShell' ; continue}
                            Default                    {$format = $_}
                        }
                        if ($AddLanguageLabels )       { "``$($_.Language)``"}
                    }
                    else {
                        switch -Regex ($_.source) {
                            '^#!csharp|^#!c#'          {$format = 'C#'         ; continue}
                            '^#!fsharp|^#!f#'          {$format = 'F#'         ; continue}
                            '^#!html'                  {$format = 'html'       ; continue}
                            '^#!JavaScript|^#!js'      {$format = 'JavaScript' ; continue}
                            '^#!markdown'              {$format = 'MarkDown'   ; continue}
                            '^#!PowerShell|^#!pwsh'    {$format = 'PowerShell' ; continue}
                            '^#!sql'                   {$format = 'SQL'        ; continue}
                        }
                        if (-not $format)              {$format = $NotebookProperties.FormatStyle}
                        elseif ($AddLanguageLabels )   { "``$format``"}
                    }
                    $marker = '```'
                    while ($_.Source -match $marker) {$marker += '`'}
                    ($marker + $format + "`n" + $_.Source + "`n" + $marker + "`n")

                    #There will only be output if we specified the -IncludeOutput and we will ignore output which isn't a string or a single HTML block.
                    if     ($_.HTMLOutput)             {"----`n`n" + ($_.HTMLOutput -replace  '\s*</?html>\s*','' -replace  '[\r\n]*$',"`n") +"`n----`n"}
                    elseif ($_.Output -is [string])    {"----`n" + '```' + "`n" + $_.Output.trim() + "`n" + '```' + "`n----`n"}
                    #elseif ($_.output.count -eq 1 -and
                    #        $_.output.'text/html')     {"----`n" + ($_.output.'text/html' -replace  '</?html>','') + "`n`n----`n"}
                    elseif ($Includeoutput) {
                        "----`n"
                        foreach ($o in $_.Output) {
                            if     ($o.'text/html')     {-join $o.'text/html' -replace  '</?html>',''}
                            elseif ($o.'text/plain')    {-join $o.'text/plain'}
                            elseif ($o.'text/markdown') {-join $o.'text/markdown'}
                        }
                        "`n----`n"
                    }
                }
            }
            if ($PSCmdlet.ParameterSetName -eq 'html') { # convert the markdown to HTML and top and tail it, render HTML & PowerShell CodeCells nicely
                if ($psboundparameters['Head']) {
                    $head = "<html>`n  <head>`n" + $psboundparameters['Head'] +"  </head>`n  <body>`n"
                }
                elseif ($psboundparameters['meta','title','cssuri']) {
                    $head = "<html>`n  <head>`n"
                    if ($psboundparameters['Title']) {
                        $head += '    <title>' + $psboundparameters['Title']       + "</title>`n"
                    }
                    else {$head += '    <title>' + (Split-Path -Leaf $P)  + "</title>`n" }

                    if (-not $PSBoundParameters['meta']) {
                        $head += '    <meta name="created" content="{0:yyyy-MM-ddTHH:mm:sszzz}">' -f [datetime]::now
                        $head +=  "`n"
                    }
                    else {
                        foreach ($k in $psboundparameters['meta'].keys) {
                        $head += '    <meta name="{0}" content="{1}">' -f $k,  $psboundparameters['meta'].$k
                        $head +=  "`n"
                        }
                    }
                    if ($psboundparameters['CssUri']) {
                        $head += '    <link rel="stylesheet" type="text/css" href="{0}" />' -f $psboundparameters['CssUri']
                        $head += "`n"
                    }
                    $head += "  </head>`n  <body>`n"
                }
                else {
                    $head = "<html>`n  <body>`n"
                }
                if ($psboundparameters['PreContent']) { $head += $psboundparameters['PreContent'] + "`n"}

                $tail = "`n  </body>`n</html>"
                if ($psboundparameters['PostContent']) { $tail = "`n" + $psboundparameters['PostContent'] + $tail }

                $markdown = $text -join "`n"
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
                $html = ($markdown | ConvertFrom-Markdown).Html -join "`n"
                $html = $html -replace '(?s)<pre><code class=(.*?)</code></pre>','<div style=''background-color: #E0E0E0''><pre><code class=$1</code></pre></div>'
                $html = $html -replace '(?<!\r)\n',"`r`n"

                $text = $head + $html + $tail
            }

            if (-not $Destination) {
                return $text
            }
            elseif (Test-Path -PathType Container -Path $Destination) { #if destination is a folder make a suitable filename
                $fileName = Join-Path $Destination -ChildPath (Split-Path -Leaf $P)
                if     ($PSCmdlet.ParameterSetName -eq 'html') {
                                    $fileName = $fileName -replace 'ipynb$', 'html'
                }
                elseif ($AsScript) {$fileName = $fileName -replace 'ipynb$', 'ps1' }
                else               {$fileName = $fileName -replace 'ipynb$', 'md'  }
                $text | Set-Content $fileName -Encoding UTF8
                Get-Item    -Path   $filename
                if ($psboundparameters['Show']) {
                    Start-Process $fileName
                }
            }
            else {
                $text | Set-Content $Destination -Encoding UTF8
                Get-Item   -Path    $Destination
                if ($psboundparameters['Show']) {
                    Start-Process   $Destination
                }
            }
        }
    }
}