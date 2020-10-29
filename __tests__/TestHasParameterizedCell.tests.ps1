Import-Module $PSScriptRoot\..\PowerShellNotebook.psd1 -Force

Describe "Test Test-HasParameterizedCell" -Tag 'Test-HasParameterizedCell' {
    
    It "Should have Test-HasParameterizedCell" {
        $actual = Get-Command Test-HasParameterizedCell -ErrorAction SilentlyContinue
        $actual | Should -Not -Be  $Null
    }

    It "Tests notebook has a parmeterized cell" {

        $actual = Test-HasParameterizedCell "$PSScriptRoot\NotebooksForUseWithInvokeOutfile\parameters.ipynb" 

        split-path -Leaf $actual.Path | Should -BeExactly 'parameters.ipynb'
        $actual.HasParameterizedCell | Should -BeTrue
    }

    It "Tests notebook has a parmeterized cell via pipeline" {
        $actual = Get-ChildItem "$PSScriptRoot\NotebooksForUseWithInvokeOutfile" *.ipynb | Test-HasParameterizedCell       
        
        $HasParameterizedCell = $actual | Where-Object { $_.HasParameterizedCell -eq $true }
        $DoesNotHaveParameterizedCell = $actual | Where-Object { $_.HasParameterizedCell -eq $false }
        
        # $HasParameterizedCell | Out-Host
        # $DoesNotHaveParameterizedCell | Out-Host

        $HasParameterizedCell.Count | Should -Be 3
       
        (Split-Path -Leaf $HasParameterizedCell[0].Path) | Should -BeExactly 'Hello-PowerShell.ipynb' 
        (Split-Path -Leaf $HasParameterizedCell[1].Path) | Should -BeExactly 'NotebookMoreThanOneParameterCell.ipynb' 
        (Split-Path -Leaf $HasParameterizedCell[2].Path) | Should -BeExactly 'parameters.ipynb' 

        (Split-Path -Leaf $DoesNotHaveParameterizedCell[0].Path) | Should -BeExactly 'CellHasAnError.ipynb' 
        (Split-Path -Leaf $DoesNotHaveParameterizedCell[1].Path) | Should -BeExactly 'ComboGoodAndErrorCells.ipynb' 
        (Split-Path -Leaf $DoesNotHaveParameterizedCell[2].Path) | Should -BeExactly 'NotebookNoParameterCells.ipynb' 
        (Split-Path -Leaf $DoesNotHaveParameterizedCell[3].Path) | Should -BeExactly 'testFile1.ipynb' 
        (Split-Path -Leaf $DoesNotHaveParameterizedCell[4].Path) | Should -BeExactly 'VariablesAcrossCells.ipynb' 
    }
}