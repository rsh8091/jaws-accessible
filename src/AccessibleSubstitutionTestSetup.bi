' Run real substitution menus with a fixed practice roster in the normal EXE.
If accessibleEngineMode = 1 And IsAccessibleTestMode% = 1 Then
    Shared rosterStatus()
    substitutionTestEnabled = 0
    substitutionTestCase$ = "timeout"
    substitutionTestClock = 135
    substitutionTestRest = 120
    substitutionTestFatigue = -5
    For substitutionArgument = 1 To _CommandCount
        substitutionArgument$ = LCase$(_Trim$(Command$(substitutionArgument)))
        If substitutionArgument$ = "--accessible-substitution-test" Then substitutionTestEnabled = 1
        If Left$(substitutionArgument$, 20) = "--substitution-case=" Then substitutionTestCase$ = Mid$(substitutionArgument$, 21)
        If Left$(substitutionArgument$, Len("--rest-seconds=")) = "--rest-seconds=" Then substitutionTestRest = Val(Mid$(substitutionArgument$, Len("--rest-seconds=") + 1))
        If Left$(substitutionArgument$, Len("--rest-fatigue=")) = "--rest-fatigue=" Then substitutionTestFatigue = Val(Mid$(substitutionArgument$, Len("--rest-fatigue=") + 1))
        If Left$(substitutionArgument$, Len("--rest-clock=")) = "--rest-clock=" Then substitutionTestClock = Val(Mid$(substitutionArgument$, Len("--rest-clock=") + 1))
    Next substitutionArgument
    If substitutionTestEnabled Then
        Print "Substitution navigation practice. This scenario uses a fixed practice roster."
        For testTeam = 0 To 1
            For testPlayer = 0 To 13
                players$(testTeam, testPlayer) = "XXX"
                rosterStatus(testTeam, testPlayer) = -1
                plyrOff_GAME!(testTeam, testPlayer, 12) = 0
                tmFatigue(testTeam, testPlayer) = substitutionTestFatigue
                playerTime(testTeam, testPlayer) = substitutionTestClock + substitutionTestRest
            Next testPlayer
            For testPlayer = 0 To 4
                players$(testTeam, testPlayer) = "Starter " + LTrim$(Str$(testPlayer + 1))
                rosterStatus(testTeam, testPlayer) = 0
                lineupIdx(testTeam, testPlayer) = testPlayer
            Next testPlayer
            players$(testTeam, 5) = "Reserve guard": rosterStatus(testTeam, 5) = 0
            players$(testTeam, 6) = "Reserve center": rosterStatus(testTeam, 6) = 0
            players$(testTeam, 7) = "Disqualified reserve": rosterStatus(testTeam, 7) = 0
            plyrOff_GAME!(testTeam, 7, 12) = 5
            players$(testTeam, 8) = "Unavailable reserve"
            positions_GAME$(testTeam, 5) = "G": positions_GAME$(testTeam, 6) = "C"
        Next testTeam
        accessiblePlayerOpt = 1
        P = 1: D = 0
        currHalf = 2: gameClock! = substitutionTestClock: shotClock = 19
        foulsToDQ = 5: timeouts(0) = 2: timeouts(1) = 3
        score(0, 0) = 60: score(1, 0) = 61
        accessiblePauseEvents = 0
        accessibleTimeoutMenuPending = 0
        Print "Players 1 through 5 start on court. Substitute 6 is a reserve guard; 7 is a reserve center."
        If substitutionTestCase$ = "empty" Then
            plyrOff_GAME!(1, 5, 12) = foulsToDQ
            plyrOff_GAME!(1, 6, 12) = foulsToDQ
        End If
        Select Case substitutionTestCase$
            Case "ft-shooter", "ft-shooter-one-and-one"
                'Reproduce pending-shooter substitution through the real engine and menus.
                'The original shooter always misses; the eligible replacement always makes.
                playerMode = 1: compTeam = 0: ballCarrier = 2
                intentional = 0: strategicFoul = 0: offStatus = 0
                autoPlay = 0: pbpOpt = 0: pbpDelay! = 0: sndOpt = 0
                tourneyPlay = 0
                accessiblePbpGroupCount = 0: accessiblePauseEvents = 1
                For testPlayer = 0 To 13
                    plyrOff_GAME!(1, testPlayer, 9) = 0
                    plyrOff_GAME!(1, testPlayer, 10) = 0
                    tmFatigue(1, testPlayer) = 0
                Next testPlayer
                plyrOff_GAME!(1, 2, 1) = 0
                plyrOff_GAME!(1, 5, 1) = 100
                Print "FT_REPRO_BEFORE shooter=Starter 3 slot=2 rating=0 replacement=Reserve guard rating=100"
                If substitutionTestCase$ = "ft-shooter-one-and-one" Then
                    Call FreeThrow_OneAndOne(testMissedFT)
                Else
                    Call FreeThrows(2, testMissedFT)
                End If
                Call AccessibleFlushPbp
                Print "FT_REPRO_AFTER slot_player="; LTrim$(Str$(lineupIdx(1, 2))); " original_fta="; LTrim$(Str$(plyrOff_GAME!(1, 2, 9))); " original_ftm="; LTrim$(Str$(plyrOff_GAME!(1, 2, 10))); " replacement_fta="; LTrim$(Str$(plyrOff_GAME!(1, 5, 9))); " replacement_ftm="; LTrim$(Str$(plyrOff_GAME!(1, 5, 10))); " home_score="; LTrim$(Str$(score(1, 0)))
                Print "FT_REPRO_COMPLETE"
                Exit Sub
            Case "timeout-resume"
                accessiblePauseEvents = 1
                accessibleTimeoutMenuPending = 1
                Call AccessibleQueuePbp(P, "Timeout resume test: timeout called.")
                Call AccessibleDeadBallMenu(1, testTakeTimeout)
                If accessibleEngineStopRequested <> 0 Then Print "SUBSTITUTION_TEST_FAIL timeout stopped game"
                If accessibleTimeoutMenuPending <> 0 Then Print "SUBSTITUTION_TEST_FAIL pending timeout"
                For resumeTestPause = 1 To 3
                    Call AccessibleQueuePbp(P, "Timeout resume test: next play-by-play pause.")
                    Call AccessibleFlushPbp
                    If accessibleEngineStopRequested <> 0 Then Print "SUBSTITUTION_TEST_FAIL pause stopped game"
                    Print "TIMEOUT_RESUME_PAUSE "; LTrim$(Str$(resumeTestPause))
                Next resumeTestPause
                ballCarrier = 0: shotType = 2
                resumeTestPlay = AccessibleReadPlayChoice%(P)
                If resumeTestPlay <> 0 And resumeTestPlay <> 1 Then Print "SUBSTITUTION_TEST_FAIL play choice"
                If accessibleEngineStopRequested <> 0 Then Print "SUBSTITUTION_TEST_FAIL play stopped game"
                Print "TIMEOUT_RESUME_PLAY "; LTrim$(Str$(resumeTestPlay))
                accessiblePauseEvents = 0
            Case "halftime"
                accessiblePlayerOpt = 0
                testHalftimeResult = AccessibleHalftimeMenu%
                If testHalftimeResult <> 0 Then Print "SUBSTITUTION_TEST_FAIL resumed second half"
            Case "foul-out"
                plyrOff_GAME!(1, 4, 12) = foulsToDQ
                Call AccessibleReplaceFouledOutPlayer(1, 4)
            Case Else
                If substitutionTestCase$ = "timeout" Then accessibleTimeoutMenuPending = 1
                Call AccessibleDeadBallMenu(1, testTakeTimeout)
                If accessibleEngineStopRequested <> 1 Then Print "SUBSTITUTION_TEST_FAIL resumed play"
        End Select
        For testTeam = 0 To 1
            Print "SUBSTITUTION_TEST_LINEUP "; LTrim$(Str$(testTeam)); ": ";
            For testSlot = 0 To 4
                If testSlot > 0 Then Print ",";
                Print LTrim$(Str$(lineupIdx(testTeam, testSlot)));
            Next testSlot
            Print
            For testPlayer = 0 To 8
                Print "SUBSTITUTION_TEST_REST "; LTrim$(Str$(testTeam)); ","; LTrim$(Str$(testPlayer)); " fatigue="; LTrim$(Str$(tmFatigue(testTeam, testPlayer))); " benched="; LTrim$(Str$(playerTime(testTeam, testPlayer)))
            Next testPlayer
        Next testTeam
        If gameClock! <> substitutionTestClock Or shotClock <> 19 Then Print "SUBSTITUTION_TEST_FAIL time"
        If timeouts(0) <> 2 Or timeouts(1) <> 3 Then Print "SUBSTITUTION_TEST_FAIL timeouts"
        If score(0, 0) <> 60 Or score(1, 0) <> 61 Then Print "SUBSTITUTION_TEST_FAIL score"
        If substitutionTestCase$ = "foul-out" Then
            If lineupIdx(1, 4) = 4 Then Print "SUBSTITUTION_TEST_FAIL fouled-out player retained"
        End If
        Print "SUBSTITUTION_TEST_COMPLETE"
        Exit Sub
    End If
End If
