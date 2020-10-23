function Test-AzureBlobStorageUrl {
    param(
        $Url
    )

    $pattern = "abs://(.*)\.blob\.core\.windows\.net\/(.*)\/(.*)\?(.*)$"

    [regex]::Match($Url, $pattern).Success
}