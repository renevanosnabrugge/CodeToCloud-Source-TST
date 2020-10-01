param
(
    [string] $GH_Token
)

function Get-Default {
  [CmdletBinding()]
  param(
      [parameter(ValueFromRemainingArguments=$true)]
      [string[]]$values
  )

  foreach ($item in $values) {
      if ($item)
      {
          return $item
      }
  }
}

$templatePath = (join-path $PSScriptRoot ".\settings-template.json")
$settingsPath = (join-path $PSScriptRoot ".\settings.json")

$template = Get-Content $templatePath | ConvertFrom-Json

if (Test-Path -PathType Leaf $settingsPath) {
  $current = Get-Content (join-path $PSScriptRoot ".\settings.json") | ConvertFrom-Json
}
else {
  $current = $template
}

if ($current.GithubToken)
{
  Write-Host "A Github token is already stored. Overwrite?"
  Switch (Read-Host "(y/N)") 
  { 
    Y { $current.GithubToken = "" } 
  } 
}
if (-not ($current.GithubToken))
{
  Write-Host "Please go to https://github.com/settings/tokens/new and create a new Oauth token with the following scopes:"
  Write-Host " + repo"
  Write-Host " + read:packages"
  Write-Host " + write:packages"
  Write-Host " + read:org"
  Write-Host " + workflow"

  $current.GithubToken = Read-Host -Prompt 'Github Token'
}
Set-Content $settingsPath (ConvertTo-Json $current) 

$default = Get-Default @($current.AzDoOrganization, $template.AzDoOrganization)
$current.AzDoOrganization = (Read-Host -Prompt "Azure DevOps Organization ($default)") ?? $default
Set-Content $settingsPath (ConvertTo-Json $current) 

if ($current.AzDoPAT)
{
  Write-Host "A Azure DevOps token is already stored. Overwrite?"
  Switch (Read-Host "(y/N)") 
  { 
    Y { $current.AzDoPAT = "" } 
  } 
}
if (-not ($current.AzDoPAT))
{
  Write-Host "Please go to https://dev.azure.com/$($current.AzDoOrganization)/_usersSettings/tokens and create a new Oauth token with the following scopes:"
  Write-Host " + Work Items: Read & Write"
  Write-Host " + Build: Read & Execute"
  Write-Host " + Project & Team: Read, Write & Manage"

  $current.AzDoPAT = Read-Host -Prompt 'Azure DevOps Token'
}
Set-Content $settingsPath (ConvertTo-Json $current) 

$default = Get-Default @($current.AzDoProject, $template.AzDoProject, "CodeToCloud-Workshop")
$current.AzDoProject = (Read-Host -Prompt "Azure DevOps Project Name ($default)") ?? $default
Set-Content $settingsPath (ConvertTo-Json $current) 

$default = Get-Default @($current.Student, $template.Student, "student")
$current.Student = (Read-Host -Prompt "Student ($default)") ?? $default
Set-Content $settingsPath (ConvertTo-Json $current) 

# Check if project exists, create if needed.
# create work items

Set-Content $settingsPath (ConvertTo-Json $current) 

