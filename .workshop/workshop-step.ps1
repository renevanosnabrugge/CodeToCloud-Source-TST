param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Exercise,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('Start','Solution')]
    [string]$Action
)

$settingsDirectory = join-path $(git rev-parse --show-toplevel) ".workshop"
$settingsFile = join-path $settingsDirectory "settings.json"
$container = "ghcr.io/xpiritbv/ghws-fix"

if (-not (Test-Path -PathType Leaf $settingsFile))
{
    throw "Couldn't find settings file: $settingsFile"
}

$dockerCommand = "docker run -e ACTION=$Action -e EXERCISE=$Exercise -e settingsLocation=/settings/settings.json -v $($settingsDirectory):/settings $container"
Invoke-Expression -Command $dockerCommand