Return to Krondor folder paths
==============================

Fixes the Steam error "an error occurred while trying to read the game
file: .trx". This download does not include the game, and it does not
change RtK.exe.

Steam's RTKRONDOR.INI usually says TrackDir=.\Tracks\. The game uses
that text as the folder for voice files. Steam often starts the game
from a different working directory, so the .trx file cannot be opened.
Verifying the game files puts the relative paths back.

This writes absolute paths for Tracks, GameData, Worlds, Bkgnd, Audio,
and Cinemats. An absolute path that already points at a folder on disk
is left alone.

Download: https://github.com/RetroKevin/return-to-krondor-paths
Use the Code button and Download ZIP.
Bug reports: https://github.com/RetroKevin/return-to-krondor-paths/issues

Install
-------
1. Extract this folder.
2. On Steam: right-click Return to Krondor, Manage, Browse local files.
3. Copy these files into that folder so Apply.bat sits next to RtK.exe.
4. Double-click Apply.bat.

The previous ini is saved as RTKRONDOR.INI.paths-bak.
If Steam verify restores the ini, run FixDirectories.bat in the game
folder.

To remove the patch, copy RTKRONDOR.INI.paths-bak over RTKRONDOR.INI
and delete FixDirectories.bat and FixDirectories.ps1.
