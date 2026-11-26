TURDTRIS custom skins
=====================

Everything is drawn in code by default. To swap in your own art, drop PNGs in
this folder (res://assets/) or, with no re-import needed, in the user data
folder under a "skins" subfolder (user://skins/). Files are picked up at launch.

  background.png   Full-screen background, 720x840 recommended.
                   Replaces the bathroom wall + toilet art.
  turd.png         One square sprite used for every block.
  turd_0.png ...   Optional per-piece sprites, one per tetromino type:
  turd_6.png         0=I 1=O 2=T 3=S 4=Z 5=J 6=L
                   (a missing turd_N.png falls back to turd.png, then to the
                   built-in drawn turd)

In game:  T toggles between Turd skin and plain Classic Tetris.
