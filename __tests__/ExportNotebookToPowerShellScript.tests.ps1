Import-Module $PSScriptRoot\..\PowerShellNotebook.psd1 -Force

Describe "Test Export-NotebookToPowerShellScript" {
    It "Should export the pynb to ps1" {
        $ipynbFileName = "$PSScriptRoot\MultiLineSourceNotebooks\MultiLineSourceAsArray.ipynb"
        Export-NotebookToPowerShellScript -FullName $ipynbFileName
        $targetPS = "./MultiLineSourceAsArray.ps1"

        Test-Path $targetPS | should be $true

        $actual = Get-Content $targetPS

        $actual.Count | should be 3
        $actual[0] | should be 'foreach ($item in 1..10) {'
        $actual[1] | should be '    $item'
        $actual[2] | should be '}'

        Remove-Item $targetPS -ErrorAction SilentlyContinue
    }
}