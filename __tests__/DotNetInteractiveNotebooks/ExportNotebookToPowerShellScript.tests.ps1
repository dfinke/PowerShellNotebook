Import-Module $PSScriptRoot\..\..\PowerShellNotebook.psd1 -Force

Describe "Test Export-NotebookToPowerShellScript" {
    It "Should create ps1 file with correct contents" {        
        $outPath = "TestDrive:\"
        
        Export-NotebookToPowerShellScript -FullName "$PSScriptRoot\TestWithInvokePS.ipynb" -outPath $outPath
        $ps1File = "$outPath\TestWithInvokePS.ps1"
        
        Test-Path $ps1File  | Should -Be $true

        $contents = Get-Content $ps1File
        
        $contents[0] | Should -BeExactly '$PSVersionTable'
        $contents[1] | Should -BeExactly '1..10 | % {'
        $contents[2] | Should -BeExactly '    $_ * 2'
        $contents[3] | Should -BeExactly '}'
    }
}