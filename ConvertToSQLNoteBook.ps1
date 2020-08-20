function loadScriptDomModules{
    #try {Import-Module SqlServer -ErrorAction Stop} catch {Install-Module -Name SqlServer -Scope CurrentUser} finally {Import-Module SqlServer}
    Import-Module -Name SqlServer
    $ScriptDom = Join-Path -Path (Get-Module -Name SqlServer).ModuleBase -ChildPath 'Microsoft.SqlServer.TransactSql.ScriptDom.dll'
    if((Test-Path $ScriptDom) -eq $true ) {Add-Type -LiteralPath $ScriptDom}
}

# Quick Helper-function to turn the file into a script fragment, using scriptdom.
function Get-ParsedSql($ScriptPath){

    loadScriptDomModules

    [Microsoft.SqlServer.TransactSql.ScriptDom.TSql150Parser] $parser = new-object Microsoft.SqlServer.TransactSql.ScriptDom.TSql150Parser($false)
    $Reader = New-Object -TypeName System.IO.StreamReader -ArgumentList $ScriptPath
    $Errors = $null
    $ScriptFrag = $parser.Parse($Reader, [ref]$Errors)
    return $ScriptFrag
}

function Get-ParsedSqlOffsets{
    [CmdletBinding()]
    param(
        $ScriptPath,
        $IncludeGaps=$true,
        [switch]$ExtractCommentsInsideBatches
    )

<#################################################################################################
Checking for Batch length
#################################################################################################>
$s = Get-Content -Raw ( Resolve-Path $ScriptPath )
$ParsedSql = Get-ParsedSql $ScriptPath
$SqlBatches = @()
$SqlBatch = @()
$id=1
foreach($Batch in $ParsedSql.Batches) {
    $SqlBatch=[pscustomobject][Ordered]@{
    StartOffset = $Batch.StartOffset;
    StopOffset  = $Batch.StartOffset+$Batch.FragmentLength;
    Length      = $Batch.FragmentLength;
    StartColumn = $Batch.StartColumn;
    BatchId     = $id;
    BlockType   = 'Code';
    Text        = $s.Substring($Batch.StartOffset, $Batch.FragmentLength)
    }
    $SqlBatches+=$SqlBatch
    $id++
}

$ScriptFrags = (Get-ParsedSql -ScriptPath $ScriptPath).ScriptTokenStream.where({$_.TokenType -eq 'MultilineComment'})
#If there are no comments to extract, we will skip the next section of code.
if($ScriptFrags){
    $Comments = @()
    $Comment = @()
    foreach($Frag in $ScriptFrags ) {
        $Comment=[pscustomobject][Ordered]@{
        StartOffset = $Frag.Offset;
        StopOffset = $Frag.Offset+$Frag.Text.Length;
        Length = $Frag.Text.Length;
        StartColumn = $Frag.Column;
        CommentLocation = $null;
        BlockType = 'Comment';
        Text = $Frag.Text
        }

        foreach($SqlBatch in $SqlBatches){

        if($Comment.StartOffset -ge $SqlBatch.StartOffset -and $Comment.StartOffset -le $SqlBatch.StopOffset)
        {$Comment.CommentLocation = "Within SQL Batch $($SqlBatch.BatchId)"}
        else {if($Comment.CommentLocation -notlike '*Within*'){$Comment.CommentLocation = "Outside"}}
        }
        $Comments+=$Comment
    }
}
<#################################################################################################
This is the basic product of Mulit-line Coments that are outside of Batches.
Can you detect parameters in a test?
#################################################################################################>
if($ExtractCommentsInsideBatches){
    $ExtractAllComments = $Comments
}
else {
    $ExtractAllComments = $Comments | Where-Object { $_.CommentLocation -eq 'Outside' }
}
$NotebookBlocks = $SqlBatches + $ExtractAllComments

if($IncludeGaps -eq $false){
return $NotebookBlocks | Sort-Object StartOffset
}
else {
    if($NotebookBlocks.Count -eq 1 -and $NotebookBlocks.StopOffset -eq $s.Length){
    return $NotebookBlocks | Sort-Object StartOffset}
    else {
    
    <#################################################################################################
    This What we do with the offset results to identify Gaps.
    #################################################################################################>
        $SqlBlocks = $NotebookBlocks | Sort-Object StartOffset

        $BlocksWitGaps = @()
        $Previous = @{StartOffset=0;StopOffset=0}
        foreach($SqlBlock in $SqlBlocks ) {
            $BlockOffsets=[ordered]@{
            StartOffset = $SqlBlock.StartOffset;
            StopOffset = $SqlBlock.StopOffset;
            Length = $SqlBlock.Length;
            GapLength = [int] $SqlBlock.StartOffset-$Previous.StopOffset;
            PreviousStartOffset = $Previous.StartOffset;
            PreviousStopOffset = $Previous.StopOffset;
            CommentLocation = $SqlBlock.CommentLocation;
            BlockType = $SqlBlock.BlockType;
            GapText = IF($SqlBlock.StartOffset-$Previous.StopOffset -gt 1){[string] $s.Substring($Previous.StopOffset, ($SqlBlock.StartOffset-$Previous.StopOffset))}else {[string] ''};
            Text = $SqlBlock.Text
            }

            $Previous=$BlockOffsets
            $BlocksWitGaps+=[pscustomobject] $BlockOffsets
        }

        <#################################################################################################
        This is an extra step to combine Gaps with Batches & Comments in a single structure.
        #################################################################################################>
        $AllBlocks = @()
        $GapOffsets = @()
        $Previous = @{StartOffset=0;StopOffset=0}
        if($BlocksWitGaps.Count -eq 1){$AllBlocks = @($SqlBlocks;[pscustomobject][Ordered]@{
            StartOffset=0; 
            StopOffset = $BlocksWitGaps.GapLength;
            Length = $BlocksWitGaps.GapLength;
            StartColumn = $null;
            BatchId=0;
            BlockType = 'Gap';
            Text = $BlocksWitGaps.GapText})}
        else{
            $AllBlocks = $SqlBlocks
            foreach($GapBlock in $BlocksWitGaps ) {
                $GapOffsets=[ordered]@{
                StartOffset = $GapBlock.PreviousStopOffset;
                StopOffset = $GapBlock.StartOffset;
                Length = $GapBlock.GapLength;
                StartColumn = $null;
                CommentLocation = 'Between';
                BlockType = 'Gap';
                Text = $GapBlock.GapText
                }

                $Previous=$GapOffsets
                $AllBlocks+=if($GapOffsets.Length -gt 2){[pscustomobject] $GapOffsets}
                }
            }
            #$AllBlocks | Sort-Object StartOffset | ft -AutoSize -Wrap
            return $AllBlocks
        }
    }
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

    New-SQLNotebook -NoteBookName $OutputNotebookName {
        $s = Get-Content -Raw ( Resolve-Path $InputFileName )
        $AllNoteBlocks = Get-ParsedSqlOffsets -ScriptPath $InputFileName

        foreach($Block in $AllNoteBlocks | Sort-Object StartOffset ) {

        
            switch ($Block.BlockType) {
                'Code'  {$CodeBlock = $s.Substring($Block.StartOffset, $Block.Length)
                            Write-Verbose "CODE - $($CodeBlock)"
    
                            if($CodeBlock.Trim().length -gt 0){
                                Add-NotebookCode -code (-join $CodeBlock)
                            }
                        }
                'Comment' {$TextBlock = $s.Substring($Block.StartOffset+2, $Block.Length-4) -replace ("\r\n", "   `n  ")
                            Write-Verbose "COMMENT - $($TextBlock)"
    
                            if($TextBlock.Trim().length -gt 0){
                                Add-NotebookMarkdown -markdown (-join $TextBlock)
                            }
                        }
                'Gap'   {$GapBlock = ($s.Substring($Block.StartOffset, $Block.Length) -replace ("\n", "   `n  ")).TrimStart().TrimEnd()
                            Write-Verbose "COMMENT - $($GapBlock)"
    
                            if($GapBlock.Trim().length -gt 0){
                                Add-NotebookMarkdown -markdown (-join $GapBlock)
                            }
                        }
            }
        }
    }
}