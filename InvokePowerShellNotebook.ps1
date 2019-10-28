function Invoke-PowerShellNotebook {
    param(
        [Parameter(ValueFromPipelineByPropertyName)]
        $NoteBookFullName,
        [Switch]$AsExcel,
        [Switch]$Show
    )

    Process {
        $codeBlocks = Get-NotebookContent $NoteBookFullName -JustCode
        $SheetCount = 0
        for ($idx = 0; $idx -lt $codeBlocks.Count; $idx++) {
            $targetCode = $codeblocks[$idx].source
            if ($AsExcel) {
                if ($idx -eq 0) {
                    $notebookFileName = Split-Path $NoteBookFullName -Leaf
                    $xlFileName = $notebookFileName -replace ".ipynb", ".xlsx"

                    $xlfile = "{0}\{1}" -f $pwd.Path, $xlFileName
                    Remove-Item $xlfile -ErrorAction SilentlyContinue
                }

                foreach ($dataSet in , @($targetCode | Invoke-Expression)) {
                    if ($dataSet) {
                        #$uniqueName = "Sheet$($idx)"
                        $SheetCount++
                        $uniqueName = "Sheet$($SheetCount)"
                        Export-Excel -InputObject $dataSet -Path $xlfile -WorksheetName $uniqueName -AutoSize -TableName $uniqueName
                    }
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