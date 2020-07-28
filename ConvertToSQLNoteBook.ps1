function ConvertTo-SQLNoteBook {
    <#
        .Example
        ConvertTo-PowerShellNoteBook -InputFileName c:\Temp\demo.txt -OutputNotebookName c:\Temp\demo.ipynb
    #>
    param(
        $InputFileName,
        $OutputNotebookName
    )
<#
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
#>
    New-SQLNotebook -NoteBookName $OutputNotebookName {
        $s = Get-Content -Raw ( Resolve-Path $InputFileName )
        #$s.GetType()

        <# Doug's code for extracting the comment blocks. #>
        $locations=@()

        $pos=$s.IndexOf("/*")

        while ($pos -ge 0) {
            $locations+=[pscustomobject]@{startPos=$pos;endPos=$null}
            $pos=$s.IndexOf("/*", $pos+2)
        }

        $count=0
        $pos=$s.IndexOf("*/")
        while ($pos -ge 0) {
            $locations[$count].endPos=$pos
            $pos=$s.IndexOf("*/", $pos+1)
            $count++
        }

        <# My basic attempt #>

        $PreviousLocation = $null
        <# The line below cpits out a code block, in the event the file stars with code. #>
        Add-NotebookCode ($s.Substring(0, ($locations[0].startPos)))
        foreach($location in $locations)
        {
            $start=$location.startPos
            $length=$location.endPos-$location.startPos+2
            <# The line below spits out the comment blocks #>
            Add-NotebookMarkdown $s.Substring($start+2, $length-4)
            <# The line below spits out the code blocks #>
            Add-NotebookCode ($s.Substring($PreviousLocation.endPos, ($location.startPos - $PreviousLocation.endPos)))
            $PreviousLocation=$location
        }

        Add-NotebookCode ($s.Substring($location.endPos+2, ($s.Length-$location.endPos-2)))
        <# The line above grabs the last code block from the .SQL file. #>

        <# When you need to debug, the list of comment-block locations is in the variable below #>
        $locations
    }
}