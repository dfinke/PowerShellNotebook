Import-Module $PSScriptRoot\..\..\PowerShellNotebook.psd1 -Force

Describe "Test Export-NotebookToPowerShellScript" {
    It "Should create ps1 file with correct contents" {
        $outPath = "TestDrive:\"

        Export-NotebookToPowerShellScript -FullName "$PSScriptRoot\TestWithInvokePS.ipynb" -outPath $outPath
        $ps1File = "$outPath\TestWithInvokePS.ps1"

        Test-Path $ps1File  | Should -Be $true

        $contents = Get-Content $ps1File

        $contents[0]  | Should -BeExactly '<#'
        $contents[1]  | Should -match     '^\s*Created from:.*TestWithInvokePS.ipynb$'
        $contents[2]  | Should -match     '^\s*Created by:'
        $contents[3]  | Should -match     '^\s*Created on:'
        $contents[4]  | Should -BeExactly '#>'
        $contents[5]  | should -benullorempty
        $contents[6]  | Should -BeExactly '$PSVersionTable'
        $contents[7]  | Should -match     '<#\s+-+\s+#>'
        $contents[8]  | Should -BeExactly '1..10 | % {'
        $contents[9]  | Should -BeExactly '    $_ * 2'
        $contents[10] | Should -BeExactly '}'
    }

    It "Should export the ipynb to ps1" {
        $ipynbFileName = "$PSScriptRoot\..\MultiLineSourceNotebooks\MultiLineSourceAsArray.ipynb"
        Export-NotebookToPowerShellScript -FullName $ipynbFileName
        $ps1File = "./MultiLineSourceAsArray.ps1"

        Test-Path $ps1File | Should -Be $true

        $actual = Get-Content $ps1File

        $actual.Count | Should -Be 9

        $actual[6] | Should -Be 'foreach ($item in 1..10) {'
        $actual[7] | Should -Be '    $item'
        $actual[8] | Should -Be '}'

        Remove-Item $ps1File -ErrorAction SilentlyContinue
    }

    It "Should export the ipynb from a URL to ps1" {
        $url = "https://raw.githubusercontent.com/dfinke/PowerShellNotebook/AddJupyterNotebookMetaInfo/samplenotebook/powershell.ipynb"

        Export-NotebookToPowerShellScript -FullName $url

        $ps1File = "./powershell.ps1"
        Test-Path $ps1File | Should -Be $true

        $contents = Get-Content $ps1File

        $contents[-1] | Should -BeExactly 'Write-Host "hello world"'

        Remove-Item $ps1File -ErrorAction SilentlyContinue
    }
}
