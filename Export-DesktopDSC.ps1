$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName = '*'
        }
    )
}

Configuration Git {
    param(
        [Parameter(Mandatory)]
        [string]$RepositoryURL,

        [Parameter(Mandatory)]
        [string]$Destination
    )

    Write-Verbose "Git cloning $RepositoryURL to $Destination"

    Script CloneOrUpdate {
        GetScript = {
            @{
                Result = $true
            }
        }

        SetScript = {
            if (-not (Test-Path -Path $using:Destination)) {
                Write-Verbose "Cloning git repository $using:RepositoryURL"
                New-Item -ItemType Directory -Force -Path $using:Destination

                # Prevent git prompting for credentials so it fails if repository doesn't exist
                $env:GIT_TERMINAL_PROMPT=0
                $env:GCM_INTERACTIVE='never'

                & git.exe clone -q $using:RepositoryURL $using:Destination | Out-Default

                if ($lastExitCode -ne 0) {
                    throw 'Git failed to complete successfully with error code $lastExitCode'
                }
            } else {
                Write-Verbose "Updating directory $using:Destination"

                Push-Location $using:Destination
                & git.exe pull
                Pop-Location

                if ($lastExitCode -ne 0) {
                    throw 'Git failed to complete successfully with error code $lastExitCode'
                }
            }
        }

        TestScript = {
            if (-not (Test-Path -Path $using:Destination)) {
                return $false
            }

            Write-Verbose 'Checking if we are behind origin'
            Push-Location $using:Destination
            & git.exe fetch 2>&1
            $output = git.exe status
            Pop-Location

            if ($output | Where-Object {$_ -match 'Your branch is behind '}) {
                Write-Verbose 'We are behind origin'
                return $false
            }

            Write-Verbose 'We are up to date'
            return $true
        }
    }
}

Configuration ConfigureDesktop {
    Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'PackageManagement' -ModuleVersion '1.4.7'
    Import-DscResource -ModuleName 'xPSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'cChoco'

    Node localhost {
        File ToolsDirectory {
            Ensure          = 'Present'
            Type            = 'Directory'
            DestinationPath = 'C:\Program Files\tools'
            Force           = $true
        }

        File DSCPackagesDirectory {
            Ensure          = 'Present'
            Type            = 'Directory'
            DestinationPath = "$ENV:USERPROFILE\Downloads\DSCPackagesDirectory"
            Force           = $true
        }

        PackageManagementSource PSGallery {
            Ensure             = 'Present'
            Name               = 'PSGallery'
            ProviderName       = 'PowerShellGet'
            SourceLocation     = 'https://www.powershellgallery.com/api/v2'
            InstallationPolicy = 'Trusted'
        }

        PackageManagement CredentialManager {
            Name           = 'CredentialManager'
            Ensure         = 'Present'
            Source         = 'PSGallery'
            MinimumVersion = '2.0'
            DependsOn      = '[PackageManagementSource]PSGallery'
        }

        PackageManagement PoshGit {
            Name           = 'posh-git'
            Ensure         = 'Present'
            Source         = 'PSGallery'
            DependsOn      = '[PackageManagementSource]PSGallery'
        }

        cChocoInstaller installChoco {
            InstallDir = 'c:\ProgramData\chocolatey'
        }

        cChocoPackageInstaller PSScriptAnalyzer {
            Name         = 'psscriptanalyzer'
            AutoUpgrade = $true
            DependsOn   = '[cChocoInstaller]installChoco'
        }

        cChocoPackageInstaller Git {
            Name        = 'git'
            AutoUpgrade = $true
            DependsOn   = '[cChocoInstaller]installChoco'
        }

        cChocoPackageInstaller RipGrep {
            Name        = 'ripgrep'
            AutoUpgrade = $true
            DependsOn   = '[cChocoInstaller]installChoco'
        }

        # Run by hand for now the Visual Studio install, takes too long for DSC plus upgrade complexity
        # TODO: Can we find a better solution? Other stuff will fail without this
        # but I can maybe live with this one step as manual.
        #
        # cChocoPackageInstaller VisualStudio2019Community {
        #     Name        = 'visualstudio2019community'
        #     params      = '--allWorkloads --includeRecommended --includeOptional --passive --locale en-US'
        #     DependsOn   = '[cChocoInstaller]installChoco'
        #     AutoUpgrade = $true
        # }

        File PowershellProfile {
            Ensure          = 'Present'
            Type            = 'File'
            SourcePath      = "$PSScriptRoot\profile.ps1"
            DestinationPath = "$ENV:USERPROFILE\Documents\WindowsPowerShell\profile.ps1"
            Force           = $true
            Checksum        = 'SHA-1'
            # DependsOn       = '[cChocoPackageInstaller]VisualStudio2019Community'
        }

        # TODO: Take out? Seems broken... Easily installed through app store
        # cChocoPackageInstaller Terminal {
        #     Name        = 'microsoft-windows-terminal'
        #     DependsOn   = '[cChocoInstaller]installChoco'
        #     AutoUpgrade = $true
        # }

        cChocoPackageInstaller Vim {
            Name        = 'vim-tux'
            DependsOn   = '[cChocoInstaller]installChoco'
            AutoUpgrade = $true
        }

        File VimRC {
            Ensure          = 'Present'
            Type            = 'File'
            SourcePath      = "$PSScriptRoot\vimrc"
            DestinationPath = 'C:\Program Files\Vim\_vimrc'
            Force           = $true
            Checksum        = 'SHA-1'
            DependsOn       = '[cChocoPackageInstaller]Vim'
        }

        xRemoteFile DownloadPathogen {
            DestinationPath = 'C:\Program Files\Vim\vimfiles\autoload\pathogen.vim'
            Uri             = 'https://tpo.pe/pathogen.vim'
            DependsOn       = '[cChocoPackageInstaller]Vim'
        }

        Git CloneVimAle {
            RepositoryURL = 'https://github.com/dense-analysis/ale'
            Destination   = 'C:\Program Files\Vim\vimfiles\bundle\ale'
            DependsOn     = @('[cChocoPackageInstaller]Vim','[cChocoPackageInstaller]Git')
        }

        Git CloneVimNerdtree {
            RepositoryURL = 'https://github.com/preservim/nerdtree'
            Destination   = 'C:\Program Files\Vim\vimfiles\bundle\nerdtree'
            DependsOn     = @('[cChocoPackageInstaller]Vim','[cChocoPackageInstaller]Git')
        }

        Git CloneVimDirdiff {
            RepositoryURL = 'https://github.com/will133/vim-dirdiff'
            Destination   = 'C:\Program Files\Vim\vimfiles\bundle\dirdiff'
            DependsOn     = @('[cChocoPackageInstaller]Vim','[cChocoPackageInstaller]Git')
        }

        cChocoPackageInstaller NeoVim {
            Name        = 'neovim'
            DependsOn   = '[cChocoInstaller]installChoco'
            AutoUpgrade = $true
            Params      = '--pre'
        }

        File NeoVimRC {
            Ensure          = 'Present'
            Type            = 'File'
            SourcePath      = "$PSScriptRoot\init.vim"
            DestinationPath = 'C:\Users\steve\AppData\Local\nvim\init.vim'
            Force           = $true
            Checksum        = 'SHA-1'
            DependsOn       = '[cChocoPackageInstaller]NeoVim'
        }

        File NeoVimQTRC {
            Ensure          = 'Present'
            Type            = 'File'
            SourcePath      = "$PSScriptRoot\ginit.vim"
            DestinationPath = 'C:\Users\steve\AppData\Local\nvim\ginit.vim'
            Force           = $true
            Checksum        = 'SHA-1'
            DependsOn       = '[cChocoPackageInstaller]NeoVim'
        }

        Git CloneNeoVimCmpBuffer {
            RepositoryURL = 'https://github.com/hrsh7th/cmp-buffer'
            Destination   = 'C:\Users\steve\AppData\Local\nvim\bundle\cmp-buffer'
            DependsOn     = @('[cChocoPackageInstaller]NeoVim','[cChocoPackageInstaller]Git')
        }

        Git CloneNeoVimCmpCmdline {
            RepositoryURL = 'https://github.com/hrsh7th/cmp-cmdline'
            Destination   = 'C:\Users\steve\AppData\Local\nvim\bundle\cmp-cmdline'
            DependsOn     = @('[cChocoPackageInstaller]NeoVim','[cChocoPackageInstaller]Git')
        }

        Git CloneNeoVimCmpVvimLsp {
            RepositoryURL = 'https://github.com/hrsh7th/cmp-nvim-lsp'
            Destination   = 'C:\Users\steve\AppData\Local\nvim\bundle\cmp-nvim-lsp'
            DependsOn     = @('[cChocoPackageInstaller]NeoVim','[cChocoPackageInstaller]Git')
        }

        Git CloneNeoVimCmpPath {
            RepositoryURL = 'https://github.com/hrsh7th/cmp-path'
            Destination   = 'C:\Users\steve\AppData\Local\nvim\bundle\cmp-path'
            DependsOn     = @('[cChocoPackageInstaller]NeoVim','[cChocoPackageInstaller]Git')
        }

        Git CloneNeoVimCmpVsnip {
            RepositoryURL = 'https://github.com/hrsh7th/cmp-vsnip'
            Destination   = 'C:\Users\steve\AppData\Local\nvim\bundle\cmp-vsnip'
            DependsOn     = @('[cChocoPackageInstaller]NeoVim','[cChocoPackageInstaller]Git')
        }

        Git CloneNeoVimCmpLuasnip {
            RepositoryURL = 'https://github.com/saadparwaiz1/cmp_luasnip'
            Destination   = 'C:\Users\steve\AppData\Local\nvim\bundle\cmp_luasnip'
            DependsOn     = @('[cChocoPackageInstaller]NeoVim','[cChocoPackageInstaller]Git')
        }

        Git CloneNeoVimLuaSnip {
            RepositoryURL = 'https://github.com/L3MON4D3/LuaSnip'
            Destination   = 'C:\Users\steve\AppData\Local\nvim\bundle\LuaSnip'
            DependsOn     = @('[cChocoPackageInstaller]NeoVim','[cChocoPackageInstaller]Git')
        }

        Git CloneNeoVimNvimCmp {
            RepositoryURL = 'https://github.com/hrsh7th/nvim-cmp'
            Destination   = 'C:\Users\steve\AppData\Local\nvim\bundle\nvim-cmp'
            DependsOn     = @('[cChocoPackageInstaller]NeoVim','[cChocoPackageInstaller]Git')
        }

        Git CloneNeoVimNvimLspInstaller {
            RepositoryURL = 'https://github.com/williamboman/nvim-lsp-installer'
            Destination   = 'C:\Users\steve\AppData\Local\nvim\bundle\nvim-lsp-installer'
            DependsOn     = @('[cChocoPackageInstaller]NeoVim','[cChocoPackageInstaller]Git')
        }

        Git CloneNeoVimNvimLspconfig {
            RepositoryURL = 'https://github.com/neovim/nvim-lspconfig'
            Destination   = 'C:\Users\steve\AppData\Local\nvim\bundle\nvim-lspconfig'
            DependsOn     = @('[cChocoPackageInstaller]NeoVim','[cChocoPackageInstaller]Git')
        }

        Git CloneNeoVimPlenary {
            RepositoryURL = 'https://github.com/nvim-lua/plenary.nvim'
            Destination   = 'C:\Users\steve\AppData\Local\nvim\bundle\plenary.nvim'
            DependsOn     = @('[cChocoPackageInstaller]NeoVim','[cChocoPackageInstaller]Git')
        }

        Git CloneNeoVimPopup {
            RepositoryURL = 'https://github.com/nvim-lua/popup.nvim'
            Destination   = 'C:\Users\steve\AppData\Local\nvim\bundle\popup.nvim'
            DependsOn     = @('[cChocoPackageInstaller]NeoVim','[cChocoPackageInstaller]Git')
        }

        Git CloneNeoVimRustTools {
            RepositoryURL = 'https://github.com/simrat39/rust-tools.nvim'
            Destination   = 'C:\Users\steve\AppData\Local\nvim\bundle\rust-tools.nvim'
            DependsOn     = @('[cChocoPackageInstaller]NeoVim','[cChocoPackageInstaller]Git')
        }

        # Git CloneNeoVimTelescope {
        #     RepositoryURL = 'https://github.com/nvim-telescope/telescope.nvim'
        #     Destination   = 'C:\Users\steve\AppData\Local\nvim\bundle\telescope.nvim'
        #     DependsOn     = @('[cChocoPackageInstaller]NeoVim','[cChocoPackageInstaller]Git')
        # }

        Git CloneNeoVimVimEasyAlign {
            RepositoryURL = 'https://github.com/junegunn/vim-easy-align'
            Destination   = 'C:\Users\steve\AppData\Local\nvim\bundle\vim-easy-align'
            DependsOn     = @('[cChocoPackageInstaller]NeoVim','[cChocoPackageInstaller]Git')
        }

        Git CloneNeoVimVimVsnip {
            RepositoryURL = 'https://github.com/hrsh7th/vim-vsnip'
            Destination   = 'C:\Users\steve\AppData\Local\nvim\bundle\vim-vsnip'
            DependsOn     = @('[cChocoPackageInstaller]NeoVim','[cChocoPackageInstaller]Git')
        }

        Git CloneNeoVimGruvbox {
            RepositoryURL = 'https://github.com/morhetz/gruvbox'
            Destination   = 'C:\Users\steve\AppData\Local\nvim\bundle\gruvbox'
            DependsOn     = @('[cChocoPackageInstaller]NeoVim','[cChocoPackageInstaller]Git')
        }

        cChocoPackageInstaller NodeJS {
            Name        = 'nodejs-lts'
            DependsOn   = '[cChocoInstaller]installChoco'
            AutoUpgrade = $true
        }

        cChocoPackageInstaller Python {
            Name        = 'python'
            DependsOn   = '[cChocoInstaller]installChoco'
            AutoUpgrade = $true
        }

        Script RunRefreshEnv {
            GetScript = {
                @{
                    Result = $true
                }
            }

            SetScript = {
                & RefreshEnv.cmd
            }

            TestScript = {
                return $false
            }

            DependsOn  = '[cChocoPackageInstaller]Python'
        }

        cChocoPackageInstaller Golang {
            Name        = 'golang'
            DependsOn   = '[cChocoInstaller]installChoco'
            AutoUpgrade = $true
        }

        # Environment CargoHome {
        #     Name   = 'CARGO_HOME'
        #     Value  = 'C:\Program Files\Rust'
        #     Ensure = 'Present'
        # }

        # Environment RustupHome {
        #     Name   = 'RUSTUP_HOME'
        #     Value  = 'C:\Program Files\Rustup'
        #     Ensure = 'Present'
        # }

        # File RustupDirectory {
        #     Ensure          = 'Present'
        #     Type            = 'Directory'
        #     DestinationPath = 'C:\Program Files\Rustup'
        #     Force           = $true
        # }

        # Script InstallRust {
        #     GetScript = {
        #         @{
        #             Result = $true
        #         }
        #     }

        #     SetScript = {
        #         if (-not (Test-Path -Path $ENV:CARGO_HOME)) {
        #             Invoke-WebRequest -Uri 'https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe' -OutFile "$ENV:RUSTUP_HOME\rustup-init.exe"
        #             & "$ENV:RUSTUP_HOME\rustup-init.exe" --profile complete --default-toolchain nightly -y -q 2>$null
        #             Remove-Item "$ENV:RUSTUP_HOME\rustup-init.exe"
        #         }

        #         & "$ENV:CARGO_HOME\bin\rustup.exe" update -q 2>$null
        #     }

        #     TestScript = {
        #         if (-not (Test-Path -Path $ENV:CARGO_HOME\bin\rustup.exe)) {
        #             return $false
        #         }

        #         $rustupCheck = & 'C:\Program Files\Rust\bin\rustup.exe' check | Where-Object { $_ -NotMatch 'Up to date' }
        #         if ($rustupCheck) {
        #             return $false
        #         }

        #         return $true
        #     }
        # }

        # Environment AddToPath {
        #     Name   = 'PATH'
        #     Path   = $true
        #     Value  = 'C:\Program Files\tools;C:\Program Files\rust\bin'
        #     Ensure = 'Present'
        # }

        cChocoPackageInstaller NTop {
            Name        = 'ntop.portable'
            DependsOn   = '[cChocoInstaller]installChoco'
            AutoUpgrade = $true
        }
    }
}

[DscLocalConfigurationManager()]
Configuration ConfigureDesktopMetaData {
    Node localhost {
        Settings {
            RebootNodeIfNeeded             = $true
            ActionAfterReboot              = 'ContinueConfiguration'
            DebugMode                      = 'All'
            AllowModuleOverwrite           = $true
            ConfigurationModeFrequencyMins = 10080
            RefreshFrequencyMins           = 10080
        }
    }
}

ConfigureDesktopMetaData -ConfigurationData $ConfigurationData
ConfigureDesktop -ConfigurationData $ConfigurationData
