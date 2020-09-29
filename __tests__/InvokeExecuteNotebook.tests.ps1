Import-Module $PSScriptRoot\..\PowerShellNotebook.psd1 -Force

Describe "Test Invoke Execute Notebook" -Tag 'Invoke-ExecuteNotebook' {

    It "Should have Invoke-ExecuteNotebook" {
        $actual = Get-Command Invoke-ExecuteNotebook -ErrorAction SilentlyContinue
        $actual | Should -Not -Be  $Null
    }

    It 'tests $Parameters takes a hashtable' {
        Invoke-ExecuteNotebook -Parmeters @{b = 2 }
    }

    It 'tests $P$arameters takes a an ordered hashtable' {
        Invoke-ExecuteNotebook -Parmeters ([ordered]@{ a = 1 })
    }

    It "Tests passing in a noteboook and get calculated results" {
        $InputNotebook = "$PSScriptRoot\NotebooksForUseWithInvokeOutfile\parameters.ipynb"        
        
        $actual = Invoke-ExecuteNotebook -InputNotebook $InputNotebook

        $actual[0].Trim() | Should -BeExactly 'alpha = 1.2, ratio = 3.7, and alpha * ratio = 4.44'
        $actual[1].Trim() | Should -BeExactly 'a = 1 and twice = 2'
    }

    It "Tests parameterization" {
        $InputNotebook = "$PSScriptRoot\NotebooksForUseWithInvokeOutfile\parameters.ipynb"        
        
        $params = @{
            alpha = 4
            ratio = 4
            a     = 15
        }

        $actual = Invoke-ExecuteNotebook -InputNotebook $InputNotebook -Parameters $params

        $actual[0].Trim() | Should -BeExactly 'alpha = 4, ratio = 4, and alpha * ratio = 16'
        $actual[1].Trim() | Should -BeExactly 'a = 15 and twice = 30'

    }

    It "Tests parameterization with no cells as parameters" {
        $InputNotebook = "$PSScriptRoot\NotebooksForUseWithInvokeOutfile\NotebookNoParameterCells.ipynb"        
        
        $params = @{msg = "Hello from parameters" }

        $actual = Invoke-ExecuteNotebook -InputNotebook $InputNotebook -Parameters $params

        $actual[0].Trim() | Should -BeExactly 'Hello from parameters'
        $actual[1].Trim() | Should -BeExactly "The length of 'Hello from parameters' is 21"
    }

    It "Tests parameterization with mutiple cells as parameters" {
        $InputNotebook = "$PSScriptRoot\NotebooksForUseWithInvokeOutfile\NotebookMoreThanOneParameterCell.ipynb"        
        
        $params = @{msg = "Hello from parameters" }

        $actual = Invoke-ExecuteNotebook -InputNotebook $InputNotebook -Parameters $params

        $actual[0].Trim() | Should -BeExactly 'Hello World'
        $actual[1].Trim() | Should -BeExactly 'Hello from parameters'
        $actual[2].Trim() | Should -BeExactly 'Goodbye'
    }

    It "Tests create new notebook using OutputNotebook" {
        $InputNotebook = "$PSScriptRoot\NotebooksForUseWithInvokeOutfile\parameters.ipynb"        
        $OutputNotebook = "TestDrive:\newParameters.ipynb"
        
        Invoke-ExecuteNotebook -InputNotebook $InputNotebook -OutputNotebook $OutputNotebook

        Test-Path $OutputNotebook | Should -Be $true

        $data = Get-Content $OutputNotebook | ConvertFrom-Json
        $codeCells = $data.cells | Where-Object { $_.cell_type -eq 'code' }

        $codeCells[1].outputs.text.trim() | should -be 'alpha = 1.2, ratio = 3.7, and alpha * ratio = 4.44'
        $codeCells[3].outputs.text.trim() | should -be 'a = 1 and twice = 2'

        $codeCells.count | should -be 4
        
        Remove-Item $OutputNotebook -ErrorAction SilentlyContinue
    }
    
    It "Tests create new notebook that already exists" {
        $InputNotebook = "$PSScriptRoot\NotebooksForUseWithInvokeOutfile\parameters.ipynb"        
        $OutputNotebook = "TestDrive:\newParameters.ipynb"
        
        "" > $OutputNotebook

        { Invoke-ExecuteNotebook -InputNotebook $InputNotebook -OutputNotebook $OutputNotebook } | Should -Throw "TestDrive:\newParameters.ipynb already exists"
        
        Remove-Item $OutputNotebook -ErrorAction SilentlyContinue
    }

    It "Tests Find-ParameterizedCell" {
        (Find-ParameterizedCell -InputNotebook "$PSScriptRoot\NotebooksForUseWithInvokeOutfile\NotebookNoParameterCells.ipynb").Count | Should -Be 0
        (Find-ParameterizedCell -InputNotebook "$PSScriptRoot\NotebooksForUseWithInvokeOutfile\parameters.ipynb").Count | Should -Be 1
        (Find-ParameterizedCell -InputNotebook "$PSScriptRoot\NotebooksForUseWithInvokeOutfile\NotebookMoreThanOneParameterCell.ipynb").Count | Should -Be 2
    }

    It "Tests Get-ParameterInsertionIndex" {
        Get-ParameterInsertionIndex -InputNotebook "$PSScriptRoot\NotebooksForUseWithInvokeOutfile\NotebookNoParameterCells.ipynb" | Should -Be 0
        Get-ParameterInsertionIndex -InputNotebook "$PSScriptRoot\NotebooksForUseWithInvokeOutfile\parameters.ipynb" | Should -Be 1
        Get-ParameterInsertionIndex -InputNotebook "$PSScriptRoot\NotebooksForUseWithInvokeOutfile\NotebookMoreThanOneParameterCell.ipynb" | Should -Be 3
    }

    It "Tests notebook returns the correct data with `outputs` having an empty array" {
        # This notebook has a cell and the `outputs` property is an empty array
        # Invoke-ExecuteNotebook will handle that
        $InputNotebook = "$PSScriptRoot\NotebooksForUseWithInvokeOutfile\testFile1.ipynb" 

        $actual = Invoke-ExecuteNotebook -InputNotebook $InputNotebook 
        $actual.Trim() | Should -BeExactly "Hello World"
    }

    It "Tests handling a cell with errors" {
        
        $InputNotebook = "$PSScriptRoot\NotebooksForUseWithInvokeOutfile\CellHasAnError.ipynb"
        
        $actual = Invoke-ExecuteNotebook -InputNotebook $InputNotebook

        $expected = "[91mRuntimeException: [91mAttempted to divide by zero.[0m"        
             
        $actual.Trim() | Should -BeExactly $expected
    }

    It "Tests reading from a URL" {
        $url = 'https://raw.githubusercontent.com/dfinke/PowerShellNotebook/master/__tests__/NotebooksForUseWithInvokeOutfile/testFile1.ipynb'
 
        $actual = Invoke-ExecuteNotebook -InputNotebook $url

        $actual.Trim() | Should -Be "Hello World"
    }
}