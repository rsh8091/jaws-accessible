Declare Function IsAccessibleMode% Static
Declare Function IsAccessibleTestMode% Static
Declare Function IsAccessibleHalftimeTestMode% Static
Declare Function IsAccessibleComputerSubsTestMode% Static
Declare Function IsAccessibleFoulOutSubsTestMode% Static
Declare Function IsAccessibleBoxscoreTestMode% Static
Declare Function IsAccessibleBoxscoreTransitionTestMode% Static
Declare Function IsAccessibleBoxscoreHtmlTestMode% Static
Declare Function IsAccessibleOvertimeTestMode% Static
Declare Function IsAccessibleIntentionalFoulTestMode% Static
Declare Function IsAccessibleJawsIntentionalFoulTestMode% Static
Declare Function IsAccessibleStrategyOwnershipTestMode% Static
Declare Function IsAccessibleTurnoverDiagnosticMode% Static
Declare Function AccessibleComputerControlsTeam% (teamIdx) Static
Declare Function AccessibleRunStrategyOwnershipTest% () Static
Declare Sub AccessibleResetPeriodDefense ()
Declare Sub AccessibleResetTurnoverDiagnostic ()
Declare Sub AccessibleRecordTurnoverCheck (teamIdx, threshold, passNumber)
Declare Sub AccessibleRecordTurnover (teamIdx, reasonCode)
Declare Sub AccessiblePrintTurnoverDiagnostic ()
Declare Function AccessibleHtml$ (value$) Static
Declare Function AccessibleReadCommand$ (promptText$) Static
Declare Sub AccessibleMainMenu ()
Declare Sub AccessibleShowHelp ()
Declare Sub AccessibleSingleGameSetup ()
Declare Function AccessibleChooseTeam% (roleName$, yearNumber$, chosenIdx, teamName$) Static
Declare Function AccessibleLoadTeams% (yearNumber$) Static
Declare Function AccessibleTeamDisplay$ (teamName$) Static
Declare Function AccessibleConfigureGame% () Static
Declare Function AccessiblePrepareMatchup% (visitorYear$, homeYear$, visitorIdx, homeIdx) Static
Declare Sub AccessibleShowLoadedTeam (gameIdx, roleName$)
Declare Function AccessibleChooseStartingLineups% () Static
Declare Function AccessibleChooseLineup% (gameIdx, roleName$, computerControlled) Static
Declare Function AccessibleChooseOffense% (gameIdx) Static
Declare Function AccessibleChooseDefense% (gameIdx) Static
Declare Sub AccessibleAutoLineup (gameIdx)
Declare Sub AccessiblePrintLineup (gameIdx, roleName$)
Declare Sub AccessibleRunGame ()
Declare Function AccessiblePrepareJawsIntentionalFoulTest% () Static
Declare Function AccessibleReadPassChoice% (teamIdx) Static
Declare Function AccessibleReadDefenderChoice% (teamIdx) Static
Declare Function AccessibleReadStrategicFoulChoice% (defendingTeam) Static
Declare Function AccessibleReadPlayChoice% (teamIdx) Static
Declare Sub AccessiblePrintGameStatus ()
Declare Sub AccessiblePrintLineupCondition (teamIdx)
Declare Sub AccessibleQueuePbp (teamIdx, eventText$)
Declare Sub AccessibleFlushPbp ()
Declare Sub AccessibleDeadBallMenu (humanTeam, userTakeTO)
Declare Sub AccessibleSubstitutionMenu (humanTeam)
Declare Sub AccessibleReplaceFouledOutPlayer (humanTeam, fouledSlot)
Declare Function AccessibleHalftimeMenu% Static
Declare Sub AccessiblePrintHalftimeSummary ()
Declare Sub AccessiblePrintRegulationSummary ()
Declare Sub AccessiblePrintOvertimeTransition (overtimeNumber)
Declare Sub AccessiblePostgameMenu ()
Declare Sub AccessiblePrintGameSummary ()
Declare Sub AccessibleTeamBoxscoreMenu (teamIdx)
Declare Sub AccessiblePrintTeamTotals (teamIdx)
Declare Sub AccessiblePrintPlayerList (teamIdx)
Declare Sub AccessiblePlayerBoxscoreMenu (teamIdx)
Declare Sub AccessiblePrintPlayerStats (teamIdx, playerIdx)
Declare Sub AccessibleLoadBoxscoreFixture ()
Declare Sub AccessibleWriteHtmlBoxscore (htmlPath$)
Declare Sub AccessibleWriteHtmlTeamTable (htmlFile, teamIdx)
Declare Sub AccessibleOpenHtmlBoxscore ()
Declare Function AccessiblePlayerPosition$ (gameIdx, playerIdx) Static
Declare Function AccessibleLineupRole$ (slot) Static
Declare Function AccessiblePlayerMatchesRole% (gameIdx, playerIdx, slot) Static
