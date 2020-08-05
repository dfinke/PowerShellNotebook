Import-Module $PSScriptRoot\..\PowerShellNotebook.psd1 -Force

Describe "Test ConvertFrom-NoteBookToMarkdown" {
    It "Should be true" {
        $false | Should -Be $true
    }

    It "Should convert to markdown" {
        $targetFile = "$PSScriptRoot\GoodNotebooks\SimpleNotebookToTestConvertToMarkdown.ipynb"

        $actual = ConvertFrom-NoteBookToMarkdown -NotebookName $targetFile -AsText

        $actual.Count | should be 3

        $actual[0].trim() | should beexactly '# Test for converting a PS Notebook to Markdown'
        $actual[2].trim() | should beexactly '## End of PS Notebook'

        ($actual[1]).StartsWith('```powershell') | should be $true
        ($actual[1]).Trim().EndsWith('```') | should be $true
    }

    It "Should convert to markdown in a file" {
        $targetFile = "$PSScriptRoot\GoodNotebooks\SimpleNotebookToTestConvertToMarkdown.ipynb"
        $mdFile = "$PSScriptRoot\GoodNotebooks\SimpleNotebookToTestConvertToMarkdown.md"
        $expected = Split-Path $mdFile -Leaf

        $actual = ConvertFrom-NoteBookToMarkdown -NotebookName $targetFile

        $actual | should beexactly $expected

        Remove-Item $expected -ErrorAction SilentlyContinue
    }
}