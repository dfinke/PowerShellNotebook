function New-InteractiveNotebook {
    <#
    .SYNOPSIS
        Create a new interactive notebook as a `dib` or `ipynb`, launching vscode
    .EXAMPLE
        New-InteractiveNotebook # Creates a new ipnyb interactive notebook 
    .EXAMPLE
        New-InteractiveNotebook -AsDib # Creates a new dib interactive notebook 
    #>
    param(
        [Switch]$AsDib
    )
    
    Start-Process ("vscode://ms-dotnettools.dotnet-interactive-vscode/newNotebook?as={0}" -f ($AsDib ? 'dib':'ipynb'))
}
