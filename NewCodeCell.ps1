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