
<#
// install chef-client with /i switch
// Actions: (do what windows bootstrap template)
//    - install chef-client

#>

function Chef-GetScriptDirectory
{
  $Invocation = (Get-Variable MyInvocation -Scope 1).Value
  Split-Path $Invocation.MyCommand.Path
}

$scriptDir = Chef-GetScriptDirectory

function Get-ChefClientMsiLogPath {
  # In current version we pick up the latest msi from within zip package.
  "$env:temp\\chef-client-msi806.log"
}

function Archive-ChefClientLog($chefClientMsiLogPath) {
  echo "Archiving previous chef-client msi log."
  mv $chefClientMsiLogPath "$chefClientMsiLogPath.$(get-date -f yyyyMMddhhmmss)"
}

function Run-ChefInstaller($localDestinationMsiPath, $chefClientMsiLogPath) {
  echo "Installing chef"
  Start-Process -FilePath "msiexec.exe" -ArgumentList "/qn /log $chefClientMsiLogPath /i $localDestinationMsiPath" -Wait -Passthru
}

function Install-AzureChefExtensionGem($chefExtensionRoot) {
  # Install the custom gem
  echo "Installing Azure-Chef-Extension gem"
  gem install "$chefExtensionRoot\\gems\\*.gem" --no-ri --no-rdoc
}

function Chef-GetExtensionRoot {
  $chefExtensionRoot = [System.IO.Path]::GetFullPath("$scriptDir\\..")
  $chefExtensionRoot
}

function Get-SharedHelper {
  $chefExtensionRoot = Chef-GetExtensionRoot
  "$chefExtensionRoot\\bin\\shared.ps1"
}

function Get-LocalDestinationMsiPath($chefExtensionRoot) {
  [System.IO.Path]::GetFullPath("$chefExtensionRoot\\installer\\chef-client-latest.msi")
}

function Install-ChefClient {
  trap [Exception] {echo $_.Exception.Message;exit 1}
  # Source the shared PS
  . $(Get-SharedHelper)

  $chefExtensionRoot = Chef-GetExtensionRoot

  $chefClientMsiLogPath = Get-ChefClientMsiLogPath

  if (Test-Path $chefClientMsiLogPath) {
    Archive-ChefClientLog $chefClientMsiLogPath
  }

  $localDestinationMsiPath = Get-LocalDestinationMsiPath $chefExtensionRoot

  Run-ChefInstaller $localDestinationMsiPath $chefClientMsiLogPath

  $env:Path += ";C:\\opscode\\chef\\bin;C:\\opscode\\chef\\embedded\\bin"

  Install-AzureChefExtensionGem $chefExtensionRoot

  # Add scriptDir to path so azure chef-client is picked up henceforth
  Chef-AddToPath $scriptDir
}

Export-ModuleMember -Function Install-ChefClient