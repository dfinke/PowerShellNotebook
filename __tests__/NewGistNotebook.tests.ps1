Import-Module $PSScriptRoot\..\PowerShellNotebook.psd1 -Force

Describe "Test New-GistNotebook" -Tag 'New-GistNotebook' {
    It "Should have New-GistNotebook" {
        $actual = Get-Command New-GistNotebook -ErrorAction SilentlyContinue
        $actual | Should -Not -Be  $Null
    }
}