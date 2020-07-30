Import-Module $PSScriptRoot\..\SQLNotebook.psm1 -Force

Describe "Test ConvertTo-SQLNoteBook" {
    It "Should convert the file to an ipynb" {
        $demoTextFile = "$PSScriptRoot\DemoFiles\demo.sql"
        $fullName = "TestDrive:\sqlTestConverted.ipnyb"

        ConvertTo-SQLNoteBook -InputFileName $demoTextFile -OutputNotebookName $fullName
        { Test-Pat $fullName } | Should Be $true

        $actual = Get-NotebookContent -NoteBookFullName $fullName
        $actual.Count | Should Be 11

        $actual = Get-NotebookContent -NoteBookFullName $fullName -JustCode

        $actual.Count | Should Be 4
        $actual[0].Source | Should BeExactly 'select DateDiff(MI,StartDate,EndDate) AS Timetaken,* FROM table1'
        $actual[1].Source | Should BeExactly 'SELECT * FROM table2 WHERE id = 1'
        $actual[2].Source | Should BeExactly 'SELECT * FROM table3 where ID = 7'
        $actual[3].Source | Should BeExactly 'SELECT * FROM table4 where ID = 8'

        $actual = Get-NotebookContent -NoteBookFullName $fullName -JustMarkdown

        $actual.Count | Should Be 7
        $actual[0].Source | Should BeExactly 'Test1'
        $actual[1].Source | Should Contain 'Multiline test'
        $actual[2].Source | Should BeExactly 'Test2'
        $actual[3].Source | Should BeExactly 'Test3'
    }
}