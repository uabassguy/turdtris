# Turdtris

A Game Boy-style Tetris clone: a porcelain toilet for a well, turds for pieces,
farts for music, and a giant butt dropping each piece. Godot 4.7, GDScript, one script (`main.gd`).

## Controls

| | Keyboard | Controller |
|---|---|---|
| Move | Arrows or A / D | D-pad or left stick |
| Soft plop (fast drop) | Down | D-pad down |
| Rotate | X | bottom face button (Xbox A, PlayStation Cross, Switch B) |
| Rotate back | Z or Ctrl | right face button (Xbox B, PlayStation Circle, Switch A) |
| Pause | P or Esc | Start (Menu / Options / +) |
| Change song | 1 / 2 / 3 | Back (View / Create / -) |
| Mute | M | |
| Fullscreen | F11 or Alt+Enter | |

On-screen prompts follow the last device you used and the type of controller connected.
Up never rotates. There is no hard drop and no hold, like the original Game Boy game.
The L piece is the one piece that can wall-kick sideways.

## Running it

### Option A: download a build (no Godot needed)

Grab the files from the repo's **Releases** page.

**Windows (PC):** download `Turdtris.exe` and double-click it. Windows SmartScreen
may warn because the file is unsigned: click *More info*, then *Run anyway*.

**Linux:** download `Turdtris-x86_64.AppImage`, then:

    chmod +x Turdtris-x86_64.AppImage
    ./Turdtris-x86_64.AppImage

If it complains about FUSE, run it with `--appimage-extract-and-run`, or install
`libfuse2` (Debian/Ubuntu: `sudo apt install libfuse2`).

**Mac:** download `Turdtris-macOS.zip` and unzip it. The app is unsigned, so the
first launch is blocked: right-click `Turdtris.app`, choose **Open**, then **Open** again.
If macOS says the app is damaged, run this once in Terminal, then open it again:

    xattr -cr /path/to/Turdtris.app

### Option B: run from source

1. Install **Godot 4.7** (standard build, not .NET) from https://godotengine.org/download
   - Windows: unzip and run the `.exe`.
   - Linux: unzip, `chmod +x` the binary, and run it (or use your package manager / Flatpak).
   - Mac: drag Godot to Applications; on first launch right-click, **Open**.
2. Open Godot, click **Import**, and pick this folder's `project.godot`.
3. Wait for the first import to finish, then press **F5** (Play).

The renderer is *Compatibility*, so it runs on old graphics hardware.

## Making your own build

1. Project > Export. If it warns about missing templates, click *Manage Export Templates*
   and download them.
2. Make sure **Rendering > Textures > VRAM Compression > Import ETC2 ASTC** is on
   (needed for the Mac build) and that `project.godot` is saved.
3. Add presets named exactly **Windows Desktop**, **Linux** and **macOS**.
   - Windows and Linux: turn on **Embed PCK** so you get a single file.
   - Linux: x86_64.
   - macOS: set a Bundle Identifier (for example `com.yourname.turdtris`), choose universal, and leave signing and notarization off.
4. Commit `export_presets.cfg`.

### Builds on GitHub

`.github/workflows/build.yml` builds all three. Push a tag that starts with `v`
(for example `v0.2.0`) and it exports Windows (`Turdtris.exe`), Linux
(`Turdtris-x86_64.AppImage`, packaged with `icon.png`) and Mac (`Turdtris-macOS.zip`),
then attaches them to a GitHub release. You can also run it by hand from the
Actions tab; that only produces downloadable run artifacts.

## Customising

- Art: see `assets/README.txt` (`background.png`, `butt.png`, turd sprites).
- Sound and music: see `assets/sounds/README.txt` (your own `fart.wav`).
- Gameplay constants and the song tables are at the top of `main.gd`.

## Saving

The high score is saved automatically in Godot's user data folder for the project.
