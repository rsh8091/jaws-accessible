# Substitution navigation check (issue #5)

Run `Test JAWS Substitution Navigation.cmd` with JAWS running. Complete setup normally. This uses only `bin\HELLO.exe` and opens a timeout menu with a fixed practice roster; it does not simulate possessions. Players 1 through 5 start on court, substitute 6 is a reserve guard, and substitute 7 is a reserve center. On September 23, 2026, the user reported that this navigation had seemed fine in JAWS testing; individual checklist steps were not separately recorded.

1. Choose **2. Make a substitution**. Confirm the lineup, **0. Back**, and **99. Cancel substitution** are announced.
2. Press Enter without a choice, then enter an invalid choice. Both should give guidance and keep the player-selection menu open.
3. Choose **5** to replace the center. Confirm the outgoing player and eligible substitutes are announced. Choose **0**. You should return to choosing the outgoing player, with the lineup unchanged.
4. Choose a different outgoing player, then choose **99**. You should return to timeout options with the lineup unchanged, without resuming play or charging another timeout.
5. Open substitution again. Choose **5**, then try blank input and unavailable player numbers. The substitute list should remain open. Choose **7**. Confirm that Reserve center replaces Starter 5, then press Enter to return to timeout options.
6. Choose **7. End this game segment**. The practice prints its resulting lineups and returns to the main menu. It should show the home lineup as `0,1,2,3,6`; these are diagnostic player indexes.

In ordinary games, the same navigation applies to dead-ball and halftime substitutions. If you control both teams at halftime, Back from outgoing-player selection returns to team selection. Cancel returns directly to halftime options. A mandatory foul-out replacement cannot be skipped with Back, Cancel, blank input, or an ineligible player.

Optional practice scenarios use the same executable and setup:

- Halftime: add `--substitution-case=halftime` to the launcher command. Choose halftime substitution, select a team, and use Back to return to team selection. Choose **5** from halftime options to finish.
- Mandatory replacement: add `--substitution-case=foul-out`. The home center has fouled out. Try Back, Cancel, and blank input, then choose **7** and press Enter. Play must not resume with the disqualified center still in the lineup.

Completed substitutions now use the same bench-time recording and fatigue-recovery routine as the original simulator, including mandatory foul-out replacements. Back, Cancel, and invalid entries leave both fatigue and bench times unchanged. The existing recovery thresholds are preserved; repeated substitutions without elapsed game time do not grant extra rest.

Automated coverage: `scripts\test-accessible-substitution-navigation.ps1` exercises the real menus and checks final lineups, substitution counts, unchanged clock/score/timeouts, outgoing bench timestamps, incoming fatigue recovery, recovery boundaries and limits, and repeat substitutions without elapsed rest. Automated checks cannot confirm JAWS speech.
