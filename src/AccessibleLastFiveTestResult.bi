            If accessibleEngineMode = 1 And IsAccessibleTestMode% = 1 And InStr(LCase$(Command$), "--accessible-last-five-test") > 0 Then
                Print "Accepted final-five choice: "; LTrim$(Str$(I1%))
                Exit Sub
            End If

