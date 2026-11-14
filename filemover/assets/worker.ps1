param(
    [Parameter(Mandatory=$true)][string]$EnginePath,
    [Parameter(Mandatory=$true)][string]$RequestBase64
)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
try {
    Add-Type -Path $EnginePath -ReferencedAssemblies System.Web.Extensions
    [FileMover.Engine]::Run($RequestBase64)
} catch {
    @{ type = 'error'; message = $_.Exception.Message } | ConvertTo-Json -Compress
    exit 1
}
