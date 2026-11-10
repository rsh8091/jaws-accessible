# Accessible schedule review: first milestone

Branch: `play-season`, based on Release 1 (`f931a5a`).

Main menu choice **3. Schedules and Boxscores** opens the accessible scheduler.
Choices 1 (single game) and 2 (help) are unchanged. Exit is now choice 4 and
must remain the final numbered main-menu choice as new features are added.
Choose **2. Play / Edit an Existing Schedule (review only)**. This follows the
upstream section and action names, but explicitly limits this milestone to review.

The game calls the same native Open dialog as upstream, filtering for `.SCD`
files and starting in the configured schedules directory. Escape cancels.
After selection, review five games per page: original game number, team names
and data identifiers, date, time, and final scores or unplayed status.

Each page starts on a fresh screen, with date and time on one line to reduce
scrolling. It waits before showing navigation choices: choose 1 or press Enter
when ready. At that pause, 0 goes Back and 99 returns to the main menu.
The navigation menu then opens on its own screen. JAWS listening validation
is still needed; the program cannot detect when a screen reader finishes speaking.

- 1: Next page.
- 2: Previous page.
- 3: Go to a game number (opens only that game's details).
- 4: Repeat the page.
- 0: Back to Schedules and Boxscores.
- 99: Cancel and return to the main menu.

At the game-number prompt, all numbers from 1 through the schedule length are
game numbers, including 99. Use 0 to return to review. Typed `cancel` is optional.

The game-detail screen waits for 1 or Enter before showing navigation:
1 Next game, 2 Previous game, 3 Repeat, 0 Back to the original schedule page,
or 99 Cancel to the main menu. Back and Cancel also work at the reading pause.
Moving between individual games does not move the underlying schedule page.

## Implementation boundary

`AccessibleSchedules.bm` owns the menus and review. It reads upstream's 52-byte
SCD records and 15-byte team-name fields with explicit read-only file access.
It does not call the graphical editing/saving workflow, initialize an active
schedule, compile statistics, or change simulation routines. The reader uses
local data rather than replacing the scheduler's or current game's shared arrays.

The only change in `HELLO.BAS` is a scoped error-handler hook for file-read
failures, so an inaccessible or locked file returns a readable error to this
review screen. Normal error handling is unchanged outside those reads.

Playing, editing, creating schedules, standings, and browsing saved box scores
remain future milestones. Team data must already be installed. The sample
schedule produced by the test script is synthetic, not a historical schedule.

## Validation

Run `scripts/test-accessible-schedules.ps1` against `bin/HELLO.exe`. It exercises
paging, boundaries, repeat, game-number validation (including game 99), Back,
Cancel, returning to single-game setup, missing/empty/truncated/oversized files,
missing team data, locked files, and read-only schedules. It verifies schedule
and team-file hashes are unchanged. Only the native picker is substituted by
a test fixture path, and only when both accessible-test flags are supplied.

Manual JAWS check still required:

1. Launch `bin/HELLO.exe --accessible` with `bin` as the working directory.
2. Choose 3, then 2. Confirm JAWS announces the Open dialog, filename field,
   folders, file list, and Open/Cancel buttons; navigate using the keyboard.
3. Cancel and confirm the scheduler menu is usable again.
4. Reopen the dialog and select an SCD file. Confirm the review is announced.
5. Try all review choices and return to the main menu, then open single-game
   setup to check that focus and navigation still work normally.

Automated tests do not establish JAWS speech or native-dialog focus behavior.
