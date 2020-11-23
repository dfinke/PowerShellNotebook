function Get-Notebook {
  <#
        .SYNOPSIS
        Get-Notebook reads the metadata of a single (or folder of) Jupyter Notebooks

        .Example
        Get-Notebook .\samplenotebook\Chapter01code.ipynb

NoteBookName     : Chapter01code.ipynb
KernelName       : powershell
CodeBlocks       : 83
MarkdownBlocks   : 23
NoteBookFullName : C:\Users\Douglas\Documents\GitHub\MyPrivateGit\PowerShellNotebook\samplenotebook\Chapter01code.ipynb

        .Example
        Get-Notebook .\samplenotebook\| Format-Table

NoteBookName          KernelName      CodeBlocks MarkdownBlocks NoteBookFullName
------------          ----------      ---------- -------------- ----------------
Chapter01code.ipynb   powershell              83             23 C:\Users\Douglas\Documents\GitHub\MyPrivateGit\Power...
csharp.ipynb          .net-csharp              1              0 C:\Users\Douglas\Documents\GitHub\MyPrivateGit\Power...
fsharp.ipynb          .net-fsharp              1              0 C:\Users\Douglas\Documents\GitHub\MyPrivateGit\Power...
powershell.ipynb      .net-powershell          1              0 C:\Users\Douglas\Documents\GitHub\MyPrivateGit\Power...
python.ipynb          python3                  1              0 C:\Users\Douglas\Documents\GitHub\MyPrivateGit\Power...
SingleCodeBlock.ipynb powershell               1              0 C:\Users\Douglas\Documents\GitHub\MyPrivateGit\Power

        .Example
        dir -Filter *.ipynb -Recurse | foreach {
Get-Notebook -Path $_.FullName } |
group KernelName

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
        [Parameter(ValueFromPipeline=$true)]
        $Path = $pwd,
        $NoteBookName = '*'
  )
  begin {
    $linguistNames = @{  #used by github to the render code in markup ```SQL will render as sql etc
        '.net-csharp'     = 'C#'
        '.net-fsharp'     = 'F#'
        '.net-powershell' = 'PowerShell'
        'not found'       = ''
        'powershell'      = 'PowerShell'
        'python3'         = 'Python'
        'sql'             = 'SQL'
    }
  }
  process {
    $targetName = "$($NotebookName).ipynb"
    foreach ($file in Get-ChildItem $Path $targetName) {
        $r = Get-Content $file.fullname | ConvertFrom-Json

        $kernelspecName = $r.metadata.kernelspec.name
        if (!$kernelspecName) { $kernelspecName = "not found" }

        $counts = $r.cells | Group-Object cell_type -AsHashTable

        [PSCustomObject][Ordered]@{
            NoteBookName         = $file.Name
            KernelName           = $kernelspecName
            CodeBlocks           = $counts.code.Count
            MarkdownBlocks       = $counts.markdown.Count
            NoteBookFullName     = $file.FullName
            FormatStyle          = $linguistNames[$kernelspecName]
            HasParameterizedCell =  $r.cells.metadata.tags -contains "parameters"
        }
    }
  }
}