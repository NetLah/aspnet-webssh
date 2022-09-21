[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)] [string] $sdkImageTag = '6.0-alpine',
    [Parameter(Mandatory = $true)] [string[]] $dockerRepository = @('netlah/aspnet-ssh'),
    [Parameter(Mandatory = $true)] [string] $Path = 'bin',
    [Parameter(Mandatory = $false)] [string] $Labels,
    [Parameter(Mandatory = $false)] [switch] $WhatIf
)

$supported = @(
    '6.0.8-alpine3.16', '6.0-alpine'
    '6.0.8-bullseye-slim', '6.0-bullseye-slim'
    '6.0.8-focal', '6.0-focal'
    '6.0.8-jammy', '6.0-jammy'

    '6.0.9-alpine3.16', '6.0-alpine'
    '6.0.9-bullseye-slim', '6.0-bullseye-slim'
    '6.0.9-focal', '6.0-focal'
    '6.0.9-jammy', '6.0-jammy'

    '7.0.0-rc.1-alpine3.16', '7.0-alpine'
    '7.0.0-rc.1-bullseye-slim', '7.0-bullseye-slim'
    '7.0.0-rc.1-jammy', '7.0-jammy'
)
$mappingSdk = @{
    '6.0.8-alpine3.16'         = '6.0-alpine'
    '6.0.8-bullseye-slim'      = '6.0-bullseye-slim'
    '6.0.8-focal'              = '6.0-focal'
    '6.0.8-jammy'              = '6.0-jammy'

    '6.0.9-alpine3.16'         = '6.0-alpine'
    '6.0.9-bullseye-slim'      = '6.0-bullseye-slim'
    '6.0.9-focal'              = '6.0-focal'
    '6.0.9-jammy'              = '6.0-jammy'
    '7.0.0-rc.1-alpine3.16'    = '7.0-alpine'
    '7.0.0-rc.1-bullseye-slim' = '7.0-bullseye-slim'
    '7.0.0-rc.1-jammy'         = '7.0-jammy'

    '6.0-alpine'               = '6.0-alpine'
    '6.0-bullseye-slim'        = '6.0-bullseye-slim'
    '6.0-focal'                = '6.0-focal'
    '6.0-jammy'                = '6.0-jammy'
    '7.0-alpine'               = '7.0-alpine'
    '7.0-bullseye-slim'        = '7.0-bullseye-slim'
    '7.0-jammy'                = '7.0-jammy'
}
$latestTag = '6.0-alpine'   # not use yet
# context mapping name
$mapping = @{
    '6.0-alpine'        = [string[]]@('alpine', '6.0-alpine')
    '6.0-bullseye-slim' = [string[]]@('debian')
    '6.0-focal'         = [string[]]@('debian') #ubuntu
    '6.0-jammy'         = [string[]]@('debian') #ubuntu
    '7.0-alpine'        = [string[]]@('alpine', '6.0-alpine')
    '7.0-bullseye-slim' = [string[]]@('debian')
    '7.0-jammy'         = [string[]]@('debian') #ubuntu
}
# sharing mapping name
$sharing = @{
    '6.0-alpine'        = [string[]]@('base_docker', 'shared')
    '6.0-bullseye-slim' = [string[]]@('base_docker', 'shared')
    '6.0-focal'         = [string[]]@('base_docker', 'shared')
    '6.0-jammy'         = [string[]]@('base_docker', 'shared')
    '7.0-alpine'        = [string[]]@('base_docker', 'shared')
    '7.0-bullseye-slim' = [string[]]@('base_docker', 'shared')
    '7.0-jammy'         = [string[]]@('base_docker', 'shared')
}

$sdkImageTagMajor = $mappingSdk[$sdkImageTag]
[string[]]$contextNames = $mapping[$sdkImageTagMajor]

if (!$contextNames -or !$sdkImageTag -or !$sdkImageTagMajor -or !$supported.Contains($sdkImageTag)) {
    Write-Error "SDK Image Tag '$sdkImageTag' is not supported" -ErrorAction Stop
}

Write-Output "Labels (raw): $Labels"
$labelStrs = $Labels.Trim() -split '\r|\n|;|,' | Where-Object { $_ }

[string[]]$shares = $sharing[$sdkImageTagMajor]
[string[]]$dockerContexts = @() + $shares + $contextNames

$dockerImages = @()
foreach ($dockerRepos in $dockerRepository) {
    $dockerImages += @("$($dockerRepos):$($sdkImageTag)")
    if ($sdkImageTag -ne $sdkImageTagMajor) {
        $dockerImages += @("$($dockerRepos):$($sdkImageTagMajor)")
    }
    if ($latestTag -eq $sdkImageTagMajor -or $latestTag -eq $sdkImageTag) {
        $dockerImages += @("$($dockerRepos):lastest")
    }
}

Remove-Item -Path $Path -Recurse -Force -Confirm:$false -ErrorAction Ignore -Verbose
$buildFolder = New-Item -Name $Path -ItemType 'Directory' -ErrorAction Stop

Write-Host "Copy from contexts: $dockerContexts"
$dockerContextSource = "src"
foreach ($dockerContext in $dockerContexts) {
    Write-Verbose "Source: '$dockerContextSource/$dockerContext'"
    Write-Verbose "Destination: '$($buildFolder.FullName)' '$buildFolder'"
    Copy-Item -Recurse -Force -Path "$dockerContextSource/$dockerContext/*" -Destination $Path  -ErrorAction Stop -Verbose
}

$params = @('build', $Path, '--pull', '--build-arg', "SDK_IMAGE_TAG=$sdkImageTag", '--progress=plain')

if ($labelStrs) {
    $params += $labelStrs | ForEach-Object { @('--label', $_) }
}

Write-Output "Docker images: $dockerImages"
foreach ($dockerImage in $dockerImages) {
    $params += @("--cache-from=$($dockerImage)", "--tag=$($dockerImage)")
}

Write-Verbose "Execute: docker $params"
docker @params
if (!$?) {
    $saveLASTEXITCODE = $LASTEXITCODE
    Write-Error "docker build failed (exit=$saveLASTEXITCODE)"
    exit $saveLASTEXITCODE
}

if (!$WhatIf -And $dockerImages) {
    Write-Host "Pushing docker images"
    foreach ($dockerImage in $dockerImages) {
        docker push $dockerImage
        if (!$?) {
            $saveLASTEXITCODE = $LASTEXITCODE
            Write-Error "docker push failed (exit=$saveLASTEXITCODE)"
            exit $saveLASTEXITCODE
        }
    }
}
