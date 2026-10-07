# Points RTKRONDOR.INI [Directories] at this install.
# Steam ships relative paths such as TrackDir=.\Tracks\. The game uses
# that string as written, and Steam often starts RtK.exe from another
# working directory, so voice files (.trx) fail to open. An absolute
# path that already exists is left alone.
param(
    [string]$GameDir
)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

$Folders = [ordered]@{
    GameDataDir = 'GameData'
    WorldDir    = 'Worlds'
    BGDir       = 'Bkgnd'
    TrackDir    = 'Tracks'
    AudioDir    = 'Audio'
    SFXAudioDir = 'Audio'
    CinematDir  = 'Cinemats'
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
    return (Test-Path -LiteralPath $v -PathType Container)
}

function Install-Helper {
    param([string]$Game, [string]$Source)
    $src = $Source
    $dest = Join-Path $Game 'FixDirectories.ps1'
    $same = $false
    if ($src -and (Test-Path -LiteralPath $src)) {
        $left = (Resolve-Path -LiteralPath $src).Path
        if ((Test-Path -LiteralPath $dest) -and ((Resolve-Path -LiteralPath $dest).Path -eq $left)) {
            $same = $true
        }
        if (-not $same) {
            Copy-Item -LiteralPath $src -Destination $dest -Force
        }
    }
    $bat = @"
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0FixDirectories.ps1"
if errorlevel 1 (
    echo.
    echo The folder paths were not updated.
    pause
    exit /b 1
)
echo.
pause
"@
    $batPath = Join-Path $Game 'FixDirectories.bat'
    $batText = $bat.Replace("`n", "`r`n")
    [System.IO.File]::WriteAllText($batPath, $batText, [System.Text.Encoding]::ASCII)
}

$game = Resolve-GameDir $GameDir
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

$changed = New-Object System.Collections.Generic.List[string]
$missing = New-Object System.Collections.Generic.List[string]

if ($start -lt 0) {
    $block = New-Object System.Collections.Generic.List[string]
    $block.Add('[Directories]')
    foreach ($key in $Folders.Keys) {
        $folder = Join-Path $game $Folders[$key]
        $block.Add($key + '=' + $folder + '\')
        $changed.Add($key)
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
        $folder = Join-Path $game $Folders[$match]
        $lines[$i] = $match + '=' + $folder + '\'
        $changed.Add($match)
        if (-not (Test-Path -LiteralPath $folder -PathType Container)) {
            if (-not $missing.Contains($Folders[$match])) { $missing.Add($Folders[$match]) }
        }
    }
    $at = $end
    foreach ($key in $Folders.Keys) {
        if ($seen.ContainsKey($key)) { continue }
        $folder = Join-Path $game $Folders[$key]
        $lines.Insert($at, $key + '=' + $folder + '\')
        $at++
        $changed.Add($key)
        if (-not (Test-Path -LiteralPath $folder -PathType Container)) {
            if (-not $missing.Contains($Folders[$key])) { $missing.Add($Folders[$key]) }
        }
    }
}

if ($changed.Count -gt 0) {
    $bak = Join-Path $game 'RTKRONDOR.INI.paths-bak'
    if (-not (Test-Path -LiteralPath $bak)) {
        [System.IO.File]::WriteAllBytes($bak, $raw)
    }
    $out = ($lines -join $newline) + $newline
    [System.IO.File]::WriteAllText($ini, $out, $enc)
    Install-Helper $game $PSCommandPath
    Write-Host "Folder paths now point at $game"
    Write-Host ("Updated " + ($changed -join ', '))
    Write-Host "The previous ini is RTKRONDOR.INI.paths-bak"
    Write-Host "If Steam verify restores the ini, run FixDirectories.bat in the game folder."
} else {
    Write-Host "Folder paths already point at folders that exist. Nothing was changed."
}

if ($missing.Count -gt 0) {
    Write-Host ("These folders are not in the install yet: " + ($missing -join ', '))
    Write-Host "Verify the game files in Steam if a .trx file is still missing."
}
