' Scenario fixture kept outside the simulator. Included inside the game routine
' because the entry label and Exit Sub belong to that routine.
If accessibleEngineMode = 1 Then
    lastFiveManualTest = 0
    lastFiveAutomatedTest = 0
    lastFiveRestrictedTest = 0
    For lastFiveArgument = 1 To _CommandCount
        Select Case LCase$(_Trim$(Command$(lastFiveArgument)))
            Case "--jaws-last-five-test": lastFiveManualTest = 1
            Case "--accessible-last-five-test": lastFiveAutomatedTest = IsAccessibleTestMode%
            Case "--restricted-choices": lastFiveRestrictedTest = 1
        End Select
    Next lastFiveArgument
    If lastFiveManualTest Or lastFiveAutomatedTest Then
        If lastFiveManualTest And playerMode <> 1 Then
            Print "This test requires one human-controlled team and one computer-controlled team."
            Print "Restart and choose control option 2 or 3."
            ignoredCommand$ = AccessibleReadCommand$("Press Enter to return to the menu: ")
            Exit Sub
        End If
        currHalf = 2
        gameClock! = 4
        P = 1 - compTeam
        D = 1 - P
        P9 = D
        ballCarrier = 0
        score(P, 1) = 30: score(P, 2) = 30: score(P, 0) = 60
        score(D, 1) = 30: score(D, 2) = 31: score(D, 0) = 61
        timeouts(P) = 1
        timeouts(D) = 0
        threePtOpt = 1
        If lastFiveRestrictedTest Then
            threePtOpt = 0
            timeouts(P) = 0
        End If
        If lastFiveManualTest Then
            Print "Manual JAWS final-five-seconds test."
            Print "Your team has the ball, down 61 to 60, with four seconds remaining."
            Print "Enter 5 for a two-point attempt, then press Enter."
            Print "The normal simulator will resolve the play. A missed shot or turnover is a valid result."
            ignoredCommand$ = AccessibleReadCommand$("Press Enter to open the offensive decision menu: ")
        End If
        GoTo LastFiveHumanDecision
    End If
End If
