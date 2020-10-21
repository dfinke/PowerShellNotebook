Import-Module $PSScriptRoot\..\PowerShellNotebook.psd1 -Force

Describe "Test Export-AsPowerShellNotebook" -Tag Export-AsPowerShellNotebook {
    It "Test throw if OutputNotebook not specified" {
        $s = "get-process *micro* | select -first 5" 
        
        { $s | Export-AsPowerShellNotebook -OutputNotebook $outputNotebook } |  Should -Throw '$OutputNotebook not specified'
    }

    It "Test create notebook from strings of PS code" {
        $outputNotebook = "TestDrive:\test.ipynb"

        $(
            "# get-process"
            "get-process *micro* | select -first 5"
            "# get-service"
            "get-service | select -first 5"
        ) | Export-AsPowerShellNotebook -OutputNotebook $outputNotebook

        Test-Path $outputNotebook | Should -BeTrue

        $actual = Get-NotebookContent -NoteBookFullName $outputNotebook 
        
        $actual.Count | Should -Be 4
        
        $actual[0].Type | Should -BeExactly 'markdown'
        $actual[0].Source | Should -BeExactly '# get-process'

        $actual[1].Type | Should -BeExactly 'code'
        $actual[1].Source | Should -BeExactly 'get-process *micro* | select -first 5'

        $actual[2].Type | Should -BeExactly 'markdown'
        $actual[2].Source | Should -BeExactly '# get-service'
        $actual[3].Type | Should -BeExactly 'code'
        $actual[3].Source | Should -BeExactly 'get-service | select -first 5'
    }

    It "Test for no text piped to function" -Skip {
        $outputNotebook = "TestDrive:\test.ipynb"

        $(
            ''
        ) | Export-AsPowerShellNotebook -OutputNotebook $outputNotebook

        Test-Path $outputNotebook | Should -BeFalse

        # $actual = Get-NotebookContent -NoteBookFullName $outputNotebook 
        
        # $actual.Count | Should -Be 4
        
        # $actual[0].Type | Should -BeExactly 'markdown'
        # $actual[0].Source | Should -BeExactly '# get-process'

        # $actual[1].Type | Should -BeExactly 'code'
        # $actual[1].Source | Should -BeExactly 'get-process *micro* | select -first 5'

        # $actual[2].Type | Should -BeExactly 'markdown'
        # $actual[2].Source | Should -BeExactly '# get-service'
        # $actual[3].Type | Should -BeExactly 'code'
        # $actual[3].Source | Should -BeExactly 'get-service | select -first 5'
    }
}