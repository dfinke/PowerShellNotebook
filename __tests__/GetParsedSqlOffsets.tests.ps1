Import-Module $PSScriptRoot\..\PowerShellNotebook.psm1 -Force

Describe "Test Get-ParsedSqlOffsets" {
    It "Should retrieve the Batch, Comment, and Gap offsets with a single code cell" {
        $demoTextFile = "$PSScriptRoot\DemoFiles\demo.sql"
        $fullName = "TestDrive:\demosql.csv"

        try{
            $Offsets = Get-ParsedSqlOffsets -ScriptPath $demoTextFile
            $Offsets | ConvertTo-Csv -NoTypeInformation > $fullName
            { Test-Path $fullName } | Should -Be $true

            @($Offsets).Count | Should -Be 1

            $Offsets = Get-ParsedSqlOffsets -ScriptPath $demoTextFile | Where-Object {$_.BlockType -ne 'Code'}

            $Offsets.Count | Should -Be 0

            $Offsets = Get-ParsedSqlOffsets -ScriptPath $demoTextFile | Where-Object {$_.BlockType -eq 'Code'}

            @($Offsets).Count | Should -Be 1

            $Offsets[0].Text | Should -BeExactly 'select DateDiff(MI,StartDate,EndDate) AS Timetaken,* FROM table1
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
    It "Should retrieve the Batch, Comment, and Gap offsets with 3 code and 6 text cells" {
        $demoTextFile = "$PSScriptRoot\DemoFiles\demo_w3GOs.sql"
        $fullName = "TestDrive:\sqlTestConverted_demo_w3GOs.csv"

        try{
            $Offsets = Get-ParsedSqlOffsets -ScriptPath $demoTextFile
            $Offsets | ConvertTo-Csv -NoTypeInformation > $fullName
            { Test-Path $fullName } | Should -Be $true

            @($Offsets).Count | Should -Be 9

            $Offsets = (Get-ParsedSqlOffsets -ScriptPath $demoTextFile).where({$_.BlockType -eq 'Comment'})

            $Offsets.Count | Should -Be 4

            $Offsets = (Get-ParsedSqlOffsets -ScriptPath $demoTextFile).where({$_.BlockType -eq 'Gap'})

            $Offsets.Count | Should -Be 2

            $Offsets = (Get-ParsedSqlOffsets -ScriptPath $demoTextFile).where({$_.BlockType -eq 'Code'})

            $Offsets.Count | Should -Be 3
        }
        catch [System.Management.Automation.RuntimeException]{
            Write-Verbose "Runtime exception encountered" -Verbose
            Write-Verbose $_ -Verbose
            throw
        }
    }
    It "Should retrieve the Batch, Comment, and Gap offsets with 3 code and 5 text cells" {
        $demoTextFile = "$PSScriptRoot\DemoFiles\AdventureWorksMultiStatementSBatch_NoGO2.sql"
        $fullName = "TestDrive:\AdventureWorksMultiStatementSBatch_NoGO2.csv"

        try{
            $Offsets = Get-ParsedSqlOffsets -ScriptPath $demoTextFile
            $Offsets | ConvertTo-Csv -NoTypeInformation > $fullName
            { Test-Path $fullName } | Should -Be $true

            @($Offsets).Count | Should -Be 8

            $Offsets = (Get-ParsedSqlOffsets -ScriptPath $demoTextFile).where({$_.BlockType -eq 'Comment'})

            $Offsets.Count | Should -Be 2

            $Offsets = (Get-ParsedSqlOffsets -ScriptPath $demoTextFile).where({$_.BlockType -eq 'Gap'})

            $Offsets.Count | Should -Be 3

            $Offsets = (Get-ParsedSqlOffsets -ScriptPath $demoTextFile).where({$_.BlockType -eq 'Code'})

            $Offsets.Count | Should -Be 3
        }
        catch [System.Management.Automation.RuntimeException]{
            Write-Verbose "Runtime exception encountered" -Verbose
            Write-Verbose $_ -Verbose
            throw
        }
    }
}