function New-CodeCell {
    param(
        [Parameter(Mandatory)]
        $Source
    )    
    @"
{
    "cell_type": "code",
    "execution_count": 0,
    "metadata": {
     "tags": [
      "new parameters"
     ]
    },
    "outputs": [],
    "source": $(@($source.split("`n")) | ConvertTo-Json)    
}
"@
}

function Invoke-ExecuteNotebook {
    param(
        $InputNotebook,
        $OutputNotebook,
        [hashtable]$Parameters
    )
}