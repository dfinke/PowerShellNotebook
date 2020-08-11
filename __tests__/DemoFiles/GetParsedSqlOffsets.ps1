function Get-ParsedSqlOffsets{
    [CmdletBinding()]
    param(
        $ScriptPath
    )
<#################################################################################################
Pre-reqs: Install the SqlServer module.
#################################################################################################>
Import-Module SqlServer
$ScriptDom = Join-Path -Path (Get-Module -Name SqlServer).ModuleBase -ChildPath 'Microsoft.SqlServer.TransactSql.ScriptDom.dll'
if((Test-Path $ScriptDom) -eq $true ) {Add-Type -LiteralPath $ScriptDom}
<#################################################################################################
Qucik Helper-function to turn the file into a script fragment, using scriptdom.
#################################################################################################>
function Get-ParsedSql($ScriptPath){
    [Microsoft.SqlServer.TransactSql.ScriptDom.TSql150Parser] $parser = new-object Microsoft.SqlServer.TransactSql.ScriptDom.TSql150Parser($false)
    $Reader = New-Object -TypeName System.IO.StreamReader -ArgumentList $ScriptToParse
    $Errors = $null
    $ScriptFrag = $parser.Parse($Reader, [ref]$Errors)
    return $ScriptFrag
    }
    <#################################################################################################>
function Get-ScriptFragment($ScriptPath){
[Microsoft.SqlServer.TransactSql.ScriptDom.TSql150Parser] $parser = new-object Microsoft.SqlServer.TransactSql.ScriptDom.TSql150Parser($false)
$Reader = New-Object -TypeName System.IO.StreamReader -ArgumentList $ScriptPath
$Errors = $null
$ScriptFrag = $parser.Parse($Reader, [ref]$Errors)
# Look for MultilineComment within Statements
($ScriptFrag.ScriptTokenStream).where({$_.TokenType -eq 'MultilineComment'})
}
<#################################################################################################
Checking for Batch length
#################################################################################################>
$s = Get-Content -Raw ( Resolve-Path $ScriptToParse )
$ParsedSql = Get-ParsedSql $ScriptToParse
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

$ScriptFrags = Get-ScriptFragment -ScriptPath $ScriptToParse
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

<#################################################################################################
This is the basic product.
#################################################################################################>
$NotebookBlocks = $SqlBatches + ($Comments | WHERE { $_.CommentLocation -eq 'Outside' })
$NotebookBlocks | SORT StartOffset
}