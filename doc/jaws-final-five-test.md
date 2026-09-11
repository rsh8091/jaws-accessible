# JAWS final-five-seconds test

Run `Test JAWS Final Five Seconds.cmd` from the project folder with JAWS running. It uses `bin\HELLO.exe` and leaves keyboard input connected to the console.

1. Set up an exhibition game normally. Choose control option 2 or 3 (one human team and one computer team), select your lineup, and choose your styles.
2. The test prepares your team with possession, trailing 61–60 with four seconds remaining, one timeout, and three-pointers enabled.
3. At the test introduction, press Enter. JAWS should read the late-game offensive decision, score and clock, and choices 0 through 5.
4. Enter `5` and press Enter. The game should accept the two-point attempt and continue with the actual play result. A miss or turnover is not a test failure.
5. Restart to try `0` (a full-court pass for two). Invalid text should produce an error and let you choose again.

For timeout and three-point restrictions, run from the bin folder:

```text
HELLO.exe --accessible --jaws-last-five-test --restricted-choices
```

Choices 1, 3, and 4 should be omitted and rejected if typed; choices 0, 2, and 5 should remain usable.

The automated companion is `scripts\test-accessible-last-five.ps1`. It checks all six choices and input restrictions but does not verify JAWS speech. The manual test continues through the normal simulator; the automated test exits after verifying selection. Test setup and the automated exit hook live in `src\AccessibleLastFiveTestSetup.bi` and `src\AccessibleLastFiveTestResult.bi`, included by the main game routine.
