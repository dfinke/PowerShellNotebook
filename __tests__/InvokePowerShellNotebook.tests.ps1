Import-Module $PSScriptRoot\..\PowerShellNotebook.psd1 -Force

Describe "Test Invoke PS Notebook" {

    It "Should have Invoke-PowerShellNotebook" {
        $actual = Get-Command Invoke-PowerShellNotebook -ErrorAction SilentlyContinue
        $actual | Should Not Be $Null
    }

    It "Should have these results from the Invoke-PowerShellNotebook" {
        $actual = Invoke-PowerShellNotebook "$PSScriptRoot\GoodNotebooks\testPSNb1.ipynb"

        $actual | Should Not Be $Null

        $actual.Count | Should Be 2

        $actual[0] | Should Be 20
        $actual[1] | Should Be 11
    }

}