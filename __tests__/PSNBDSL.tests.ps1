Import-Module $PSScriptRoot\..\PowerShellNotebook.psd1 -Force

Describe "Test Invoke PS Notebook" {

    It "Should have New-PSNotebook" {
        $actual = Get-Command New-PSNotebook -ErrorAction SilentlyContinue
        $actual | Should Not Be $Null
    }

    It "Should have Add-NotebookCode" {
        $actual = Get-Command Add-NotebookCode -ErrorAction SilentlyContinue
        $actual | Should Not Be $Null
    }

    It "Should have Add-NotebookMarkdown" {
        $actual = Get-Command Add-NotebookMarkdown -ErrorAction SilentlyContinue
        $actual | Should Not Be $Null
    }

    It "Should generate correct PowerShell notebook format" {
        $actualJson = New-PSNotebook -AsText {
            Add-NotebookCode "8+12"
            Add-NotebookCode "8+3"
            Add-NotebookMarkdown @'
## Math

- show addition
- show other

'@
        }

        $actual = $actualJson | ConvertFrom-Json
        $actual.cells.count | Should Be 3

        $actual.cells[0].source | Should BeExactly "8+12"
        $actual.cells[1].source | Should BeExactly "8+3"
        $actual.cells[2].source | Should BeExactly "## Math

- show addition
- show other
"
    }
}