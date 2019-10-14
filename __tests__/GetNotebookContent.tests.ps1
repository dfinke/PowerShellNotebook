Import-Module $PSScriptRoot\..\PowerShellNotebook.psd1 -Force

Describe "Test PS Notebook Content" {

    It "Should have Get-NotebookContent" {
        $actual = Get-Command Get-NotebookContent -ErrorAction SilentlyContinue
        $actual | Should Not Be $Null
    }
}