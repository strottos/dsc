param (
    [Parameter()]
    [switch]$q
)

if (-not $q) {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

    $modules = @(
        @{
            Name = 'PowerShellGet'
        },
        @{
            Name = 'PackageManagement'
            RequiredVersion = '1.4.7'
        },
        @{
            Name = 'xPSDesiredStateConfiguration'
        },
        @{
            Name = 'cChoco'
        },
        # Can't run -AllowClobber in DSC, just put it here for easy sake
        @{
            Name         = 'pscx'
            AllowClobber = $true
        }
    )
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

    foreach ($module in $modules) {
        Write-Output "[$ENV:COMPUTERNAME] Testing package $($module.Name)"
        $installed = Get-InstalledModule $module.Name -ErrorAction Ignore
        $foundModules = Find-Module $module.Name
        if (-not $module.RequiredVersion) {
            $requiredVersion = ($foundModules | measure-object -Property Version -maximum).maximum
        } else {
            $requiredVersion = $module.RequiredVersion
        }

        if (-not $installed) {
            Write-Output "[$ENV:ComputerName] Installing module $($module.Name) version $requiredVersion"

            Install-Module @module -Force
        } else {
            $installedVersion = $installed.Version
            if ($installedVersion -ne $requiredVersion) {
                Write-Output "[$ENV:ComputerName] Upgrading module $($module.Name) from version $installedVersion to $requiredVersion"
                Update-Module -Name $module.Name -RequiredVersion $requiredVersion -Force
                Uninstall-Module -Name $module.Name -RequiredVersion $installedVersion
            }
        }
    }
}

Import-Module PackageManagement -Verbose:$false

& '.\Export-DesktopDSC.ps1'

if (-not $q -and -not (Test-WSMan localhost -ErrorAction SilentlyContinue)) {
    winrm quickconfig -quiet
}

Set-DscLocalConfigurationManager -Path .\ConfigureDesktopMetaData -Verbose -Force
Start-DscConfiguration -Path .\ConfigureDesktop -Wait -Verbose -Force
