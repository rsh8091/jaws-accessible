' Exercise the actual menus in the normal executable, with deterministic state.
If accessibleEngineMode = 1 And IsAccessibleTestMode% = 1 Then
    clockTestEnabled = 0
    For clockTestArgument = 1 To _CommandCount
        If LCase$(_Trim$(Command$(clockTestArgument))) = "--accessible-clock-test" Then clockTestEnabled = 1
    Next clockTestArgument
    If clockTestEnabled Then
        currHalf = 1
        gameClock! = 42: Call AccessiblePrintGameClock
        gameClock! = 1: Call AccessiblePrintGameClock
        gameClock! = 0: Call AccessiblePrintGameClock
        gameClock! = -1: Call AccessiblePrintGameClock
        currHalf = 2
        gameClock! = 60: Call AccessiblePrintGameClock
        gameClock! = 61: Call AccessiblePrintGameClock
        gameClock! = 120: Call AccessiblePrintGameClock
        gameClock! = 135.9: Call AccessiblePrintGameClock
        currHalf = 3
        gameClock! = 300: Call AccessiblePrintGameClock
        currHalf = 4
        gameClock! = 1: Call AccessiblePrintGameClock
        currHalf = 2: gameClock! = 135
        shotClock = 19: sClockVal = 1
        P = 1 - compTeam: D = compTeam: ballCarrier = 0
        score(0, 0) = 60: score(1, 0) = 61
        timeouts(0) = 2: timeouts(1) = 3
        shotType = 2: threePtOpt = 1
        clockTestPossessions = accessibleEnginePossessions
        clockTestOffense = offStrat(P): clockTestDefense = defStrat(D)
        For clockTestPhase = 1 To 3
            If clockTestPhase = 1 Then
                clockTestChoice = AccessibleReadPlayChoice%(P)
                If clockTestChoice <> 0 Then Print "CLOCK_TEST_FAIL action"
            Else
                P = compTeam: D = 1 - P
                accessiblePauseEvents = 1
                Call AccessibleQueuePbp(P, "Clock test computer possession pause.")
                Call AccessibleFlushPbp
                If accessiblePbpGroupCount <> 0 Then Print "CLOCK_TEST_FAIL narration"
            End If
            If gameClock! <> 135 Or shotClock <> 19 Then Print "CLOCK_TEST_FAIL time"
            If score(0, 0) <> 60 Or score(1, 0) <> 61 Then Print "CLOCK_TEST_FAIL score"
            If timeouts(0) <> 2 Or timeouts(1) <> 3 Then Print "CLOCK_TEST_FAIL timeouts"
            If accessibleEnginePossessions <> clockTestPossessions Then Print "CLOCK_TEST_FAIL possessions"
            If clockTestPhase = 1 And P <> 1 - compTeam Then Print "CLOCK_TEST_FAIL possession"
            If clockTestPhase > 1 And P <> compTeam Then Print "CLOCK_TEST_FAIL possession"
            If offStrat(1 - compTeam) <> clockTestOffense Or defStrat(compTeam) <> clockTestDefense Then Print "CLOCK_TEST_FAIL strategies"
            If accessibleTimeoutMenuPending <> 0 Then Print "CLOCK_TEST_FAIL timeout menu"
            If clockTestPhase < 3 And accessibleEngineStopRequested <> 0 Then Print "CLOCK_TEST_FAIL unexpected stop"
            If clockTestPhase = 3 And accessibleEngineStopRequested <> 1 Then Print "CLOCK_TEST_FAIL end"
            Print "CLOCK_TEST_PHASE "; LTrim$(Str$(clockTestPhase)); " complete"
        Next clockTestPhase
        accessiblePauseEvents = 0
        Print "CLOCK_TEST_COMPLETE"
        Exit Sub
    End If
End If
