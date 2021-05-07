function Invoke-PowerShellNotebook {
    <#
        .SYNOPSIS
        Invoke-PowerShellNotebook executes all the PowerShell code blocks in a PowerShell Notebook.

        .Example
        Invoke-PowerShellNotebook .\SingleCodeBlock.ipynb

Region Item  TotalSold
------ ----  ---------
South  lime  20
West   melon 76

    #>
    param(
        [Parameter(ValueFromPipelineByPropertyName)]
        $NoteBookFullName,
        $OutFile,
        [Switch]$AsExcel,
        [Switch]$Show
    )

    Process {
        
        if ($OutFile) {
            if (Test-Path $OutFile) {
                throw "$OutFile already exists"
            }

            $PSNotebookRunspace = New-PSNotebookRunspace

            $null = Copy-Item $NoteBookFullName $OutFile
            $notebookJson = Get-Content $OutFile | ConvertFrom-Json

            $codeCells = $notebookJson.cells | Where-Object { $_.'cell_type' -eq 'code' }

            foreach ($codeCell in $codeCells) {

                # Clear Errors
                $PSNotebookRunspace.PowerShell.Streams.Error.Clear()
                # Clear Commands
                $PSNotebookRunspace.PowerShell.Commands.Clear()

                $result = $PSNotebookRunspace.Invoke($codeCell.source)
                if ($PSNotebookRunspace.PowerShell.Streams.Error.Count -gt 0) {
                    $text = $PSNotebookRunspace.PowerShell.Streams.Error | Out-String                    
                }
                else {
                    $text = $result
                }

                $codeCell.outputs = @()
                $codeCell.outputs += [ordered]@{
                    name        = "stdout"
                    text        = $text -join "`n"
                    output_type = "stream"
                }
            }
            
            $PSNotebookRunspace.Close()
            
            $notebookJson | ConvertTo-Json -Depth 5 | Set-Content $OutFile -Encoding UTF8            
        }
        else {

            $codeBlocks = @(Get-NotebookContent $NoteBookFullName -JustCode)
            $codeBlockCount = $codeBlocks.Count
            $SheetCount = 0

            for ($idx = 0; $idx -lt $codeBlockCount; $idx++) {

                $targetCode = $codeblocks[$idx].source

                Write-Progress -Activity "Executing PowerShell code block - [$(Get-Date)]" -Status (-join $targetCode) -PercentComplete (($idx + 1) / $codeBlockCount * 100)

                if ($AsExcel) {
                    if (!(Get-Module -ListAvailable ImportExcel -ErrorAction SilentlyContinue)) {
                        throw "This feature requires the ImportExcel PowerShell module. Use 'Install-Module -Name ImportExcel' to get it from the PS Gallery."
                    }

                    if ($idx -eq 0) {
                        $notebookFileName = Split-Path $NoteBookFullName -Leaf
                        $xlFileName = $notebookFileName -replace ".ipynb", ".xlsx"

                        $xlfile = "{0}\{1}" -f $pwd.Path, $xlFileName
                        Remove-Item $xlfile -ErrorAction SilentlyContinue
                    }

                    foreach ($dataSet in , @($targetCode | Invoke-Expression)) {
                        if ($dataSet) {
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
}