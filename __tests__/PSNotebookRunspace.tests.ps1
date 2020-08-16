Import-Module $PSScriptRoot\..\PowerShellNotebook.psd1 -Force

Describe "PSNotebookRunspace tests" {
    BeforeEach {
        $psrs = New-PSNotebookRunspace
    }

    It "Should -Not -Be  null" {
        $psrs | Should -Not -Be  $null
    }

    It "Should -Be 42" {
        $code = '10+32'
        $actual = $psrs.Invoke($code)
        $expected = 42

        $actual | Should -Be $expected
    }

    It "Should also be 42" {
        $null = $psrs.Invoke('$x = 10')
        $null = $psrs.Invoke('$y = 32')
        $null = $psrs.Invoke('$total = $x + $y')
        $actual = $psrs.Invoke('$total')
        $expected = 42

        $actual | Should -Be $expected
    }

    It "Should create the correct book and results" {
        $json = New-PSNotebook -AsText -IncludeCodeResults {
            Add-NotebookCode -code '10+2'
        }

        $obj = $json | ConvertFrom-Json
        $obj.Cells.outputs.text.Trim() -eq 12
    }
}