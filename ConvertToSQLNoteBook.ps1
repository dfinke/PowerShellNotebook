function loadScriptDomModules{
    #try {Import-Module SqlServer -ErrorAction Stop} catch {Install-Module -Name SqlServer -Scope CurrentUser} finally {Import-Module SqlServer}
    Import-Module -Name SqlServer
    $ScriptDom = Join-Path -Path (Get-Module -Name SqlServer).ModuleBase -ChildPath 'Microsoft.SqlServer.TransactSql.ScriptDom.dll'
    if((Test-Path $ScriptDom) -eq $true ) {Add-Type -LiteralPath $ScriptDom}
}

# Quick Helper-function to turn the file into a script fragment, using scriptdom.
function Get-ScriptComments($ScriptPath){
    [Microsoft.SqlServer.TransactSql.ScriptDom.TSql150Parser] $parser = new-object Microsoft.SqlServer.TransactSql.ScriptDom.TSql150Parser($false);
    $Reader = New-Object -TypeName System.IO.StreamReader -ArgumentList $ScriptPath
    $Errors = $null
    $ScriptFrag = $parser.Parse($Reader, [ref]$Errors)
    # Look for Drop Statements
    ($ScriptFrag.ScriptTokenStream).where({$_.TokenType -eq 'MultilineComment'})
}

function ConvertTo-SQLNoteBook {
    <#
        .Example
        ConvertTo-SQLNoteBook -InputFileName 'C:\temp\AdventureWorksMultiStatementSBatch.sql' -OutputNotebookName 'C:\temp\AdventureWorksMultiStatementSBatch.ipynb'
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