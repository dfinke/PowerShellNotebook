function Invoke-PowerShellNotebook {
    param(
        [Parameter(ValueFromPipelineByPropertyName)]
        $NoteBookFullName,
        [Switch]$AsExcel
    )

    Process {
        $codeBlocks = Get-NotebookContent $NoteBookFullName -JustCode
        for ($idx = 0; $idx -lt $codeBlocks.Count; $idx++) {
            $targetCode = $codeblocks[$idx].source
            if ($AsExcel) {
                if ($idx -eq 0) {
                    $xlfile = $NoteBookFullName -replace ".ipynb", ".xlsx"
                    Remove-Item $xlfile -ErrorAction SilentlyContinue
                }

                $uniqueName = "Sheet$($idx+1)"
                $targetCode |
                    Invoke-Expression |
                    Export-Excel -Path $xlfile -WorksheetName $uniqueName -AutoSize -TableName $uniqueName
            }
            else {
                , @($targetCode | Invoke-Expression)
            }
        }

        if ($AsExcel) {
            Invoke-Item $xlfile
        }
    }
}