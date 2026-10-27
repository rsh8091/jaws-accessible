COURTSIDE College Basketball ACCESSIBLE BETA
=========================

Thank you for testing the accessible beta.

INSTALLATION
------------
1. Download the release ZIP from the project's GitHub Releases page.
2. Extract the entire ZIP to a normal, writable folder where you want to play.
   A folder such as C:\Games\Courtside is recommended.
   Do not run the game from inside the ZIP.
   Avoid Program Files and cloud-synchronized folders such as OneDrive.
3. Open the extracted folder and run "1 Install Team Data.cmd" once.
   This requires an internet connection and downloads the official team files.
4. Run "2 Start Accessible Game.cmd" whenever you want to play.

Do not move HELLO.exe away from the other extracted files. The game uses the
schedule and support files stored beside it.

TESTED SYSTEMS
--------------
- Windows 11, 64-bit: supported and tested.
- Windows 10 version 22H2, 64-bit: best-effort support.
- JAWS 2026, version 2026.2606.132.400: tested.

Older versions of JAWS are expected to work, but have not yet been formally tested.

Windows 7, Windows 8, Windows 8.1, and 32-bit Windows are not supported.

QUICK START
-----------
The launcher starts HELLO.exe with the --accessible option. Follow the spoken
prompts and use Enter to advance when requested.

Read "BETA TESTING AND FEEDBACK.txt" before reporting a problem. Known beta
limitations are listed in "KNOWN ISSUES.txt".

CREDITS
-------
Courtside College Basketball was originally created by Lance Haffner.

This release builds on Jason Leonard's work preserving and modernizing the game:
https://github.com/jleonard2099/LHG_CollegeBB

See the included LICENSE, QB64PE.license.txt, and Ack_UWL.txt files for additional
license and acknowledgment information.

If team data is missing, the launcher opens a Windows dialog with an OK button.
Press Enter to dismiss it, then run 1 Install Team Data.cmd and start again.
If Windows cannot show the dialog, the console repeats the instructions and
waits for Enter before closing.

Running the team-data installer again detects existing files, including a
partial installation. Choose 1 to keep them without downloading, 2 to reinstall
and replace matching files (including edits), or 99 to cancel. Blank or invalid
input asks again; it never authorizes a reinstall.

The installer verifies the team archive against the expected SHA-256 checksum
before extracting it and accepts only supported team-data filenames. If
verification fails, no files are installed. Download again from the official
release page; if the error continues, report it.
