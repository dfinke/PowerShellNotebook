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
    #>
    param(
        $Path,
        $NoteBookName
    )

    if (!$Path) { $Path = "." }
    if (!$NoteBookName) { $NoteBookName = '*' }

    $targetName = "$($NotebookName).ipynb"
    foreach ($file in Get-ChildItem $Path $targetName) {
        $r = Get-Content $file.fullname | ConvertFrom-Json

        $kernelspecName = $r.metadata.kernelspec.name
        if (!$kernelspecName) { $kernelspecName = "not found" }

        $counts = $r.cells | Group-Object cell_type -AsHashTable

        [PSCustomObject][Ordered]@{
            NoteBookName     = $file.Name
            KernelName       = $kernelspecName
            CodeBlocks       = $counts.code.Count
            MarkdownBlocks   = $counts.markdown.Count
            NoteBookFullName = $file.FullName
        }
    }
}