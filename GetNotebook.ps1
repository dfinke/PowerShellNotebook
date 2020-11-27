function Get-Notebook {
  <#
        .SYNOPSIS
        Get-Notebook reads the metadata of  Jupyter Notebooks

        .Example
        Get-Notebook .\samplenotebook\Chapter01code.ipynb

NoteBookName         : Chapter01code.ipynb
KernelName           : powershell
CodeBlocks           : 83
MarkdownBlocks       : 23
FullName             : C:\Users\Douglas\Documents\GitHub\MyPrivateGit\PowerShellNotebook\samplenotebook\Chapter01code.ipynb
FormatStyle          : PowerShell
HasParameterizedCell : False

        .Example
        Get-Notebook .\samplenotebook\| Format-Table

NoteBookName          KernelName      CodeBlocks MarkdownBlocks FullName
------------          ----------      ---------- -------------- ----------------
Chapter01code.ipynb   powershell              83             23 C:\Users\Douglas\Documents\GitHub\MyPrivateGit\Power...
csharp.ipynb          .net-csharp              1              0 C:\Users\Douglas\Documents\GitHub\MyPrivateGit\Power...
fsharp.ipynb          .net-fsharp              1              0 C:\Users\Douglas\Documents\GitHub\MyPrivateGit\Power...
powershell.ipynb      .net-powershell          1              0 C:\Users\Douglas\Documents\GitHub\MyPrivateGit\Power...
python.ipynb          python3                  1              0 C:\Users\Douglas\Documents\GitHub\MyPrivateGit\Power...
SingleCodeBlock.ipynb powershell               1              0 C:\Users\Douglas\Documents\GitHub\MyPrivateGit\Power

        .Example
        Get-Notebook -recurse | group KernelName

Count Name                      Group
----- ----                      -----
   98 powershell                {@{NoteBookName=Aaron_CopyWorkspace.ipynb; KernelName=powershell; CodeBlocks=14; Mar...
    2 not found                 {@{NoteBookName=BPCheck.ipynb; KernelName=not found; CodeBlocks=0; MarkdownBlocks=0;...
   36 SQL                       {@{NoteBookName=BPCheck.ipynb; KernelName=SQL; C...
   29 python3                   {@{NoteBookName=python install powershell_kernel.ipynb; KernelName=python3; CodeBloc...
  781 .net-powershell           {@{NoteBookName=Using_ConvertTo-SQLNoteBook.ipynb; KernelName=.net-powershell; CodeB...
    3 pyspark3kernel            {@{NoteBookName=load-sample-data-into-bdc.ipynb; KernelName=pyspark3kernel; C...

This command will allow you to serch through a directory & all sub directories to find Jupyter Notebooks & group them by Kernel used in each of those Notebook.
  #>
  param(
        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Alias('Fullname')]
        $Path = $pwd,
        $NoteBookName = '*',
        [switch]$Recurse
  )
  begin {
    $linguistNames = @{  #used by github to the render code in markup ```SQL will render as sql etc
        '.net-csharp'     = 'C#'
        '.net-fsharp'     = 'F#'
        '.net-powershell' = 'PowerShell'
        'not found'       = ''
        'powershell'      = 'PowerShell'
        'python3'         = 'Python'
        'Python [Root]'   = 'Python'
        'sql'             = 'SQL'
    }
    function ObjectFromJson {
    param(
        $Retrieved ,
        $SourcePath
    )
        $kernelspecName = $Retrieved.metadata.kernelspec.name
        if (!$kernelspecName) { $kernelspecName = "not found" }

        $counts = $Retrieved.cells | Group-Object cell_type -AsHashTable

        [PSCustomObject][Ordered]@{
            NoteBookName         = (Split-Path -Leaf $SourcePath)
            KernelName           = $kernelspecName
            CodeBlocks           = $counts.code.Count
            MarkdownBlocks       = $counts.markdown.Count
            FullName             = $SourcePath
            FormatStyle          = $linguistNames[$kernelspecName]
            HasParameterizedCell = $Retrieved.cells.metadata.tags -contains "parameters"
        }
    }
  }
  process {
    if ([System.Uri]::IsWellFormedUriString($p, [System.UriKind]::Absolute)) {
            ObjectFromJson (Invoke-RestMethod $p)  $p
    }
    else {
        $targetName = "$($NotebookName).ipynb"
        foreach ($file in Get-ChildItem $Path $targetName -Recurse:$Recurse) {
            ObjectFromJson (Get-Content $file | ConvertFrom-Json) $file.FullName
        }
    }
  }
}