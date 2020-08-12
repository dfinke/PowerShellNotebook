Import-Module $PSScriptRoot\..\PowerShellNotebook.psm1 -Force

Describe "Test ConvertTo-SQLNoteBook" {
    It "Should convert the file to an ipynb with a single code cell" {
        $demoTextFile = "$PSScriptRoot\DemoFiles\demo.sql"
        $fullName = "C:\temp\sqlTestConverted.ipynb"

        try{
            ConvertTo-SQLNoteBook -InputFileName $demoTextFile -OutputNotebookName $fullName
            { Test-Path $fullName } | Should Be $true

            $actual = Get-NotebookContent -NoteBookFullName $fullName
            $actual.Count | Should Be 1

            $actual = Get-NotebookContent -NoteBookFullName $fullName -JustCode

            $actual.Count | Should Be 1
            write-verbose "tests $($actual[0].Source)" -Verbose
            $actual[0].Source | Should -BeLike '*table3*'

            $actual = Get-NotebookContent -NoteBookFullName $fullName -JustMarkdown

            $actual.Count | Should Be 0
        }
        catch [System.Management.Automation.RuntimeException]{
            Write-Verbose "Runtime exception encountered" -Verbose
            Write-Verbose $_ -Verbose
            throw
        }
    }
    It "Should convert the file to an ipynb with 3 code and 6 text cells" {
        $demoTextFile = "$PSScriptRoot\DemoFiles\demo_w3GOs.sql"
        $fullName = "C:\temp\sqlTestConverted_demo_w3GOs.ipynb"

        try{
            ConvertTo-SQLNoteBook -InputFileName $demoTextFile -OutputNotebookName $fullName
            { Test-Path $fullName } | Should Be $true

            $actual = Get-NotebookContent -NoteBookFullName $fullName
            $actual.Count | Should Be 9

            $actual = Get-NotebookContent -NoteBookFullName $fullName -JustCode

            $actual.Count | Should Be 3
            write-verbose "tests $($actual[0].Source)" -Verbose
            $actual[0].Source | Should -BeLike '*table1*'
            $actual[1].Source | Should -BeLike '*table3*'

            $actual = Get-NotebookContent -NoteBookFullName $fullName -JustMarkdown

            $actual.Count | Should Be 6
            $actual[0].Source.Trim() | Should BeExactly 'GO'
            $actual[1].Source.Trim() | Should BeExactly 'Test1'
            $actual[2].Source.Trim() | Should -BeLike '*Multiline test*'
            $actual[3].Source.Trim() | Should BeExactly 'Test2'
            $actual[4].Source.Trim() | Should BeExactly 'GO'
            $actual[5].Source.Trim() | Should BeExactly 'Test3'
        }
        catch [System.Management.Automation.RuntimeException]{
            Write-Verbose "Runtime exception encountered" -Verbose
            Write-Verbose $_ -Verbose
            throw
        }
    }
}