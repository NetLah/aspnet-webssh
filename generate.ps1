[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)] [string] $Path = 'src'
)

# docker context arch mapping names
$mappingDockerContext = @{
    'alpine' = [string[]]@('base_docker', 'shared', 'alpine')
    'debian' = [string[]]@('base_docker', 'shared', 'debian')
}

$dockerContextSource = "eng"

Remove-Item -Path $Path -Recurse -Force -Confirm:$false -ErrorAction Ignore -Verbose
$srcFolder = New-Item -Name $Path -ItemType 'Directory' -ErrorAction Stop

foreach ($arch in $mappingDockerContext.Keys) {
    Write-Host "Proceed Arch $arch"

    [string[]]$dockerContexts = $mappingDockerContext[$arch]
    $archDockerContext = New-Item -Name $arch -Path $srcFolder -ItemType 'Directory' -ErrorAction Stop

    foreach ($dockerContext in $dockerContexts) {
        Copy-Item -Recurse -Force -Path "$dockerContextSource/$dockerContext/*" -Destination $archDockerContext  -ErrorAction Stop -Verbose
    }
}
