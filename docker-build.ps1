[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)] [string] $imageTag = '6.0-alpine',
    [Parameter(Mandatory = $false)] [string] $Path = 'src',   
    [Parameter(Mandatory = $false)] [string[]] $dockerRepository = @('netlah/aspnet-webssh'),
    [Parameter(Mandatory = $false)] [string] $Labels,
    [Parameter(Mandatory = $false)] [string] $Tags,
    [Parameter(Mandatory = $false)] [switch] $Squash,
    [Parameter(Mandatory = $false)] [switch] $WhatIf
)

$mappingVersionArch = @{
    '^8\.0\.0-preview[^-]+-alpine(.*)$'          = '8.0-preview-alpine', '8.0-alpine', '8.0'
    '^8\.0\.0-preview[^-]+-bookworm-slim$'       = '8.0-preview-bookworm-slim', '8.0-preview', '8.0', 'preview-bookworm-slim', 'bookworm-slim'
    '^8\.0\.0-preview[^-]+-jammy$'               = '8.0-preview-jammy', '8.0-preview', '8.0', 'jammy'
    '^8\.0\.0-preview[^-]+-jammy-chiseled$'      = '8.0-preview-jammy-chiseled', '8.0-jammy-chiseled', 'jammy-chiseled'
    
    '^8\.0\.0-rc[^-]+-alpine(.*)$'               = '8.0-rc-alpine', '8.0-alpine', '8.0'
    '^8\.0\.0-rc[^-]+-bookworm-slim$'            = '8.0-rc-bookworm-slim', '8.0-rc', '8.0-bookworm-slim', '8.0', 'bookworm-slim'
    '^8\.0\.0-rc[^-]+-jammy$'                    = '8.0-rc-jammy', '8.0-rc', '8.0-jammy', '8.0', 'jammy'
    '^8\.0\.0-rc[^-]+-jammy-chiseled$'           = '8.0-rc-jammy-chiseled', '8.0-jammy-chiseled', 'jammy-chiseled'
    
    '^8\.0(\.\d+)?-alpine(.*)$'                  = '8.0-alpine', '8.0'
    '^8\.0(\.\d+)?-bookworm-slim$'               = '8.0-bookworm-slim', '8.0', 'bookworm-slim'
    '^8\.0(\.\d+)?-jammy$'                       = '8.0-jammy', '8.0', 'jammy'
    '^8\.0(\.\d+)?-jammy-chiseled$'              = '8.0-jammy-chiseled', 'jammy-chiseled'
    '^8\.0(\.\d+)?-noble$'                       = '8.0-noble', '8.0', 'noble'
    '^8\.0(\.\d+)?-noble-chiseled$'              = '8.0-noble-chiseled', 'noble-chiseled'
    '^8\.0(\.\d+)?-azurelinux3.0$'               = '8.0-azurelinux3.0', '8.0', 'azurelinux3.0'
    
    '^9\.0(\.\d+)?-preview[^-]*-alpine(.*)$'     = '9.0-preview-alpine', '9.0-alpine', '9.0'
    '^9\.0(\.\d+)?-preview[^-]*-bookworm-slim$'  = '9.0-preview-bookworm-slim', '9.0-preview', '9.0', 'preview-bookworm-slim', 'bookworm-slim'
    '^9\.0(\.\d+)?-preview[^-]*-noble$'          = '9.0-preview-noble', '9.0-noble', '9.0-preview', '9.0', 'noble'
    '^9\.0(\.\d+)?-preview[^-]*-noble-chiseled$' = '9.0-preview-noble-chiseled', '9.0-noble-chiseled', '9.0-preview', 'noble-chiseled'
    
    '^9\.0(\.\d+)?-rc[^-]*-alpine(.*)$'          = '9.0-rc-alpine', '9.0-alpine', '9.0'
    '^9\.0(\.\d+)?-rc[^-]*-bookworm-slim$'       = '9.0-rc-bookworm-slim', '9.0-bookworm-slim', '9.0-rc', '9.0', 'bookworm-slim'
    '^9\.0(\.\d+)?-rc[^-]*-noble$'               = '9.0-rc-noble', '9.0-noble', '9.0-rc', '9.0', 'noble'
    '^9\.0(\.\d+)?-rc[^-]*-noble-chiseled$'      = '9.0-rc-noble-chiseled', '9.0-noble-chiseled', 'noble-chiseled'
    
    '^9\.0(\.\d+)?-alpine(.*)$'                  = '9.0-alpine', '9.0'
    '^9\.0(\.\d+)?-bookworm-slim$'               = '9.0-bookworm-slim', '9.0', 'bookworm-slim'
    '^9\.0(\.\d+)?-noble$'                       = '9.0-noble', '9.0', 'noble'
    '^9\.0(\.\d+)?-noble-chiseled$'              = '9.0-noble-chiseled', 'noble-chiseled'
    '^9\.0(\.\d+)?-azurelinux3.0$'               = '9.0-azurelinux3.0', '9.0', 'noble'
}


# sdkMajor mappings arch
$mappingArch = @{
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
    '8.0-noble'                  = 'debian'  #ubuntu 24.04 LTS
    '8.0-noble-chiseled'         = 'debian'  #ubuntu 24.04 LTS
    '8.0-noble-chiseled-extra'   = 'debian'  #ubuntu 24.04 LTS
    '9.0-preview-alpine'         = 'alpine'
    '9.0-preview-bookworm-slim'  = 'debian'
    '9.0-preview-noble'          = 'debian'  #ubuntu 22.04 LTS
    '9.0-preview-noble-chiseled' = 'debian'  #ubuntu 22.04 LTS
    '9.0-rc-alpine'              = 'alpine'
    '9.0-rc-bookworm-slim'       = 'debian'
    '9.0-rc-noble'               = 'debian'  #ubuntu 22.04 LTS
    '9.0-rc-noble-chiseled'      = 'debian'  #ubuntu 22.04 LTS
    '9.0-alpine'                 = 'alpine'
    '9.0-bookworm-slim'          = 'debian'
    '9.0-noble'                  = 'debian'  #ubuntu 24.04 LTS
    '9.0-noble-chiseled'         = 'debian'  #ubuntu 24.04 LTS
}

function private:AddDockerImage($image) {
    if ($image -And !($script:dockerImages -Contains $image)) {
        $script:dockerImages += @($image)
    }
}

foreach ($entry in $mappingVersionArch.GetEnumerator()) {
    if ($imageTag -match $entry.Key) {
        $versionArches = [string[]] $entry.Value
    }
} 

$imageTagMajor = $versionArches | Select-Object -Index 0
if ($imageTagMajor) {
    $imageArch = $mappingArch[$imageTagMajor]
}

if (!$imageTag -or !$imageTagMajor -or !$imageArch) {
    Write-Error "SDK Image Tag '$imageTag' is not supported" -ErrorAction Stop
}

Write-Output "Labels (raw): $Labels"
$labelStrs = $Labels.Trim() -split '\r|\n|;|,' | Where-Object { $_ }
$tagStrs = $Tags.Trim() -split '\r|\n|;|,' | Where-Object { $_ }

$dockerImages = @()
foreach ($dockerRepos in $dockerRepository) {
    AddDockerImage "$($dockerRepos):$($imageTag)"
    foreach ($tag1 in $tagStrs) {
        AddDockerImage "$($dockerRepos):$($tag1)"
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
