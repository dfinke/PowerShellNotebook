function Test-Uri {
    param(
        $FullName
    )

    [System.Uri]::IsWellFormedUriString($FullName, [System.UriKind]::Absolute)
}