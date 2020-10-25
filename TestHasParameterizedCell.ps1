function Test-HasParameterizedCell {
    param(
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias("FullName")]
        $InputNotebook
    )

    Process {
 
        $content = Get-NotebookContent $InputNotebook -PassThru
        $HasParameterizedCell = $false
        foreach ($tag in $content.cells.metadata.tags) { 
            if ($tag -eq 'parameters') { 
                $HasParameterizedCell = $true
                break
            } 
        }

        [PSCustomObject][Ordered]@{
            HasParameterizedCell = $HasParameterizedCell
            Path                 = $InputNotebook
        }
    }
}