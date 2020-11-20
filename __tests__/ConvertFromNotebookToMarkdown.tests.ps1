Import-Module $PSScriptRoot\..\PowerShellNotebook.psd1 -Force

Describe "Test ConvertFrom-NoteBookToMarkdown" {
    It "Should convert to markdown" {
        $targetFile = "$PSScriptRoot\GoodNotebooks\SimpleNotebookToTestConvertToMarkdown.ipynb"

        $actual = ConvertFrom-NoteBookToMarkdown -NotebookName $targetFile -AsText

        $actual.Count | Should -Be 3

        $actual[0].trim() | Should -Beexactly '# Test for converting a PS Notebook to Markdown'
        $actual[2].trim() | Should -Beexactly '## End of PS Notebook'

        ($actual[1]).StartsWith('```powershell') | Should -Be $true
        ($actual[1]).Trim().EndsWith('```') | Should -Be $true
    }

    It "Should convert to markdown in a file" {
        $targetFile = "$PSScriptRoot\GoodNotebooks\SimpleNotebookToTestConvertToMarkdown.ipynb"
        $mdFile = "$PSScriptRoot\GoodNotebooks\SimpleNotebookToTestConvertToMarkdown.md"
        $expected = Split-Path $mdFile -Leaf

        $actual = ConvertFrom-NoteBookToMarkdown -NotebookName $targetFile

        $actual | Should -Beexactly $expected

        Remove-Item $expected -ErrorAction SilentlyContinue
    }
    
    It "Should remove the #!pwsh shebang in code blocks" {
        $targetFile = "$PSScriptRoot\DotNetInteractiveNotebooks\PwshShebangTest.ipynb"

        $actual = ConvertFrom-NotebookToMarkdown -NotebookName $targetFile -AsText

        $powerShellCodeBlock = $actual[1]
        
        $powerShellCodeBlock.Split([System.Environment]::NewLine) | Should -Not -Contain "#!pwsh"
    }
    
    It "Should not remove the #!pwsh shebang in markdown blocks" {
        $targetFile = "$PSScriptRoot\DotNetInteractiveNotebooks\PwshShebangTest.ipynb"

        $actual = ConvertFrom-NotebookToMarkdown -NotebookName $targetFile -AsText

        $markDownBlock = $actual[2]
        
        $markDownBlock.Split([System.Environment]::NewLine) | Should -Contain "#!pwsh"
    }
}