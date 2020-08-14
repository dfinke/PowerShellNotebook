Import-Module $PSScriptRoot\..\PowerShellNotebook.psm1 -Force

Describe "Test ConvertTo-SQLNoteBook" {
    It "Should convert the file to an ipynb with a single code cell" {
        $demoTextFile = "$PSScriptRoot\DemoFiles\demo.sql"
        $fullName = "TestDrive:\sqlTestConverted.ipynb"

        try{
            ConvertTo-SQLNoteBook -InputFileName $demoTextFile -OutputNotebookName $fullName
            { Test-Path $fullName } | Should Be $true

            $actual = Get-NotebookContent -NoteBookFullName $fullName

            @($actual).Count | Should -Be 1

            $actual = Get-NotebookContent -NoteBookFullName $fullName -JustMarkdown

            $actual.Count | Should -Be 0

            $actual = Get-NotebookContent -NoteBookFullName $fullName -JustCode

            @($actual).Count | Should -Be 1

            write-verbose "tests $($actual[0].Source)" -Verbose
            $actual[0].Source | Should -BeLike '*table3*'
            $actual[0].Source | Should -BeExactly 'select DateDiff(MI,StartDate,EndDate) AS Timetaken,* FROM table1
SELECT * FROM table2 WHERE id = 1
/* Test1 */
/* Multiline test
1
2
*/
/* Test2 */
SELECT * FROM table3 where ID = 7
/* Test3 */
SELECT * FROM table4 where ID = 8'
        }
        catch [System.Management.Automation.RuntimeException]{
            Write-Verbose "Runtime exception encountered" -Verbose
            Write-Verbose $_ -Verbose
            throw
        }
    }
    It "Should convert the file to an ipynb with 3 code and 6 text cells" {
        $demoTextFile = "$PSScriptRoot\DemoFiles\demo_w3GOs.sql"
        $fullName = "TestDrive:\sqlTestConverted_demo_w3GOs.ipynb"

        try{
            ConvertTo-SQLNoteBook -InputFileName $demoTextFile -OutputNotebookName $fullName
            { Test-Path $fullName } | Should -Be $true

            $actual = Get-NotebookContent -NoteBookFullName $fullName
            $actual.Count | Should -Be 9

            $actual = Get-NotebookContent -NoteBookFullName $fullName -JustCode

            $actual.Count | Should -Be 3
            write-verbose "tests $($actual[0].Source)" -Verbose
            $actual[0].Source | Should -BeLike '*table1*'
            $actual[1].Source | Should -BeLike '*table3*'

            $actual = Get-NotebookContent -NoteBookFullName $fullName -JustMarkdown

            $actual.Count | Should -Be 6
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
    It "Should convert the file to an ipynb with 3 code and 6 text cells" {
        $demoTextFile = "$PSScriptRoot\DemoFiles\AdventureWorksMultiStatementSBatch_NoGO2.sql"
        $fullName = "TestDrive:\AdventureWorksMultiStatementSBatch_NoGO2.ipynb"

        try{
            ConvertTo-SQLNoteBook -InputFileName $demoTextFile -OutputNotebookName $fullName
            { Test-Path $fullName } | Should -Be $true

            $actual = Get-NotebookContent -NoteBookFullName $fullName
            $actual.Count | Should -Be 7

            $actual = Get-NotebookContent -NoteBookFullName $fullName -JustCode

            $actual.Count | Should -Be 3
            write-verbose "Code cells: $($actual.Count)" -Verbose
            $actual[0].Source | Should -BeLike '*Person.PersonPhone*'
            $actual[1].Source | Should -BeLike '*GETUTCDATE*'

            $actual = Get-NotebookContent -NoteBookFullName $fullName -JustMarkdown

            $actual.Count | Should -Be 4
            $actual[0].Source.Trim() | Should -BeLike 'Look up user and phone number by last name*'
            $actual[1].Source.Trim() | Should -BeLike '*-- Wait for 4 seconds total after go 2'
            $actual[2].Source.Trim() | Should -BeLike '*note the Go 2 has been*'
            $actual[3].Source.Trim() | Should -BeLike 'Commenting out until the field is added*'
        }
        catch [System.Management.Automation.RuntimeException]{
            Write-Verbose "Runtime exception encountered" -Verbose
            Write-Verbose $_ -Verbose
            throw
        }
    }
}