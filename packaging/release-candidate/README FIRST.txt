COURTSIDE COLLEGE BASKETBALL ACCESSIBLE
Release 1, Candidate 3 (1.0-RC3) - October 7, 2026

This candidate focuses on accessible single-game play. It is ready for final
hands-on review; it is not a claim that every simulation issue is resolved.

INSTALLATION
1. Extract the entire Courtside-Accessible-1.0-RC3.zip into a writable folder,
   such as C:\Games\Courtside-RC3. Do not run from inside the ZIP.
   Use a separate folder from an older installation to preserve its files.
   Avoid Program Files and cloud-synchronized folders such as OneDrive.
2. Run "1 Install Team Data.cmd" once. Internet access is required. This
   downloads Jason Leonard's NCAA_Teams_thru2025.zip from his v5.26 release
   and installs the season/team files beside our accessible game.
3. Run "2 Start Accessible Game.cmd" to play.

Keep HELLO.exe beside the supplied support files. Season data is downloaded
separately, as in our previous beta packages; it is not bundled in this ZIP.
The installer downloads only team data, not Jason's executable. Our accessible
game and release numbering remain separate; no installation of his game is needed.

WINDOWS SECURITY PROMPTS
This candidate's HELLO.exe is not digitally signed. Windows may ask you to
confirm before running the downloaded game or its launcher scripts.

If Microsoft Defender SmartScreen says "Windows protected your PC" or calls
the app unrecognized, and you obtained this package from the developer or the
project's release page and intend to run it:
1. Choose "More info".
2. Check that the file is the game or launcher you intended to open.
3. Choose "Run anyway", if that option is available.
Use Tab or Shift+Tab to move between controls and Enter to activate a focused
control. Wording and available controls can vary with Windows settings.

For an "Open File - Security Warning" prompt, review the file name and choose
"Run" only if it is the expected file from your trusted package.

Some computers use Smart App Control or organization policies that block an
unsigned app without a Run anyway option. If that happens, report the exact
message or contact your administrator. Do not turn off Windows security or
antivirus protection to install the game. A specific malware detection is
different from an unrecognized-app warning; stop and report it.

Installing into your own writable folder should not require Run as administrator.
The supplied SHA256 checksum verifies that a download matches the package; it
does not replace publisher signing or a security scan.

QUICK START
Use the numbered menus and press Enter to submit a choice. Choose Accessibility
Help from the main menu for controls. Typed shortcuts are optional.
At halftime, 6 changes offense and 7 changes defense. Choose 1 to start the
second half, listen to both final lineups, then press Enter to begin play.

SYSTEMS
The project's previously tested configuration is Windows 11, 64-bit, with
JAWS 2026 (2026.2606.132.400). This candidate has automated checks but still
needs final hands-on screen-reader testing. Other screen-reader versions have
not been formally validated. Windows 10 22H2, 64-bit is best-effort support.
Windows 7, 8, 8.1 and 32-bit Windows are not supported.

Read RELEASE NOTES.txt, KNOWN ISSUES.txt and TESTING AND FEEDBACK.txt.

CREDITS
Original game: Lance Haffner.
Preservation and modernization: Jason Leonard.
https://github.com/jleonard2099/LHG_CollegeBB
Accessibility fork: https://github.com/rsh8091/jaws-accessible
See LICENSE, QB64PE.license.txt and Ack_UWL.txt for acknowledgments and licensing.
