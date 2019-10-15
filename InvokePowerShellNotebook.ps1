function Invoke-PowerShellNotebook {
    param(
        [Parameter(ValueFromPipelineByPropertyName)]
        $NoteBookFullName,
        [Switch]$AsExcel,
        [Switch]$Show
    )

    Process {
        $codeBlocks = Get-NotebookContent $NoteBookFullName -JustCode
        for ($idx = 0; $idx -lt $codeBlocks.Count; $idx++) {
            $targetCode = $codeblocks[$idx].source
            if ($AsExcel) {
                if ($idx -eq 0) {
                    $xlfile = $NoteBookFullName -replace ".ipynb", ".xlsx"
                    #$xlfile = "$PSScriptRoot\$xlfile"
                    #$xlfile = "$($pwd.Path)\$xlfile"
                    Remove-Item $xlfile -ErrorAction SilentlyContinue
                }

                $uniqueName = "Sheet$($idx+1)"
                foreach ($dataSet in , @($targetCode | Invoke-Expression)) {
                    Export-Excel -InputObject $dataSet -Path $xlfile -WorksheetName $uniqueName -AutoSize -TableName $uniqueName
                    #$dataSet | Export-Excel -Path $xlfile -WorksheetName $uniqueName -AutoSize -TableName $uniqueName
                }
            }
            else {
                , @($targetCode | Invoke-Expression)
            }
        }

        if ($AsExcel) {
            if ($Show) {
                Invoke-Item $xlfile
            }
            else {
                $xlfile
            }
        }
    }
}