# Accessible mode implementation and handoff specification

## 1. Purpose and current status

The accessible mode adds an optional command-line interface for blind players and players who use screen readers such as JAWS while preserving the original graphical interface and simulation engine. It currently supports accessible team and rule configuration, starting lineups, human and computer coaching, complete regulation and overtime play, substitutions, timeouts, strategic fouling, and spoken or HTML postgame box scores. Basketball outcomes remain the responsibility of the original simulator. The accessible layer supplies choices to that engine and presents its state and results as sequential text. The implementation is approaching beta quality but still requires broader full-game and simulation-integrity testing.

The historical compiler, executable, and upstream source baseline is recorded in [accessibility-baseline.md](accessibility-baseline.md). This specification describes the current implementation and the information needed to continue the work.

## 2. Design principles

- Preserve the existing graphical interface as the default experience.
- Activate accessible mode only through an explicit command-line option.
- Keep shots, passes, turnovers, fouls, rebounds, fatigue, scoring, timing, and other basketball calculations in the original simulator.
- Present prompts and events as complete sequential lines that do not depend on cursor position, color, graphics, animation, or sound.
- Pause at meaningful review and decision points so the player controls the reading pace.
- Keep accessible interaction in dedicated modules where practical and limit changes to the original engine to narrow integration hooks.
- Preserve human coaching choices and allow computer strategy changes only for computer-controlled teams.
- Protect integration boundaries with automated transcript tests and source-level regression guards.
- Treat malformed, incomplete, or unsupported game-data files as outside the accessibility layer's scope.

## 3. Accessibility architecture

Accessible mode is an adapter around the original game engine. It gathers selections through sequential text prompts, converts them into the state expected by the existing simulator, and presents simulator events as screen-reader-friendly text. It does not implement a second basketball simulation.

```text
Player using a screen reader
    |
    | Sequential text commands
    v
AccessibleMode.bm
    |
    | Teams, rules, lineups, strategies, and play choices
    v
HELLO.BAS integration points
    |
    | Existing engine variables and routines
    v
Original simulation engine
    |
    | Passes, shots, turnovers, fouls, rebounds,
    | fatigue, substitutions, clock, and scoring
    v
AccessibleMode.bm
    |
    | Grouped play-by-play, status, decisions,
    | halftime, overtime, and box scores
    v
Player using a screen reader
```

### Component responsibilities

`AccessibleMode.bm` owns accessible prompts, menus, narration, summaries, and reports. `HELLO.BAS` retains the game flow and original simulation, with small integration points that redirect inaccessible input and output through accessible mode. `Variables.bi` stores shared integration state, and `AccessibleMode.bi` declares the callable boundary between the accessible adapter and the game.

### Simulation boundary

Accessible mode may select teams, configure supported rules, choose lineups, provide coaching decisions, and format engine results. It must not independently decide whether a pass is stolen, a shot succeeds, a foul occurs, a rebound is collected, or a team wins. Those decisions remain with the original engine.

### Strategy ownership

Human-selected offensive and defensive strategies must survive game initialization and remain in effect until the player changes them. Only computer-controlled teams may invoke computer strategy selection. The legacy `ComputerStrategy` routine acts on the global `P9` team variable, so accessible integration must assign `P9` to the intended computer-controlled team before calling it. Human defenses are categorized for engine calculations without invoking computer coaching.

### Interface compatibility

The graphical interface remains the default when the executable is started normally. Accessible behavior is enabled only with `--accessible`, `-a`, or `/accessible`. Both interfaces use the same team records and simulation routines.

## 4. `HELLO.BAS` integration map

`HELLO.BAS` remains the main game program and contains the original simulation. Most new accessibility functions were added to `AccessibleMode.bm`; changes in `HELLO.BAS` primarily add conditional calls to that adapter at existing setup, decision, narration, stoppage, and period-transition points. No parallel pass, shot, turnover, foul, rebound, or scoring engine was added.

### Program startup

Startup detects `--accessible`, `-a`, or `/accessible` and calls `AccessibleMainMenu`. Without one of those options, execution follows the original graphical path. The accessible declaration and implementation modules are included alongside the existing game modules.

### Main game initialization in `COLHOOP`

`COLHOOP` remains the main single-game routine. When accessible setup has already prepared a game, it accepts the selected teams, rules, lineups, and control options instead of repeating graphical setup. Original initialization of statistics, stamina, team ratings, and simulation adjustments still occurs.

Accessible initialization preserves strategies selected by human players. It invokes computer strategy only for computer-controlled teams and explicitly assigns the legacy `P9` target before calling `ComputerStrategy`. Human defenses are passed through `CategorizeDefense` so the engine receives the correct coverage and pressure categories without replacing the player's choice. This is a high-risk integration area because an incorrect team target or extra computer-strategy call can change simulation behavior before tipoff.

### Possession and decision points in `COLHOOP`

Hooks at existing possession boundaries flush pending play-by-play, announce possession and status, and count bounded possessions during automated tests. Test limits do not apply to normal interactive games. Existing human pass and shot decision points call accessible menus and receive the same lineup-slot and play-choice values expected by the original engine. The original code continues to determine possession changes and calculate play results.

### Halftime, regulation, and overtime

Existing period transitions flush accessible narration before changing game stages. Accessible hooks announce halftime and regulation summaries, pause for review, continue tied games through the original overtime path, and open the accessible postgame menu after completion. The original clock, scoring, temporary-fatigue reset, overtime timeout, and period calculations remain authoritative.

### Play-by-play, delay, and screen routines

`PBP` sends original engine narration to the accessible grouping layer when accessible mode is active. `DELAY` avoids timed visual pacing that would make narration difficult to follow with a screen reader. `WINDEX`, `CLEARPBPBOX`, `UPDATESCREEN`, and `SCOREBOARD` avoid unnecessary cursor-positioned or graphical work when the accessible adapter owns presentation. These hooks change presentation and pacing, not the result of a play.

### Passing and defensive pressure

`GetPassChoice` calls the accessible pass menu and returns the original zero-based lineup slot. The engine then performs its normal pressure, pass, turnover, and steal calculations. `PRESSGUARD` uses existing computer selection logic in accessible mode rather than entering an inaccessible positioned-screen prompt for choosing a guard against pressure.

### Fouls, foul-outs, and free throws

`FoulCalled` remains responsible for personal and team fouls, bonus state, and disqualification. When a human-controlled player fouls out, it calls the accessible replacement menu; computer-controlled teams continue through original substitution evaluation.

`FreeThrow_OneAndOne` and `FreeThrows` preserve the original free-throw calculations while preventing intentional or strategic fouls from creating an extra coaching stoppage between the foul and its free throws. Accessible mode supplies the late-game foul decision and designated defender before entering these existing routines.

The defender menu lists the five current lineup roles and player names, accepts `repeat` or `list`, and confirms the selected player by name before the foul enters the engine. The manual JAWS test hook prepares a late-game state and then rejoins the normal `COLHOOP` decision path; it does not implement a separate foul or continuation path.

### Dead-ball and stoppage handling

`DEADBALLOPTIONS` and `STOPPAGE` call the accessible coaching menu at supported review points while retaining computer substitution evaluation, defensive-fatigue evaluation, timeouts, clock checks, and steal or pressure adjustments. This is a high-risk integration area because an extra or missing stoppage can change possession flow or invoke coaching twice.

### Human and computer control checks

`IsDefensePC` contains an accessible path that prevents the original game from entering an inaccessible defensive interaction. Changes to this function or related `playerMode`, `compTeam`, `P`, and `D` conditions must be reviewed for coaching ownership so a computer cannot make a decision assigned to the human player.

### Automated test hooks

`COLHOOP` contains narrowly scoped branches for accessible halftime, overtime, intentional-foul, and computer-substitution test modes. Automated branches arrange deterministic engine states and exit after their target transition. The manual JAWS intentional-foul branch only prepares the late-game state before rejoining the normal engine path for the remainder of the game. All test branches must remain gated by explicit test arguments and must never run during an ordinary game.

## 5. Implemented user experience

### Starting accessible mode

The accessible command-line option bypasses the graphical main menu and presents complete, numbered text choices. The player can start a single game or exit without interacting with graphics, sound, color, or positioned screen regions.

### Selecting teams and rules

Single-game setup accepts separate visitor and home season identifiers, searches team names, and loads each selected team from the appropriate upstream data file. The player can configure team control, location, shot clock, three-point rules, and the foul-disqualification limit using supported engine options.

### Selecting lineups and strategies

Computer-controlled teams receive automatic lineups. Human-controlled teams may accept an automatic lineup or select players for the original engine's two guard, two forward, and center roles. Selection warns about missing or mismatched historical positions without inventing data or blocking otherwise eligible players. Human players select an offense and defense from the original strategy lists before tipoff.

### Playing possessions

The original engine processes the jump ball and every possession. Computer possessions run through original coaching and play selection. Human possessions pause at the engine's existing decision points and expose accessible pass and shot choices. Decision screens report the current possession, ball carrier, clock, shot clock, adjusted shot chance, and active strategies as appropriate.

Play-by-play is grouped into short sets of complete lines. Partial groups are flushed before a human choice, possession change, or other review point so a screen reader does not miss the latest event. Commands allow the player to repeat relevant information or hear score, strategy, lineup, stamina, and fatigue without unintentionally advancing play.

### Coaching at stoppages

Human-controlled teams may change supported offensive or defensive strategies, make substitutions, review lineup condition, and call timeouts at appropriate stoppages. Computer-controlled teams continue using the original substitution, strategy, fatigue, and defensive evaluation routines. Accessible coaching must not replace a human strategy with an AI choice.

When a timeout opens the accessible coaching menu, the timeout announcement and coaching choices are presented as one interaction. The menu reports both teams' remaining timeouts and does not require a separate Enter press for queued timeout narration. Reviewing the lineup, changing strategy, calling a timeout, or correcting an invalid choice returns directly to the coaching choices without an additional return prompt. The original timeout charge, clock restoration, fatigue recovery, and play-resumption routines remain authoritative.

### Halftime and overtime

Halftime announces the score, first-half team fouls, timeouts, and lineup condition. The original temporary-fatigue reset is applied before the second half, and the player may make accessible halftime substitutions. Tied games continue through the simulator's five-minute overtime periods until a winner is determined. Each overtime transition announces the tied score and added timeout and waits for the player before continuing.

### Fouls and disqualification

Accessible mode presents late-game strategic-foul decisions and allows the player to choose the defender who commits the foul. The defender list can be repeated and confirms the selected player by name. Foul recording, bonus rules, free throws, and disqualification remain in the original engine. Human teams receive an accessible replacement prompt after a foul-out, while computer teams use the original substitution evaluation.

### Postgame reporting

The final score explicitly announces that the game is over and waits for the player before leaving the game. Postgame options provide spoken player and team box scores and can generate a semantic `accessible-boxscore.html` file. The generated report uses headings and table headers and does not contain a development-machine path. The player may return to the accessible main menu after reviewing the results.

## 6. Source components

The following table identifies where a new maintainer should look when changing accessible mode.

| Component | Responsibility | Important boundary |
|---|---|---|
| `src/AccessibleMode.bm` | Accessible setup, prompts, narration, coaching menus, summaries, and reports | Should adapt engine input and output rather than calculate game outcomes |
| `src/AccessibleMode.bi` | Declarations for accessible functions and subroutines | Defines the callable interface used by the main game |
| `src/HELLO.BAS` | Main game flow, original simulation, and accessible integration hooks | Engine changes should remain separate from accessibility-only changes where possible |
| `src/Variables.bi` | Shared accessible configuration and integration state | Add shared state only when both the adapter and engine require it |
| `scripts/build.ps1` | Reproducible QB64-PE build entry point | Writes the ignored executable to `bin/HELLO.exe` |
| `scripts/install-team-data.ps1` | Installation of the upstream team-data dependency | Team data is not maintained by the accessibility layer |
| `scripts/test-*.ps1` | Automated transcript tests and source-level regression guards | Tests should be updated whenever an integration boundary changes |
| `doc/accessibility-baseline.md` | Historical upstream baseline and initial development record | Retains reproducibility details that are not repeated here |
| `AGENTS.md` | Persistent project build instructions | Requires the sole executable output to remain `bin\HELLO.exe` |

## 7. Important implementation details

### Engine team variables

- `P` identifies the team currently on offense.
- `D` identifies the team currently on defense.
- `P9` is a legacy target used by several coaching and strategy routines.
- `compTeam` identifies the computer-controlled team in a human-versus-computer game.
- `playerMode` distinguishes human, human-versus-computer, and computer-versus-computer engine operation.
- `accessiblePlayerOpt` stores the equivalent choice made during accessible setup.

Do not assume that `P9` automatically matches a loop variable or the current offense. Assign it explicitly before calling a legacy routine that uses it.

### Defense categorization

The simulator derives generalized defensive coverage and pressure categories from the selected defensive strategy. These derived values participate in pass, shot, steal, foul, and turnover adjustments. After accessible mode accepts or restores a human defensive strategy, it must call the original defense-categorization routine without calling computer strategy selection.

### Play-by-play grouping

Original play-by-play can be emitted rapidly and was designed for a visually updated screen. Accessible mode buffers short groups and presents them as stable text. Flush the buffer before any prompt that depends on the most recent play, before changing possessions, and before leaving a game stage.

### Bounded automated execution

Hidden accessible test options run deterministic or bounded portions of the original simulator. They exercise real engine transitions while keeping transcript tests fast. Interactive accessible games are not possession-limited and continue through regulation and any required overtime.

### Team data and cross-season games

Visitor and home season identifiers must remain independent throughout loading. Some historical records do not contain player positions; accessible mode reports that absence rather than supplying invented positions. Malformed or unsupported team files remain an upstream data concern.

### Foul and stoppage transitions

Strategic fouls must enter the original foul and free-throw routines with the intended defender and must not create an extra coaching stoppage between the foul and its free throws. After a disqualification, accessible integration must allow the original computer substitution flow or present the accessible human replacement flow as appropriate.

## 8. Automated tests

The test suite combines runtime transcript validation with source-level guards for fragile legacy transitions.

| Test | Type | Behavior protected |
|---|---|---|
| `test-accessible-menu.ps1` | Runtime transcript | Accessible startup, menu wording, and command handling |
| `test-accessible-team-selection.ps1` | Runtime transcript | Season loading, team search, matchup setup, rules, and starting lineups |
| `test-accessible-human-vs-computer.ps1` | Runtime transcript | Original-engine possessions and accessible human decisions |
| `test-accessible-halftime.ps1` | Runtime transcript | Halftime summary, substitutions, fatigue transition, and second-half resumption |
| `test-accessible-timeout.ps1` | Runtime transcript | Accessible timeout flow and computer substitution evaluation |
| `test-accessible-overtime.ps1` | Runtime transcript | Tied regulation, overtime transition, added timeout, and continued play |
| `test-accessible-boxscore.ps1` | Runtime transcript | Spoken box scores and semantic HTML report generation |
| `test-accessible-intentional-foul.ps1` | Runtime transcript | Strategic-foul decision, defender selection, free throws, and engine transition |
| `test-intentional-foul-regression.ps1` | Source guard | Intentional-foul conditions, stoppage sequencing, and engine-slot indexing |
| `test-accessible-strategy-ownership.ps1` | Source guard | Human strategy preservation and correct computer strategy targeting |

Build before running runtime transcript tests:

```powershell
.\scripts\build.ps1

.\scripts\test-accessible-menu.ps1
.\scripts\test-accessible-team-selection.ps1
.\scripts\test-accessible-human-vs-computer.ps1
.\scripts\test-accessible-halftime.ps1
.\scripts\test-accessible-timeout.ps1
.\scripts\test-accessible-overtime.ps1
.\scripts\test-accessible-boxscore.ps1
.\scripts\test-accessible-intentional-foul.ps1
.\scripts\test-intentional-foul-regression.ps1
.\scripts\test-accessible-strategy-ownership.ps1
```

## 9. Manual testing

Automated transcripts supplement rather than replace testing with a real screen reader. Before a beta release:

1. Complete a human-versus-computer game with JAWS.
2. Exercise passing, shooting, status, repeat, lineup, stamina, and fatigue commands.
3. Change offense and defense and confirm that the computer does not overwrite the human choices.
4. Make substitutions during ordinary stoppages and at halftime.
5. Call a timeout and confirm that play resumes from the correct state.
6. Exercise strategic fouling, free throws, and a player foul-out during normal gameplay.
7. Complete a tied game through overtime.
8. Review spoken player and team box scores.
9. Generate and review the semantic HTML box score.
10. Confirm that prompts remain available and do not depend on cursor position, color, graphics, or sound.
11. Start the program without an accessibility option and smoke-test the original graphical mode.

The intentional-foul interaction can also be tested with JAWS without playing a complete game:

```powershell
.\bin\HELLO.exe --accessible --jaws-intentional-foul-test
```

Choose a human-versus-computer control option during setup. The game then jumps to a late second-half foul decision, supports repeating the five-defender list, confirms the selected player, and rejoins the normal engine path for the foul, free throws, possession change, and remaining game.

Manual JAWS verification completed on August 23, 2026. The defender menu, repeat command, selected-player confirmation, foul assignment, free throws, possession transition, and continued gameplay were exercised successfully.

## 10. Known risks and beta work

- Compare turnover, foul, scoring, possession, and other game totals between accessible and graphical computer-versus-computer runs to detect integration drift.
- Reproduce the reported computer foul-out replacement behavior and determine whether it is an original simulation issue or an accessible stoppage issue.
- Verify that accessible integration does not interfere with the original engine's handling of substitutions and player disqualifications during normal gameplay.
- Complete broader JAWS testing across teams, seasons, rule combinations, and coaching styles.
- Ask additional blind players to review terminology, prompt order, pacing, and recoverability.
- Decide with the upstream maintainer whether contributions should be reviewed as one feature branch or as smaller focused pull requests.
- Update `accessibility-baseline.md` where its incremental status statements still describe completed features as future work.

### Out of scope

- Repairing malformed or incomplete team-data files.
- Supporting roster or season formats rejected by the original game.
- Correcting inaccurate historical player or team data.
- Redesigning the original simulator's roster-size or eligibility rules.
- Adding accessibility-specific recovery for unsupported game files.
- Replacing or independently reimplementing the simulation model.

## 11. Build and run instructions

The documented build uses QB64-PE 4.6.0 on Windows x64. Extract the compiler into `.tools/qb64pe`, install the official upstream team data, and build the executable:

```powershell
.\scripts\install-team-data.ps1
.\scripts\build.ps1
```

The executable is written to `bin/HELLO.exe`. This is the project's only permitted executable build output; do not create alternate, temporary, or test executables. If it is locked, identify the process before rebuilding and do not close a user's interactive game. Start accessible mode with:

```powershell
.\bin\HELLO.exe --accessible
```

The aliases `-a` and `/accessible` are also accepted. Start `HELLO.exe` without one of these options to use the graphical interface.

Generated executables, compiler files, runtime configuration, team-data installations, and generated reports should not be committed unless a future distribution process explicitly requires them.

## 12. Handoff guidance

1. Read this specification and `doc/accessibility-baseline.md` before changing the accessible game flow.
2. Build the current branch and run the complete regression suite before making engine-integration changes.
3. Put new prompts, narration, and accessible menus in `AccessibleMode.bm` whenever practical.
4. Keep general simulation fixes separate from accessibility changes so upstream behavior remains reviewable.
5. Trace legacy routines for global inputs such as `P`, `D`, and `P9` before calling them from a new context.
6. Preserve human coaching choices and verify which team owns every strategy or lineup mutation.
7. Add or extend a regression test whenever an integration bug is fixed.
8. Test meaningful workflow changes with JAWS, not only with captured console transcripts.
9. Update this specification when functionality, architectural boundaries, commands, dependencies, tests, known risks, or scope changes.
10. Build only `bin\HELLO.exe`; never create a second executable for testing or as a workaround for a locked file.
