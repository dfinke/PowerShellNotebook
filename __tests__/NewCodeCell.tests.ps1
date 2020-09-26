Import-Module $PSScriptRoot\..\PowerShellNotebook.psd1 -Force

Describe "Test New-CodeCell" -Tag 'New-CodeCell' {
    It "Should have New-CodeCell" {
        $actual = Get-Command New-CodeCell -ErrorAction SilentlyContinue
        $actual | Should -Not -Be  $Null
    }

    It "Test source" {
        $vars = @'
$a=1
$b=3
'@
        $json = New-CodeCell -Source $vars

        $actual = $json | ConvertFrom-Json

        $actual.cell_type | Should -BeExactly "code"
        $actual.execution_count | Should -Be 0
        $actual.outputs | Should -Be $null
        $actual.metadata.tags | Should -Be "new parameters"
        $actual.source.count | Should -Be 2
        
        $actual.source[0] | Should -BeExactly "`$a=1`r"
        $actual.source[1] | Should -BeExactly '$b=3'
    }
}