[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)] [string] $imageTag = '6.0-alpine',
    [Parameter(Mandatory = $false)] [string] $Path = 'src',   
    [Parameter(Mandatory = $false)] [string[]] $dockerRepository = @('netlah/aspnet-webssh'),
    [Parameter(Mandatory = $false)] [string] $Labels,
    [Parameter(Mandatory = $false)] [switch] $WhatIf
)

$mappingSdkMajor = @{
    '^6\.0(\.\d+)?-alpine(.*)$'               = '6.0-alpine'
    '^6\.0(\.\d+)?-bullseye-slim$'            = '6.0-bullseye-slim'
    '^6\.0(\.\d+)?-focal$'                    = '6.0-focal'
    '^6\.0(\.\d+)?-jammy$'                    = '6.0-jammy'

    '^7\.0(\.\d+(-rc[^-]+)?)?-alpine(.*)$'    = '7.0-alpine'
    '^7\.0(\.\d+(-rc[^-]+)?)?-bullseye-slim$' = '7.0-bullseye-slim'
    '^7\.0(\.\d+(-rc[^-]+)?)?-jammy$'         = '7.0-jammy'
}
$latestTag = '6.0-alpine'   # not use yet

# sdkMajor mappings arch
$mappingArch = @{
    '6.0-alpine'        = 'alpine'
    '6.0-bullseye-slim' = 'debian'
    '6.0-focal'         = 'debian'  #ubuntu 20.04 LTS
    '6.0-jammy'         = 'debian'  #ubuntu 22.04 LTS
    '7.0-alpine'        = 'alpine'
    '7.0-bullseye-slim' = 'debian'
    '7.0-jammy'         = 'debian'  #ubuntu 22.04 LTS
}

function getMajorSdk($imageTag) {
    foreach ($entry in $mappingSdkMajor.GetEnumerator()) {
        if ($imageTag -match $entry.Key) {
            return $entry.Value
        }
    } 
}

$imageTagMajor = getMajorSdk $imageTag
$imageArch = $mappingArch[$imageTagMajor]

if (!$imageTag -or !$imageTagMajor -or !$imageArch) {
    Write-Error "SDK Image Tag '$imageTag' is not supported" -ErrorAction Stop
}

Write-Output "Labels (raw): $Labels"
$labelStrs = $Labels.Trim() -split '\r|\n|;|,' | Where-Object { $_ }

$dockerImages = @()
foreach ($dockerRepos in $dockerRepository) {
    $dockerImages += @("$($dockerRepos):$($imageTag)")
    if ($imageTag -ne $imageTagMajor) {
        $dockerImages += @("$($dockerRepos):$($imageTagMajor)")
    }
    if ($latestTag -eq $imageTagMajor -or $latestTag -eq $imageTag) {
        $dockerImages += @("$($dockerRepos):lastest")
    }
}

$params = @('build', "$Path/$imageArch", '--pull', '--build-arg', "SDK_IMAGE_TAG=$imageTag", '--progress=plain')

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
