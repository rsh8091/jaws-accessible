# Draft follow-up for Jason after release

Post to https://github.com/jleonard2099/LHG_CollegeBB/issues/38 after merge to main and release publication. The RC5 full-game test is complete. This draft has not been posted.

Before posting, replace both link placeholders. Keep the testing summary and known issues current if the build changes.

---

Hi Jason,

Following up on your interest in reviewing the accessibility work: we've now published an accessible gameplay release in our fork.

Release and download: [INSERT RELEASE LINK]
Code changes: [INSERT CODE COMPARISON LINK]

The release adds numbered, screen-reader-friendly menus for team selection, rules, lineups, and coaching; regulation and overtime gameplay; substitutions, timeouts, halftime adjustments, and intentional fouling; accessible play-by-play and clock/status reports; and spoken and HTML postgame box scores.

Accessible mode uses the original simulation engine and is enabled with `--accessible`. The graphical interface remains the default. This release focuses on playing games; it doesn't add accessible season or schedule management.

We've brought the branch up to date with your main branch. All 18 automated gameplay test scripts passed, along with package and installer checks. I also completed a full game with RC5 successfully. The release notes describe the changes and known issues.

How would you prefer to review this—try the packaged release first, review the code together, or have us prepare one PR or several smaller, focused PRs? Happy to organize the changes in whatever way works best for you.

Thanks,
Randy
