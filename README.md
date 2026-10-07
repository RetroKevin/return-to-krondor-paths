# Return to Krondor ini repair

A small patch for two Steam problems that both live in `RTKRONDOR.INI`. It does not include the game, and it does not change `RtK.exe`.

Download the zip from the green Code button on [this repository](https://github.com/RetroKevin/return-to-krondor-paths). Bug reports go in [Issues](https://github.com/RetroKevin/return-to-krondor-paths/issues).

## What one run fixes

**Voice files.** Steam's ini usually says `TrackDir=.\Tracks\`. The game uses that text as the folder for `.trx` files. Steam often starts the game from a different working directory, so the file cannot be opened, most often when a conversation starts. The patch writes absolute paths for `Tracks`, `GameData`, `Worlds`, `Bkgnd`, `Audio`, and `Cinemats`. An absolute path that already points at a folder on disk is left alone, so a working GOG install is not rewritten.

**Startup crash.** The popup "An error has been detected which prevents the game from continuing", or a start that sits in Task Manager with no window, happens when the ini asks for a hardware 3D driver. That call crashes inside the graphics driver. The patch writes the software renderer, which is the renderer a GOG install already falls back to when no driver is selected. `Engine=1` with no Driver line is left alone.

Verifying the game files puts the original ini back.

**A period in a folder name.** A folder such as `GOG.com` makes a conversation crash. The game treats the last period in a path as the file extension, so the voice file is looked up in the wrong place. When the install path has that shape, `Apply.bat` also makes a launch folder with no period, `D:\RtK` on the same drive, and points the ini at it. Start `RtK.exe` from that folder. Steam's Play button still starts the original path.

## Install

Extract this folder. Copy it into the game folder so `Apply.bat` sits next to `RtK.exe` and `RTKRONDOR.INI`, then double-click `Apply.bat`.

On Steam: right-click Return to Krondor, choose Manage, then Browse local files. That is the game folder.

If the patch is extracted somewhere else:

```
powershell -ExecutionPolicy Bypass -File Apply.ps1 -GameDir "D:\Steam\steamapps\common\Return to Krondor"
```

The window names the install and says the previous ini is `RTKRONDOR.INI.paths-bak`.

## After Steam verifies the files

`FixRtK.bat` stays in the game folder. Run it again.

This patch does not turn on compatibility mode. A Windows 98 or XP mode on `RtK.exe` makes Windows load its own DirectDraw. The picture fix for Windows 10 and 11 is the separate display patch: https://github.com/RetroKevin/return-to-krondor-display

If a folder in the install path contains a period, the script says so and does not move the game.

## Remove

Copy `RTKRONDOR.INI.paths-bak` over `RTKRONDOR.INI`. Delete `FixRtK.bat` and `FixRtK.ps1`.
