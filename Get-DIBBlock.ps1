function Get-DIBBlock {
    param(
        [Parameter(Mandatory)]
        $fileName 
    )

    $content = Get-Content $fileName

    $lineNumber = -1

    $locations = foreach ($line in $content) {
        $lineNumber++
        if ($line.Startswith('#!')) { 
            $lineNumber
        } 
    }

    for ($idx = 0; $idx -lt $locations.Count; $idx++) {
        $startBlock = $locations[$idx] + 1
        if ($idx + 1 -eq $locations.Count) {
            $endBlock = $content.Count - 1
        }
        else {
            $endBlock = $locations[$idx + 1] - 1
        }

        [pscustomobject][ordered]@{
            FileName = $fileName
            Block    = $idx        
            Range    = '{0}..{1}' -f $startBlock, $endBlock
            Type     = $content[$locations[$idx]]
            Content  = $content[$startBlock..$endBlock] -join "`n"
        }
    }
}