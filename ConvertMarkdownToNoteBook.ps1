function Convert-MarkdownToNoteBook {
    <#
        .SYNOPSIS
        Convert a markdown file to an interactive PowerShell Notebook

        .Description

        .Example
        # converts .\demo.md to demo.ipynb
        Convert-MarkdownToNoteBook .\demo.md

        .Example
        # converts .\demo.md to demo.ipynb and watches the file for changes and automatically converts it again
        Convert-MarkdownToNoteBook .\demo.md -watch
    #>
    param(
        $filename,
        [Switch]$watch
    )

    function DoWatch {
        param(
            $targetFile,
            [scriptblock]$sb
        )

        "Watching - Press Ctl-C to stop"
        $targetFile = Resolve-Path $targetFile
        $sb = {
            foreach ($entry in $args[0].GetEnumerator()) {
                if ($entry.Key -eq $targetFile -and $entry.Value -eq "Changed") {
                    & $sb
                }
            }
        }.GetNewClosure()

        &"$PSScriptRoot\Watch-Directory.ps1" -Path . -TestSeconds .5 -WaitSeconds 1 -Command $sb
    }

    "[{0}] Converting {1}" -f (Get-Date), $filename

    $content = Get-Content $filename

    $chapters = [ordered]@{ }
    $chapterIndex = 1

    switch ($content) {
        "<!-- CHAPTER END -->" {
            $inChapter = $false
            $chapterIndex += 1
        }

        { $inChapter } {
            $currentChapter = "Chapter {0}" -f $chapterIndex
            if (!$chapters.$currentChapter) {
                $chapters.$currentChapter = @()
            }

            $chapters.$currentChapter += $_
        }

        "<!-- CHAPTER START -->" { $inChapter = $true }
    }


    $code = @()
    $markDown = @()

    New-PSNotebook -NoteBookName ($filename -replace '.md', '.ipynb') -IncludeCodeResults {

        foreach ($chapter in $chapters.Keys) {

            Add-NotebookMarkdown -markdown ("# $($chapter)")

            $inCodeBlock = $false

            switch ($chapters.$chapter) {
                { $_ -eq '```ps' -or $_ -eq '```powershell' } {
                    Add-NotebookMarkdown -markdown (-join $markDown)
                    $code = @()
                    $inCodeBlock = $true
                }
                '```' {
                    Add-NotebookCode -code (-join $code)
                    $markDown = @()
                    $inCodeBlock = $false
                }
                default {
                    if ($inCodeBlock) {
                        $code += $_ + "`r`n"
                    }
                    else {
                        $markDown += $_ + "`r`n"
                    }
                }
            }

            if ($markDown) {
                Add-NotebookMarkdown -markdown (-join $markDown)
                $markDown = @()
            }
        }
    }

    "[{0}] Finished {1}" -f (Get-Date), $filename

    # if ($Watch) { DoWatch $filename { .\ConvertMarkdownToNoteBook.ps1 -filename $filename } }
    if ($Watch) { DoWatch $filename { Convert-MarkdownToNoteBook -filename $filename } }
}