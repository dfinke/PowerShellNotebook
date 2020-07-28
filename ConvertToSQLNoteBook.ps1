function ConvertTo-SQLNoteBook {
    <#
        .Example
        ConvertTo-PowerShellNoteBook -InputFileName c:\Temp\demo.txt -OutputNotebookName c:\Temp\demo.ipynb
    #>
    param(
        $InputFileName,
        $OutputNotebookName
    )

    New-SQLNotebook -NoteBookName $OutputNotebookName {
        $content =  Get-Content $InputFileName | Out-String
        $insideBlockComment = $false
        $lines = [regex]::split($content,'\r\n')

        foreach ($line in $lines) {
            if($line.Length -eq 0) { continue }
            if ($insideBlockComment) {
                $blockComment += $line
                if ($line -match '\*/') {
                    $insideBlockComment = $false
                    Add-NotebookMarkdown $blockComment
                    Write-Verbose "block comment - $blockComment" -Verbose
                    $blockComment = ''
                    continue
                }


                Write-Verbose "block comment - $blockComment" -Verbose
            }
            elseif ($line -match '/\*') {
                $insideBlockComment = $true;
                $blockComment += $line
                #Write-Verbose "comment - $line" -Verbose

            }else{
                if ($line -match '--') {
                    # Write-Verbose "comment - $line" -Verbose
                    Add-NotebookMarkdown $line
                }
                else{
                    Add-NotebookCode $line
                    #Write-Verbose "code - $line" -Verbose
                }
            }
        }
    }
}