# Repairs RTKRONDOR.INI for a current Windows install.
# Relative TrackDir=.\Tracks\ cannot open voice files when Steam's working
# directory is not the game folder. Engine=1 with a Driver guid sends
# startup into the graphics driver's DLL. One run writes absolute folder
# paths and, when a hardware driver is selected, the software renderer.
# An absolute path that already exists is left alone. Engine=1 with no
# Driver line is left alone, because the game already falls back to software.
# Compatibility mode is not turned on.
param(
    [string]$GameDir,
    [string]$CleanDir
)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$display = 'https://github.com/RetroKevin/return-to-krondor-display'

$Folders = [ordered]@{
    GameDataDir = 'GameData'
    WorldDir    = 'Worlds'
    BGDir       = 'Bkgnd'
    TrackDir    = 'Tracks'
    AudioDir    = 'Audio'
    SFXAudioDir = 'Audio'
    CinematDir  = 'Cinemats'
}

$Safe = [ordered]@{
    Cinemat  = @('Playback=1', 'Stretch=0')
    Console  = @('Console=0')
    Audio    = @('MasterVolume=1.000000', 'MusicVolume=1.000000', 'MusicEnabled=1')
    Graphics = @('Gamma=1.000000', 'Engine=0')
}

function Resolve-GameDir {
    param([string]$Asked)
    if ($Asked) {
        if (-not (Test-Path -LiteralPath (Join-Path $Asked 'RTKRONDOR.INI'))) {
            throw "No RTKRONDOR.INI in $Asked"
        }
        return (Resolve-Path -LiteralPath $Asked).Path
    }
    foreach ($candidate in @($here, (Join-Path $here '..'))) {
        $ini = Join-Path $candidate 'RTKRONDOR.INI'
        if (Test-Path -LiteralPath $ini) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }
    throw "Run this from the game folder, or pass -GameDir 'C:\path\to\Return to Krondor'."
}

function Get-Plain([string]$Value) {
    if ($null -eq $Value) { return '' }
    return $Value.Trim().Trim('"').Trim()
}

function Test-WindowsAbsolute([string]$Value) {
    $v = (Get-Plain $Value) -replace '/', '\'
    if ($v.StartsWith('\\')) { return $true }
    return ($v.Length -ge 2 -and [char]::IsLetter($v[0]) -and $v[1] -eq ':')
}

function Test-DirectoryOk([string]$Value) {
    $v = Get-Plain $Value
    if (-not $v) { return $false }
    if ($v.StartsWith('.\') -or $v.StartsWith('./')) { return $false }
    if (-not (Test-WindowsAbsolute $v)) { return $false }
    if (Test-DottedPath $v) { return $false }
    return (Test-Path -LiteralPath $v -PathType Container)
}

function Install-Helper {
    param([string]$Game, [string]$Source)
    $dest = Join-Path $Game 'FixRtK.ps1'
    if ($Source -and (Test-Path -LiteralPath $Source)) {
        $left = (Resolve-Path -LiteralPath $Source).Path
        $same = (Test-Path -LiteralPath $dest) -and ((Resolve-Path -LiteralPath $dest).Path -eq $left)
        if (-not $same) {
            Copy-Item -LiteralPath $Source -Destination $dest -Force
        }
    }
    foreach ($old in @('FixDirectories.bat', 'FixDirectories.ps1', 'RepairLaunch.bat', 'RepairLaunch.ps1')) {
        $path = Join-Path $Game $old
        if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force }
    }
    $bat = @"
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0FixRtK.ps1"
if errorlevel 1 (
    echo.
    echo RTKRONDOR.INI was not updated.
    pause
    exit /b 1
)
echo.
pause
"@
    $batPath = Join-Path $Game 'FixRtK.bat'
    [System.IO.File]::WriteAllText($batPath, $bat.Replace("`n", "`r`n"), [System.Text.Encoding]::ASCII)
}

function Test-NeedsLaunchRepair {
    param($Lines)
    $section = ''
    $engine = $null
    $driver = ''
    foreach ($line in $Lines) {
        $body = $line.Trim()
        if ($body.StartsWith('[') -and $body.EndsWith(']')) {
            $section = $body.Substring(1, $body.Length - 2).Trim()
            continue
        }
        if ($section -ne 'Graphics' -or -not $body.Contains('=')) { continue }
        $name = $body.Split('=', 2)[0].Trim()
        $value = $body.Split('=', 2)[1].Trim().Trim('"')
        if ($name -eq 'Engine') { $engine = $value }
        if ($name -eq 'Driver') { $driver = $value }
    }
    if ($null -eq $engine) { return $false }
    $number = 0
    if (-not [int]::TryParse($engine, [ref]$number)) { return $true }
    if ($number -eq 0) { return $false }
    if ($number -eq 1 -and -not $driver) { return $false }
    return $true
}

function Repair-LaunchSections {
    param($Lines)
    $out = New-Object System.Collections.Generic.List[string]
    $seen = @{}
    $i = 0
    while ($i -lt $Lines.Count) {
        $body = $Lines[$i].Trim()
        $replaced = $false
        if ($body.StartsWith('[') -and $body.EndsWith(']')) {
            $name = $body.Substring(1, $body.Length - 2).Trim()
            foreach ($key in @($Safe.Keys)) {
                if ($name.Equals($key, [StringComparison]::OrdinalIgnoreCase)) {
                    $seen[$key] = $true
                    $out.Add('[' + $key + ']')
                    foreach ($row in $Safe[$key]) { $out.Add($row) }
                    $i++
                    while ($i -lt $Lines.Count) {
                        $peek = $Lines[$i].Trim()
                        if ($peek.StartsWith('[') -and $peek.EndsWith(']')) { break }
                        $i++
                    }
                    $replaced = $true
                    break
                }
            }
        }
        if ($replaced) { continue }
        $out.Add($Lines[$i])
        $i++
    }
    foreach ($key in $Safe.Keys) {
        if ($seen.ContainsKey($key)) { continue }
        if ($out.Count -gt 0 -and $out[$out.Count - 1].Trim()) { $out.Add('') }
        $out.Add('[' + $key + ']')
        foreach ($row in $Safe[$key]) { $out.Add($row) }
    }
    return $out
}

function Test-DottedPath {
    param([string]$Path)
    $cursor = $Path
    while ($cursor) {
        $leaf = Split-Path -Path $cursor -Leaf
        if ($leaf -and $leaf -ne '.' -and $leaf -ne '..' -and $leaf.Contains('.')) { return $leaf }
        $parent = Split-Path -Path $cursor -Parent
        if (-not $parent -or $parent -eq $cursor) { break }
        $cursor = $parent
    }
    return $null
}

function Get-LaunchRoot {
    param([string]$Game)
    $dotted = Test-DottedPath $Game
    if (-not $dotted) { return $Game }
    $parent = if ($CleanDir) { $CleanDir } else { Split-Path -Path $Game -Qualifier }
    foreach ($name in @('RtK', 'ReturnToKrondor')) {
        $link = Join-Path $parent $name
        if (Test-Path -LiteralPath $link) {
            $item = Get-Item -LiteralPath $link -Force
            $target = $null
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                $target = $item.Target
                if ($target -is [array]) { $target = $target[0] }
            }
            if ($target -and ((Resolve-Path -LiteralPath $target).Path -eq (Resolve-Path -LiteralPath $Game).Path)) {
                return $link
            }
            continue
        }
        & cmd.exe /c "mklink /J `"$link`" `"$Game`"" | Out-Null
        if (Test-Path -LiteralPath $link) { return $link }
    }
    throw "Could not make a launch folder without a period in $parent"
}

function Write-Warnings {
    param([string]$Game)
    $cursor = $Game
    while ($cursor) {
        $leaf = Split-Path -Path $cursor -Leaf
        if ($leaf -and $leaf.Contains('.')) {
            Write-Host "The folder '$leaf' contains a period. The game cuts a path at the last period, so a conversation crashes while opening its voice file."
            Write-Host "Start RtK.exe from the launch folder this patch prints below. Steam's Play button still starts the original path."
            break
        }
        $parent = Split-Path -Path $cursor -Parent
        if (-not $parent -or $parent -eq $cursor) { break }
        $cursor = $parent
    }
    if (-not (Test-Path -LiteralPath (Join-Path $Game 'ddraw.dll'))) {
        Write-Host "This folder has no ddraw.dll. The picture on Windows 10 and 11 uses the display patch:"
        Write-Host $display
    }
    $reg = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey(
        'Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers')
    foreach ($name in @('RtK.exe', 'RtKGame.exe')) {
        $exe = Join-Path $Game $name
        if (-not (Test-Path -LiteralPath $exe)) { continue }
        $layers = ''
        if ($reg) { $layers = [string]$reg.GetValue($exe) }
        if ($layers -match 'WIN98|WIN95|WINXP|NT4SP5') {
            Write-Host "$name has a Windows compatibility mode set. Clear that checkbox."
            Write-Host "The mode makes Windows load its own DirectDraw. The display patch is the picture fix."
            break
        }
    }
}

$game = Resolve-GameDir $GameDir
$launch = Get-LaunchRoot $game
$ini = Join-Path $game 'RTKRONDOR.INI'
$enc = [System.Text.Encoding]::Default
$raw = [System.IO.File]::ReadAllBytes($ini)
if ($raw.Length -ge 3 -and $raw[0] -eq 0xEF -and $raw[1] -eq 0xBB -and $raw[2] -eq 0xBF) {
    $enc = New-Object System.Text.UTF8Encoding $false
}
$text = $enc.GetString($raw)
$newline = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }
$lines = New-Object System.Collections.Generic.List[string]
foreach ($line in ($text -split "`r`n|`n", -1)) { $lines.Add($line) }
if ($lines.Count -gt 0 -and $lines[$lines.Count - 1] -eq '') {
    $lines.RemoveAt($lines.Count - 1)
}

$start = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i].Trim().ToLowerInvariant() -eq '[directories]') { $start = $i; break }
}

$pathChanged = New-Object System.Collections.Generic.List[string]
$missing = New-Object System.Collections.Generic.List[string]

if ($start -lt 0) {
    $block = New-Object System.Collections.Generic.List[string]
    $block.Add('[Directories]')
    foreach ($key in $Folders.Keys) {
        $folder = Join-Path $launch $Folders[$key]
        $block.Add($key + '=' + $folder + '\')
        $pathChanged.Add($key)
        if (-not (Test-Path -LiteralPath $folder -PathType Container)) { $missing.Add($Folders[$key]) }
    }
    $block.Add('')
    $lines.InsertRange(0, $block)
} else {
    $end = $lines.Count
    for ($j = $start + 1; $j -lt $lines.Count; $j++) {
        $body = $lines[$j].Trim()
        if ($body.StartsWith('[') -and $body.EndsWith(']')) { $end = $j; break }
    }
    $seen = @{}
    for ($i = $start + 1; $i -lt $end; $i++) {
        $body = $lines[$i].Trim()
        if (-not $body -or $body.StartsWith(';') -or $body.StartsWith('#') -or -not $body.Contains('=')) { continue }
        $name = $body.Split('=', 2)[0].Trim()
        $value = $body.Split('=', 2)[1]
        $match = $null
        foreach ($key in @($Folders.Keys)) {
            if ($name.Equals($key, [StringComparison]::OrdinalIgnoreCase)) { $match = $key; break }
        }
        if (-not $match) { continue }
        $seen[$match] = $true
        if (Test-DirectoryOk $value) { continue }
        $folder = Join-Path $launch $Folders[$match]
        $lines[$i] = $match + '=' + $folder + '\'
        $pathChanged.Add($match)
        if (-not (Test-Path -LiteralPath $folder -PathType Container)) {
            if (-not $missing.Contains($Folders[$match])) { $missing.Add($Folders[$match]) }
        }
    }
    $at = $end
    foreach ($key in $Folders.Keys) {
        if ($seen.ContainsKey($key)) { continue }
        $folder = Join-Path $launch $Folders[$key]
        $lines.Insert($at, $key + '=' + $folder + '\')
        $at++
        $pathChanged.Add($key)
        if (-not (Test-Path -LiteralPath $folder -PathType Container)) {
            if (-not $missing.Contains($Folders[$key])) { $missing.Add($Folders[$key]) }
        }
    }
}

$repairLaunch = Test-NeedsLaunchRepair $lines
if ($repairLaunch) { $lines = Repair-LaunchSections $lines }

Write-Warnings $game

if ($pathChanged.Count -gt 0 -or $repairLaunch) {
    $bak = Join-Path $game 'RTKRONDOR.INI.paths-bak'
    if (-not (Test-Path -LiteralPath $bak)) {
        [System.IO.File]::WriteAllBytes($bak, $raw)
    }
    $out = ($lines -join $newline) + $newline
    [System.IO.File]::WriteAllText($ini, $out, $enc)
    Install-Helper $game $PSCommandPath
    if ($pathChanged.Count -gt 0) {
        Write-Host "Folder paths now point at $launch"
        Write-Host ("Updated " + ($pathChanged -join ', '))
    } else {
        Write-Host "Folder paths already point at folders that exist."
    }
    if ($repairLaunch) {
        Write-Host "Launch settings now use the software renderer."
    }
    Write-Host "The previous ini is RTKRONDOR.INI.paths-bak"
    Write-Host "If Steam verify restores the ini, run FixRtK.bat in the game folder."
} else {
    Write-Host "Folder paths and launch settings were already set. Nothing was changed."
}

if ($missing.Count -gt 0) {
    Write-Host ("These folders are not in the install yet: " + ($missing -join ', '))
    Write-Host "Verify the game files in Steam if a .trx file is still missing."
}
