function loadScriptDomModules{
    Import-Module -Name SqlServer
    Add-Type -LiteralPath "C:\Program Files (x86)\Microsoft SQL Server\140\DAC\bin\Microsoft.SqlServer.TransactSql.ScriptDom.dll"
}

# Quick Helper-function to turn the file into a script fragment, using scriptdom.
function Get-ScriptComments($ScriptPath){
    [Microsoft.SqlServer.TransactSql.ScriptDom.TSql140Parser] $parser = new-object Microsoft.SqlServer.TransactSql.ScriptDom.TSql140Parser($false);
    $Reader = New-Object -TypeName System.IO.StreamReader -ArgumentList $ScriptPath
    $Errors = $null
    $ScriptFrag = $parser.Parse($Reader, [ref]$Errors)
    # Look for Drop Statements
    ($ScriptFrag.ScriptTokenStream).where({$_.TokenType -eq 'MultilineComment'})
}

function ConvertTo-SQLNoteBook {
    <#
        .Example
        ConvertTo-PowerShellNoteBook -InputFileName c:\Temp\demo.txt -OutputNotebookName c:\Temp\demo.ipynb
    #>
    param(
        $InputFileName,
        $OutputNotebookName
    )

    loadScriptDomModules

    New-SQLNotebook -NoteBookName $OutputNotebookName {
        $s = Get-Content -Raw ( Resolve-Path $InputFileName )
        $ScriptFrags = Get-ScriptComments -ScriptPath $InputFileName

        $StartCode=0
        foreach($Comment in $ScriptFrags ) {
            $LengthCode = $Comment.Offset - $StartCode
            $CodeBlock = $s.Substring($StartCode, $LengthCode)
            Write-Verbose "CODE - $($CodeBlock)" -Verbose
            if($CodeBlock.Trim().length -gt 0){
                Add-NotebookCode -code (-join $CodeBlock)
            }

            $StartText= $Comment.Offset
            $LengthText= $Comment.Text.Length
            $TextBlock = $s.Substring($StartText+2, $LengthText-4) -replace ("\n", "   `n  ")
            Write-Verbose "COMMENT - $($TextBlock)" -Verbose

            if($TextBlock.Trim().length -gt 0){
                Add-NotebookMarkdown -markdown (-join $TextBlock)
            }

            $StartCode= $StartText + $LengthText
        }
        # Left over code after last comment block
        $LengthCode = $s.Length - $StartCode
        $LastCodeBlock = $s.Substring($StartCode, $LengthCode)
        Write-Verbose "CODE - $($LastCodeBlock)" -Verbose
        if($LastCodeBlock.Trim().length -gt 0){
            Add-NotebookCode -code (-join $LastCodeBlock)
        }
    }
}