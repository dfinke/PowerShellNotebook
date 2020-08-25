Import-Module $PSScriptRoot\..\..\PowerShellNotebook.psd1 -Force

Describe "Test Export-NotebookToSqlScript" {
    It "Should create SQL file with correct contents" -Skip {        
        $outPath = "TestDrive:\"
        
        Export-NotebookToSqlScript -FullName "$PSScriptRoot\Simple_SELECTs.ipynb" -outPath $outPath
        $SQLFile = "$outPath\Simple_SELECTs.SQL"
        
        Test-Path $SQLFile  | Should -Be $true

        $contents = Get-Content $SQLFile
        
        $contents[0] | Should -BeExactly '/*'
        $contents[1].StartsWith('    Created from:') | Should -Be $true        
        $contents[3].StartsWith('    Created by:') | Should -Be $true        
        $contents[4].StartsWith('    Created on:') | Should -Be $true
        $contents[5] | Should -BeExactly '*/'

        $contents[7] | Should -BeExactly '/*  First, find out how many databases are on this instance.  */'
        $contents[8] | Should -BeExactly ''
        $contents[9] | Should -BeExactly 'SELECT *'
        $contents[10] | Should -BeExactly '  FROM sys.databases'
        $contents[19] | Should -BeExactly 'SELECT SYSDATETIME()'

        Remove-Item $SQLFile -ErrorAction SilentlyContinue
    }

    It "Should export the ipynb from a URL to SQL" {
        $url = "https://raw.githubusercontent.com/dfinke/PowerShellNotebook/master/__tests__/SQLNotebooks/Simple_SELECTs.ipynb"

        try{

        Export-NotebookToSqlScript -FullName $url

        $SQLFile = "./Simple_SELECTs.SQL"
        #Test-Path $SQLFile | Should -Be $true

        #$contents = Get-Content $SQLFile

        #$contents[7] | Should -BeExactly '/* BP Check READ ME - http://aka.ms/BPCheck;'
        }
        catch [System.Management.Automation.RuntimeException]{
            Write-Verbose "Runtime exception encountered" -Verbose
            Write-Verbose $_ -Verbose
            throw
        }

        #Remove-Item $SQLFile -ErrorAction SilentlyContinue
    }
}    