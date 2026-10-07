# Return to Krondor folder paths

A small patch for the Steam error **an error occurred while trying to read the game file: .trx**. It does not include the game, and it does not change `RtK.exe`.

Steam's `RTKRONDOR.INI` usually says `TrackDir=.\Tracks\`. The game uses that text as the folder for voice files. Steam often starts the game from a different working directory, so the `.trx` file cannot be opened. This happens most often when a conversation starts. Verifying the game files puts the relative paths back.

The patch writes absolute paths for `Tracks`, `GameData`, `Worlds`, `Bkgnd`, `Audio`, and `Cinemats`. An absolute path that already points at a folder on disk is left alone, so a working GOG install is not rewritten.

Download the zip from the green Code button on [this repository](https://github.com/RetroKevin/return-to-krondor-paths). Bug reports go in [Issues](https://github.com/RetroKevin/return-to-krondor-paths/issues).

## Install

Extract this folder. Copy it into the game folder so `Apply.bat` sits next to `RtK.exe` and `RTKRONDOR.INI`, then double-click `Apply.bat`.

On Steam: right-click Return to Krondor, choose Manage, then Browse local files. That is the game folder.

If the patch is extracted somewhere else:

```
powershell -ExecutionPolicy Bypass -File Apply.ps1 -GameDir "D:\Steam\steamapps\common\Return to Krondor"
```

The window names the install and says the previous ini is `RTKRONDOR.INI.paths-bak`.

## After Steam verifies the files

Verify restores `RTKRONDOR.INI` and the error can come back. `FixDirectories.bat` stays in the game folder. Run it again.

## Remove

Copy `RTKRONDOR.INI.paths-bak` over `RTKRONDOR.INI`. Delete `FixDirectories.bat` and `FixDirectories.ps1`.
