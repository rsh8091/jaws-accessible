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
