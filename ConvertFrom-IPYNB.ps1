using namespace System.Management.Automation
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
        [Parameter(Position=0,ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [Alias('FullName')]
        [string]$Path,
        [Alias('Outpath')]
        $Destination ,
        [Parameter(ParameterSetName="MD")]
        [Parameter(ParameterSetName="Html")]
        [Switch]$Includeoutput,
        [Parameter(ParameterSetName="Html")]
        [Switch]$AsHTML,
        [Parameter(ParameterSetName="Script")]
        [Switch]$AsScript
    )
    # Add "JustCode" parameter if -AsScript is specified, and Parameters from ConvertTo-HTML if -AsHtml is
    dynamicParam {
        $paramDictionary     = New-Object RuntimeDefinedParameterDictionary
        $paramAttribute      = New-Object ParameterAttribute
        $attributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $attributeCollection.Add($paramAttribute)

        if ($AsHTML) {
            $params= @{ 'CssUri'      = [uri]
                        'Meta'        = [hashtable]
                        'Title'       = [String]
                        'Head'        = [string[]]
                        'PreContent'  = [string[]]
                        'PostContent' = [string[]]}
            foreach ($k in $params.keys) {
                $paramDictionary.Add($k, (New-Object RuntimeDefinedParameter -ArgumentList $k,$params[$k],$attributeCollection ))
            }
        }
        if ($AsScript.IsPresent) {$paramDictionary.Add('JustCode', (New-Object RuntimeDefinedParameter -ArgumentList 'JustCode',([switch]),$attributeCollection))}
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
                {$_.Type -eq 'markdown' -and -not $AsScript} {$_.Source}
                {$_.Type -eq 'code'     -and      $AsScript} {$_.Source}
                {$_.Type -eq 'code'     -and -not $AsScript} {
                    #if present, convert .NetInteractive magic commands into "linguist" names used by github to the render code in markup
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
                    if     ($_.HtmlOutput)          {$_.HtmlOutput + "`n"}
                    elseif ($_.Output -is [string]) { '```' + "`n" + $_.Output.trim() + "`n" + '```' + "`n"}
                    elseif ($_.output.count -eq 1 -and $_.output.'text/html') {$_.output.'text/html' + "`n"}
                }
            }
            if ($AsHTML) { # convert the markdown to HTML and top and tail it
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
                $text = $head + ($text | ConvertFrom-Markdown).Html + $tail
            }

            if (-not $Destination) {
                return $text
            }
            elseif (Test-Path -PathType Container -Path $Destination) { #if destination is a folder make a suitable filename
                $fileName = Join-Path $Destination -ChildPath (Split-Path -Leaf $P)
                if     ($AsHTML)     {$fileName = $fileName -replace 'ipynb$', 'html'}
                elseif ($AsScript)   {$fileName = $fileName -replace 'ipynb$', 'ps1' }
                else                 {$fileName = $fileName -replace 'ipynb$', 'md'  }
                $text | Set-Content   $fileName -Encoding UTF8
                Get-Item  -Path $filename
            }
            else {
                $text | Set-Content -Encoding UTF8 $Destination
                Get-Item  -Path $Destination
            }
        }
    }
}