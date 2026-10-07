# JAWS overtime coaching test

Run `Test JAWS Overtime.cmd` from the project folder. It uses the normal
`bin\HELLO.exe`; no separate test executable is needed.

Complete the usual team, rule, lineup, and control setup and start play.
The shortcut sets the score to 70–70 at the end of regulation, then opens
Overtime options. The ensuing overtime uses the normal game engine.

1. Choose 2 or 3 to review the current lineups.
2. Choose 4 to substitute. Check 0 for Back and 99 for Cancel, then make a substitution.
3. Choose 6 to change offense and 7 to change defense. Choose 0 to leave either
   strategy menu without changing it. With two human coaches, select the team first.
4. Choose 1 to start overtime. Confirm the announced lineups include your
   substitution, then press Enter to begin play.
5. Alternatively choose 5 to end the game segment without starting overtime.

The same coaching menu appears before each additional overtime. Strategy
restrictions use the five-minute overtime starting clock, so tactics limited
to the final three minutes remain unavailable before overtime starts.

Automated coverage: `scripts/test-accessible-overtime.ps1` exercises human home,
human visitor, both human, computer-only, cancellation, early exit, and repeated
overtime. It verifies retained strategy choices and announced versus actual
starting lineups. Its controlled overtime possession ends immediately so these
checks do not depend on a randomly tied full game. The JAWS launcher instead
lets you play the overtime normally.
