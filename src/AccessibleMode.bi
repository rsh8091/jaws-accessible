Declare Function IsAccessibleMode% Static
Declare Function AccessibleReadCommand$ (promptText$) Static
Declare Sub AccessibleMainMenu ()
Declare Sub AccessibleShowHelp ()
Declare Sub AccessibleSingleGameSetup ()
Declare Function AccessibleChooseTeam% (roleName$, yearNumber$, chosenIdx, teamName$) Static
Declare Function AccessibleLoadTeams% (yearNumber$) Static
Declare Function AccessibleTeamDisplay$ (teamName$) Static
Declare Function AccessibleConfigureGame% () Static
Declare Function AccessiblePrepareMatchup% (yearNumber$, visitorIdx, homeIdx) Static
Declare Sub AccessibleShowLoadedTeam (gameIdx, roleName$)
