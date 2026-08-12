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

Visitor and home season IDs are stored independently, so cross-season matchups load each selected team from its correct data file.

Some historical companion files, including 1987, contain blank player-position fields. Accessible output reports these as `position not provided in this season's data` instead of reading an empty label; it does not invent a position that is absent from the source data.

The accessible path now plays one opening possession using the selected starters and original player shooting ratings. It announces tipoff, score, game clock, possession, shot clock, shooter, result, and the next possession as complete lines. Human offenses receive a numbered menu: 1 two-point shot, 2 three-point shot, 3 computer choice, 4 status, 5 lineup, 6 help, and 7 cancel. Descriptive command words remain aliases. Computer-controlled offenses choose automatically. This intentionally stops after one possession while the remaining graphical gameplay loop is adapted.

After building, run the accessible main-menu transcript test with:

```powershell
.\scripts\test-accessible-menu.ps1
.\scripts\test-accessible-team-selection.ps1
.\scripts\test-accessible-offense-menu.ps1
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
