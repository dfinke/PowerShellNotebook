Import-Module D:\mygit\Pode.Web\src\Pode.Web.psd1 -Force

Start-PodeServer {
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging
    Use-PodeWebTemplates -Title Test

    Set-PodeState -Name fileName -Value "$PSScriptRoot\data.csv"

    Add-PodeRoute -Method Post -Path '/api/test' -ContentType 'application/json' -ScriptBlock {
        $fileName = Get-PodeState -Name fileName

        $(
            if (Test-Path $fileName) { Import-Csv $fileName }
            
            [PSCustomObject]$WebEvent.Data
        ) | Export-Csv -Path $fileName
    }

    $table3 = New-PodeWebTable -Name 'PowerShell Notebook Runs' -ScriptBlock {
        $fileName = Get-PodeState -Name fileName
        if (Test-Path $fileName) {
            Import-Csv $fileName
        }
        else {
            $null
        }
    }

    Set-PodeWebHomePage -Components $table3
}