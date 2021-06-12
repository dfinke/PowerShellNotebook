function Open-InteractiveNotebook {
    <#
    .SYNOPSIS
        Open a local notebook or from remote source
    .EXAMPLE
    # opens a local .dib interactive notebook 
    Open-InteractiveNotebook .\Untitled-1.dib 
    .EXAMPLE
    # opens a remote .dib interactive notebook 
    Open-InteractiveNotebook https://raw.githubusercontent.com/dotnet/interactive/main/NotebookTestScript.dib
    #>    
    param(
        [Parameter(ValueFromPipeline)]
        $Target
    )

    Process {
        $Target = [uri]::UnescapeDataString($Target)
        if (Test-Path $Target) {
            $Target = Resolve-Path $Target
            $targetType = 'path'
        }
        elseif ([System.Uri]::IsWellFormedUriString($Target, [System.UriKind]::Absolute) ) {
            $targetType = 'url'        
        }
        
        $targetMoniker = 'vscode://ms-dotnettools.dotnet-interactive-vscode/openNotebook?{0}={1}' -f $targetType, $Target
        $null = Start-Process $targetMoniker
    }
}