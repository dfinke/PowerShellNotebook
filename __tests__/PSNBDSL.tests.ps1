Import-Module $PSScriptRoot\..\PowerShellNotebook.psd1 -Force

Describe "Test Invoke PS Notebook" -Tag 'InvokePSNotebook' {

    It "Should have New-PSNotebook" {
        $actual = Get-Command New-PSNotebook -ErrorAction SilentlyContinue
        $actual | Should -Not -Be  $Null
    }

    It "Should have Add-NotebookCode" {
        $actual = Get-Command Add-NotebookCode -ErrorAction SilentlyContinue
        $actual | Should -Not -Be  $Null
    }

    It "Should have Add-NotebookMarkdown" {
        $actual = Get-Command Add-NotebookMarkdown -ErrorAction SilentlyContinue
        $actual | Should -Not -Be  $Null
    }

    It "Should generate correct PowerShell notebook format" {
        $actualJson = New-PSNotebook -AsText {
            Add-NotebookCode "8+12"
            Add-NotebookCode "8+3"
            Add-NotebookMarkdown @'
## Math

- show addition
- show other

'@
        }

        $actual = $actualJson | ConvertFrom-Json
        $actual.cells.count | Should -Be 3

        $actual.cells[0].source | Should -BeExactly "8+12"
        $actual.cells[1].source | Should -BeExactly "8+3"
        $actual.cells[2].source | Should -BeExactly "## Math

- show addition
- show other
"
    }

    It "Save file" {
        $fullName = "TestDrive:\test.ipynb"

        New-PSNotebook -NoteBookName $fullName {
            Add-NotebookCode "8+12"
        }

        $r = Test-Path $fullName
        $r | Should -Be $true
    }

    It "Should have correct top level metadata" {
        $actual = ConvertFrom-Json (New-PSNotebook -AsText { })
        <#
                {
                    "metadata": {
                        "kernelspec": {
                            "name": "powershell",
                            "display_name": "PowerShell"
                        },
                        "language_info": {
                            "name": "powershell",
                            "codemirror_mode": "shell",
                            "mimetype": "text/x-sh",
                            "file_extension": ".ps1"
                        }
                    },
                    "nbformat_minor": 2,
                    "nbformat": 4,
                    "cells": [

                    ]
                }
        #>

        $actual.metadata | Should -Not -Be  $null
        $actual.metadata.kernelspec.name | Should -BeExactly 'powershell'
        $actual.metadata.kernelspec.display_name | Should -BeExactly 'PowerShell'

        $actual.metadata.language_info.name | Should -BeExactly 'powershell'
        $actual.metadata.language_info.codemirror_mode | Should -BeExactly 'shell'
        $actual.metadata.language_info.mimetype | Should -BeExactly 'text/x-sh'
        $actual.metadata.language_info.file_extension | Should -BeExactly '.ps1'

        $actual.nbformat_minor | Should -Be 2
        $actual.nbformat | Should -Be 4
        $actual.cells.Count | Should -Be 0
    }

    It "Should have correct markdown metadata" {
        <#
            {
                "metadata": {
                    "kernelspec": {
                        "name": "powershell",
                        "display_name": "PowerShell"
                    },
                    "language_info": {
                        "name": "powershell",
                        "codemirror_mode": "shell",
                        "mimetype": "text/x-sh",
                        "file_extension": ".ps1"
                    }
                },
                "nbformat_minor": 2,
                "nbformat": 4,
                "cells": [
                    {"cell_type":"markdown","metadata":{},"source":["# Hello World"]}
                ]
            }
        #>
        $nb = New-PSNotebook -AsText {
            Add-NotebookMarkdown -markdown "# Hello World"
        }

        $actual = ConvertFrom-Json $nb

        $actual.cells.Count | Should -Be 1
        $actual.cells[0].cell_type | Should -BeExactly 'markdown'
        $actual.cells[0].metadata.GetType().name | Should -BeExactly "PSCustomObject"
        $actual.cells[0].source | Should -BeExactly '# Hello World'
    }
        
    It "Tests Invoke returning a string" {
        $s = "'Hello World'"
 
        $PSNotebookRunspace = New-PSNotebookRunspace
        $actual = $PSNotebookRunspace.Invoke($s)

        $actual.Trim() | Should -BeExactly "Hello World"
    }

    It "Tests Invoke returning an object" {
        $s = "[PSCustomObject]@{msg='Hello World'}"
 
        $PSNotebookRunspace = New-PSNotebookRunspace -ReturnAsObjects
        $actual = $PSNotebookRunspace.Invoke($s)

        $actual.msg | Should -BeExactly "Hello World"
    }
 
    It "Tests code cell with null language specified" {
        $actualJson = New-PSNotebook -AsText {
            Add-NotebookCode '1..2'            
        } | ConvertFrom-Json

        $actualJson.cells.Count | Should -Be 1
        $actualJson.cells[0].metadata.'dotnet_interactive' | Should -BeNullOrEmpty
        $actualJson.cells[0].metadata.'dotnet_interactive'.language | Should -BeNullOrEmpty
    }

    It "Tests code cell with PowerShell language specified" {
        $actualJson = New-PSNotebook -AsText {
            Add-NotebookCode '1..2' -language PowerShell
        } | ConvertFrom-Json

        $actualJson.cells.Count | Should -Be 1
        $actualJson.cells[0].metadata.'dotnet_interactive' | Should -Not -BeNullOrEmpty
        $actualJson.cells[0].metadata.'dotnet_interactive'.language | Should -BeExactly 'pwsh'
    }

    It "Tests code cell with C# language specified" {
        $actualJson = New-PSNotebook -AsText {
            Add-NotebookCode '1..2' -language C#
        } | ConvertFrom-Json

        $actualJson.cells.Count | Should -Be 1
        $actualJson.cells[0].metadata.'dotnet_interactive' | Should -Not -BeNullOrEmpty
        $actualJson.cells[0].metadata.'dotnet_interactive'.language | Should -BeExactly 'csharp'
    }

    It "Tests code cell with F# language specified" {
        $actualJson = New-PSNotebook -AsText {
            Add-NotebookCode '1..2' -language F#
        } | ConvertFrom-Json

        $actualJson.cells.Count | Should -Be 1
        $actualJson.cells[0].metadata.'dotnet_interactive' | Should -Not -BeNullOrEmpty
        $actualJson.cells[0].metadata.'dotnet_interactive'.language | Should -BeExactly 'fsharp'
    }

    It "Tests code cell with SQL language specified" {
        $actualJson = New-PSNotebook -AsText {
            Add-NotebookCode '1..2' -language SQL
        } | ConvertFrom-Json

        $actualJson.cells.Count | Should -Be 1
        $actualJson.cells[0].metadata.'dotnet_interactive' | Should -Not -BeNullOrEmpty
        $actualJson.cells[0].metadata.'dotnet_interactive'.language | Should -BeExactly 'sql'
    }    
}