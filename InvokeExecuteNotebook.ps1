function Invoke-ExecuteNotebook {
    <#
        .Synopsis
        Adds a new cell tagged with injected-parameters with input parameters in order to overwrite the values in parameters. 
        If no cell is tagged with parameters the injected cell will be inserted at the top of the notebook.

        .Description 
        This opens up new opportunities for how notebooks can be used. For example:

        Perhaps you have a financial report that you wish to run with different values on the first or last day of a month or at the beginning or end of the year, using parameters makes this task easier.
        Do you want to run a notebook and depending on its results, choose a particular notebook to run next? You can now programmatically execute a workflow without having to copy and paste from notebook to notebook manually.        
        
        .Example
        Invoke-ExecuteNotebook -InputNotebook .\basic.ipynb -Parameters @{arr = 1, 2, 3}

    #>
    param(
        $InputNotebook,
        $OutputNotebook,
        [hashtable]$Parameters,
        # When cells are run, it returns objects not strings
        [Switch]$ReturnAsObjects,
        [Switch]$Force,
        [Switch]$DoNotLaunchBrowser,
        [Switch]$DotNetInteractive
    )

    if (!$InputNotebook) { return }

    if ([System.Uri]::IsWellFormedUriString($InputNotebook, [System.UriKind]::Absolute)) {
        try {
            $data = Invoke-RestMethod $InputNotebook
        }
        catch {
            throw "$($InputNotebook) is not a valid Jupyter Notebook" 
        }
    }
    else {
        $json = Get-Content $InputNotebook 
        $data = $json | ConvertFrom-Json
    }
    
    [System.Collections.ArrayList]$cells = $data.cells

    $PSNotebookRunspace = New-PSNotebookRunspace -ReturnAsObjects:$ReturnAsObjects

    if ($Parameters) {        
        $cvt = "@'`r`n" + ($Parameters | ConvertTo-Json) + "`r`n'@"
        
        $source = @'
# injected parameters        
$payload = {0} | ConvertFrom-Json

$names = $payload.psobject.Properties.name
$names | foreach-object {{ Set-Variable -Name $_ -Value $payload.$_ }}

Remove-Variable payload -ErrorAction SilentlyContinue
Remove-Variable names -ErrorAction SilentlyContinue
'@ -f $cvt

        $newParams = New-CodeCell $source -DotNetInteractive:$DotNetInteractive | ConvertFrom-Json -Depth 3

        $index = Get-ParameterInsertionIndex -InputNotebook $InputNotebook
        $cells.Insert($index, $newParams)
    }

    $startedExecution = Get-Date
    $totalCells = $cells.count
    for ($idx = 0; $idx -lt $totalCells; $idx++) {
        $pct = 100 * ($idx / $totalCells)
        Write-Progress -Activity "[$($startedExecution)] Executing Notebook $($InputNotebook)" -Status "Running cell $($idx+1) of $($totalCells)" -PercentComplete $pct

        $cell = $cells[$idx]        
        if ($cell.cell_type -ne 'code') { continue }

        # Clear Errors
        $PSNotebookRunspace.PowerShell.Streams.Error.Clear()

        # Clear Commands
        $PSNotebookRunspace.PowerShell.Commands.Clear()

        $result = $PSNotebookRunspace.Invoke($cell.source)
        if ($PSNotebookRunspace.PowerShell.Streams.Error.Count -gt 0) {
            $text = $PSNotebookRunspace.PowerShell.Streams.Error | Out-String                    
        }
        else {
            $text = $result
        }

        $cell.outputs = @()
        if ($text) {
            $cell.outputs += [ordered]@{
                name        = "stdout"
                text        = $text
                output_type = "stream"
            }
        }
    }

    $data.cells = $cells
    
    if ($OutputNotebook) {
        $isUri = Test-Uri $OutputNotebook
        if ($isUri) {
            if ($OutputNotebook.startswith("gist://")) {

                $OutFile = $OutputNotebook.replace("gist://", "")
                $targetFileName = Split-Path $OutFile -Leaf

                Write-Progress -Activity "Creating Gist" -Status $targetFileName
                $contents = $data | ConvertTo-Json -Depth 5
                
                $Show = !$DoNotLaunchBrowser
                $result = New-GistNotebook -contents $contents -fileName $targetFileName -Show:$Show
            }
            elseif ($OutputNotebook.startswith("abs://")) {
                if (Test-AzureBlobStorageUrl $outputNotebook) {
                
                    $fullName = [System.IO.Path]::GetRandomFileName()
                    ConvertTo-Json -InputObject $data -Depth 5 | Set-Content $fullName -Encoding utf8

                    try {
                        $headers = @{'x-ms-blob-type' = 'BlockBlob' }                
                        Invoke-RestMethod -Uri ($OutputNotebook.Replace('abs', 'https')) -Method Put -Headers $headers -InFile $fullName    
                    }
                    catch {
                        throw $_.Exception.Message
                    }
                    finally {
                        Remove-Item $fullName -ErrorAction SilentlyContinue
                    }
                }
            }
            else {
                throw "Invalid OutputNotebook url '{0}'" -f $OutputNotebook
            }
        }
        else {
            if ((Test-Path $OutputNotebook) -and !$Force) {
                throw "$OutputNotebook already exists"
            }

            ConvertTo-Json -InputObject $data -Depth 5 |
            Set-Content $OutputNotebook -Encoding utf8
        }
    }
    else {
        $data.cells.outputs.text
    }    
}