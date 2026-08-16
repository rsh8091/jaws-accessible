# Accessibility baseline

## Known-good upstream build

- Source commit: `38e15f215fec8a032fda3e1b5b66360e875e9936`
- Game source version: `5.32`
- Compiler: QB64-PE `4.6.0`, Windows x64
- Compiler release artifact: `qb64pe_win-x64-4.6.0.7z`
- Compiler artifact SHA-256: `2C18A41A1435248B14B2080404811E9C6F7C0AC6D9E41976F720544480729E61`
- Baseline executable size: `15420928` bytes
- Baseline executable SHA-256: `A2543B80E6B6C7C5A119572C1953C905F44F71B8573FAA1C916762ABD1C3724F`

The unchanged source compiles successfully and the resulting executable starts from the `bin` directory with the bundled assets. A five-second startup smoke test left the process running, created `FOLDERS.CFG`, and produced no `errlog`.

## Build

Extract QB64-PE into `.tools/qb64pe`, then run:

```powershell
.\scripts\build.ps1
```

The build script compiles `src/HELLO.BAS` and writes the ignored executable to `bin/HELLO.exe`. A different compiler or output path can be supplied with `-Compiler` and `-Output`.

Run the accessible command-line mode with:

```powershell
.\bin\HELLO.exe --accessible
```

The aliases `-a` and `/accessible` are also accepted. Running the executable without one of these arguments preserves the original graphical interface.

Install the official upstream team-data archive before using single-game setup:

```powershell
.\scripts\install-team-data.ps1
```

Accessible single-game setup now accepts a season ID, searches team names, presents numbered results, selects visitor and home teams, configures control/location/rules, loads the original team records, and reads both rosters. It pauses between roster sections without clearing the console review history. Computer teams receive an automatic lineup; human teams can select five starters by number or enter `auto` for a recommended lineup before reaching the ready-for-tipoff checkpoint. Team data remains an upstream release dependency and is not committed to this repository.

Lineup slots preserve the original engine's roles: first guard, second guard, first forward, second forward, and center. Automatic selection prefers eligible players whose recorded position matches each role. If no match exists, it assigns the best remaining eligible player and announces a warning. Manual selection also warns about missing or mismatched recorded positions without blocking historical teams.

Visitor and home season IDs are stored independently, so cross-season matchups load each selected team from its correct data file.

Some historical companion files, including 1987, contain blank player-position fields. Accessible output reports these as `position not provided in this season's data` instead of reading an empty label; it does not invent a position that is absent from the source data.

The accessible path now runs bounded validation through the original simulator. Accessible mode supplies team and rules configuration, then adapts the simulator's play-by-play to complete command-line lines for JAWS. The original engine remains responsible for coaching, passing, shots, turnovers, fouls, rebounds, scoring, timing, and all other basketball calculations. Computer-versus-computer validation runs six possessions.

Interactive human-controlled games now run through both halves and stop at the end of regulation. Computer possessions provide detailed original-engine play-by-play. Human possessions pause at the simulator's existing decision points for accessible numbered pass and shot menus. Each possession and requested status announces the same current offensive and defensive strategies shown on the sighted scoreboard, using full strategy names. Each human decision announces the current shot clock and the original simulator's adjusted shot chance for the current opportunity. Commands remain available to hear full status or request the current lineup's stamina and effective fatigue without advancing play. Human-controlled teams select from the original simulator's offensive and defensive styles before tipoff and may change either style from accessible dead-ball options. At stoppages, computer-controlled teams run the original simulator's substitution and defensive-fatigue evaluation before accessible coaching options appear. The accessible offensive menu enforces the original clock, score, shot-clock, opposing-defense, and three-point restrictions. At halftime, accessible mode applies the original temporary-fatigue reset before reporting the score, first-half team fouls, remaining timeouts, lineup condition, and substitution options. The stamina number remains the original simulator's full-game contribution budget rather than a halftime-rest meter. Regulation ends with an accessible score summary; overtime and the complete postgame box score remain future stages.

The hidden automated transcript mode remains intentionally short: it runs at least one possession for each team and continues until a human decision prompt has been exercised. This keeps regression tests fast while interactive JAWS testing covers the full half.

Accessible gameplay clears the console at each new possession and again before a human offensive decision. Original-engine play-by-play is presented consistently for both teams in groups of up to three adjacent messages, with a single Enter press to advance each group. Partial groups are presented before a human decision or possession change. Human decision screens repeat the latest play description, then announce the current team, player with the ball, and complete choice menu. This prevents a screen reader from needing to track an indefinitely scrolling console buffer or racing against computer play.

After building, run the accessible main-menu transcript test with:

```powershell
.\scripts\test-accessible-menu.ps1
.\scripts\test-accessible-team-selection.ps1
.\scripts\test-accessible-human-vs-computer.ps1
.\scripts\test-accessible-halftime.ps1
.\scripts\test-accessible-timeout.ps1
```

Windows may mark executables extracted from a downloaded archive as blocked. After verifying the official release checksum, clear that marker if necessary:

```powershell
Get-ChildItem .tools\qb64pe -Recurse -File | Unblock-File
```

## First accessible vertical slice

The first milestone is one complete single game using sequential command-line input and output:

1. Start in accessible mode.
2. Select visiting and home teams.
3. Select human or computer control.
4. Configure essential rules.
5. Confirm starting lineups.
6. Play every possession with spoken, line-oriented narration and coaching commands.
7. Read the final score and box score.
8. Return to the accessible menu or exit.

The existing graphical mode remains the default while the vertical slice is developed.

## Initial interface seams

- `src/KeyInput.bm`: shared immediate-key input functions.
- `src/QPProEqu.bm`: shared graphical menu implementations.
- `Main_Menu` in `src/HELLO.BAS`: top-level dispatch.
- `COLHOOP` in `src/HELLO.BAS`: single-game flow.
- `PBP`, `UPDATESCREEN`, and `DisplayUserOpts` in `src/HELLO.BAS`: play narration and continuously repainted game state.
- `DEADBALLOPTIONS`, `DEFENSEMENU`, and substitution routines in `src/HELLO.BAS`: coaching decisions.
- `POSTGAME` and box-score routines in `src/HELLO.BAS`: end-of-game output.

Accessible mode must not depend on cursor position, color, mouse interaction, graphics, or sound. Prompts and game events should be emitted once as complete lines and remain available through explicit `repeat`, `score`, `lineup`, `strategy`, and `help` commands.
