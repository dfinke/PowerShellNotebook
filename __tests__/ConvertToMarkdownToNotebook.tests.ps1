Import-Module $PSScriptRoot\..\PowerShellNotebook.psd1 -Force
$expectedPSNBFilename = "$PSScriptRoot\samplemarkdown\demo.ipynb"

Describe "Test Convert-MarkdownToPowerShellNoteBook" {
    BeforeEach {
        Remove-Item $expectedPSNBFilename -ErrorAction SilentlyContinue
    }

    AfterAll {
        Remove-Item $expectedPSNBFilename -ErrorAction SilentlyContinue
    }

    It "Should create a PSNotebookRunspace " {
        $actual = New-PSNotebookRunspace

        $actual | should not be $null
        $actual.GetType().Name | should be 'PSNotebookRunspace'
    }

    It "Should return this after Invoke" {
        $obj = New-PSNotebookRunspace

        $actual = $obj.Invoke("1+1")

        $actual | should be 2
    }

    It "Should create a notebook file" {
        $sourceMD = "$PSScriptRoot\samplemarkdown\demo.md"
        Convert-MarkdownToNoteBook -filename $sourceMD
        (Test-Path $expectedPSNBFilename) | should be $true
    }

    It "Check the PS NB content" {
        $sourceMD = "$PSScriptRoot\samplemarkdown\demo.md"
        Convert-MarkdownToNoteBook -filename $sourceMD
        (Test-Path $expectedPSNBFilename) | should be $true

        $psnb = Get-Content $expectedPSNBFilename | ConvertFrom-Json

        $psnb.cells.count | should be 4

        $psnb.cells[0].cell_type | should be markdown
        $psnb.cells[0].source | should beexactly '# Chapter 1'

        $psnb.cells[1].cell_type | should be markdown
        $psnb.cells[1].source.trim() | should beexactly 'This is `addition`'

        $psnb.cells[2].cell_type | should be code
        $psnb.cells[2].source.trim() | should beexactly "5 + 7"
        $psnb.cells[2].outputs.text.trim() | should beexactly "12"

        $psnb.cells[3].cell_type | should be markdown
    }
}