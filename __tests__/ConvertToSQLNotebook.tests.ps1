Import-Module $PSScriptRoot\..\PowerShellNotebook.psm1 -Force

Describe "Test ConvertTo-SQLNoteBook" {
    It "Should convert the file to an ipynb" {
        $demoTextFile = "$PSScriptRoot\DemoFiles\demo.sql"
        $fullName = "C:\temp\sqlTestConverted.ipnyb"

        try{
            ConvertTo-SQLNoteBook -InputFileName $demoTextFile -OutputNotebookName $fullName
            { Test-Pat $fullName } | Should Be $true

            $actual = Get-NotebookContent -NoteBookFullName $fullName
            $actual.Count | Should Be 7

            $actual = Get-NotebookContent -NoteBookFullName $fullName -JustCode

            $actual.Count | Should Be 3
            write-verbose "tests $($actual[0].Source)" -Verbose
            $actual[0].Source | Should -BeLike '*table1*'
            $actual[1].Source | Should -BeLike '*table3*'

            $actual = Get-NotebookContent -NoteBookFullName $fullName -JustMarkdown

            $actual.Count | Should Be 4
            $actual[0].Source.Trim() | Should BeExactly 'Test1'
            $actual[1].Source.Trim() | Should -BeLike '*Multiline test*'
            $actual[2].Source.Trim() | Should BeExactly 'Test2'
            $actual[3].Source.Trim() | Should BeExactly 'Test3'
        }
        catch [System.Management.Automation.RuntimeException]{
            Write-Verbose "Runtime exception encountered" -Verbose
            Write-Verbose $_ -Verbose
            throw
        }
    }
}