Drop your fart sound here as fart.wav (or fart.ogg / fart.mp3).

Turdtris pitches it up and down to play the music, so a short, clean, single
fart works best. Without a file here, the built-in synthesised tune plays.
The same sample is also used for the game-over farts and when each new piece
spawns (that one is played at a higher pitch).

If the tune sounds too high or low for your sample, change FART_PITCH_OFFSET
near the top of main.gd (in semitones; 12 = one octave).

Songs
-----
Press 1 / 2 / 3 in game (or the controller's music button) to switch songs.
Fart Fanfare is the default:
  1  Fart Fanfare   (original, parts A + B)
  2  Korobeiniki    (traditional Russian folk song, plays A A B A)
  3  Brownsleeves   (Minuet in G, Petzold, long attributed to Bach)
All three are played with your fart sample when fart.wav/.ogg/.mp3 is here,
otherwise with the built-in synth. The music speeds up when the stack gets
more than 60% full. The notes live in the SONGS table at the top of main.gd
if you want to edit or add songs.

Built-in sound effects (always synthesised, no files needed)
-----------------------------------------------------------
  plop      a piece lands
  fart      a new piece appears (your sample is used if present)
  flush     lines clear
  lose      the toilet clogs
  pause     a falling four-note bell jingle; resume plays it rising
  levelup   a bright rising chime when the level goes up
Their volumes are in the vols table in _build_sounds in main.gd.
