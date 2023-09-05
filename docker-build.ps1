[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)] [string] $imageTag = '6.0-alpine',
    [Parameter(Mandatory = $false)] [string] $Path = 'src',   
    [Parameter(Mandatory = $false)] [string[]] $dockerRepository = @('netlah/aspnet-webssh'),
    [Parameter(Mandatory = $false)] [string] $Labels,
    [Parameter(Mandatory = $false)] [switch] $Squash,
    [Parameter(Mandatory = $false)] [switch] $WhatIf
)

$mappingVersionArch = @{
    '^6\.0(\.\d+)?-alpine(.*)$'             = '6.0-alpine', '6.0'
    '^6\.0(\.\d+)?-bullseye-slim$'          = '6.0-bullseye-slim', '6.0', 'bullseye-slim'
    '^6\.0(\.\d+)?-bookworm-slim$'          = '6.0-bookworm-slim', '6.0', 'bookworm-slim'
    '^6\.0(\.\d+)?-focal$'                  = '6.0-focal', '6.0', 'focal'
    '^6\.0(\.\d+)?-jammy$'                  = '6.0-jammy', '6.0', 'jammy'

    '^7\.0(\.\d+)?-alpine(.*)$'             = '7.0-alpine', '7.0'
    '^7\.0(\.\d+)?-bullseye-slim$'          = '7.0-bullseye-slim', '7.0', 'bullseye-slim'
    '^7\.0(\.\d+)?-bookworm-slim$'          = '7.0-bookworm-slim', '7.0', 'bookworm-slim'
    '^7\.0(\.\d+)?-jammy$'                  = '7.0-jammy', '7.0', 'jammy'

    '^8\.0\.0-preview[^-]+-alpine(.*)$'     = '8.0-preview-alpine', '8.0-alpine', '8.0'
    '^8\.0\.0-preview[^-]+-bookworm-slim$'  = '8.0-preview-bookworm-slim', '8.0-preview', '8.0', 'preview-bookworm-slim', 'bookworm-slim'
    '^8\.0\.0-preview[^-]+-jammy$'          = '8.0-preview-jammy', '8.0-preview', '8.0', 'jammy'
    '^8\.0\.0-preview[^-]+-jammy-chiseled$' = '8.0-preview-jammy-chiseled', '8.0-jammy-chiseled', 'jammy-chiseled'
    
    '^8\.0\.0-rc[^-]+-alpine(.*)$'          = '8.0-rc-alpine', '8.0-alpine', '8.0'
    '^8\.0\.0-rc[^-]+-bookworm-slim$'       = '8.0-rc-bookworm-slim', '8.0-rc', '8.0', 'bookworm-slim'
    '^8\.0\.0-rc[^-]+-jammy$'               = '8.0-rc-jammy', '8.0-rc', '8.0', 'jammy'
    '^8\.0\.0-rc[^-]+-jammy-chiseled$'      = '8.0-rc-jammy-chiseled', '8.0-jammy-chiseled', 'jammy-chiseled'
    
    '^8\.0(\.\d+)?-alpine(.*)$'             = '8.0-alpine', '8.0'
    '^8\.0(\.\d+)?-bookworm-slim$'          = '8.0-bookworm-slim', '8.0', 'bookworm-slim'
    '^8\.0(\.\d+)?-jammy$'                  = '8.0-jammy', '8.0', 'jammy'
    '^8\.0(\.\d+)?-jammy-chiseled$'         = '8.0-jammy-chiseled', 'jammy-chiseled'
}

$latestTag = '6.0-alpine'

# sdkMajor mappings arch
$mappingArch = @{
    '6.0-alpine'                 = 'alpine'
    '6.0-bullseye-slim'          = 'debian'
    '6.0-bookworm-slim'          = 'debian'
    '6.0-focal'                  = 'debian'  #ubuntu 20.04 LTS
    '6.0-jammy'                  = 'debian'  #ubuntu 22.04 LTS
    '7.0-alpine'                 = 'alpine'
    '7.0-bullseye-slim'          = 'debian'
    '7.0-bookworm-slim'          = 'debian'
    '7.0-jammy'                  = 'debian'  #ubuntu 22.04 LTS
    '8.0-preview-alpine'         = 'alpine'
    '8.0-preview-bookworm-slim'  = 'debian'
    '8.0-preview-jammy'          = 'debian'  #ubuntu 22.04 LTS
    '8.0-preview-jammy-chiseled' = 'debian'  #ubuntu 22.04 LTS
    '8.0-rc-alpine'              = 'alpine'
    '8.0-rc-bookworm-slim'       = 'debian'
    '8.0-rc-jammy'               = 'debian'  #ubuntu 22.04 LTS
    '8.0-rc-jammy-chiseled'      = 'debian'  #ubuntu 22.04 LTS
    '8.0-alpine'                 = 'alpine'
    '8.0-bookworm-slim'          = 'debian'
    '8.0-jammy'                  = 'debian'  #ubuntu 22.04 LTS
    '8.0-jammy-chiseled'         = 'debian'  #ubuntu 22.04 LTS
}

function getVersionArch($imageTag) {
    foreach ($entry in $mappingVersionArch.GetEnumerator()) {
        if ($imageTag -match $entry.Key) {
            return [string[]] $entry.Value
        }
    } 
}

$versionArches = getVersionArch $imageTag

$imageTagMajor = $versionArches | Select-Object -Index 0
if ($imageTagMajor) {
    $imageArch = $mappingArch[$imageTagMajor]
}

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
        $dockerImages += @("$($dockerRepos):latest")
    }
}

$sourceImageTag = $imageTag

$params = @('build', "$Path/$imageArch")

foreach ($dockerFile in $versionArches | ForEach-Object { "$Path/$imageArch/Dockerfile-$($_)" }) {
    if (Test-Path -Path $dockerFile -PathType Leaf) {
        $params += @('--file', $dockerFile)
        break
    }
}

$params += @('--pull', '--build-arg', "IMAGE_TAG=$sourceImageTag", '--progress=plain')

if ($Squash -And !($Env:OS)) {
    $params += @('--squash')
}

if ($labelStrs) {
    $params += $labelStrs | ForEach-Object { @('--label', $_) }
}

Write-Output "Docker images: $dockerImages"
[bool]$isGitHubAction = "$Env:GITHUB_ACTIONS" -eq $true
if (!$isGitHubAction) {
    foreach ($dockerImage in $dockerImages) {
        $params += @("--cache-from=$($dockerImage)")
    }
}
foreach ($dockerImage in $dockerImages) {
    $params += @("--tag=$($dockerImage)")
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
