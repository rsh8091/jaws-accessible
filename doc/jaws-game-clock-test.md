# JAWS game-clock check (issue #7)

Status: the user confirmed JAWS testing on September 22, 2026, and closed issue #7 as completed. Automated output and state checks cannot confirm speech.

Run `Test JAWS Game Clock.cmd` with JAWS running. This uses only `bin\HELLO.exe` and keeps keyboard input connected to the console.

1. Set up a single game with one human team and one computer team (control option 2 or 3). Choose your lineup and strategies normally.
2. The fixture prints time-format examples, then opens the normal offensive menu with 2 minutes 15 seconds remaining in the second half and 19 seconds on the shot clock.
3. Enter `7`. Confirm JAWS reads "Second half, 2 minutes 15 seconds remaining." Leave it alone briefly and use your normal review commands: the result must remain available until you press Enter. It should not announce the score or shot clock as part of this clock-only report.
4. Type `clock` again at the review prompt. Confirm the time is unchanged. Press Enter to return to offensive choices, then enter `clock` there and repeat the review.
5. Return to offensive choices and enter `5`. Confirm the full score, game clock, possession, shot clock, and strategies are readable and remain available until Enter. This checks the original missed-announcement report.
6. Return and select `1` (Pass). This fixture checks the selection without simulating the pass, then opens a computer-possession play-by-play pause at the same time.
7. At that pause, type `clock` twice. Each request must read the same time and remain paused. Invalid text must give guidance and remain paused. Press Enter to continue to the next fixture pause.
8. At the second computer pause, request `clock`, then type `end`. The scenario should finish and return to the accessible main menu.

Record whether JAWS automatically reads each requested report, whether review remains possible, and whether any narration overlaps or disappears. Note the JAWS version and the failing step if something is wrong. A `CLOCK_TEST_FAIL` message also indicates a failure; include its text.

For ordinary play, option 7 / `clock` is available at offensive decisions, including the separate final-five-seconds menu; `clock` is also available at play-by-play pauses. Clock requests do not advance play. This scenario does not test NVDA.

Optional late-game check: run `Test JAWS Final Five Seconds.cmd`, finish setup, and use `7` and `clock` at its offensive menu. Both should report four seconds remaining and wait for Enter before you select a play.
