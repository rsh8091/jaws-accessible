# Unexpected segment completion investigation

September 23, 2026: the user reported an unexpected "segment complete" ending
with roughly five minutes left, probably at a play-by-play Enter prompt after
a timeout. They recalled pressing 1 or 2. Other gameplay performance was good;
setup and substitution navigation had also seemed fine.

Run `scripts/test-accessible-timeout-resume.ps1` against `bin/HELLO.exe`.
The fixture uses real timeout, substitution, play-by-play, and offensive menus
at five minutes remaining in the second half. It checks continuing directly,
canceling a substitution, backing out of substitute selection, and completing
a substitution. Each case then supplies Enter, 1 followed by Enter, and 2
followed by Enter at three narration pauses, followed by a pass or shot choice.
Checks require the stop flag to remain clear, pending timeout to clear, and
clock, score, and remaining timeouts to remain unchanged during menu navigation.
Transcripts are saved under `dist/timeout-resume-tests`.

This isolates menu transitions; it does not simulate the intervening basketball
possessions, live keyboard timing, or JAWS speech. Passing it cannot rule out
an intermittent gameplay or input-timing issue. No cause is confirmed yet.

Result: all five timeout-resume cases passed on September 23, 2026. Neither
number ended the game at a narration pause; both repeated the guidance and
waited for Enter. The unexpected ending has not been reproduced.
