Import-Module $PSScriptRoot\..\PowerShellNotebook.psd1 -Force

Describe "Test Invoke PS Notebook" {

    It "Should have New-PSNotebook" {
        $actual = Get-Command New-PSNotebook -ErrorAction SilentlyContinue
        $actual | Should Not Be $Null
    }

    It "Should have Add-NotebookCode" {
        $actual = Get-Command Add-NotebookCode -ErrorAction SilentlyContinue
        $actual | Should Not Be $Null
    }

    It "Should have Add-NotebookMarkdown" {
        $actual = Get-Command Add-NotebookMarkdown -ErrorAction SilentlyContinue
        $actual | Should Not Be $Null
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
        $actual.cells.count | Should Be 3

        $actual.cells[0].source | Should BeExactly "8+12"
        $actual.cells[1].source | Should BeExactly "8+3"
        $actual.cells[2].source | Should BeExactly "## Math

- show addition
- show other
"
    }

    It "Save file" {
        $fullName = "TestDrive:\test.ipnyb"

        New-PSNotebook -NoteBookName $fullName {
            Add-NotebookCode "8+12"
        }

        $r = Test-Path $fullName
        $r | should be $true
    }

    It "Should have correct top level metadata fot Azure Data Studio" {
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

        $actual.metadata | Should Not Be $null
        $actual.metadata.kernelspec.name | Should BeExactly 'powershell'
        $actual.metadata.kernelspec.display_name | Should BeExactly 'PowerShell'

        $actual.metadata.language_info.name | Should BeExactly 'powershell'
        $actual.metadata.language_info.codemirror_mode | Should BeExactly 'shell'
        $actual.metadata.language_info.mimetype | Should BeExactly 'text/x-sh'
        $actual.metadata.language_info.file_extension | Should BeExactly '.ps1'

        $actual.nbformat_minor | Should Be 2
        $actual.nbformat | Should Be 4
        $actual.cells.Count | Should Be 0
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

        $actual.cells.Count | should be 1
        $actual.cells[0].cell_type | should BeExactly 'markdown'
        $actual.cells[0].metadata.GetType().name | should BeExactly "PSCustomObject"
        $actual.cells[0].source | should BeExactly '# Hello World'
    }

    It "Should have correct top level metadata fot Jupyter Notebooks" {
        $actual = ConvertFrom-Json (New-PSNotebook -AsText -NotebookType Jupyter { })
        <#
            "metadata": {
                "kernelspec": {
                    "display_name": ".NET (PowerShell)",
                    "language": "PowerShell",
                    "name": ".net-powershell"
                },
                "language_info": {
                    "file_extension": ".ps1",
                    "mimetype": "text/x-powershell",
                    "name": "PowerShell",
                    "pygments_lexer": "powershell",
                    "version": "7.0"
                }
            },
            "nbformat": 4,
            "nbformat_minor": 4
        #>

        $actual.metadata | Should Not Be $null

        $actual.metadata.kernelspec.display_name | Should BeExactly '.NET (PowerShell)'
        $actual.metadata.kernelspec.language | Should BeExactly 'PowerShell'
        $actual.metadata.kernelspec.name | Should BeExactly '.net-powershell'

        $actual.metadata.language_info.file_extension | Should BeExactly '.ps1'
        $actual.metadata.language_info.mimetype | Should BeExactly 'text/x-powershell'
        $actual.metadata.language_info.name | Should BeExactly 'PowerShell'
        $actual.metadata.language_info.pygments_lexer | Should BeExactly 'powershell'
        $actual.metadata.language_info.version | Should BeExactly '7.0'

        $actual.nbformat | Should Be 4
        $actual.nbformat_minor | Should Be 4
        $actual.cells.Count | Should Be 0
    }

}