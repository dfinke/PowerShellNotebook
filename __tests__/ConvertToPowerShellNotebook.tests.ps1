Import-Module $PSScriptRoot\..\PowerShellNotebook.psd1 -Force

Describe "Test ConvertTo-PowerShellNoteBook" {
    It "Should convert the file to an ipynb" -Skip {
        $demoTextFile = "$PSScriptRoot\DemoFiles\demo.txt"
        $fullName = "TestDrive:\testConverted.ipynb"

        ConvertTo-PowerShellNoteBook -InputFileName $demoTextFile -OutputNotebookName $fullName
        { Test-Pat $fullName } | Should -Be $true

        $actual = Get-NotebookContent -NoteBookFullName $fullName
        $actual.Count | Should -Be 8

        $actual = Get-NotebookContent -NoteBookFullName $fullName -JustCode

        $actual.Count | Should -Be 4
        $actual[0].Source | Should -BeExactly 'ps | select -first 10'
        $actual[1].Source | Should -BeExactly 'gsv | select -first 10'
        $actual[2].Source | Should -BeExactly 'function SayHello($p) {"Hello $p"}'
        $actual[3].Source | Should -BeExactly 'SayHello World'

        $actual = Get-NotebookContent -NoteBookFullName $fullName -JustMarkdown

        $actual.Count | Should -Be 4
        $actual[0].Source | Should -BeExactly '# Get first 10 process'
        $actual[1].Source | Should -BeExactly '# Get first 10 services'
        $actual[2].Source | Should -BeExactly '# Create a function'
        $actual[3].Source | Should -BeExactly '# Use the function'
    }
    It "Should convert the file with a single comment and single line of code to an ipynb" -Skip {
        $demoTextFile = "$PSScriptRoot\DemoFiles\demo_SingleCommentSingleLineCodeBlock.ps1"
        $fullName = "TestDrive:\testConverted.ipynb"

        ConvertTo-PowerShellNoteBook -InputFileName $demoTextFile -OutputNotebookName $fullName
        { Test-Pat $fullName } | Should -Be $true

        $actual = Get-NotebookContent -NoteBookFullName $fullName
        $actual.Count | Should -Be 2

        $actual = Get-NotebookContent -NoteBookFullName $fullName -JustCode

        @($actual).Count | Should -Be 1
        $actual[0].Source | Should -BeExactly 'ps | select -first 10'

        $actual = Get-NotebookContent -NoteBookFullName $fullName -JustMarkdown

        @($actual).Count | Should -Be 1
        $actual[0].Source | Should -BeExactly '# Get first 10 process'
    }

    It "Should convert the file to an ipynb" -Skip {
        $demoTextFile = "$PSScriptRoot\DemoFiles\GetParsedSqlOffsets.ps1"
        $fullName = "TestDrive:\GetParsedSqlOffsets.ipynb"

        ConvertTo-PowerShellNoteBook -InputFileName $demoTextFile -OutputNotebookName $fullName
        { Test-Path $fullName } | Should -Be $true

        $actual = Get-NotebookContent -NoteBookFullName $fullName
        $actual.Count | Should -Be 13

        $actual = Get-NotebookContent -NoteBookFullName $fullName -JustCode

        $actual.Count | Should -Be 7
        $actual[0].Source | Should -BeExactly 'function Get-ParsedSqlOffsets{
    [CmdletBinding()]
    param(
        $ScriptPath
    )'

        $actual = Get-NotebookContent -NoteBookFullName $fullName -JustMarkdown

        $actual.Count | Should -Be 6
        $actual[2].Source  | Should -BeExactly '<#################################################################################################>'
    }
}