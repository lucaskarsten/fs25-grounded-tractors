# Publishing on ModHub

Source: [ModHub Guidelines FS25](https://forum.giants-software.com/viewtopic.php?t=209169) (re-read before each submission; values change with game patches).

| Requirement | Status |
|---|---|
| Zip named `FS25_GroundedTractors.zip`, no version in name; updates `FS25_GroundedTractors_update.zip` | done (`build.sh`) |
| `descVersion` = current patch | 113: TestRunner 0.9.22 allows exactly 113 |
| Description in EN and DE, Script Mod template (Description, Hotkeys, GitHub link) | done |
| Mod icon `icon_*.dds`, 512x512, BC1, no mipmaps | done: in-game screenshot of the Vestrum 130 |
| At least 3 screenshots, 1600x900, full frame, first without HUD, no collages | 4 in docs/screenshots (field work, HUD off via `gtHud`); a ditch shot would show the effect better |
| Changelog | CHANGELOG.md |
| Self-test with the official TestRunner (forum t=187502, GDN account) | PASS (TestRunner 0.9.22, 2026-10-15) |
| Free, no paid content | yes |
| GitHub link in description must work | repo must be public before submitting |

Minor updates: wait at least 4 weeks between submissions; major fixes may go sooner.

## Uploading (from GIANTS' "Modders Guide to the ModHub", GDN downloads)

1. Log in at https://modhub.giants-software.com/main.php (ModHub account, separate from GDN). Upload only works on the website, not in game.
2. "Add New" (bottom left) creates an "Untitled Mod" at the top of the list; click its name.
3. Under "Data", pick `FS25_GroundedTractors.zip` from the GitHub release, accept the terms, "Upload Mod". The page fills its fields from modDesc.xml.
4. Fill the fields still marked on the left (screenshots from `docs/screenshots/`), then "Submit" next to "Certification". Status becomes "pending"; QA answers by email, questions go through the ModHub Messenger.
5. Updates: open the released mod, "Create Update", "View/Edit Update", replace the zip, "Submit".

Script mods are never released on console, so console compatibility does not apply.

Common rejection reasons the guide lists that touch this mod: tabs in the modDesc description (none), description missing EN or DE (both present), copyrighted icons (icon is an in-game frame), HUD in screenshots must be in English (ours have no HUD).
