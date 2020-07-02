param ($fullPath)

if (-not $fullPath) {
    $fullpath = $env:PSModulePath -split ":(?!\\)|;|," |
        Where-Object {$_ -notlike ([System.Environment]::GetFolderPath("UserProfile")+"*") -and $_ -notlike "$pshome*"} |
            Select-Object -First 1
            $fullPath = Join-Path $fullPath -ChildPath "PowerShellNotebook"
}

Push-location $PSScriptRoot
Robocopy . $fullPath /mir /XD .vscode .git CI __tests__ data mdHelp /XF appveyor.yml azure-pipelines.yml .gitattributes .gitignore filelist.txt install.ps1 InstallModule.ps1 PublishToGallery.ps1
Pop-Location