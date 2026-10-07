Return to Krondor ini repair
============================

Fixes two Steam problems that both live in RTKRONDOR.INI. This download
does not include the game, and it does not change RtK.exe.

Voice files. Steam's ini usually says TrackDir=.\Tracks\. The game uses
that text as the folder for .trx files. Steam often starts the game from
a different working directory, so the file cannot be opened. This writes
absolute paths for Tracks, GameData, Worlds, Bkgnd, Audio, and Cinemats.
An absolute path that already points at a folder on disk is left alone.

Startup crash. The popup "An error has been detected which prevents the
game from continuing", or a start that never shows a window, happens
when the ini asks for a hardware 3D driver. This writes the software
renderer. Engine=1 with no Driver line is left alone.

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
If Steam verify restores the ini, run FixRtK.bat in the game folder.

A folder name with a period, such as GOG.com, crashes a conversation.
The game cuts the path at that period. Apply.bat then makes a launch
folder with no period, X:\RtK on the same drive, and points the ini at
it. Start RtK.exe from that folder. Steam's Play button still starts
the original path.

This patch does not turn on compatibility mode. The picture fix for
Windows 10 and 11 is the display patch:
https://github.com/RetroKevin/return-to-krondor-display

To remove it, copy RTKRONDOR.INI.paths-bak over RTKRONDOR.INI and delete
FixRtK.bat and FixRtK.ps1.
