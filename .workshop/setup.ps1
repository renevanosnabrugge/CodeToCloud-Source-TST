param
(
    [string] $GH_Token
)

#Requires -Version 7.0

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

$templatePath = (join-path $PSScriptRoot "settings-template.json")
$settingsPath = (join-path $PSScriptRoot "settings.json")

$template = Get-Content $templatePath | ConvertFrom-Json

if (Test-Path -PathType Leaf $settingsPath) {
  $current = Get-Content (join-path $PSScriptRoot "settings.json") | ConvertFrom-Json
}
else {
  $current = $template
}

$repo = $(git remote get-url origin)
$default = Get-Default @($current.TargetRepo, $template.TargetRepo, $repo)
$current.TargetRepo = Get-Default @((Read-Host -Prompt "Github reporitory url ($default)"), $default)
Set-Content $settingsPath (ConvertTo-Json $current) 

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
$current.AzDoOrganization = Get-Default @((Read-Host -Prompt "Azure DevOps Organization ($default)"), $default)
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
$current.AzDoProject = Get-Default @((Read-Host -Prompt "Azure DevOps Project Name ($default)"), $default)
Set-Content $settingsPath (ConvertTo-Json $current) 

$default = Get-Default @($current.Student, $template.Student, "student")
$current.Student = Get-Default @((Read-Host -Prompt "Student ($default)"), $default)
Set-Content $settingsPath (ConvertTo-Json $current) 

#login to azure devops
$env:AZURE_DEVOPS_EXT_PAT = $current.AzDoPAT

# Check if project exists, create if needed.
$projectExists = ((az devops project list --org https://dev.azure.com/$($current.AzDoOrganization) | ConvertFrom-Json).value | ?{ $_.name -eq $current.AzDoProject } ).count -gt 0

if (-not ($projectExists))
{
  az devops project create --name $current.AzDoProject --org https://dev.azure.com/$($current.AzDoOrganization) --process "basic"
}

# create work items
$workitems = @(az boards query --wiql "SELECT [System.Id] FROM workitems WHERE [System.TeamProject] = '$($current.AzDoProject)' AND [System.WorkItemType] = 'Issue' AND [System.Title] CONTAINS 'Module'" --project $current.AzDoProject --org https://dev.azure.com/$($current.AzDoOrganization) | ConvertFrom-Json)
#if ($workitems.Count -eq 4)
# delete work items if they exist?

Write-Host "(Re)create workitems?"
Switch -Regex (Read-Host "(Y/n)") 
{ 
   "(|[yY])" { 
    if ($workitems.count -gt 0)
    {
      $workitems | %{ az boards work-item delete --id $_.id --yes --project $current.AzDoProject --org https://dev.azure.com/$($current.AzDoOrganization) } | Out-Null
    }

    $current.WorkItemIdModule1 = ( az boards work-item create --type "Issue" --title "Module 1" --project $current.AzDoProject --org https://dev.azure.com/$($current.AzDoOrganization) | ConvertFrom-Json ).id
    $current.WorkItemIdModule2 = ( az boards work-item create --type "Issue" --title "Module 2" --project $current.AzDoProject --org https://dev.azure.com/$($current.AzDoOrganization) | ConvertFrom-Json ).id
    $current.WorkItemIdModule3 = ( az boards work-item create --type "Issue" --title "Module 3" --project $current.AzDoProject --org https://dev.azure.com/$($current.AzDoOrganization) | ConvertFrom-Json ).id
    $current.WorkItemIdModule4 = ( az boards work-item create --type "Issue" --title "Module 4" --project $current.AzDoProject --org https://dev.azure.com/$($current.AzDoOrganization) | ConvertFrom-Json ).id
  } 
} 

Set-Content $settingsPath (ConvertTo-Json $current) 