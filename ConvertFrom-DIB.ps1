function ConvertFrom-DIB {
    param(
        [Switch]$AsText,
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias("FullName")]
        $Path
    )

    Process {
        $psnParams = @{DNI = $true }

        if ($AsText) {
            $psnParams['AsText'] = $true
        }
        else {
            $NoteBookName = (Split-Path $Path -Leaf) -replace 'dib', 'ipynb'
            $psnParams['NoteBookName'] = $NoteBookName
        }

        New-PSNotebook @psnParams {
            switch (Get-DIBBlock $Path) {
                { $_.Type -eq '#!markdown' } {
                    Add-NotebookMarkdown $_.Content
                }
                { $_.Type -eq '#!pwsh' } {
                    Add-NotebookCode $_.Content -NoGUID
                }
            }
        }
    }
}