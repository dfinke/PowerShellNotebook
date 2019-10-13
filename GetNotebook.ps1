function Get-Notebook {
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