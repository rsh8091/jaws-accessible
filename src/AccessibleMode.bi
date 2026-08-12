Declare Function IsAccessibleMode% Static
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
