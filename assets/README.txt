TURDTRIS custom art
===================

Everything is drawn in code by default. To swap in your own art, put PNGs in
this folder (assets/) and open the project in the Godot editor once so they get
imported. Files are picked up at launch.

  background.png   The backdrop: wall, toilet bowl (the well), tank (side
                   panel), everything behind the pieces and text. A ready-made,
                   editable copy of the default look is included, so open it
                   in any image editor and change it. 1440x1680 pixels
                   (any size with the same 6:7 shape works; it is scaled to
                   the 720x840 window). Delete the file to go back to the
                   built-in drawn version.

                   The game draws these on top of your image, so keep the
                   layout (in 720x840 units, double it for the 1440x1680 file):
                     well (where pieces fall)   x 40-400,  y 60-780
                     side panel (text, NEXT)    x 430-700, y 40-800
                   The well has rounded corners (radius 30 at the top, 56 at
                   the bottom). The game paints the corner bits of your image
                   back over the pieces so they never poke out, so keep the
                   well's shape if you edit it.
                   Keep the well dark and fairly plain so the pieces read,
                   and the panel dark enough for light text. The water at
                   the bottom of the well is drawn by the game.
                   The butt is NOT in this file any more (see butt.png).

  butt.png         The giant butt. A transparent PNG, 1440x880 (720x440 in
                   stage units), drawn ON TOP of the pieces. Its top-left
                   corner sits at (-140, -340) on the 720x840 stage, so it
                   extends past the left edge and above the top on purpose,
                   to avoid cutting the cheeks off on wide screens. It should
                   reach down only about 28 stage pixels into the well, the
                   first row of the grid. Delete it to use the built-in
                   drawn butt.

  turd.png         One square sprite used for every block.
  turd_0.png ...   Optional per-piece sprites, one per tetromino type:
  turd_6.png         0=I 1=O 2=T 3=S 4=Z 5=J 6=L
                   (a missing turd_N.png falls back to turd.png, then to the
                   built-in drawn turd)

Window: opens at 1280x720 and scales to any size; wider screens get extra wall
tiles on the sides. The icon used for the Linux AppImage is icon.png in the
project root (256x256).

Sounds go in assets/sounds/ (see the README there).
