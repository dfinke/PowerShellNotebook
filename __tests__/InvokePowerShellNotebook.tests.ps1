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

    It "Should have these results from the testPSExcel.ipynb" {
        $actual = Invoke-PowerShellNotebook "$PSScriptRoot\GoodNotebooks\testPSExcel.ipynb"

        $actual.Count | Should Be 3

        # Returns results from get-service
        $propertyNames = $actual[0][0].psobject.Properties.name
        $propertyNames[0] | Should Be 'Status'
        $propertyNames[1] | Should Be 'Name'
        $propertyNames[2] | Should Be 'DisplayName'

        # Returns results from get-process
        $propertyNames = $actual[1][0].psobject.Properties.name
        $propertyNames[0] | Should Be 'Company'
        $propertyNames[1] | Should Be 'Name'
        $propertyNames[2] | Should Be 'Handles'

        # Returns results from an array
        $actual[2].Count | Should Be 10
    }

}