function ConvertTo-PowerShellNoteBook {
    <#
        .Synopsis
        Convert PowerShell scripts (ps1 files) to interactive notebooks (ipynb files)

        .Description
        Convert PowerShell scripts on disk or the internet to interactive notebooks that can be run in Azure Data Studio or with `Invoke-ExecuteMethod`

        .Example
        ConvertTo-PowerShellNoteBook -InputFileName c:\Temp\demo.txt -OutputNotebookName c:\Temp\demo.ipynb

        .Example
        ConvertTo-PowerShellNoteBook 'https://raw.githubusercontent.com/dfinke/PowerShellNotebook/master/__tests__/DemoFiles/demo_SingleCommentSingleLineCodeBlock.ps1'

        .Example
        $(
            'https://raw.githubusercontent.com/dfinke/PowerShellNotebook/master/__tests__/DemoFiles/demo_SingleCommentSingleLineCodeBlock.ps1'
             dir *.ps1
        ) | ConvertTo-PowerShellNoteBook
    #>
    param(
        [parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('FullName', 'Path')]
        $InputFileName,
        $OutputNotebookName
    )

    Process {
        #region Parsing section.

        Write-Progress -Activity "Converting PowerShell file to Notebook" -Status "Converting $($InputFileName)"

        if ([System.Uri]::IsWellFormedUriString($InputFileName, [System.UriKind]::Absolute)) {
            $s = Invoke-RestMethod -Uri $InputFileName
        }
        else {
            $InputFileName = Resolve-Path $InputFileName
            $s = Get-Content -Raw $InputFileName
        }

        # if no $OutputNotebookName, grab the filename and replace the ps1
        # should work with both filenames and uri's
        if (!$OutputNotebookName) {
            $OutputNotebookName = (Split-Path -leaf  $InputFileName) -replace '.ps1', '.ipynb'
            $OutputNotebookName = $pwd.Path + "\" + $OutputNotebookName
        }

        try {
            # $CommentRanges = [System.Management.Automation.PSParser]::Tokenize((Get-Content -Raw $InputFileName), [ref]$null).Where( { $_.Type -eq 'Comment' }) |
            $CommentRanges = [System.Management.Automation.PSParser]::Tokenize($s, [ref]$null).Where( { $_.Type -eq 'Comment' }) |
            Select-Object -Property Start, Length, Type, Content
        }
        Catch {
            "This is not a valid PowerShell file"
        }

        $BlocksWitGaps = @()
        $Previous = $null
        foreach ($CommentBlock in $CommentRanges ) {
            $BlockOffsets = [ordered]@{
                Start              = $CommentBlock.Start;
                StopOffset         = $CommentBlock.Start + $CommentBlock.Length;
                Length             = $CommentBlock.Length;
                GapLength          = [int] $CommentBlock.Start - $Previous.StopOffset;
                PreviousStart      = $Previous.Start;
                PreviousStopOffset = $Previous.StopOffset;
                Type               = 'Code';
                GapText            = IF ($CommentBlock.Start - $Previous.StopOffset -gt 1) { [string] $s.Substring($Previous.StopOffset, ($CommentBlock.Start - $Previous.StopOffset)).trimstart() }else { [string] '' };
                Content            = $CommentBlock.Content
            }

            $Previous = $BlockOffsets
            $BlocksWitGaps += [pscustomobject] $BlockOffsets
        }


        $AllBlocks = @()
        $Previous = $null
        $AllBlocks = $CommentRanges
        <# Catch anything missed from the tail of the file, add it to $AllBlocks #>
        if ($BlocksWitGaps.Count -eq 1) {
            <# This step handles ading the psobjects together if $CommentBlock isn't an array. #>
            $AllBlocks = @($CommentBlock; [pscustomobject][Ordered]@{
                    Start   = ($CommentBlock.Start + $CommentBlock.Length);
                    Length  = $s.Length - ($CommentBlock.Start + $CommentBlock.Length);
                    Type    = 'Gap';
                    Content = $s.Substring(($CommentBlock.Start + $CommentBlock.Length), ($s.Length - ($CommentBlock.Start + $CommentBlock.Length))).trimstart()
                })
        }
        else {
            if (($CommentBlock.Start + $CommentBlock.Length) -lt $s.Length) {
                $AllBlocks += [pscustomobject][ordered]@{
                    Start   = ($CommentBlock.Start + $CommentBlock.Length);
                    Length  = $s.Length - ($CommentBlock.Start + $CommentBlock.Length);
                    Type    = 'Gap';
                    Content = $s.Substring(($CommentBlock.Start + $CommentBlock.Length), ($s.Length - ($CommentBlock.Start + $CommentBlock.Length))).trimstart()
                }
            }
        }

        foreach ($GapBlock in $BlocksWitGaps ) {
            $GapOffsets = [ordered]@{
                Start      = $GapBlock.PreviousStopOffset;
                StopOffset = $GapBlock.Start;
                Length     = $GapBlock.GapLength;
                Type       = 'Gap';
                Content    = $GapBlock.GapText.trimstart()
            }

            $Previous = $GapOffsets
            $AllBlocks += if ($GapOffsets.Length -gt 0) { [pscustomobject] $GapOffsets }
        }
        #endregion
        #region Notebook creation section.
        New-PSNotebook -NoteBookName $OutputNotebookName -DotNetInteractive {

            foreach ($Block in $AllBlocks | Sort-Object Start ) {

                switch ($Block.Type) {
                    'Comment' {
                        $TextBlock = $s.Substring($Block.Start, $Block.Length) -replace ("\n", "   `n  ")

                        if ($TextBlock.Trim().length -gt 0) {
                            Add-NotebookMarkdown -markdown (-join $TextBlock)
                        }
                    }
                    'Gap' {
                        $GapBlock = $s.Substring($Block.Start, $Block.Length)

                        if ($GapBlock.Trim().length -gt 0) {
                            Add-NotebookCode -code (-join $GapBlock.trimstart().trimend()) # -replace ("\n", "   `n  ")
                        }
                    }
                }
            }
        }
        # Set $OutputNotebookName to $null otherwise if the $InputFileName is being piped to, it won't get reset
        $OutputNotebookName = $null
        #endregion
    }
}