Import-Module $PSScriptRoot\..\PowerShellNotebook.psd1 -Force

Describe "Test Export-NotebookToPowerShellScript" {
    It "Should export the pynb to ps1" {
        $ipynbFileName = "$PSScriptRoot\MultiLineSourceNotebooks\MultiLineSourceAsArray.ipynb"
        Export-NotebookToPowerShellScript -FullName $ipynbFileName
        $targetPS = "./MultiLineSourceAsArray.ps1"

        Test-Path $targetPS | should be $true

        $actual = Get-Content $targetPS

        $actual.Count | should be 11

        $actual[7] | should be 'foreach ($item in 1..10) {'
        $actual[8] | should be '    $item'
        $actual[9] | should be '}'

        Remove-Item $targetPS -ErrorAction SilentlyContinue
    }
}