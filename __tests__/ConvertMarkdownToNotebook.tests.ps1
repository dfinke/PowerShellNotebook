Import-Module $PSScriptRoot\..\PowerShellNotebook.psd1 -Force
$script:expectedPSNBFilename = "$PSScriptRoot\samplemarkdown\demo.ipynb"

Describe "Test Convert-MarkdownToPowerShellNoteBook" {
    BeforeEach {
        Remove-Item $script:expectedPSNBFilename -ErrorAction SilentlyContinue
    }

    AfterAll {
        Remove-Item $script:expectedPSNBFilename -ErrorAction SilentlyContinue
    }

    It "Should create a PSNotebookRunspace " {
        $actual = New-PSNotebookRunspace

        $actual | Should -Not -Be  $null
        $actual.GetType().Name | Should -Be 'PSNotebookRunspace'
    }

    It "Should return this after Invoke" {
        $obj = New-PSNotebookRunspace

        $actual = $obj.Invoke("1+1")

        $actual | Should -Be 2
    }

    It "Should create a notebook file" {
        $sourceMD = "$PSScriptRoot\samplemarkdown\demo.md"
        Convert-MarkdownToNoteBook -filename $sourceMD
        (Test-Path $script:expectedPSNBFilename) | Should -Be $true
    }

    It "Check the PS NB content" {
        $sourceMD = "$PSScriptRoot\samplemarkdown\demo.md"
        Convert-MarkdownToNoteBook -filename $sourceMD
        (Test-Path $script:expectedPSNBFilename) | Should -Be $true

        $psnb = Get-Content $script:expectedPSNBFilename | ConvertFrom-Json

        $psnb.cells.count | Should -Be 4

        $psnb.cells[0].cell_type | Should -Be markdown
        $psnb.cells[0].source | Should -Beexactly '# Chapter 1'

        $psnb.cells[1].cell_type | Should -Be markdown
        $psnb.cells[1].source.trim() | Should -Beexactly 'This is `addition`'

        $psnb.cells[2].cell_type | Should -Be code
        $psnb.cells[2].source.trim() | Should -Beexactly "5 + 7"
        $psnb.cells[2].outputs.text.trim() | Should -Beexactly "12"

        $psnb.cells[3].cell_type | Should -Be markdown
    }

    It "Check the PowerShell fence block NB content" {
        $sourceMD = "$PSScriptRoot\samplemarkdown\demoPowerShellFenceBlock.md"
        $nbFile = "$PSScriptRoot\samplemarkdown\demoPowerShellFenceBlock.ipynb"

        Convert-MarkdownToNoteBook -filename $sourceMD

        (Test-Path $nbFile) | Should -Be $true

        $psnb = Get-Content $nbFile | ConvertFrom-Json

        $psnb.cells.count | Should -Be 4

        $psnb.cells[0].cell_type | Should -Be markdown
        $psnb.cells[0].source | Should -Beexactly '# Chapter 1'

        $psnb.cells[1].cell_type | Should -Be markdown
        $psnb.cells[1].source.trim() | Should -Beexactly 'This is `addition`'

        $psnb.cells[2].cell_type | Should -Be code
        $psnb.cells[2].source.trim() | Should -Beexactly "40 + 2"
        $psnb.cells[2].outputs.text.trim() | Should -Beexactly "42"

        $psnb.cells[3].cell_type | Should -Be markdown
        Remove-Item $nbFile -ErrorAction SilentlyContinue
    }

    It "Should exclude results from PowerShell Notebook" {
        $sourceMD = "$PSScriptRoot\samplemarkdown\excludeResults.md"
        Convert-MarkdownToNoteBook -filename $sourceMD
        $expectedOutFileName = "$PSScriptRoot\samplemarkdown\excludeResults.ipynb"

        (Test-Path $expectedOutFileName) | Should -Be $true

        $psnb = Get-Content $expectedOutFileName | ConvertFrom-Json

        $codeBlocks = $psnb.cells | Where-Object { $_.cell_type -eq 'code' }
        $codeBlocks.count | Should -Be 3

        $codeBlocks[0].outputs.text.length | Should -Be 0
        $codeBlocks[1].outputs.text.length | Should -Be 0

        if ($PSVersionTable.Platform -eq 'Unix') {
            $codeBlocks[2].outputs.text.length | Should -Be 2
        }
        else {
            $codeBlocks[2].outputs.text.length | Should -Be 3
        }

        Remove-Item $expectedOutFileName -Force -ErrorAction SilentlyContinue
    }

    It "Should convert more than one chapter" {
        $sourceMD = "$PSScriptRoot\MultipleChapters\MultipleChapters.md"

        Convert-MarkdownToNoteBook -filename $sourceMD

        $expectedOutFileName = "$PSScriptRoot\MultipleChapters\MultipleChapters.ipynb"

        (Test-Path $expectedOutFileName) | Should -Be $true

        $psnb = Get-Content $expectedOutFileName | ConvertFrom-Json

        $markdownBlocks = $psnb.cells | Where-Object { $_.cell_type -eq 'markdown' }
        $markdownBlocks.count | Should -Be 5

        $markdownBlocks[0].source | Should -Be "# Chapter 1"
        $markdownBlocks[2].source | Should -Be "# SUMMARY`r`n"
        $markdownBlocks[3].source | Should -Be "# Chapter 2"

        $result = $markdownBlocks[4].source -notmatch "^# SUMMARY"
        $result | Should -Be $true

        Remove-Item $expectedOutFileName -Force -ErrorAction SilentlyContinue
    }
}