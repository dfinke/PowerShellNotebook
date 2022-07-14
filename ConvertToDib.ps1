function ConvertTo-Dib {
    <#
        .Synopsis
    #>
    
    param(
        [Parameter(ValueFromPipelineByPropertyName)]
        $FullName
    )
    
    Process {
        if ($FullName.EndsWith('.ipynb')) {
            $dibName = $FullName.Replace('.ipynb', '.dib')
 
            foreach ($block in Get-NotebookContent $FullName) {
                $prefix = $null
                if ($block.Type -eq 'markdown') {
                    $prefix = "#!markdown`n"
                }
                
                $prefix + $block.Source | Add-Content $dibName -Encoding utf8
            }
        }
    } 
}