function Get-ParameterInsertionIndex {
    param(
        [Parameter(Mandatory)]
        $InputNotebook
    )

    $cell = Find-ParameterizedCell $InputNotebook | Select-Object -First 1
    if ([string]::IsNullOrEmpty($cell)) {
        return 0
    }
    $cell + 1
}