# Turdtris: Call of Doody: v0.9

## New
- **Renamed** the game to *Turdtris: Call of Doody* on the title screen (in-game it stays "Turdtris").
- **Win screen**: clear 25 lines in B-type style for a rocket launch scene, with a rocket take-off sound, a "press" prompt that only accepts input after it appears (so you can't skip it by accident), and credits (game by ResidentEmil_, with assistance from Claude AI).
- **F9 test key** jumps straight to the win screen.
- **Title screen music**: a slow, moody lounge theme in A minor, separate from the in-game songs.
- **Four songs** (keys 1-4 or the MUSIC menu row, plus OFF): Fart Fanfare (default), Korobeiniki (A A B A), Brownsleeves (formerly Minuet in G), and Loose Groove (new, original, A minor at 130 BPM).
- **INSTANT PLOP** option on the main menu (Up/W/D-pad up), remembered between runs.
- **Fart sound on every new piece** (higher pitched), with a little fart-cloud animation around the new piece.
- **Level-up chime** and a **pause jingle** (quieter).
- **Next-piece hints** now show over the water.
- **Controller-aware prompts**: Xbox, PlayStation and Switch icons depending on the connected pad, with keyboard prompts when the keyboard takes over.
- **L piece** can now rotate against either wall (sideways wall-kick).
- Board clears when you return to the title screen.

## Look
- **Retro 8/16-bit pixel style**: SNES-style palette, 12x12 pixel turd sprites that meld together, pixelated background and butt art, nearest-neighbor filtering, and a built-in blocky bitmap font with drop shadows.
- Wider butt that covers the pieces, a toilet-style frame, and rounded gameplay corners that also clip the pieces.
- Retro square dialog boxes, a wider menu that fits all its text, and a more readable right-hand panel.
- Water flicker fixed.
- Menu wording: "Music - <Select>", "Soft Plop" instead of "Soft Drop".
- New app icon (also set for macOS).

## Fixes
- Changing the MUSIC row on the menu no longer restarts the title theme.
- Controller type is no longer shown on the right side of the HUD.
- Win/lose screens ignore Enter/A until their prompt appears.

## Build and release
- GitHub Actions workflow exports **Windows (.exe), Linux (AppImage) and macOS (zip)** and attaches them to a release when you push a `v*` tag.
- Updated actions to v5 (Node.js 20 warning), fixed the export-templates error, and enabled ETC2/ASTC import for the universal/arm64 Mac export.
- Window override 1280x720, with the viewport scaling to fit.
- READMEs updated with setup instructions for Linux, PC and Mac.

## Notes
- Nothing here was run in Godot by the assistant; please playtest before tagging.
- To release: `git tag v0.9 && git push origin v0.9`.
