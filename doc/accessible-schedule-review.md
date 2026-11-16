# Accessible schedule review and team extraction

Branch: `play-season`, based on Release 1 (`f931a5a`).

Main menu choice **3. Schedules and Boxscores** opens the accessible scheduler.
Choices 1 (single game) and 2 (help) are unchanged. Exit is now choice 4 and
must remain the final numbered main-menu choice as new features are added.
Choose **2. Play / Edit an Existing Schedule**. This follows the upstream
section and action names. Editing schedule entries is not implemented yet.

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
- 5: Reset Scores. Confirm with 1 to mark every game unplayed and save to the
  same open schedule file; 0 goes Back without changes and 99 cancels to main.
  Like upstream, this clears completion flags while preserving the stored score
  numbers, which are hidden for unplayed games. Teams, dates, settings, and all
  other files are unchanged. No new copy or filename is required. The write
  requires the file to match the loaded version and reports failures.
- 0: Back to Schedules and Boxscores.
- 99: Cancel and return to the main menu.

At the game-number prompt, all numbers from 1 through the schedule length are
game numbers, including 99. Use 0 to return to review. Typed `cancel` is optional.

The game-detail screen waits for 1 or Enter before showing navigation:
1 Next game, 2 Previous game, 3 Repeat, 0 Back to the original schedule page,
or 99 Cancel to the main menu. Back and Cancel also work at the reading pause.
Moving between individual games does not move the underlying schedule page.

## Extract Team Schedule

Schedule menu choice **3. Extract Team Schedule** opens the source schedule
picker, followed by the existing accessible team selector. The first game's
season ID is offered as the default; another season can be selected for a
mixed-season schedule. Search or browse for the team using numbered choices.

Matching uses both the team record number and season ID, on either side of
each game, as upstream `ExtractSchedule` action 3 does. Games remain in source
order with their scores, completion status, and other settings. Like upstream,
the extracted games set the selected team to human control and set the
play-by-play delay to zero. The original file is never written.

After the game count is announced, choose 1 to open the native Save dialog.
Choose a new filename; existing files are refused even if the native dialog
offers replacement. Escape cancels. A missing `.SCD` extension is added.
After saving, choose 1 to review the extracted schedule, 0 for the schedule
menu, or 99 for the main menu. A failed save reports the problem and warns
that a partial destination may remain, without reporting success.

The accessible adapter implements the upstream record matching and extraction
settings without invoking its graphical prompts or modifying its shared
schedule arrays. The existing accessible team picker uses the normal team
index, just as in single-game setup. No simulation routines are changed.

## Implementation boundary

### Play one scheduled game

In an unplayed game's detail navigation, choose **4. Play this game**.
The matchup and schedule rules are fixed. Review the rosters, use the existing
accessible lineup and strategy choices, and confirm tipoff. Human control follows
the schedule, including the team selected when extracting a team schedule.
Games run through the existing simulator, halftime, overtime, and postgame menus.
Computer-versus-computer scheduled games run to completion in normal use.

For human-controlled games, setup announces the scheduled human role and offers
1 Coach and select shots (the single-game interaction), 2 Coach only and let
the computer shoot, and 98 Keep the current role. Back preserves that choice
during setup, and the role is announced again before tipoff. This uses upstream's
existing coach setting for the current game only; it does not rewrite the
schedule's stored settings. Computer-only games skip this choice.

After a completed game, choose 5 in postgame options, then 1 to save its result
or 0 to discard it. Saving updates only that game's completion flag and final
scores; it preserves all other schedule bytes. The schedule must still match
the version loaded before play. Changed, read-only, or locked files produce a
save error with a retry option. Completed games cannot be replayed from this
menu. Canceling setup or ending an unfinished game does not save anything.

This milestone saves schedule results only, not cumulative season statistics,
standings, ticker data, or automatic boxscore archives. The existing HTML boxscore
option remains available before leaving postgame options.

`AccessibleScheduledPlay.bm` handles validation, setup, and saving. Two small
hooks in `HELLO.BAS` apply the schedule's rules to the existing prepared-game
path and identify a completed game. Simulation decisions are unchanged.

`AccessibleSchedules.bm` owns the menus and review. It reads upstream's 52-byte
SCD records and 15-byte team-name fields with explicit read-only file access.
It does not call the graphical editing/saving workflow, initialize an active
schedule, compile statistics, or change simulation routines. The reader uses
local data rather than replacing the scheduler's or current game's shared arrays.

The schedule reader also uses a scoped error-handler hook in `HELLO.BAS` for file I/O
failures, so an inaccessible or locked file returns a readable error to this
review screen. Extraction also scopes this hook around writing the new file.
Normal error handling is unchanged outside those operations.

Editing, creating schedules from scratch, standings, and browsing saved box scores
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

Run `scripts/test-accessible-schedule-extraction.ps1` for extraction checks:
exact output records for home/away matches, exclusion of another season,
preserved results/order, unchanged source/team data, existing-file protection,
cancellation, no matches, failed saves, and filename extension handling.

For manual testing, choose 3 on the main menu and 3 on the schedule menu.
Select a real season, keep its season ID, search for a team, and save a new
team schedule. Confirm the match count and Save dialog are spoken, then review
the saved games. Also try canceling the Open and Save dialogs.

Run `scripts/test-accessible-scheduled-play.ps1` for scheduled gameplay checks.
It uses synthetic three-game schedules and real installed team data. Full-game
cases use the existing diagnostic mode to run the actual simulator without
interactive play prompts. The saved score must equal the engine's final score,
and every byte outside the selected completion flag and scores must be unchanged.
Other cases cover canceling setup, unfinished games, discarding results,
read-only save failure, completed-game protection, missing teams, and invalid rules.
Reset cases check confirmation, invalid input, Back/Cancel, read-only failure,
exact preservation of every byte except completion flags, and a full simulated
game saved after resetting a schedule containing historical results.
Human-role cases verify that selecting shots reaches the simulator's Pass and
Shoot menu, and cover keeping coach-only mode or switching into it. These cases
also verify that selecting a role does not change the schedule's stored settings.

Manual JAWS check: open a copy of a team schedule, open an unplayed game's
details, choose 4, review setup, play, then save the result. Reopen the schedule
and confirm the score remains. Also cancel setup and confirm no result was saved.
