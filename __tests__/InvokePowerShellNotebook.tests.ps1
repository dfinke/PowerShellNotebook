#Import-Module $PSScriptRoot\..\PowerShellNotebook.psd1 -Force

Describe "Test Invoke PS Notebook" {

    It "Should have Invoke-PowerShellNotebook" {
        $actual = Get-Command Invoke-PowerShellNotebook -ErrorAction SilentlyContinue
        $actual | Should -Not -Be  $Null
    }

    It "Should have these results from the Invoke-PowerShellNotebook" {
        $actual = Invoke-PowerShellNotebook "$PSScriptRoot\GoodNotebooks\testPSNb1.ipynb"

        $actual | Should -Not -Be  $Null

        $actual.Count | Should -Be 2

        $actual[0] | Should -Be 20
        $actual[1] | Should -Be 11
    }

    It "Should have these results from the testPSExcel.ipynb" {
        $actual = Invoke-PowerShellNotebook "$PSScriptRoot\GoodNotebooks\testPSExcel.ipynb"
    
        $actual.Count | Should -Be 3

        # # Returns results from get-service
        # $propertyNames = $actual[0][0].psobject.Properties.name
        # $propertyNames[0] | Should -Be 'Status'
        # $propertyNames[1] | Should -Be 'Name'
        # $propertyNames[2] | Should -Be 'DisplayName'

        # Returns results from get-process
        $propertyNames = $actual[1][0].psobject.Properties.name
        $propertyNames[0] | Should -Be 'Company'
        $propertyNames[1] | Should -Be 'Name'
        $propertyNames[2] | Should -Be 'Handles'

        # Returns results from an array
        $actual[2].Count | Should -Be 10
    }

    It "Should create and Excel file" {
        $actual = Invoke-PowerShellNotebook "$PSScriptRoot\GoodNotebooks\testPSExcel.ipynb" -AsExcel

        $actualPath = Split-Path $actual
        $expectedPath = $pwd.path

        $actualPath | Should -Be $expectedPath

        $actualExcelFileName = Split-Path $actual -Leaf
        $expectedExcelFileName = "testPSExcel.xlsx"

        $actualExcelFileName | Should -Be $expectedExcelFileName

        Remove-Item $actual #-ErrorAction SilentlyContinue
    }

    It "Should export to an Excel file to cwd from the testPSExcel.ipynb" {
        $actual = Invoke-PowerShellNotebook "$PSScriptRoot\GoodNotebooks\testPSExcel.ipynb" -AsExcel
        # $actual | Should -Be "$PSScriptRoot\testPSExcel.xlsx"
        $actualExcelFileName = Split-Path $actual -Leaf
        $expectedExcelFileName = "testPSExcel.xlsx"
        $actualExcelFileName | Should -Be $expectedExcelFileName

        $sheets = Get-ExcelSheetInfo $actual

        $sheets.Count | Should -Be 2

        $sheets[0].Name | Should -Be 'Sheet1'
        $sheets[1].Name | Should -Be 'Sheet2'


        Remove-Item $actual -ErrorAction SilentlyContinue
    }

    It "Should read and execute a single code block" {
        $actual = @(Invoke-PowerShellNotebook "$PSScriptRoot\GoodNotebooks\SingleCodeBlock.ipynb")

        $actual.Count | Should -Be 1

        $record = $actual[0]
        $record[0].Region | Should -BeExactly "South"
        $record[0].Item | Should -BeExactly "lime"
        $record[0].TotalSold | Should -Be 20

        $record[1].Region | Should -BeExactly "West"
        $record[1].Item | Should -BeExactly "melon"
        $record[1].TotalSold | Should -Be 76
    }

    It "Should read and execute a code block stored as a string" {
        $actual = @(Invoke-PowerShellNotebook "$PSScriptRoot\MultiLineSourceNotebooks\MultiLineSourceAsString.ipynb")

        $actual[0][0] | Should -Be 1
        $actual[0][9] | Should -Be 10
    }

    It "Should read and execute a code block stored as an array" {
        $actual = @(Invoke-PowerShellNotebook "$PSScriptRoot\MultiLineSourceNotebooks\MultiLineSourceAsArray.ipynb")

        $actual[0][0] | Should -Be 1
        $actual[0][9] | Should -Be 10
    }
}