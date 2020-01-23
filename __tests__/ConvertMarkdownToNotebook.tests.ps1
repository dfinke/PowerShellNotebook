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

    It "Check the PowerShell fence block NB content" {
        $sourceMD = "$PSScriptRoot\samplemarkdown\demoPowerShellFenceBlock.md"
        $nbFile = "$PSScriptRoot\samplemarkdown\demoPowerShellFenceBlock.ipynb"

        Convert-MarkdownToNoteBook -filename $sourceMD

        (Test-Path $nbFile) | should be $true

        $psnb = Get-Content $nbFile | ConvertFrom-Json

        $psnb.cells.count | should be 4

        $psnb.cells[0].cell_type | should be markdown
        $psnb.cells[0].source | should beexactly '# Chapter 1'

        $psnb.cells[1].cell_type | should be markdown
        $psnb.cells[1].source.trim() | should beexactly 'This is `addition`'

        $psnb.cells[2].cell_type | should be code
        $psnb.cells[2].source.trim() | should beexactly "40 + 2"
        $psnb.cells[2].outputs.text.trim() | should beexactly "42"

        $psnb.cells[3].cell_type | should be markdown
        Remove-Item $nbFile -ErrorAction SilentlyContinue
    }

    It "Should exclude results from PowerShell Notebook" {
        $sourceMD = "$PSScriptRoot\samplemarkdown\excludeResults.md"
        Convert-MarkdownToNoteBook -filename $sourceMD
        $expectedOutFileName = "$PSScriptRoot\samplemarkdown\excludeResults.ipynb"

        (Test-Path $expectedOutFileName) | should be $true

        $psnb = Get-Content $expectedOutFileName | ConvertFrom-Json

        $codeBlocks = $psnb.cells | Where-Object { $_.cell_type -eq 'code' }
        $codeBlocks.count | should be 3

        $codeBlocks[0].outputs.text.length | should be 0
        $codeBlocks[1].outputs.text.length | should be 0
        $codeBlocks[2].outputs.text.length | should be 3

        Remove-Item $expectedOutFileName -Force -ErrorAction SilentlyContinue
    }

    It "Should convert more than one chapter" {
        $sourceMD = "$PSScriptRoot\MultipleChapters\MultipleChapters.md"

        Convert-MarkdownToNoteBook -filename $sourceMD

        $expectedOutFileName = "$PSScriptRoot\MultipleChapters\MultipleChapters.ipynb"

        (Test-Path $expectedOutFileName) | should be $true

        $psnb = Get-Content $expectedOutFileName | ConvertFrom-Json

        $markdownBlocks = $psnb.cells | Where-Object { $_.cell_type -eq 'markdown' }
        $markdownBlocks.count | should be 5

        $markdownBlocks[0].source | should be "# Chapter 1"
        $markdownBlocks[2].source | should be "# SUMMARY`r`n"
        $markdownBlocks[3].source | should be "# Chapter 2"

        $result = $markdownBlocks[4].source -notmatch "^# SUMMARY"
        $result | should be $true

        Remove-Item $expectedOutFileName -Force -ErrorAction SilentlyContinue
    }
}