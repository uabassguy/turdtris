TURDTRIS custom art
===================

Everything is drawn in code by default. To swap in your own art, put PNGs in
this folder (assets/) and open the project in the Godot editor once so they get
imported. Files are picked up at launch.

  background.png   The WHOLE backdrop: wall, toilet bowl (the well), tank (side
                   panel), everything behind the pieces and text. A ready-made,
                   editable copy of the default look is included, so just open
                   it in any image editor and change it. 1440x1680 pixels
                   (any size with the same 6:7 shape works; it is scaled to
                   the 720x840 window). Delete the file to go back to the
                   built-in drawn version.

                   The game draws these on top of your image, so keep the
                   layout (in 720x840 units, double it for the 1440x1680 file):
                     well (where pieces fall)   x 40-400,  y 60-780
                     side panel (text, NEXT)    x 430-700, y 40-800
                   Keep the well dark and fairly plain so the pieces read,
                   and the panel dark enough for light text. The water at
                   the bottom of the well is drawn by the game.

  turd.png         One square sprite used for every block.
  turd_0.png ...   Optional per-piece sprites, one per tetromino type:
  turd_6.png         0=I 1=O 2=T 3=S 4=Z 5=J 6=L
                   (a missing turd_N.png falls back to turd.png, then to the
                   built-in drawn turd)

Sounds go in assets/sounds/ (see the README there).
