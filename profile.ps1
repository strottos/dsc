Set-Alias -Name vi -Value 'C:\Program Files\Vim\vim82\vim.exe'
New-Alias which Get-Command
New-Alias unzip Expand-Archive
New-Alias od Format-Hex

Import-Module Posh-Git

function dev() {
    Invoke-BatchFile 'C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\Common7\Tools\VsDevCmd.bat'
    # TODO: This seems needed on some systems to get rust to compile correctly
    # Invoke-BatchFile 'C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsall.bat' x64
}

function DisplayBytesPretty($num) {
    <#
        .SYNOPSIS
            Display the number of Bytes in Bytes, KiloBytes, MegaBytes, etc

        .PARAMETER num
            Total number of bytes

        .EXAMPLE
            DisplayBytesPretty 125626
    #>

    $suffix = "B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"
    $index = 0
    while ($num -gt 1kb)
    {
        $num = $num / 1kb
        $index++
    }

    "{0:N1} {1}" -f $num, $suffix[$index]
}

function DisplayTimePretty {
    <#
        .SYNOPSIS
            Display the time as appropriate in units ranging from nanoseconds to years

        .PARAMETER num
            Total amount of time in the units given, defaults to milliseconds

        .PARAMETER units
            The units from 'ns' (nanoseconds), 'nanoseconds', 'microseconds', 'ms' (milliseconds), 'milliseconds',
            's' (seconds), 'seconds', 'm' (minutes), 'minutes', 'h' (hours), 'hours', 'd' (days), 'days'

        .EXAMPLE
            DisplayTimePretty 1698219850 -units 's'
    #>

    param (
        [double]
        $num,

        [string]
        $units = "ms"
    )

    $suffix = "nanoseconds", "microseconds", "milliseconds", "seconds", "minutes", "hours", "days", "years"
    $divides = 1000, 1000, 1000, 60, 60, 24, 365.25

    $index = switch ($units.ToLower()) {
        'ns' { 0 }
        'nanoseconds' { 0 }
        'microseconds' { 1 }
        'ms' { 2 }
        'milliseconds' { 2 }
        's' { 3 }
        'seconds' { 3 }
        'm' { 4 }
        'minutes' { 4 }
        'h' { 5 }
        'hours' { 5 }
        'd' { 6 }
        'days' { 6 }
        default { throw "Can't understand $units" }
    }

    while ($num / $divides[$index] -gt 1 -and $index -le 6)
    {
        $num = $num / $divides[$index]
        $index++
    }

    "{0:N2} {1}" -f $num, $suffix[$index]
}

function Get-DirectorySummary {
    <#
        .SYNOPSIS
            Display the number of Bytes in each item under a directory and the total

        .PARAMETER dir
            The directory to get the number of bytes for

        .PARAMETER h
            Specify -h to get the summary of the whole directory

        .EXAMPLE
            Get-DirectorySummary .
    #>

    param (
        [string]$dir=".",
        [switch]$h
    )

    $out = Get-ChildItem $dir | ForEach-Object { $f = $_ ;
        Get-ChildItem -r $_.FullName |
        Measure-Object -property length -sum 2>$null |
        Select-Object @{Name="Name";Expression={$f}},@{Name="Size";Expression={$_.Sum}}
    }

    $total = $out | Measure-Object -property Size -Sum | Select-Object Sum
    $out += New-Object psobject -Property @{Name = 'Total Size'; Size = $total.Sum}

    if ($h) {
        $out = $out | Select-Object Name, @{Name="Size";Expression={DisplayBytesPretty($_.Size)}}
    }

    $out | Format-Table -AutoSize
}

New-Alias du Get-DirectorySummary

##############################################################################
##
## Watch-Command
##
## From PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################
function Watch-Command {
    <#

    .SYNOPSIS

    Watches the result of a command invocation, alerting you when the output
    either matches a specified string, lacks a specified string, or has simply
    changed.

    .EXAMPLE

    PS > Watch-Command { Get-Process -Name Notepad | Measure } -UntilChanged
    Monitors Notepad processes until you start or stop one.

    .EXAMPLE

    PS > Watch-Command { Get-Process -Name Notepad | Measure } -Until "Count    : 1"
    Monitors Notepad processes until there is exactly one open.

    .EXAMPLE

    PS > Watch-Command { Get-Process -Name Notepad | Measure } -While 'Count    : \d\s*\n'
    Monitors Notepad processes while there are between 0 and 9 open
    (once number after the colon).

    #>

    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ScriptBlock] $ScriptBlock,

        ## The delay, in seconds, between monitoring attempts
        [Parameter()]
        [Double] $DelaySeconds = 2,

        ## The delay, in seconds, between monitoring attempts
        [Parameter(Mandatory = $false)]
        [int] $Number,

        ## Specifies that the alert sound should not be played
        [Parameter()]
        [Switch] $Quiet,

        ## Monitoring continues only while the output of the
        ## command remains the same.
        [Parameter(Mandatory = $false)]
        [Switch] $UntilChanged,

        ## The regular expression to search for. Monitoring continues
        ## until this expression is found.
        [Parameter(Mandatory = $false)]
        [String] $Until,

        ## The regular expression to search for. Monitoring continues
        ## until this expression is not found.
        [Parameter(Mandatory = $false)]
        [String] $While
    )

    Set-StrictMode -Version 3

    $initialOutput = ""
    $runs = 0
    Clear-Host

    ## Start a continuous loop
    while($true)
    {
        ## Run the provided script block
        $r = & $ScriptBlock

        ## Clear the screen and display the results
        $buffer = $ScriptBlock.ToString().Trim() + "`r`n"
        $buffer += "`r`n"
        $textOutput = $r | Out-String
        $buffer += $textOutput

        Write-Output $buffer

        ## Remember the initial output, if we haven't
        ## stored it yet
        if(-not $initialOutput)
        {
            $initialOutput = $textOutput
        }

        ## If we are just looking for any change,
        ## see if the text has changed.
        if($UntilChanged)
        {
            if($initialOutput -ne $textOutput)
            {
                break
            }
        }

        ## If we need to ensure some text is found,
        ## break if we didn't find it.
        if($While)
        {
            if($textOutput -notmatch $While)
            {
                break
            }
        }

        ## If we need to wait for some text to be found,
        ## break if we find it.
        if($Until)
        {
            if($textOutput -match $Until)
            {
                break
            }
        }

        $runs += 1

        if ($Number -ge 1 -and $runs -ge $Number) {
            break
        }

        ## Delay
        Start-Sleep -Seconds $DelaySeconds

        Clear-Host
    }

    ## Notify the user
    if(-not $Quiet)
    {
        [Console]::Beep(1000, 1000)
    }
}

New-Alias watch Watch-Command

function Open-PowershellHistory {
    <#

    .SYNOPSIS

    Open the PowerShell full history file in gvim

    #>
    $file = (Get-PSReadlineOption).HistorySavePath
    gvim $file
}

function Get-FileEncoding($Path) {
    <#

    .SYNOPSIS

    Checks the file at the path specified for the encoding type

    #>

    $bytes = [byte[]](Get-Content $Path -Encoding byte -ReadCount 4 -TotalCount 4)

    if(!$bytes) { return 'utf8' }

    switch -regex ('{0:x2}{1:x2}{2:x2}{3:x2}' -f $bytes[0],$bytes[1],$bytes[2],$bytes[3]) {
        '^efbbbf'   { return 'utf8' }
        '^2b2f76'   { return 'utf7' }
        '^fffe'     { return 'unicode' }
        '^feff'     { return 'bigendianunicode' }
        '^0000feff' { return 'utf32' }
        default     { return 'ascii' }
    }
}

function Invoke-TimeScript([scriptblock]$scriptBlock, $name) {
    <#
        .SYNOPSIS
            Run the given scriptblock, and say how long it took at the end.

        .PARAMETER scriptBlock
            A single computer name or an array of computer names. You may also provide IP addresses.

        .PARAMETER name
            Use this for long scriptBlocks to avoid quoting the entire script block in the final output line

        .EXAMPLE
            time { ls -recurse }

        .EXAMPLE
            time { ls -recurse } "All the things"
    #>

    if (!$stopWatch)
    {
        $script:stopWatch = new-object System.Diagnostics.StopWatch
    }
    $stopWatch.Reset()
    $stopWatch.Start()
    & $scriptBlock
    $stopWatch.Stop()
    if (-not $name) {
        $name = "$scriptBlock"
    }
    "Execution time: $(DisplayTimePretty($stopWatch.ElapsedMilliseconds)) for $name"
}

New-Alias time Invoke-TimeScript
