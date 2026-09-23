# Setup navigation check (issue #4)

Run `Test JAWS Setup Navigation.cmd` with JAWS running. It uses `bin\HELLO.exe`, keeps keyboard input connected to the console, and stops after setup instead of starting gameplay. On September 23, 2026, the user reported that this navigation had seemed fine in JAWS testing; individual checklist steps were not separately recorded.

Numbered menus are the primary interface. Every setup menu announces `0` for Back and names its destination, plus `99` for Cancel setup. A displayed Keep option retains a selection explicitly; blank input does not accept it. Typed `back`, `cancel`, and `keep` remain optional shortcuts.

1. Choose a single game, then choose **Enter a season ID**. Enter `2025`. Choose **Search by team name**, enter `duke`, and choose the result. Only the year and team search require text entry. Alternatively, use **Browse all teams** and the numbered page controls.
2. At the home team's season menu, choose **Back to visiting team selection**. Confirm Duke is still selected. Choose **Keep current team and continue**. Select 2003 Syracuse for the home team.
3. Confirm the matchup. Select human control of the home team. At game location, choose Back. Confirm the control selection is preserved. Keep it, select a neutral site, and move on to rules. Go back again and confirm the neutral-site selection remains.
4. Choose custom rules. Use the numbered choices for the shot clock, three-point shot, and foul limit. Move backward through those settings and verify that the current values are announced. Keep or change them, then accept the configuration summary.
5. At each roster review, use Back and Continue. Verify that Back returns to the named preceding review or summary, without canceling setup. Blank or invalid input should explain the choices and keep the review open.
6. Select a human lineup manually. Go back one position and confirm the previous player is retained. Use the numbered Keep option to advance. A player already selected for an earlier position must be rejected. If a new selection takes a player from a later position, that affected position must be selected again. At lineup confirmation, Back returns to center selection.
7. Select an offensive style, then go back from defensive style. Confirm the offensive style is retained. Back again returns to lineup selection, where **Keep the current lineup and continue** is available. Return through roster review and configuration, change only the location, and verify the lineup and style remain selected.
8. Go back to the matchup and change one team. The changed team's roster, lineup, and strategies must be reviewed again; the unchanged team's completed lineup and style must remain available. Changing control mode must allow all human-controlled teams to review their coaching choices.
9. Try **Cancel setup** at an early menu and again at a lineup or strategy menu. It should return directly to the main menu. Back from the first setup menu also returns to the main menu. Starting a new setup should start fresh.
10. Complete setup. The test prints the final configuration, lineups, and strategies, then returns to the main menu. Confirm JAWS reads the menus, destinations, current selections, and final information without losing output.

Automated checks: `scripts\test-accessible-setup-navigation.ps1`. They exercise the same executable and menus, including numbered and typed navigation, invalid input, cancellation, preservation of choices, and dependent-choice validation. They cannot confirm screen-reader speech.

Custom settings currently remain a sequence of menus. The editor proposed in issue #8, which permits editing settings in any order, is separate work. Issue #9 covers further roster and lineup confirmation refinements.
