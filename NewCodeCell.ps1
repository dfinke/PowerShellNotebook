function New-CodeCell {
    param(
        [Parameter(Mandatory)]
        $Source,
        [Switch]$DotNetInteractive
    )

    $DotNetInteractiveMetadata = ''
    if ($DotNetInteractive) {
        $DotNetInteractiveMetadata = @'
        "dotnet_interactive": {
            "language": "pwsh"
          },
'@        
    }

    $targetSource = @($source.split("`n")) | ConvertTo-Json

    $result = @"
{{
    "cell_type": "code",
    "execution_count": 0,
    "metadata": {{
        {0}
        "tags": [
        "injected-parameters"
        ]
    }},
    "outputs": [],
    "source": {1}
}}    
"@ -f $DotNetInteractiveMetadata, $targetSource

    $result
}