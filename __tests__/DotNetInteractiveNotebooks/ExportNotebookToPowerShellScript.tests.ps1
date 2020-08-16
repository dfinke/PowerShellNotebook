Import-Module $PSScriptRoot\..\..\PowerShellNotebook.psd1 -Force

Describe "Test Export-NotebookToPowerShellScript" {
    It "Should create ps1 file with correct contents" {        
        $outPath = "TestDrive:\"
        
        Export-NotebookToPowerShellScript -FullName "$PSScriptRoot\TestWithInvokePS.ipynb" -outPath $outPath
        $ps1File = "$outPath\TestWithInvokePS.ps1"
        
        Test-Path $ps1File  | Should -Be $true

        $contents = Get-Content $ps1File
        
        $contents[0] | Should -BeExactly '<#'
        $contents[1].StartsWith('    Created from:') | Should -Be $true        
        $contents[3].StartsWith('    Created by:') | Should -Be $true        
        $contents[4].StartsWith('    Created on:') | Should -Be $true
        $contents[5] | Should -BeExactly '#>'

        $contents[7] | Should -BeExactly '$PSVersionTable'
        $contents[8] | Should -BeExactly ''
        $contents[9] | Should -BeExactly '1..10 | % {'
        $contents[10] | Should -BeExactly '    $_ * 2'
        $contents[11] | Should -BeExactly '}'
    }

    It "Should export the pynb to ps1" {
        $ipynbFileName = "$PSScriptRoot\..\MultiLineSourceNotebooks\MultiLineSourceAsArray.ipynb"
        Export-NotebookToPowerShellScript -FullName $ipynbFileName
        $ps1File = "./MultiLineSourceAsArray.ps1"
    
        Test-Path $ps1File | Should -Be $true
    
        $actual = Get-Content $ps1File
    
        $actual.Count | Should -Be 11
    
        $actual[7] | Should -Be 'foreach ($item in 1..10) {'
        $actual[8] | Should -Be '    $item'
        $actual[9] | Should -Be '}'
    
        Remove-Item $ps1File -ErrorAction SilentlyContinue
    }

    It "Should export the pynb from a URL to ps1" {
        $url = "https://raw.githubusercontent.com/dfinke/PowerShellNotebook/AddJupyterNotebookMetaInfo/samplenotebook/powershell.ipynb"

        Export-NotebookToPowerShellScript -FullName $url

        $ps1File = "./powershell.ps1"
        Test-Path $ps1File | Should -Be $true

        $contents = Get-Content $ps1File

        $contents[7] | Should -BeExactly 'Write-Host "hello world"'

        Remove-Item $ps1File -ErrorAction SilentlyContinue
    }
}    
