Import-Module $PSScriptRoot\..\PowerShellNotebook.psd1 -Force

Describe "Test PS Notebooks" {

    It "Should have Get-Notebook" {
        $actual = Get-Command Get-Notebook -ErrorAction SilentlyContinue
        $actual | Should -Not -Be  $Null
    }

    It "Should find no notebooks" -Skip {
        $actual = Get-Notebook
        $actual.Count | Should -Be 0
    }

    It "Should find no notebooks in specified directory" {
        $actual = Get-Notebook $PSScriptRoot\NoNotebooks
        $actual.Count | Should -Be 0
    }

    It "Should find one notebook in specified directory" {
        $actual = @(Get-Notebook "$PSScriptRoot\OneNotebook")
        $actual.Count | Should -Be 1
    }

    It "Should find notebooks in specified directory" {
        $actual = @(Get-Notebook "$PSScriptRoot\GoodNotebooks")
        $actual.Count | Should -Be 6
    }

    It "Should find a notebook by name in specified directory" {
        $actual = @(Get-Notebook "$PSScriptRoot\GoodNotebooks" testpsnb1*)
        $actual.Count | Should -Be 1
    }

    It "Should find a notebook by name in specified directory" {
        $actual = @(Get-Notebook "$PSScriptRoot\GoodNotebooks" testpsnb1*)
        $actual.Count | Should -Be 1
    }

    It "Should find notebook testpsnb1.ipynb and get metadata content" {
        $actual = @(Get-Notebook "$PSScriptRoot\GoodNotebooks" testpsnb1*)

        $actual.Count | Should -Be 1

        <#
            NoteBookName     : testPSNb1.ipynb
            KernelName       : powershell
            CodeBlocks       : 2
            MarkdownBlocks   : 1
            NoteBookFullName : C:\Users\Douglas\Documents\GitHub\MyPrivateGit\PowerShellNotebook\__tests__\GoodNotebooks\testPSNb1.ipynb
        #>

        $actual.NoteBookName | Should -Be "testPSNb1.ipynb"
        $actual.KernelName | Should -Be "powershell"
        $actual.CodeBlocks | Should -Be 2
        $actual.MarkdownBlocks | Should -Be 1
    }

}