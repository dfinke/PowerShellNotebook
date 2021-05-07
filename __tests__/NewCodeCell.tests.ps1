Import-Module $PSScriptRoot\..\PowerShellNotebook.psd1 -Force

Describe "Test New-CodeCell" -Tag 'New-CodeCell' {
    BeforeAll {
        $vars = @'
$a=1
$b=3
'@

    }

    It "Should have New-CodeCell" {
        $actual = Get-Command New-CodeCell -ErrorAction SilentlyContinue
        $actual | Should -Not -Be  $Null
    }

    It "Test source" {
        $json = New-CodeCell -Source $vars

        $actual = $json | ConvertFrom-Json

        $actual.cell_type | Should -BeExactly "code"
        $actual.execution_count | Should -Be 0
        $actual.outputs | Should -Be $null
        $actual.metadata.tags | Should -Be "injected-parameters"
        $actual.source.count | Should -Be 2
             
        $actual.source[0].Trim() | Should -BeExactly '$a=1'
        $actual.source[1] | Should -BeExactly '$b=3'
    }

    It "Tests .net interactive metadata" {
        <#
{
    "cell_type": "code",
    "execution_count": 0,
    "metadata": {
                "dotnet_interactive": {
            "language": "pwsh"
          },
        "tags": [
        "injected-parameters"
        ]
    },
    "outputs": [],
    "source": [
  "$a=1",
  "$b=3"
]    
}    

#>        

        $json = New-CodeCell -Source $vars -DotNetInteractive
        $actual = $json | ConvertFrom-Json

        $actual.cell_type | Should -BeExactly "code"
        $actual.execution_count | Should -Be 0
        $actual.outputs | Should -Be $null
        
        $actual.metadata.psobject.properties.name.count | Should -Be 2
        $actual.metadata.psobject.properties.name[0] | Should -BeExactly 'dotnet_interactive'
        $actual.metadata.dotnet_interactive.language | Should -BeExactly 'pwsh'

        $actual.metadata.tags | Should -Be "injected-parameters"
        $actual.source.count | Should -Be 2
             
        $actual.source[0].Trim() | Should -BeExactly '$a=1'
        $actual.source[1] | Should -BeExactly '$b=3'
    }
}