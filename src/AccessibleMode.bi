Declare Function IsAccessibleMode% Static
Declare Function IsAccessibleTestMode% Static
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
Declare Sub AccessibleAutoLineup (gameIdx)
Declare Sub AccessiblePrintLineup (gameIdx, roleName$)
Declare Sub AccessiblePlayOpeningPossession ()
Declare Function AccessibleReadPassChoice% (teamIdx) Static
Declare Function AccessibleReadDefenderChoice% (teamIdx) Static
Declare Function AccessibleReadPlayChoice% (teamIdx) Static
Declare Sub AccessiblePrintGameStatus ()
Declare Sub AccessibleQueuePbp (teamIdx, eventText$)
Declare Sub AccessibleFlushPbp ()
Declare Function AccessiblePlayerPosition$ (gameIdx, playerIdx) Static
Declare Function AccessibleLineupRole$ (slot) Static
Declare Function AccessiblePlayerMatchesRole% (gameIdx, playerIdx, slot) Static
