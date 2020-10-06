$moduleName = '\PowerShellNotebook'

if (($PSVersionTable).PSVersion.Major -eq 5) {
    $targets = @('C:\Program Files\WindowsPowerShell\Modules' + $moduleName) # PS 5
}
else {
    $targets = @('C:\Program Files\PowerShell\Modules' + $moduleName) # PS 7   
}

# $targets = @(
#     #'C:\Program Files\WindowsPowerShell\Modules' + $moduleName # PS 5.1
#     'C:\Program Files\PowerShell\Modules' + $moduleName # PS 7+
# )

foreach ($fullPath in $targets) {
    Robocopy . $fullPath /mir /XD .vscode .git CI __tests__ data mdHelp /XF appveyor.yml azure-pipelines.yml .gitattributes .gitignore filelist.txt install.ps1 InstallModule.ps1 PublishToGallery.ps1
}

"copied to: "
$targets