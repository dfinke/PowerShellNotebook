function Find-ParameterizedCell {
    <#
        .Synopsis
        Reads a Jupyter Notebook and returns all cells with a tag -eq to 'parameters'
        .Example
        Invoke-ExecuteNotebook -InputNotebook .\test.ipynb "abs://$($account)/$($containerName)/test.ipynb?$($sasToken)"
    #>
    param(
        [Parameter(Mandatory)]
        $InputNotebook
    )

    if ([System.Uri]::IsWellFormedUriString($InputNotebook, [System.UriKind]::Absolute)) {
        $data = Invoke-RestMethod $InputNotebook
    }
    else {
        $json = Get-Content $InputNotebook 
        $data = $json | ConvertFrom-Json
    }    

    for ($idx = 0; $idx -lt $data.cells.Count; $idx++) {
        $currentCell = $data.cells[$idx]
        if ($currentCell.metadata.tags -eq 'parameters') {
            $idx
        }
    }
}

function Get-ParameterInsertionIndex {
    param(
        [Parameter(Mandatory)]
        $InputNotebook
    )

    $cell = Find-ParameterizedCell $InputNotebook | Select-Object -First 1
    if ([string]::IsNullOrEmpty($cell)) {
        return 0
    }
    $cell + 1
}

function Invoke-ExecuteNotebook {
    param(
        $InputNotebook,
        $OutputNotebook,
        [hashtable]$Parameters,
        [Switch]$Force,
        [Switch]$DoNotLaunchBrowser
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
    
    $PSNotebookRunspace = New-PSNotebookRunspace

    if ($Parameters) {        
        $newVars = @("# override parameters")
        $newVars += $(
            foreach ($entry in $parameters.GetEnumerator() ) {
                $quote = $null
                $currentValue = $entry.value
                                
                if ($currentValue -is [string]) { $quote = "'" }
                '${0} = {1}{2}{1}' -f $entry.name, $quote, $currentValue                
            }
        )
            
        $newParams = New-CodeCell ($newVars -join "`r`n") | ConvertFrom-Json

        $index = Get-ParameterInsertionIndex -InputNotebook $InputNotebook
        $cells.Insert($index, $newParams)
    }

    for ($idx = 0; $idx -lt $cells.count; $idx++) {
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

                $contents = $data | ConvertTo-Json -Depth 4
                $result = New-GistNotebook -contents $contents -fileName $targetFileName
                
                Write-Progress -Activity "Creating Gist" -Status $targetFileName

                if (!$DoNotLaunchBrowser -and $result) {
                    Start-Process $result.html_url
                }            
            }
            elseif ($OutputNotebook.startswith("abs://")) {
                if (Test-AzureBlobStorageUrl $outputNotebook) {
                
                    $fullName = [System.IO.Path]::GetRandomFileName()
                    ConvertTo-Json -InputObject $data -Depth 4 | Set-Content $fullName -Encoding utf8

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

            ConvertTo-Json -InputObject $data -Depth 4 |
            Set-Content $OutputNotebook -Encoding utf8
        }
    }
    else {
        $data.cells.outputs.text
    }    
}

function Test-AzureBlobStorageUrl {
    param(
        $Url
    )

    $pattern = "abs://(.*)\.blob\.core\.windows\.net\/(.*)\/(.*)\?(.*)$"

    [regex]::Match($Url, $pattern).Success
}

function Test-Uri {
    param(
        $FullName
    )

    [System.Uri]::IsWellFormedUriString($FullName, [System.UriKind]::Absolute)
}