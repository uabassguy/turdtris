extends Node2D
## TURDTRIS: CALL OF DOODY - Tetris, but the well is a toilet bowl and the pieces are turds.
## Everything is drawn / synthesised in code, so it runs with zero imported assets.
## Drop PNGs in res://assets/ to re-skin it (see assets/README.txt).

enum State { TITLE, MENU, PLAYING, CLEARING, PAUSED, OVER }

const COLS := 10
const ROWS := 20
const CELL := 36.0
const BOARD_POS := Vector2(40, 60)
const BOARD_SIZE := Vector2(360, 720)
const VIEW_SIZE := Vector2(720, 840)
const PANEL := Rect2(430, 40, 270, 760)

# --- Game Boy Tetris timing: the Game Boy runs at 59.73 fps
const GB_FPS := 59.73
const DAS_DELAY := 23.0 / GB_FPS          # 23 frames before auto-shift starts
const ARR := 9.0 / GB_FPS                 # then one column every 9 frames
const SOFT_DROP_INTERVAL := 3.0 / GB_FPS  # holding Down: one row every 3 frames (1/3 G)
# Frames per row for levels 0-20 (our menu level 1 = Game Boy level 0). No lock delay: a piece
# locks when a gravity tick can't move it down, just like the original.
const GB_FRAMES := [53, 49, 45, 41, 37, 33, 28, 22, 17, 11, 10, 9, 8, 7, 6, 6, 5, 5, 4, 4, 3]
const SHOW_GHOST := true                  # the Game Boy has no ghost piece; set false for pure original
const CLEAR_TIME := 0.55
const GOAL := 25            # B-type: lines to clear
const SAVE_PATH := "user://turdtris.save"
const START_FULLSCREEN := false   # F11 / Alt+Enter toggles fullscreen at any time

# Piece order: I O T S Z J L
const SIZES := [4, 2, 3, 3, 3, 3, 3]
# Distinct rotation states: I, S and Z only flip between two, O has one (as on the Game Boy)
const STATES := [2, 1, 4, 2, 2, 4, 4]
# Spawn orientations. T, J and L spawn pointing down. No wall kicks, except the L.
const SHAPES := [
	[Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2)],   # I (flat in the 3rd row of its box)
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],   # O
	[Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)],   # T  XXX / .X.
	[Vector2i(1, 1), Vector2i(2, 1), Vector2i(0, 2), Vector2i(1, 2)],   # S  .XX / XX.
	[Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 2)],   # Z  XX. / .XX
	[Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 2)],   # J  XXX / ..X
	[Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(0, 2)],   # L  XXX / X..
]
# The Game Boy's randomizer numbers the pieces in multiples of 4 (I O T S Z J L)
const GB_VALUE := [8, 16, 24, 20, 12, 4, 0]
const TURD_COLORS := [
	Color("7b4a2b"), Color("8d5a30"), Color("6a3d22"), Color("9a6b3c"),
	Color("5c351d"), Color("84512a"), Color("a06f40"),
]
const CLASSIC_COLORS := [
	Color("00d8e0"), Color("f0d000"), Color("b040e0"), Color("40d040"),
	Color("e04040"), Color("4060f0"), Color("f09020"),
]
const REST := -99
# Songs are semitones above the sample's own pitch (REST = silence), one entry per step,
# staccato (a long note = the note followed by RESTs). Bass: one note per two steps.
# Press 1 / 2 / 3 / 4 to switch (controller: Back button cycles).

# 1: original tune, parts A and B
const MEL_FANFARE := [
	# A
	12, REST, 9, 12, 11, 9, 7, REST, 9, 11, 12, 9, 7, 4, 7, REST,
	4, 7, 9, REST, 12, 11, 9, 7, 5, 7, 9, 11, 12, REST, 12, REST,
	# B: bouncier, climbs up to a high peak and walks back down
	4, REST, 7, REST, 9, 7, 4, REST, 5, REST, 9, REST, 12, 9, 5, REST,
	7, 9, 11, 12, 14, 12, 11, 9, 7, 5, 4, 2, 4, REST, 12, REST,
]
const BASS_FANFARE := [
	0, 0, 5, 5, 7, 7, 0, 0, 0, 0, 5, 5, 7, 7, 0, 0,
	5, 5, 0, 0, 7, 7, 0, 0, 5, 5, 9, 9, 7, 7, 7, 7,
]

# 2: "Korobeiniki" (traditional Russian folk song, public domain), A minor, A = 0
const MEL_KOROBEINIKI := [
	7, REST, 2, 3, 5, REST, 3, 2,
	0, REST, 0, 3, 7, REST, 5, 3,
	2, REST, REST, 3, 5, REST, 7, REST,
	3, REST, 0, REST, 0, REST, REST, REST,
	5, REST, REST, 8, 12, REST, 10, 8,
	7, REST, REST, 3, 7, REST, 5, 3,
	2, REST, 2, 3, 5, REST, 7, REST,
	3, REST, 0, REST, 0, REST, REST, REST,
	# A again
	7, REST, 2, 3, 5, REST, 3, 2,
	0, REST, 0, 3, 7, REST, 5, 3,
	2, REST, REST, 3, 5, REST, 7, REST,
	3, REST, 0, REST, 0, REST, REST, REST,
	5, REST, REST, 8, 12, REST, 10, 8,
	7, REST, REST, 3, 7, REST, 5, 3,
	2, REST, 2, 3, 5, REST, 7, REST,
	3, REST, 0, REST, 0, REST, REST, REST,
	# B: the slower, singing second half (long notes, then it comes back around)
	7, REST, REST, REST, 3, REST, REST, REST,
	5, REST, REST, REST, 2, REST, REST, REST,
	3, REST, REST, REST, 0, REST, REST, REST,
	-1, REST, REST, REST, REST, REST, REST, REST,
	7, REST, REST, REST, 3, REST, REST, REST,
	5, REST, REST, REST, 2, REST, REST, REST,
	3, REST, 7, REST, 12, REST, REST, REST,
	11, REST, REST, REST, REST, REST, REST, REST,
	# A once more
	7, REST, 2, 3, 5, REST, 3, 2,
	0, REST, 0, 3, 7, REST, 5, 3,
	2, REST, REST, 3, 5, REST, 7, REST,
	3, REST, 0, REST, 0, REST, REST, REST,
	5, REST, REST, 8, 12, REST, 10, 8,
	7, REST, REST, 3, 7, REST, 5, 3,
	2, REST, 2, 3, 5, REST, 7, REST,
	3, REST, 0, REST, 0, REST, REST, REST,
]
const BASS_KOROBEINIKI := [
	0, 7, 0, 7,   0, 7, 0, 7,   -5, 2, -5, 2,   0, 7, 0, 0,
	-7, 0, -7, 0,   3, -2, 3, -2,   -5, 2, -5, 2,   0, 7, 0, 0,
	# A again
	0, 7, 0, 7,   0, 7, 0, 7,   -5, 2, -5, 2,   0, 7, 0, 0,
	-7, 0, -7, 0,   3, -2, 3, -2,   -5, 2, -5, 2,   0, 7, 0, 0,
	# B
	0, 7, 0, 7,   -5, 2, -5, 2,   0, 7, 0, 7,   -5, 2, -5, 2,
	0, 7, 0, 7,   -5, 2, -5, 2,   0, 7, 0, 7,   -5, 2, 0, 0,
	# A once more
	0, 7, 0, 7,   0, 7, 0, 7,   -5, 2, -5, 2,   0, 7, 0, 0,
	-7, 0, -7, 0,   3, -2, 3, -2,   -5, 2, -5, 2,   0, 7, 0, 0,
]

# 3: Minuet in G (Petzold, long attributed to J.S. Bach, public domain), G = 0, 3/4 time
const MEL_MINUET := [
	7, REST, 0, 2, 4, 5,
	7, REST, 0, REST, 0, REST,
	9, REST, 5, 7, 9, 10,
	12, REST, 0, REST, 0, REST,
	5, REST, 7, 5, 4, 2,
	4, REST, 5, 4, 2, 0,
	-1, REST, 0, 2, 4, 0,
	0, REST, REST, REST, REST, REST,
]
const BASS_MINUET := [
	0, 7, 7,   0, 7, 7,   5, 12, 12,   0, 7, 7,
	7, 14, 14,   0, 7, 7,   7, 14, 14,   0, 7, 0,
]

# Title / setup-screen theme (original): slow, smoky and a little sly, a lounge groove in A minor
# with a walking bass, instead of a cheery fanfare. Semitones above the sample's pitch, A = 0.
const MEL_TITLE := [
	7, REST, REST, 10, 12, REST, 10, REST,
	8, REST, REST, 5, 8, REST, 12, REST,
	7, REST, 2, REST, 7, REST, 11, REST,
	12, REST, REST, REST, REST, REST, REST, REST,
	8, REST, REST, 12, 15, REST, 12, REST,
	14, REST, 10, REST, 5, REST, 10, REST,
	15, REST, 12, REST, 11, REST, 7, REST,
	12, REST, REST, REST, REST, REST, REST, REST,
]
const BASS_TITLE := [
	0, 3, 7, 3,   5, 8, 12, 8,   7, 11, 14, 11,   0, 3, 7, 10,
	5, 8, 12, 8,   10, 14, 17, 14,   3, 7, 7, 11,   0, 7, 0, 7,
]
const TITLE_SONG := {"name": "Title", "mel": MEL_TITLE, "bass": BASS_TITLE, "step": 0.23}

# 4: "Loose Groove" (original, inspired by the form of a classic relaxed puzzle theme): 24 bars of A minor at 130 BPM,
# sixteenth-note steps. Shape: Am vamp x2, a root walk-down (A G F# F), a higher Am hook, a D / G lift,
# a G# tension bar and a C - D turnaround. The tune itself is new.
# Semitones above the sample's pitch, A = 0 (C = 3, E = 7, G = 10, high A = 12, high C = 15).
const MEL_CHILL := [
	12, REST, 15, REST, 14, 12, REST, 7, 10, REST, REST, REST, 7, REST, REST, REST,
	12, REST, 15, REST, 14, 12, REST, 17, 15, REST, REST, REST, REST, REST, REST, REST,
	12, REST, 15, REST, 14, 12, REST, 7, 10, REST, 12, REST, 14, REST, 15, REST,
	19, REST, REST, 17, 15, REST, 14, REST, 12, REST, REST, REST, REST, REST, REST, REST,
	7, REST, 10, REST, 12, REST, 10, 7, 12, REST, REST, REST, 10, REST, 7, REST,
	7, REST, 10, REST, 12, REST, 14, REST, 15, REST, REST, REST, REST, REST, REST, REST,
	7, REST, 10, REST, 12, REST, 10, 7, 12, REST, 15, REST, 17, REST, 15, REST,
	14, REST, 12, REST, 10, REST, 7, REST, 12, REST, REST, REST, REST, REST, REST, REST,
	12, REST, REST, 15, REST, REST, 12, REST, 14, REST, REST, REST, REST, REST, REST, REST,
	10, REST, REST, 14, REST, REST, 10, REST, 12, REST, REST, REST, REST, REST, REST, REST,
	9, REST, REST, 12, REST, REST, 9, REST, 11, REST, REST, REST, REST, REST, REST, REST,
	8, REST, REST, 12, REST, REST, 8, REST, 10, REST, 11, REST, 14, REST, REST, REST,
	19, REST, REST, 17, REST, 15, REST, 14, 15, REST, REST, REST, 12, REST, REST, REST,
	14, REST, 15, REST, 17, REST, 15, REST, 14, REST, REST, REST, REST, REST, REST, REST,
	19, REST, REST, 17, REST, 15, REST, 14, 15, REST, 17, REST, 19, REST, REST, REST,
	17, REST, 15, REST, 14, REST, 12, REST, 7, REST, REST, REST, REST, REST, REST, REST,
	14, REST, REST, 17, REST, REST, 14, REST, 12, REST, REST, REST, REST, REST, REST, REST,
	14, REST, REST, 17, REST, REST, 19, REST, 17, REST, REST, REST, REST, REST, REST, REST,
	14, REST, REST, 17, REST, REST, 14, REST, 15, REST, REST, REST, 12, REST, REST, REST,
	17, REST, 15, REST, 14, REST, 10, REST, 12, REST, REST, REST, REST, REST, REST, REST,
	12, REST, REST, REST, 11, REST, REST, REST, 12, REST, REST, REST, 14, REST, REST, REST,
	15, REST, REST, REST, 14, REST, 11, REST, 12, REST, REST, REST, REST, REST, REST, REST,
	15, REST, REST, 12, REST, REST, 15, REST, 17, REST, REST, REST, REST, REST, REST, REST,
	17, REST, REST, 14, REST, REST, 17, REST, 19, REST, REST, REST, 12, REST, REST, REST,
]
const BASS_CHILL := [
	0, 12, 0, 7, 0, 12, 0, 7,
	0, 12, 0, 7, 0, 12, 0, 7,
	0, 12, 0, 7, 0, 12, 0, 7,
	0, 12, 0, 7, 0, 12, 0, 7,
	0, 12, 0, 7, 0, 12, 0, 7,
	0, 12, 0, 7, 0, 12, 0, 7,
	0, 12, 0, 7, 0, 12, 0, 7,
	0, 12, 0, 7, 0, 12, 0, 7,
	0, 12, 0, 7, 0, 12, 0, 7,
	10, 10, 10, 5, 10, 10, 10, 5,
	9, 9, 9, 4, 9, 9, 9, 4,
	8, 8, 8, 3, 8, 8, 8, 3,
	0, 12, 0, 7, 0, 12, 0, 7,
	0, 12, 0, 7, 0, 12, 0, 7,
	0, 12, 0, 7, 0, 12, 0, 7,
	0, 12, 0, 7, 0, 12, 0, 7,
	5, 5, 5, 12, 5, 5, 5, 12,
	10, 10, 10, 5, 10, 10, 10, 5,
	5, 5, 5, 12, 5, 5, 5, 12,
	10, 10, 10, 5, 10, 10, 10, 5,
	0, 12, 0, 7, 0, 12, 0, 7,
	0, 12, 0, 7, 0, 12, 0, 7,
	3, 3, 3, 10, 3, 3, 3, 10,
	5, 5, 5, 12, 5, 5, 5, 12,
]

const SONGS := [
	{"name": "Fart Fanfare", "mel": MEL_FANFARE, "bass": BASS_FANFARE, "step": 0.2},
	{"name": "Korobeiniki", "mel": MEL_KOROBEINIKI, "bass": BASS_KOROBEINIKI, "step": 0.19},
	{"name": "Brownsleeves", "mel": MEL_MINUET, "bass": BASS_MINUET, "step": 0.2},
	{"name": "Loose Groove", "mel": MEL_CHILL, "bass": BASS_CHILL, "step": 0.115},
]
const FART_PITCH_OFFSET := -7.0   # shifts the whole tune; tweak if your sample sounds too high / low
const CLEAR_NAMES := ["", "PLOP!", "DOUBLE DUMP!", "TRIPLE LOG JAM!", "SHITRIS!!!"]
const CLEAR_POINTS := [0, 100, 300, 500, 800]

var board: Array[int] = []
var ids: Array[int] = []        # which dropped piece each settled cell belongs to (for melding)
var piece_serial := 0
var meld_id := -1               # most recently locked piece, melds a split second after landing
var meld_t := 0.0
var soft_blocked := false       # down was held through a line clear: ignore until released
var style_cache := {}
var cur_type := 0
var cur_rot := 0
var cur_pos := Vector2i.ZERO
var next_type := 0

var score := 0
var high := 0
var level := 1
var lines := 0

var state := State.TITLE
var fall_timer := 0.0
var lock_timer := 0.0
var soft_timer := 0.0
var lock_resets := 0
var das_dir := 0
var das_timer := 0.0
var clear_rows: Array[int] = []
var clear_timer := 0.0
var popup_text := ""
var popup_timer := 0.0
var shake := 0.0
var puffs: Array = []   # little fart clouds around a new piece: {pos, vel, age, life, size}
var time := 0.0

const turd_mode := true
var muted := false
var bg_tex: Texture2D = null
var butt_tex: Texture2D = null   # assets/butt.png, drawn on top of the pieces
const BUTT_ORIGIN := Vector2(-140, -340)   # where butt.png's top-left sits on the stage
const BUTT_SIZE := Vector2(720, 440)
var turd_texs: Array[Texture2D] = []
var turd_styles: Array[StyleBoxFlat] = []
var classic_styles: Array[StyleBoxFlat] = []
var players := {}
var music: AudioStreamPlayer
var fart_sample: AudioStream = null
var seq_pool: Array[AudioStreamPlayer] = []
var seq_stop: Array[float] = []
var seq_step := 0
var seq_acc := 0.0
var cur_song := 0
var music_enabled := true
var music_speed := 1.0          # 1.0 normally, faster while the stack is above 60% height
var game_type := 0              # 0 = A-type (endless), 1 = B-type (clear GOAL lines)
var start_level := 1
var start_height := 0           # B-type: starting garbage, height x 2 rows
var menu_row := 0
var instant_drop := false      # setup-menu option: Up / D-pad up drops the piece instantly
var won := false
var pause_row := 0               # pause menu: 0 = RESUME / NO (the defaults), 1 = RETURN TO TITLE / YES
var pause_confirm := false      # "are you sure?" step before leaving to the title
var win_t := 0.0                 # seconds since the win screen started (drives the rocket)
var launched := false
var clog_progress := 0.0        # rows of poo that have flooded in from the bottom after losing
var song_streams := {}


func _toggle_fullscreen() -> void:
	var m := DisplayServer.window_get_mode()
	if m == DisplayServer.WINDOW_MODE_FULLSCREEN or m == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST   # crisp pixel art
	_build_font()
	randomize()
	if START_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	Input.joy_connection_changed.connect(_on_joy_changed)
	if not Input.get_connected_joypads().is_empty():
		_use_pad(Input.get_connected_joypads()[0])
	_build_styles()
	_load_skins()
	_build_sounds()
	_load_high()
	board.resize(COLS * ROWS)
	board.fill(-1)
	ids.resize(COLS * ROWS)
	ids.fill(-1)
	next_type = randi() % 7


# ------------------------------------------------------------------ setup

func _build_styles() -> void:
	for i in 7:
		var s := StyleBoxFlat.new()
		s.bg_color = TURD_COLORS[i]
		s.border_color = TURD_COLORS[i].darkened(0.45)
		s.set_border_width_all(2)
		s.set_corner_radius_all(14)
		s.anti_aliasing = true
		turd_styles.append(s)
		var c := StyleBoxFlat.new()
		c.bg_color = CLASSIC_COLORS[i]
		c.border_color = CLASSIC_COLORS[i].darkened(0.5)
		c.set_border_width_all(2)
		c.set_corner_radius_all(3)
		classic_styles.append(c)


func _try_tex(file: String) -> Texture2D:
	var p := "res://assets/" + file
	if ResourceLoader.exists(p):
		return load(p) as Texture2D
	return null


func _load_skins() -> void:
	bg_tex = _try_tex("background.png")
	butt_tex = _try_tex("butt.png")
	var single := _try_tex("turd.png")
	turd_texs.clear()
	for i in 7:
		var t := _try_tex("turd_%d.png" % i)
		turd_texs.append(t if t != null else single)


func _load_high() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if f:
			high = f.get_32()
			if f.get_position() < f.get_length():   # older save files have only the high score
				instant_drop = f.get_8() == 1


func _save_high() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_32(high)
		f.store_8(1 if instant_drop else 0)


# ------------------------------------------------------------------ sound

func _make_wav(samples: PackedFloat32Array, rate: int) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 30000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = bytes
	return w


func _make_plop() -> AudioStreamWAV:
	var rate := 22050
	var n := int(rate * 0.28)
	var s := PackedFloat32Array()
	s.resize(n)
	var ph := 0.0
	var lp := 0.0
	for i in n:
		var t := float(i) / rate
		# low "thud" body: pitch drops fast to a deep sub tone
		var f := 48.0 + 130.0 * exp(-t * 28.0)
		ph += TAU * f / rate
		var body := sin(ph) * exp(-t * 11.0)
		# soft wet "plop" on top: short, quickly falling bubble
		var bub := sin(TAU * (160.0 + 240.0 * exp(-t * 40.0)) * t) * exp(-t * 35.0) * 0.35
		# muffled impact noise right at the start
		lp += 0.15 * ((randf() * 2.0 - 1.0) - lp)
		var thump := lp * exp(-t * 60.0) * 0.6
		s[i] = (body * 0.9 + bub + thump) * minf(1.0, t * 400.0)
	return _make_wav(s, rate)


# A tiny bell jingle: falling arpeggio = pause, rising = resume
func _make_blips(freqs: Array) -> AudioStreamWAV:
	var rate := 22050
	var per := int(rate * 0.11)
	var tail := int(rate * 0.25)
	var s := PackedFloat32Array()
	s.resize(per * (freqs.size() - 1) + tail)
	for k in freqs.size():
		var f: float = freqs[k]
		for i in tail:
			var t := float(i) / rate
			var env := minf(1.0, t * 500.0) * exp(-t * 11.0)
			var v := (sin(TAU * f * t) + 0.3 * sin(TAU * f * 2.0 * t) + 0.12 * sin(TAU * f * 3.0 * t)) * env * 0.45
			var idx := k * per + i
			if idx < s.size():
				s[idx] += v
	return _make_wav(s, rate)


func _make_music(song: Dictionary) -> AudioStreamWAV:
	# Plays a song on a fart synth + thumpy bass (used when there is no fart sample).
	var rate := 22050
	var spn := int(rate * float(song["step"]))
	var rest := REST
	var mel: Array = song["mel"]
	var bass: Array = song["bass"]
	var total := mel.size() * spn
	var buf := PackedFloat32Array()
	buf.resize(total)
	for i in mel.size():
		var m: int = mel[i]
		if m == rest:
			continue
		var base := 110.0 * pow(2.0, m / 12.0)
		var note_len := int(spn * 0.92)
		var y := 0.0
		var ph := 0.0
		for j in note_len:
			var t := float(j) / rate
			var f := base * (1.0 + 0.025 * sin(TAU * 26.0 * t)) * (1.0 - 0.06 * t)
			ph += f / rate
			var saw := fposmod(ph, 1.0) * 2.0 - 1.0
			var flutter := 0.6 + 0.4 * sin(TAU * 34.0 * t)
			var env := minf(1.0, t * 80.0) * pow(maxf(0.0, 1.0 - float(j) / note_len), 0.5)
			var x := (saw * 0.8 + (randf() * 2.0 - 1.0) * 0.12) * flutter * env
			y += 0.4 * (x - y)
			buf[i * spn + j] += y * 0.55
	for b in bass.size():
		var f := 55.0 * pow(2.0, float(bass[b]) / 12.0)
		var ph := 0.0
		for j in int(spn * 1.2):
			var t := float(j) / rate
			ph += TAU * f * (1.0 + 0.5 * exp(-t * 40.0)) / rate
			var idx := b * 2 * spn + j
			if idx < total:
				buf[idx] += sin(ph) * exp(-t * 9.0) * 0.5
	var w := _make_wav(buf, rate)
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = total
	return w


func _make_fart() -> AudioStreamWAV:
	var rate := 22050
	var dur := 0.8
	var n := int(rate * dur)
	var s := PackedFloat32Array()
	s.resize(n)
	var ph := 0.0
	var y := 0.0
	for i in n:
		var t := float(i) / rate
		var f := 62.0 + 14.0 * sin(TAU * 9.0 * t) - 22.0 * t + randf() * 3.0
		ph += f / rate
		var saw := fposmod(ph, 1.0) * 2.0 - 1.0
		var flutter := 0.55 + 0.45 * sin(TAU * 31.0 * t + sin(TAU * 5.0 * t) * 2.0)
		var env := pow(maxf(0.0, 1.0 - t / dur), 0.6) * minf(1.0, t * 40.0)
		var x := (saw * 0.7 + (randf() * 2.0 - 1.0) * 0.15) * flutter * env
		y += 0.35 * (x - y)
		s[i] = y * 1.4
	return _make_wav(s, rate)


func _make_long_fart() -> AudioStreamWAV:
	var rate := 22050
	var dur := 1.9
	var n := int(rate * dur)
	var s := PackedFloat32Array()
	s.resize(n)
	var ph := 0.0
	var y := 0.0
	for i in n:
		var t := float(i) / rate
		var k := t / dur
		# wobbling low rumble that sags, then a squeaky tail
		var squeak := maxf(0.0, k - 0.78) * 900.0
		var f := 80.0 + 18.0 * sin(TAU * 8.0 * t) - 25.0 * k + squeak + randf() * 4.0
		ph += f / rate
		var saw := fposmod(ph, 1.0) * 2.0 - 1.0
		var flutter := 0.5 + 0.5 * sin(TAU * (24.0 + 12.0 * k) * t)
		var pulse := 0.65 + 0.35 * sin(TAU * 3.1 * t)
		var env := minf(1.0, t * 30.0) * pow(maxf(0.0, 1.0 - k), 0.4)
		var x := (saw * 0.75 + (randf() * 2.0 - 1.0) * 0.15) * flutter * pulse * env
		y += 0.4 * (x - y)
		s[i] = y * 1.5
	return _make_wav(s, rate)


func _make_launch() -> AudioStreamWAV:
	var rate := 22050
	var n := int(rate * 3.2)
	var s := PackedFloat32Array()
	s.resize(n)
	var lp := 0.0
	var ph := 0.0
	for i in n:
		var t := float(i) / rate
		lp += (0.12 + 0.1 * minf(t, 1.5)) * ((randf() * 2.0 - 1.0) - lp)   # rumble that brightens as it climbs
		var env := minf(1.0, t * 6.0) * (1.0 if t < 2.2 else maxf(0.0, 1.0 - (t - 2.2)))
		ph += TAU * (45.0 + 70.0 * t) / rate
		s[i] = (lp * 1.4 + sin(ph) * 0.45) * env * 0.8
	return _make_wav(s, rate)


func _make_flush() -> AudioStreamWAV:
	var rate := 22050
	var dur := 1.4
	var n := int(rate * dur)
	var s := PackedFloat32Array()
	s.resize(n)
	var y := 0.0
	for i in n:
		var t := float(i) / rate
		var k := t / dur
		var a := 0.06 + 0.5 * sin(PI * k)
		y += a * ((randf() * 2.0 - 1.0) - y)
		var env := pow(sin(PI * k), 0.7)
		var gurgle := sin(TAU * (220.0 - 100.0 * t) * t) * 0.15 * k
		s[i] = (y * 1.2 + gurgle) * env * 0.6
	return _make_wav(s, rate)


func _build_sounds() -> void:
	var table := {"plop": _make_plop(), "fart": _make_fart(), "flush": _make_flush(), "lose": _make_long_fart(), "pause": _make_blips([784.0, 659.0, 523.0, 392.0]), "resume": _make_blips([392.0, 523.0, 659.0, 784.0]), "levelup": _make_blips([659.0, 784.0, 988.0, 1319.0]), "launch": _make_launch()}
	var vols := {"plop": -13.0, "fart": -6.0, "flush": -20.0, "lose": -3.0, "pause": -14.0, "resume": -14.0, "levelup": -11.0, "launch": -17.0}
	for key in table:
		var p := AudioStreamPlayer.new()
		p.stream = table[key]
		p.volume_db = vols[key]
		add_child(p)
		players[key] = p
	music = AudioStreamPlayer.new()
	music.volume_db = -14.0
	add_child(music)
	_load_fart_sample()
	if fart_sample == null:
		music.stream = _song_stream(cur_song)   # only needed when there is no custom sample


# Put your own fart in res://assets/sounds/ as fart.wav / fart.ogg / fart.mp3.
# It gets pitched up and down to play the tune; without it the built-in synth tune plays.
func _load_fart_sample() -> void:
	for ext: String in ["wav", "ogg", "mp3"]:
		var p := "res://assets/sounds/fart." + ext
		if ResourceLoader.exists(p):
			fart_sample = load(p) as AudioStream
			break
	if fart_sample == null:
		return
	players["fart"].stream = fart_sample
	for i in 10:
		var pl := AudioStreamPlayer.new()
		pl.stream = fart_sample
		add_child(pl)
		seq_pool.append(pl)
		seq_stop.append(0.0)


func _play_note(semi: float, dur: float, vol: float) -> void:
	for k in seq_pool.size():
		if not seq_pool[k].playing:
			var pl := seq_pool[k]
			pl.pitch_scale = clampf(pow(2.0, (semi + FART_PITCH_OFFSET) / 12.0), 0.05, 8.0)
			pl.volume_db = vol
			pl.play()
			seq_stop[k] = time + dur
			return


func _seq_tick() -> void:
	var song: Dictionary = TITLE_SONG if _in_title() else SONGS[cur_song]
	var mel: Array = song["mel"]
	var bass: Array = song["bass"]
	var step: float = song["step"]
	var i := seq_step % mel.size()
	var m: int = mel[i]
	if m != REST:
		_play_note(float(m), step * 0.9, -10.0)
	if i % 2 == 0:
		_play_note(float(bass[(i >> 1) % bass.size()]) - 12.0, step * 1.8, -8.0)
	seq_step += 1


func _in_title() -> bool:
	return state == State.TITLE or state == State.MENU


var was_in_title := false
var title_stream: AudioStreamWAV = null


func _start_title_music() -> void:
	seq_step = 0
	seq_acc = 0.0
	_stop_seq()
	if fart_sample == null and music_enabled:
		if title_stream == null:
			title_stream = _make_music(TITLE_SONG)
		music.stream = title_stream
		music.play()


func _song_stream(i: int) -> AudioStreamWAV:
	if not song_streams.has(i):
		song_streams[i] = _make_music(SONGS[i])
	return song_streams[i]


func set_song(i: int) -> void:
	i = posmod(i, SONGS.size() + 1)   # the last slot is OFF
	var was_enabled := music_enabled
	music_enabled = i < SONGS.size()
	if _in_title():
		# On the title / setup screens the picked song only matters for the game: the title
		# theme keeps playing without a restart. (Only OFF / back ON touches it.)
		if music_enabled:
			cur_song = i
			if not was_enabled:
				_start_title_music()
		else:
			music.stop()
			_stop_seq()
		return
	seq_step = 0
	seq_acc = 0.0
	_stop_seq()
	if not music_enabled:
		music.stop()
		return
	cur_song = i
	if fart_sample == null:
		if _in_title():
			_start_title_music()
		else:
			music.stream = _song_stream(cur_song)
			if state == State.PLAYING or state == State.CLEARING or state == State.PAUSED:
				music.play()


func _stop_seq() -> void:
	for k in seq_pool.size():
		seq_pool[k].stop()
		seq_stop[k] = 0.0


func play_sfx(sfx_name: String, pitch: float = 1.0) -> void:
	var p: AudioStreamPlayer = players.get(sfx_name)
	if p:
		p.pitch_scale = pitch
		p.play()


# ------------------------------------------------------------------ game logic

func piece_cells(type: int, rot: int) -> Array[Vector2i]:
	var size: int = SIZES[type]
	var out: Array[Vector2i] = []
	for c in SHAPES[type]:
		var p: Vector2i = c
		for i in rot % int(STATES[type]):
			p = Vector2i(size - 1 - p.y, p.x)
		out.append(p)
	return out


# Game Boy randomizer: roll once; if the roll ORed with the preview and the piece that just
# locked equals the locked piece (it would repeat too much), roll one more time.
func _gb_roll(locked: int, current: int) -> int:
	var r := randi() % 7
	if locked >= 0:
		var lv: int = GB_VALUE[locked]
		if (int(GB_VALUE[r]) | int(GB_VALUE[current]) | lv) == lv:
			r = randi() % 7
	return r


func fits(type: int, rot: int, pos: Vector2i) -> bool:
	for c in piece_cells(type, rot):
		var x := pos.x + c.x
		var y := pos.y + c.y
		if x < 0 or x >= COLS or y >= ROWS:
			return false
		if y >= 0 and board[y * COLS + x] != -1:
			return false
	return true


func new_game() -> void:
	board.fill(-1)
	ids.fill(-1)
	meld_id = -1
	soft_blocked = false
	cur_type = -1
	score = 0
	level = start_level
	lines = 0
	won = false
	clog_progress = 0.0
	music_speed = 1.0
	clear_rows.clear()
	popup_timer = 0.0
	next_type = randi() % 7
	state = State.PLAYING
	seq_step = 0
	seq_acc = 0.0
	if fart_sample == null and music_enabled:
		music.stream = _song_stream(cur_song)
		music.play()
	if game_type == 1 and start_height > 0:
		_add_garbage(start_height * 2)
	spawn_next()


func _add_garbage(rows_n: int) -> void:
	for r in rows_n:
		var y := ROWS - 1 - r
		var hole := randi() % COLS
		for x in COLS:
			if x == hole or randf() < 0.45:
				continue
			piece_serial += 1
			board[y * COLS + x] = randi() % 7
			ids[y * COLS + x] = piece_serial


func stack_height() -> int:
	for y in ROWS:
		for x in COLS:
			if board[y * COLS + x] != -1:
				return ROWS - y
	return 0


func spawn_piece(type: int) -> void:
	cur_type = type
	cur_rot = 0
	var top := 99
	for c in piece_cells(type, 0):
		top = mini(top, c.y)
	cur_pos = Vector2i((COLS - int(SIZES[type])) >> 1, -top)   # highest block on the top row
	fall_timer = 0.0
	if not fits(cur_type, cur_rot, cur_pos):
		game_over()
	else:
		play_sfx("fart", randf_range(1.6, 2.0))   # every new piece announces itself, high and squeaky
		_spawn_puffs()


func _spawn_puffs() -> void:
	for c in piece_cells(cur_type, cur_rot):
		var centre := BOARD_POS + (Vector2(cur_pos + c) + Vector2(0.5, 0.5)) * CELL
		for k in 3:
			var dir := Vector2.from_angle(randf() * TAU)
			puffs.append({
				"pos": centre + dir * randf_range(8.0, 20.0),
				"vel": dir * randf_range(25.0, 70.0) + Vector2(0, -12),
				"age": 0.0,
				"life": randf_range(0.45, 0.8),
				"size": randf_range(7.0, 13.0),
			})


func spawn_next() -> void:
	var locked := cur_type
	spawn_piece(next_type)
	next_type = _gb_roll(locked, cur_type)


func _defeat_sound() -> void:
	shake = 10.0
	clog_progress = 0.0
	if fart_sample == null:
		play_sfx("lose")   # one long, sad, squeaky fart
		return
	# with your own sample: three farts sinking in pitch, like a sad trombone
	for i in 3:
		_play_note(-3.0 * i, 2.0, -3.0)
		await get_tree().create_timer(0.3).timeout
		if state != State.OVER:
			return


func win() -> void:
	state = State.OVER
	won = true
	win_t = 0.0
	launched = false
	high = maxi(high, score)
	_save_high()
	music.stop()
	_stop_seq()
	play_sfx("flush")


func game_over() -> void:
	state = State.OVER
	won = false
	high = maxi(high, score)
	_save_high()
	music.stop()
	_stop_seq()
	_defeat_sound()


func gravity_interval() -> float:
	var idx := clampi(level - 1, 0, GB_FRAMES.size() - 1)
	return float(GB_FRAMES[idx]) / GB_FPS


func try_move(d: Vector2i) -> bool:
	if fits(cur_type, cur_rot, cur_pos + d):
		cur_pos += d
		return true
	return false


# Nintendo rotation: turn in place or not at all. No wall kicks, no floor kicks.
func try_rotate(dir: int) -> void:
	var nr := (cur_rot + dir + 4) % 4
	if fits(cur_type, nr, cur_pos):
		cur_rot = nr
		return
	# The L is the one piece allowed to kick sideways, so it can still turn against a wall or the stack
	if cur_type == 6:
		for dx in [1, -1]:
			var p := cur_pos + Vector2i(dx, 0)
			if fits(cur_type, nr, p):
				cur_rot = nr
				cur_pos = p
				return


func ghost_pos() -> Vector2i:
	var p := cur_pos
	while fits(cur_type, cur_rot, p + Vector2i.DOWN):
		p += Vector2i.DOWN
	return p


func lock_piece() -> void:
	piece_serial += 1
	meld_id = piece_serial
	meld_t = 0.12
	for c in piece_cells(cur_type, cur_rot):
		var x := cur_pos.x + c.x
		var y := cur_pos.y + c.y
		if y < 0:
			game_over()
			return
		board[y * COLS + x] = cur_type
		ids[y * COLS + x] = piece_serial
	soft_blocked = true   # down must be released and pressed again for the next piece
	play_sfx("plop", randf_range(0.9, 1.15))
	clear_rows.clear()
	for y in ROWS:
		var full := true
		for x in COLS:
			if board[y * COLS + x] == -1:
				full = false
				break
		if full:
			clear_rows.append(y)
	if clear_rows.is_empty():
		spawn_next()
	else:
		state = State.CLEARING
		clear_timer = CLEAR_TIME
		popup_text = CLEAR_NAMES[clear_rows.size()]
		popup_timer = 1.2
		play_sfx("flush")
		if clear_rows.size() == 4:
			play_sfx("fart", 1.3)
			shake = 10.0


func finish_clear() -> void:
	var n := clear_rows.size()
	var kept: Array[int] = []
	var kept_ids: Array[int] = []
	for y in ROWS:
		if clear_rows.has(y):
			continue
		for x in COLS:
			kept.append(board[y * COLS + x])
			kept_ids.append(ids[y * COLS + x])
	var nb: Array[int] = []
	nb.resize(n * COLS)
	nb.fill(-1)
	nb.append_array(kept)
	board = nb
	var ni: Array[int] = []
	ni.resize(n * COLS)
	ni.fill(-1)
	ni.append_array(kept_ids)
	ids = ni
	soft_blocked = true   # holding down through a clear must not carry into the next piece
	score += int(CLEAR_POINTS[n]) * level
	lines += n
	var old_level := level
	level = start_level + int(floor(lines / 10.0))
	if level > old_level:
		play_sfx("levelup")
	clear_rows.clear()
	high = maxi(high, score)
	if game_type == 1 and lines >= GOAL:
		win()
		return
	state = State.PLAYING
	spawn_next()


# ------------------------------------------------------------------ input / update

func _start_or_restart() -> void:
	# On the win / lose screens the button only works once its "press ..." prompt is showing,
	# so mashing buttons can't skip the rocket or the clog by accident.
	if state == State.OVER and ((won and win_t < WIN_PROMPT_AT) or (not won and clog_progress < float(ROWS))):
		return
	if state == State.TITLE or state == State.OVER:
		state = State.MENU
	elif state == State.MENU:
		new_game()


func _music_index() -> int:
	return cur_song if music_enabled else SONGS.size()


func menu_move(d: int) -> void:
	menu_row = posmod(menu_row + d, 6)
	if menu_row == 2 and game_type == 0:   # HEIGHT only applies to B-type
		menu_row = posmod(menu_row + d, 6)


func menu_change(d: int) -> void:
	match menu_row:
		0:
			game_type = posmod(game_type + d, 2)
		1:
			start_level = posmod(start_level - 1 + d, 10) + 1
		2:
			if game_type == 1:
				start_height = posmod(start_height + d, 6)
		3:
			set_song(_music_index() + d)
		4:
			instant_drop = not instant_drop
			_save_high()   # remember the setting


func _menu_key(k: int) -> bool:
	match k:
		KEY_UP, KEY_W:
			menu_move(-1)
		KEY_DOWN, KEY_S:
			menu_move(1)
		KEY_LEFT, KEY_A:
			menu_change(-1)
		KEY_RIGHT, KEY_D:
			menu_change(1)
		KEY_SPACE:
			new_game()
		KEY_ESCAPE:
			state = State.TITLE
		_:
			return false
	return true


func _toggle_pause() -> void:
	if state == State.PLAYING:
		state = State.PAUSED
		play_sfx("pause")
		pause_row = 0          # RESUME is the default
		pause_confirm = false
	elif state == State.PAUSED:
		if pause_confirm:      # backing out of "are you sure?"
			pause_confirm = false
			pause_row = 1
		else:
			state = State.PLAYING
			play_sfx("resume")


func pause_move(d: int) -> void:
	pause_row = posmod(pause_row + d, 2)


func _pause_select() -> void:
	if not pause_confirm:
		if pause_row == 0:
			state = State.PLAYING
			play_sfx("resume")
		else:
			pause_confirm = true
			pause_row = 0      # NO is the default answer
	elif pause_row == 1:
		quit_to_title()
	else:
		pause_confirm = false
		pause_row = 1


func quit_to_title() -> void:
	high = maxi(high, score)
	_save_high()
	music.stop()
	_stop_seq()
	pause_confirm = false
	pause_row = 0
	board.fill(-1)
	ids.fill(-1)
	cur_type = -1
	meld_t = 0.0
	clog_progress = 0.0
	clear_rows.clear()
	popup_timer = 0.0
	puffs.clear()
	score = 0
	lines = 0
	level = start_level
	won = false
	state = State.TITLE


func _pause_key(k: int) -> bool:
	match k:
		KEY_UP, KEY_W, KEY_LEFT, KEY_A:
			pause_move(-1)
		KEY_DOWN, KEY_S, KEY_RIGHT, KEY_D:
			pause_move(1)
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			_pause_select()
		_:
			return false
	return true


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed:
		_use_pad(event.device)
		_pad_button(event.button_index)
		return
	if event is InputEventJoypadMotion and absf(event.axis_value) > 0.6:
		_use_pad(event.device)
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	using_pad = false   # the keyboard took over: show key prompts again
	var k: int = event.keycode
	if k == KEY_NONE:
		k = event.physical_keycode
	if k == KEY_F9 and state != State.OVER:   # test key: jump straight to the win screen and the rocket
		win()
		return
	if k == KEY_F11 or (k == KEY_ENTER and event.alt_pressed):
		_toggle_fullscreen()
		return
	if state == State.MENU and _menu_key(k):
		return
	if state == State.PAUSED and _pause_key(k):
		return
	match k:
		KEY_M:
			muted = not muted
			AudioServer.set_bus_mute(0, muted)
		KEY_ENTER, KEY_KP_ENTER:
			_start_or_restart()
		KEY_P, KEY_ESCAPE:
			_toggle_pause()
		KEY_1, KEY_2, KEY_3, KEY_4:
			set_song(k - KEY_1)
		_:
			if state == State.PLAYING:
				_play_key(k)


# ---- button prompts: they follow whichever device was used last, and the kind of pad connected
var using_pad := false
var pad_kind := "xbox"   # xbox / ps / switch

func _use_pad(device: int) -> void:
	using_pad = true
	var n := Input.get_joy_name(device).to_lower()
	if "playstation" in n or "dualsense" in n or "dualshock" in n or "ps5" in n or "ps4" in n or "ps3" in n or "sony" in n:
		pad_kind = "ps"
	elif "nintendo" in n or "switch" in n or "joy-con" in n or "pro controller" in n:
		pad_kind = "switch"
	else:
		pad_kind = "xbox"   # Xbox pads and anything unknown


# Prompt text for an action. Godot's "A" is the bottom face button, "B" the right one.
func _p(action: String) -> String:
	if not using_pad:
		match action:
			"confirm": return "ENTER"
			"back": return "ESC"
			"pause": return "P"
			"rot": return "X"
			"rotb": return "Z"
			"music": return "1 - 4"
		return action
	var names := {
		"xbox": {"confirm": "A", "back": "B", "rot": "A", "rotb": "B", "pause": "Menu", "music": "Select"},
		"ps": {"confirm": "Cross", "back": "Circle", "rot": "Cross", "rotb": "Circle", "pause": "Options", "music": "Select"},
		"switch": {"confirm": "B", "back": "A", "rot": "B", "rotb": "A", "pause": "+", "music": "Select"},
	}
	return str(names[pad_kind].get(action, action))


func _pad_name() -> String:
	return {"xbox": "Xbox", "ps": "PlayStation", "switch": "Switch"}[pad_kind]


func _on_joy_changed(device: int, connected: bool) -> void:
	if connected:
		_use_pad(device)
	elif Input.get_connected_joypads().is_empty():
		using_pad = false


# Controller: D-pad / left stick move + soft drop, A rotate, B rotate back,
# Start pause / start, Back = next song. D-pad Up / Down never rotate.
func _pad_button(b: int) -> void:
	match b:
		JOY_BUTTON_START:
			if state == State.TITLE or state == State.OVER or state == State.MENU:
				_start_or_restart()
			else:
				_toggle_pause()
		JOY_BUTTON_BACK:
			set_song(_music_index() + 1)
		JOY_BUTTON_A:
			if state == State.TITLE or state == State.OVER or state == State.MENU:
				_start_or_restart()
			elif state == State.PLAYING:
				try_rotate(-1)
			elif state == State.PAUSED:
				_pause_select()
		JOY_BUTTON_B:
			if state == State.PLAYING:
				try_rotate(1)
			elif state == State.MENU:
				state = State.TITLE
			elif state == State.PAUSED:
				_toggle_pause()
		JOY_BUTTON_DPAD_UP:
			if state == State.PLAYING and instant_drop:
				hard_drop()
			elif state == State.MENU:
				menu_move(-1)
			elif state == State.PAUSED:
				pause_move(-1)
		JOY_BUTTON_DPAD_DOWN:
			if state == State.MENU:
				menu_move(1)
			elif state == State.PAUSED:
				pause_move(1)
		JOY_BUTTON_DPAD_LEFT:
			if state == State.MENU:
				menu_change(-1)
			elif state == State.PAUSED:
				pause_move(-1)
		JOY_BUTTON_DPAD_RIGHT:
			if state == State.MENU:
				menu_change(1)
			elif state == State.PAUSED:
				pause_move(1)


func _pad_held(btn: int) -> bool:
	for d in Input.get_connected_joypads():
		if Input.is_joy_button_pressed(d, btn):
			return true
	return false


func _pad_stick() -> Vector2:
	var best := Vector2.ZERO
	for d in Input.get_connected_joypads():
		var v := Vector2(Input.get_joy_axis(d, JOY_AXIS_LEFT_X), Input.get_joy_axis(d, JOY_AXIS_LEFT_Y))
		if v.length() > best.length():
			best = v
	return best


func hard_drop() -> void:
	if state != State.PLAYING or cur_type < 0:
		return
	while fits(cur_type, cur_rot, cur_pos + Vector2i.DOWN):
		cur_pos += Vector2i.DOWN
	fall_timer = 0.0
	shake = maxf(shake, 3.0)
	lock_piece()


func _play_key(k: int) -> void:
	match k:
		KEY_UP, KEY_W:
			if instant_drop:
				hard_drop()
		KEY_X:
			try_rotate(-1)
		KEY_Z, KEY_CTRL:
			try_rotate(1)


func _process(delta: float) -> void:
	delta = minf(delta, 0.05)   # a long hitch must never fast-forward gravity
	time += delta
	shake = move_toward(shake, 0.0, delta * 30.0)
	popup_timer = maxf(0.0, popup_timer - delta)
	meld_t = maxf(0.0, meld_t - delta)
	for i in range(puffs.size() - 1, -1, -1):
		var pf: Dictionary = puffs[i]
		pf["age"] = float(pf["age"]) + delta
		pf["pos"] = (pf["pos"] as Vector2) + (pf["vel"] as Vector2) * delta
		pf["vel"] = (pf["vel"] as Vector2) * (1.0 - 2.5 * delta)
		if float(pf["age"]) >= float(pf["life"]):
			puffs.remove_at(i)
	if state == State.OVER and won:
		win_t += delta
		if win_t >= LAUNCH_AT and not launched:
			launched = true
			shake = 8.0
			play_sfx("launch")
		if win_t >= LAUNCH_AT - 0.6 and _rocket_top() > BOARD_POS.y - 260.0:
			var nozzle := Vector2(BOARD_POS.x + BOARD_SIZE.x * 0.5, _rocket_top() + 5.0 * CELL + 12.0)
			for k in 2:
				var dir := Vector2(randf_range(-0.5, 0.5), 1.0).normalized()
				puffs.append({"pos": nozzle + Vector2(randf_range(-14.0, 14.0), 0.0), "vel": dir * randf_range(90.0, 220.0), "age": 0.0, "life": randf_range(0.5, 1.1), "size": randf_range(12.0, 22.0)})
	if state == State.OVER and not won:
		clog_progress = minf(float(ROWS) + 4.0, clog_progress + delta * 14.0)
	music.stream_paused = (state == State.PAUSED)
	var target_speed := 1.0
	if (state == State.PLAYING or state == State.CLEARING) and stack_height() > int(ROWS * 0.6):
		target_speed = 1.3
	music_speed = move_toward(music_speed, target_speed, delta * 1.5)
	music.pitch_scale = music_speed   # built-in synth tune speeds up (and rises) like the Game Boy
	var titleish := _in_title()
	if titleish != was_in_title:
		was_in_title = titleish
		if titleish:
			_start_title_music()
		else:
			_stop_seq()
			music.stop()
	if fart_sample != null and music_enabled:
		for k in seq_pool.size():
			if seq_stop[k] > 0.0 and time >= seq_stop[k]:
				seq_pool[k].stop()
				seq_stop[k] = 0.0
		if state == State.PLAYING or state == State.CLEARING or titleish:
			seq_acc += delta
			var step: float = float((TITLE_SONG if titleish else SONGS[cur_song])["step"]) / music_speed
			while seq_acc >= step:
				seq_acc -= step
				_seq_tick()
	match state:
		State.PLAYING:
			_update_play(delta)
		State.CLEARING:
			clear_timer -= delta
			if clear_timer <= 0.0:
				finish_clear()
	queue_redraw()


func _update_play(delta: float) -> void:
	var stick := _pad_stick()
	var dir := 0
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A) or _pad_held(JOY_BUTTON_DPAD_LEFT) or stick.x < -0.5:
		dir -= 1
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D) or _pad_held(JOY_BUTTON_DPAD_RIGHT) or stick.x > 0.5:
		dir += 1
	if dir != das_dir:
		das_dir = dir
		das_timer = 0.0
		if dir != 0:
			try_move(Vector2i(dir, 0))
	elif dir != 0:
		das_timer += delta
		while das_timer >= DAS_DELAY:
			das_timer -= ARR
			try_move(Vector2i(dir, 0))

	var down_held := Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S) or _pad_held(JOY_BUTTON_DPAD_DOWN)
	if not down_held:
		soft_blocked = false   # released: soft drop works again on the next press
	var soft := down_held and not soft_blocked
	if soft:
		# Soft drop has its own clock: exactly one row per tick, never a burst. (The old code
		# reused the gravity timer, so pressing Down mid-fall paid off all the stored time at
		# once and the piece teleported to the bottom.)
		fall_timer = 0.0
		soft_timer += delta
		if soft_timer >= SOFT_DROP_INTERVAL:
			soft_timer = 0.0
			if fits(cur_type, cur_rot, cur_pos + Vector2i.DOWN):
				cur_pos += Vector2i.DOWN
				score += 1
			else:
				lock_piece()
				return
	else:
		soft_timer = SOFT_DROP_INTERVAL   # so the first row steps down right when Down is pressed
		fall_timer += delta
		var interval := gravity_interval()
		while fall_timer >= interval:
			fall_timer -= interval
			if fits(cur_type, cur_rot, cur_pos + Vector2i.DOWN):
				cur_pos += Vector2i.DOWN
			else:
				lock_piece()   # no lock delay: the first tick that can't move it down locks it
				return


# ------------------------------------------------------------------ drawing

func _box(r: Rect2, fill: Color, border: Color, _radius: int, bw: int = 3, _shadow: int = 0) -> void:
	# retro dialog: black outline, bright rim, then the fill (square corners, no blur)
	var t := float(maxi(2, bw))
	draw_rect(Rect2(r.position + Vector2(t, t) * 0.5, r.size), Color(0, 0, 0, 0.35))   # hard drop shadow
	draw_rect(r, Color.BLACK)
	draw_rect(r.grow(-t * 0.5), border)
	draw_rect(r.grow(-t * 1.5), Color.BLACK)
	draw_rect(r.grow(-t * 1.5 - 1.0), fill)


const FONT_CHARS := "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 .,!?-+/():%<>'=#_"
const FONT_BITS := [
	".###.#...##...#######...##...##...#",
	"####.#...##...#####.#...##...#####.",
	".###.#...##....#....#....#...#.###.",
	"####.#...##...##...##...##...#####.",
	"######....#....####.#....#....#####",
	"######....#....####.#....#....#....",
	".###.#...##....#.####...##...#.###.",
	"#...##...##...#######...##...##...#",
	".###...#....#....#....#....#...###.",
	"....#....#....#....##...##...#.###.",
	"#...##..#.#.#..##...#.#..#..#.#...#",
	"#....#....#....#....#....#....#####",
	"#...###.###.#.##.#.##...##...##...#",
	"#...###..##.#.##..###...##...##...#",
	".###.#...##...##...##...##...#.###.",
	"####.#...##...#####.#....#....#....",
	".###.#...##...##...##.#.##..#..##.#",
	"####.#...##...#####.#.#..#..#.#...#",
	".#####....#.....###.....#....#####.",
	"#####..#....#....#....#....#....#..",
	"#...##...##...##...##...##...#.###.",
	"#...##...##...##...##...#.#.#...#..",
	"#...##...##...##.#.##.#.###.###...#",
	"#...##...#.#.#...#...#.#.#...##...#",
	"#...##...#.#.#...#....#....#....#..",
	"#####....#...#...#...#...#....#####",
	".###.#...##..###.#.###..##...#.###.",
	"..#...##....#....#....#....#...###.",
	".###.#...#....#...#...#...#...#####",
	"####.....#....#.###.....#....#####.",
	"...#...##..#.#.#..#.#####...#....#.",
	"######....####.....#....##...#.###.",
	".###.#....#....####.#...##...#.###.",
	"#####....#...#...#...#....#....#...",
	".###.#...##...#.###.#...##...#.###.",
	".###.#...##...#.####....#....#.###.",
	"...................................",
	"..........................##...##..",
	".....................##...##...#...",
	"..#....#....#....#....#.........#..",
	".###.#...#....#...#...#.........#..",
	"................###................",
	".......#....#..#####..#....#.......",
	"....#....#...#...#...#...#....#....",
	"...#...#...#....#....#.....#.....#.",
	".#.....#.....#....#....#...#...#...",
	"......##...##........##...##.......",
	"##..###..#...#...#...#...#..###..##",
	"...#...#...#...#.....#.....#.....#.",
	".#.....#.....#.....#...#...#...#...",
	"..#....#...#.......................",
	"..........#####.....#####..........",
	".#.#.#####.#.#..#.#.#####.#.#......",
	"..............................#####",
]
var font_tex: Texture2D = null


# Built-in 5x7 bitmap font (no font file needed): every glyph is drawn from one tiny atlas,
# scaled with hard pixels. Text is upper-cased, like the old Nintendo games.
func _build_font() -> void:
	var img := Image.create(5 * FONT_CHARS.length(), 7, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0))
	for i in FONT_CHARS.length():
		var bits: String = FONT_BITS[i]
		for k in 35:
			if bits[k] == "#":
				img.set_pixel(i * 5 + k % 5, k / 5, Color.WHITE)
	font_tex = ImageTexture.create_from_image(img)


func _font_width(s: String, scale: float) -> float:
	return maxf(0.0, s.length() * 6.0 * scale - scale)


func _font_draw(s: String, pos: Vector2, scale: float, col: Color) -> void:
	var x := pos.x
	for ch in s:
		var i := FONT_CHARS.find(ch)
		if i >= 0 and ch != " ":
			draw_texture_rect_region(font_tex, Rect2(Vector2(x, pos.y - 7.0 * scale), Vector2(5.0 * scale, 7.0 * scale)), Rect2(i * 5, 0, 5, 7), col)
		x += 6.0 * scale


func _text_a(s: String, pos: Vector2, size: int, col: Color, w: float, align: HorizontalAlignment, outline: int = 0, ocol: Color = Color.BLACK) -> void:
	s = s.to_upper()
	var sc := maxf(size * 0.1, 1.7)
	var tw := _font_width(s, sc)
	if w > 0.0 and tw > w:      # long lines shrink to fit instead of spilling out
		sc *= w / tw
		tw = w
	var x := pos.x
	if align == HORIZONTAL_ALIGNMENT_CENTER:
		x += (w - tw) * 0.5
	elif align == HORIZONTAL_ALIGNMENT_RIGHT:
		x += w - tw
	x = roundf(x)
	var y := roundf(pos.y)
	if outline > 0:
		var o := maxf(1.0, roundf(sc * 0.9))
		for d in [Vector2(-o, 0), Vector2(o, 0), Vector2(0, -o), Vector2(0, o), Vector2(-o, -o), Vector2(o, -o), Vector2(-o, o), Vector2(o, o)]:
			_font_draw(s, Vector2(x, y) + d, sc, ocol)
	if outline == 0:   # a hard 1-2 px shadow keeps small text readable on any background
		var so := maxf(1.0, roundf(sc * 0.6))
		_font_draw(s, Vector2(x, y) + Vector2(so, so), sc, Color(0, 0, 0, col.a * 0.85))
	_font_draw(s, Vector2(x, y), sc, col)


func _text(s: String, pos: Vector2, size: int, col: Color, w: float = PANEL.size.x, outline: int = 0, ocol: Color = Color.BLACK) -> void:
	_text_a(s, pos, size, col, w, HORIZONTAL_ALIGNMENT_CENTER, outline, ocol)


func _draw() -> void:
	# The window can be wider/taller than the 720x840 stage (fullscreen): the wall fills the
	# whole screen and the stage is centred on it.
	var screen := get_viewport_rect().size
	var stage := ((screen - VIEW_SIZE) * 0.5).floor()
	draw_set_transform(Vector2.ZERO)
	_draw_backdrop(screen, stage)
	if state == State.MENU:
		draw_set_transform(stage)
		_draw_menu()
		if turd_mode:
			_draw_butt_layer()   # hangs over the top of the title box too
		return
	var off := stage
	if shake > 0.1:
		off += Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake
	draw_set_transform(off)
	_draw_fixtures()
	_draw_well()
	_draw_panel()
	_draw_overlays()
	if turd_mode:
		_draw_butt_layer()   # on top of everything in the well: pieces, dimming, pause and title boxes
	for pf in puffs:
		var u := float(pf["age"]) / float(pf["life"])
		var px3 := roundf(float(pf["size"]) * (0.7 + 0.8 * u) / 3.0) * 3.0
		var pp: Vector2 = ((pf["pos"] as Vector2) / 3.0).round() * 3.0
		var pa := 1.0 if u < 0.7 else 0.55
		draw_rect(Rect2(pp - Vector2(px3, px3) * 0.5, Vector2(px3, px3)), Color(0.36, 0.56, 0.2, pa))
		draw_rect(Rect2(pp - Vector2(px3, px3) * 0.5, Vector2(px3, px3) * 0.5), Color(0.66, 0.84, 0.32, pa))


func _draw_menu() -> void:
	var tcol := Color("e9d8bd")
	var scol := Color("7f93a0")
	var gold := Color("ffe9a8")
	var vw := VIEW_SIZE.x
	_box(Rect2(20, 50, 680, 740), Color(0.05, 0.07, 0.09, 0.93), Color("55666f"), 26, 4, 14)
	_text("TURDTRIS", Vector2(0, 146), 68, Color("c68a52"), vw, 10, Color("3a2212"))
	_text("CALL OF DOODY", Vector2(0, 186), 26, Color("ffe9a8"), vw, 4, Color("3a2212"))
	_text("- GAME SETUP -", Vector2(0, 218), 16, scol, vw)
	_text("HIGH SCORE  %d" % high, Vector2(0, 246), 16, tcol, vw)
	var rows := [
		["GAME TYPE", "A-TYPE" if game_type == 0 else "B-TYPE"],
		["LEVEL", str(start_level)],
		["HEIGHT", str(start_height)],
		["MUSIC", str(SONGS[cur_song]["name"]) if music_enabled else "OFF"],
		["INSTANT PLOP", "ON" if instant_drop else "OFF"],
		["START", ""],
	]
	for i in rows.size():
		var y := 304.0 + i * 66.0
		var sel := i == menu_row
		var dimmed := i == 2 and game_type == 0
		var col := gold if sel else tcol
		if dimmed:
			col = Color(0.35, 0.4, 0.45)
		if sel:
			draw_rect(Rect2(110, y - 40, 500, 52), Color(1, 1, 1, 0.06 + 0.04 * sin(time * 6.0)))
			draw_block(Vector2(120, y - 34), 36.0, 0, 0)
		_text_a(str(rows[i][0]), Vector2(175, y), 28, col, 300.0, HORIZONTAL_ALIGNMENT_LEFT)
		var val := str(rows[i][1])
		if i == 5:
			if sel:
				val = _p("confirm").to_upper()
		elif sel and not dimmed:
			val = "<  %s  >" % val
		elif dimmed:
			val = "-"
		_text_a(val, Vector2(175, y), 28, col, 415.0, HORIZONTAL_ALIGNMENT_RIGHT)
	var tips := [
		"A-TYPE plays until you clog the toilet. B-TYPE: clear 25 lines.",
		"Starting level. Higher levels drop faster.",
		"B-TYPE only: starting garbage, HEIGHT x 2 rows.",
		"Songs 1 - 4 or OFF. The 1 - 4 keys also work during the game.",
		"ON: Up%s plops the piece instantly. OFF: classic Game Boy feel." % (" (D-pad)" if using_pad else ""),
		"Press %s to start." % _p("confirm"),
	]
	_text(tips[menu_row], Vector2(40, 722), 15, scol, 640.0)
	_text(("D-PAD select / change    %s start    %s back" if using_pad else "UP / DOWN select    LEFT / RIGHT change    %s start    %s back") % [_p("confirm"), _p("back")], Vector2(40, 752), 13, scol, 640.0)


func _draw_wall(screen: Vector2, stage: Vector2) -> void:
	# Dark bathroom wall tiles, laid out on the stage's 60px grid so they line up with background.png
	draw_rect(Rect2(Vector2.ZERO, screen), Color("07090b"))
	var t := 60.0
	var tx0 := int(floor(-stage.x / t))
	var tx1 := int(ceil((screen.x - stage.x) / t))
	var ty0 := int(floor(-stage.y / t))
	var ty1 := int(ceil((screen.y - stage.y) / t))
	for ty in range(ty0, ty1):
		for tx in range(tx0, tx1):
			var j := float(posmod((tx * 31 + ty * 17) * 7, 5)) * 0.006
			var o := stage + Vector2(tx, ty) * t
			draw_rect(Rect2(o.x + 1.5, o.y + 1.5, t - 3.0, t - 3.0), Color(0.09 + j, 0.12 + j, 0.145 + j))
			draw_rect(Rect2(o.x + 4.0, o.y + 4.0, t - 14.0, 3.0), Color(1, 1, 1, 0.05))


func _draw_backdrop(screen: Vector2, stage: Vector2) -> void:
	if not turd_mode:
		draw_rect(Rect2(Vector2.ZERO, screen), Color("14161f"))
		return
	_draw_wall(screen, stage)
	if bg_tex != null:
		draw_texture_rect(bg_tex, Rect2(stage, VIEW_SIZE), false)


func _draw_fixtures() -> void:
	var bowl := Rect2(BOARD_POS - Vector2(22, 22), BOARD_SIZE + Vector2(44, 44))
	if not turd_mode:
		_box(bowl, Color("232638"), Color("3a3f5c"), 8, 3)
		_box(PANEL, Color("1b1d2b"), Color("3a3f5c"), 16, 3)
		return
	if bg_tex != null:
		return   # a custom background.png draws the whole toilet itself
	var porcelain := Color("e6edf1")
	var edge := Color("8da0ab")
	# floor shadow and the flared pedestal the bowl sits on, with bolt caps
	draw_colored_polygon(_ellipse_poly(Vector2(220, 838), 150.0, 7.0), Color(0, 0, 0, 0.35))
	var foot := PackedVector2Array([Vector2(120, 780), Vector2(320, 780), Vector2(312, 812), Vector2(350, 832),
		Vector2(350, 840), Vector2(90, 840), Vector2(90, 832), Vector2(128, 812)])
	draw_colored_polygon(foot, Color("c9d4db"))
	var foot_line := foot.duplicate()
	foot_line.append(foot[0])
	draw_polyline(foot_line, edge, 3.0)
	for bx in [112.0, 328.0]:
		draw_circle(Vector2(bx, 828), 7.0, edge)
		draw_circle(Vector2(bx, 828), 5.0, Color("eef3f6"))
	_box(Rect2(408, 700, 26, 40), Color("a9b8c1"), edge, 6, 2)             # pipe from the tank to the bowl
	# water supply pipe and shut-off valve under the tank
	_box(Rect2(636, 800, 16, 24), Color("b9c6cd"), edge, 4, 2)
	_box(Rect2(636, 814, 76, 14), Color("b9c6cd"), edge, 5, 2)
	draw_circle(Vector2(676, 821), 8.0, Color("7d8b95"))
	draw_circle(Vector2(676, 821), 5.0, Color("c9d3d9"))
	_box(PANEL, porcelain, edge, 28, 4, 12)                                # porcelain tank frame
	_box(Rect2(446, 72, 238, 712), Color("0d1318"), Color("6d818c"), 18, 3) # inset panel for the stats
	_box(Rect2(PANEL.position.x - 12.0, 22, PANEL.size.x + 24.0, 34), Color("f1f5f8"), edge, 14, 4, 6)   # lid
	# dual-flush buttons on the lid
	for bt in [[Vector2(535, 39), 12.0], [Vector2(594, 39), 8.0]]:
		draw_circle(bt[0], float(bt[1]) + 2.0, Color("7d8b95"))
		draw_circle(bt[0], float(bt[1]), Color("c9d3d9"))
		draw_circle((bt[0] as Vector2) + Vector2(-2, -2), float(bt[1]) * 0.4, Color("eef3f6"))
	for bx in [440.0, 690.0]:                                               # tank lid bolts
		draw_circle(Vector2(bx, 39), 6.0, Color("7d8b95"))
		draw_circle(Vector2(bx, 39), 4.0, Color("c9d3d9"))
		draw_line(Vector2(bx - 3, 39), Vector2(bx + 3, 39), Color("7d8b95"), 1.5)
	for bx in [470.0, 650.0]:                                               # tank-to-bowl bolts on the tank face
		draw_circle(Vector2(bx, 60), 4.0, Color("8da0ab"))
		draw_circle(Vector2(bx, 60), 2.5, Color("eef3f6"))
	_box(bowl, porcelain, edge, 80, 4, 14)                                 # porcelain bowl
	var bp := _round_poly(bowl, 80.0, 80.0, 14)                            # curved-shading toward the bottom
	var bcols := PackedColorArray()
	for p in bp:
		var t := clampf((p.y - bowl.position.y) / bowl.size.y, 0.0, 1.0)
		bcols.append(Color(0.25, 0.35, 0.45, 0.0).lerp(Color(0.25, 0.35, 0.45, 0.34), t * t))
	draw_polygon(bp, bcols)
	_box(Rect2(28, 48, 384, 744), Color("f4f7f9"), Color("b6c4cc"), 70, 3) # toilet seat
	_box(Rect2(110, 26, 36, 16), Color("b8c4cb"), Color("7d8b95"), 4, 2)   # seat hinges
	_box(Rect2(294, 26, 36, 16), Color("b8c4cb"), Color("7d8b95"), 4, 2)
	for bm in [Vector2(62, 786), Vector2(378, 786)]:                       # rubber seat bumpers
		draw_circle(bm, 5.0, Color("5a6770"))
	for r in [Rect2(24, 150, 3, 270), Rect2(437, 110, 3, 220), Rect2(33, 450, 2, 190)]:   # porcelain gloss
		draw_rect(r, Color(1, 1, 1, 0.65))


func _draw_well() -> void:
	var well := Rect2(BOARD_POS, BOARD_SIZE)
	if turd_mode:
		if bg_tex == null:
			_draw_bowl_interior(well)
	else:
		_box(well, Color("0e0f18"), Color("3a3f5c"), 4, 2)
	var gc := Color(0.6, 0.75, 0.85, 0.07) if turd_mode else Color(1, 1, 1, 0.06)
	for x in range(1, COLS):
		draw_line(BOARD_POS + Vector2(x * CELL, CELL), BOARD_POS + Vector2(x * CELL, BOARD_SIZE.y - 4), gc)
	for y in range(1, ROWS):
		draw_line(BOARD_POS + Vector2(4, y * CELL), BOARD_POS + Vector2(BOARD_SIZE.x - 4, y * CELL), gc)

	# settled blocks
	for y in ROWS:
		for x in COLS:
			var i := y * COLS + x
			var v := board[i]
			if v >= 0:
				var id := ids[i]
				var mask := 0
				if y > 0 and ids[i - COLS] == id:
					mask |= 1
				if y < ROWS - 1 and ids[i + COLS] == id:
					mask |= 2
				if x > 0 and ids[i - 1] == id:
					mask |= 4
				if x < COLS - 1 and ids[i + 1] == id:
					mask |= 8
				# a just-landed piece stays as separate squares for a moment, then melds
				if id == meld_id and meld_t > 0.0:
					mask = -1
				draw_block(BOARD_POS + Vector2(x, y) * CELL, CELL, v, x * 31 + y * 17 + v, mask)

	if state == State.OVER and not won:
		_draw_clog()

	# ghost + active piece
	if state == State.PLAYING or state == State.PAUSED:
		for c in piece_cells(cur_type, cur_rot):
			if cur_pos.y + c.y >= 0:
				var o := BOARD_POS + Vector2(cur_pos.x + c.x, cur_pos.y + c.y) * CELL
				draw_block(o, CELL, cur_type, (cur_pos.x + c.x) * 31 + (cur_pos.y + c.y) * 17 + cur_type)

	# water at the bottom of the bowl: plain 6 px columns whose tops move in whole 3 px steps
	# (rectangles only: the rounded corners are trimmed by the corner caps drawn right after)
	if turd_mode:
		var top := BOARD_POS.y + BOARD_SIZE.y - 2.5 * CELL
		var bottom := BOARD_POS.y + BOARD_SIZE.y
		var wx := 0.0
		while wx < BOARD_SIZE.x:
			var sy: float = top + roundf(sin(time * 1.6 + wx * 0.05) * 1.2) * 3.0
			var cw := minf(6.0, BOARD_SIZE.x - wx)
			draw_rect(Rect2(BOARD_POS.x + wx, sy, cw, bottom - sy), Color(0.2, 0.42, 0.8, 0.45))
			draw_rect(Rect2(BOARD_POS.x + wx, sy, cw, 3.0), Color(0.62, 0.84, 1.0, 0.8))
			wx += 6.0

	# pieces must not poke out of the rounded corners: paint the corner bits of the frame over them
	if turd_mode:
		_draw_corner_caps(well)

	# piece hint (ghost) sits over the water so it stays visible
	if SHOW_GHOST and (state == State.PLAYING or state == State.PAUSED):
		var gp2 := ghost_pos()
		var gcol2: Color = TURD_COLORS[cur_type] if turd_mode else CLASSIC_COLORS[cur_type]
		gcol2 = gcol2.lightened(0.25)
		gcol2.a = 0.8
		for c in piece_cells(cur_type, cur_rot):
			if gp2.y + c.y >= 0:
				var o2 := BOARD_POS + Vector2(gp2.x + c.x, gp2.y + c.y) * CELL
				draw_rect(Rect2(o2, Vector2(CELL, CELL)).grow(-4.0), gcol2, false, 2.0)

	# FLUSH animation over cleared rows
	if state == State.CLEARING:
		var t := 1.0 - clear_timer / CLEAR_TIME
		for y in clear_rows:
			var r := Rect2(BOARD_POS + Vector2(0, y * CELL), Vector2(BOARD_SIZE.x, CELL))
			draw_rect(r, Color(0.6, 0.85, 1.0, clampf(t * 2.5, 0.0, 1.0)))
			var sx := r.position.x + (r.size.x + 80.0) * t - 80.0
			var x0 := maxf(r.position.x, sx)
			var x1 := minf(r.end.x, sx + 80.0)
			if x1 > x0:
				draw_rect(Rect2(x0, r.position.y, x1 - x0, CELL), Color(1, 1, 1, 0.85))


func _turd_style(type: int, mask: int) -> StyleBoxFlat:
	var key := type * 16 + mask
	if style_cache.has(key):
		return style_cache[key]
	var base: Color = TURD_COLORS[type]
	var sb := StyleBoxFlat.new()
	sb.bg_color = base
	sb.border_color = base.darkened(0.55)
	# edges shared with a neighbour of the same piece get no border and no rounding
	sb.border_width_top = 0 if (mask & 1) != 0 else 3
	sb.border_width_bottom = 0 if (mask & 2) != 0 else 3
	sb.border_width_left = 0 if (mask & 4) != 0 else 3
	sb.border_width_right = 0 if (mask & 8) != 0 else 3
	sb.corner_radius_top_left = 9 if (mask & 5) == 0 else 0
	sb.corner_radius_top_right = 9 if (mask & 9) == 0 else 0
	sb.corner_radius_bottom_left = 9 if (mask & 6) == 0 else 0
	sb.corner_radius_bottom_right = 9 if (mask & 10) == 0 else 0
	sb.anti_aliasing = true
	style_cache[key] = sb
	return sb


# Pixel-art turd cell: a 12x12 sprite built in code, one per piece colour and neighbour mask.
# The swirl creases use only x and y, repeating every 12 px, so melded cells flow into each other.
const PX := 12
const SWIRL := [0, 1, 2, 2, 1, 0, 0, -1, -2, -2, -1, 0]
var pixel_cache := {}


func _pixel_turd(type: int, mask: int) -> Texture2D:
	var key := type * 16 + mask
	if pixel_cache.has(key):
		return pixel_cache[key]
	# SNES-style: 15-bit colours, a small ramp of browns with a coloured (not black) outline
	var outline := Color("2a1408")
	var deep := Color("4a2a14")
	var shade := Color("6e4120")
	var base := Color("94592c")
	var mid := Color("b57a3e")
	var light := Color("d9a35c")
	var shine := Color("f4d79a")
	var corn := Color("e8d070")
	var up := (mask & 1) != 0
	var down := (mask & 2) != 0
	var left := (mask & 4) != 0
	var right := (mask & 8) != 0
	var img := Image.create(PX, PX, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var last := PX - 1
	for y in PX:
		for x in PX:
			# rounded outer corners: a corner with no neighbour on either side is cut off
			if (x == 0 and y == 0 and not left and not up) or (x == last and y == 0 and not right and not up) \
					or (x == 0 and y == last and not left and not down) or (x == last and y == last and not right and not down):
				continue
			if (x == 0 and not left) or (x == last and not right) or (y == 0 and not up) or (y == last and not down):
				img.set_pixel(x, y, outline)
				continue
			# each coil: dark crease, bright top edge, soft body, shadowed underside
			var band := posmod(y + int(SWIRL[x]) + type * 2, 6)
			var c := base
			match band:
				0: c = deep
				1: c = shine if (x + y) % 5 == 0 else light
				2: c = mid
				3: c = base
				4: c = shade
				5: c = deep if (x + y) % 2 == 0 else shade
			# lit from the top-left: the rim just inside an exposed edge catches light or falls into shadow
			if band != 0:
				if (x == 1 and not left) or (y == 1 and not up):
					c = light if c != shine else c
				elif (x == last - 1 and not right) or (y == last - 1 and not down):
					c = shade if c != deep else c
			if x == 8 and y == 4 and type % 2 == 0:
				c = corn
			if x == 3 and y == 8 and type % 3 == 0:
				c = corn
			img.set_pixel(x, y, c)
	var tex := ImageTexture.create_from_image(img)
	pixel_cache[key] = tex
	return tex


# mask < 0: a loose square (falling piece, previews). mask >= 0: a settled cell, with
# bits 1/2/4/8 = same-piece neighbour above/below/left/right, which melds into one lump.
func _clogged(x: int, y: int) -> bool:
	if x < 0 or x >= COLS or y < 0 or y >= ROWS:
		return false
	return board[y * COLS + x] == -1 and float(ROWS - 1 - y) < clog_progress


# After losing, every empty space fills with poo, rising from the bottom and melding into one mass.
func _draw_clog() -> void:
	for y in ROWS:
		for x in COLS:
			if not _clogged(x, y):
				continue
			var mask := 0
			if _clogged(x, y - 1):
				mask |= 1
			if _clogged(x, y + 1):
				mask |= 2
			if _clogged(x - 1, y):
				mask |= 4
			if _clogged(x + 1, y):
				mask |= 8
			draw_block(BOARD_POS + Vector2(x, y) * CELL, CELL, 4, x * 31 + y * 17 + 4, mask)


func _ellipse_poly(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 72:
		var a := TAU * i / 72.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


# A giant butt hanging in from the top of the screen: two cheeks, crack over the middle of the
# well where the pieces come out. It only reaches the top row of the grid, and the pieces are
# drawn on top of it.
func _draw_butt_layer() -> void:
	if butt_tex != null:
		draw_texture_rect(butt_tex, Rect2(BUTT_ORIGIN, BUTT_SIZE), false)
	else:
		_draw_butt()


func _draw_butt() -> void:
	for cx in [105.0, 335.0]:
		var c := Vector2(cx, -120.0)
		draw_colored_polygon(_ellipse_poly(c + Vector2(0, 8), 228.0, 208.0), Color(0, 0, 0, 0.35))   # contact shadow
		draw_colored_polygon(_ellipse_poly(c, 228.0, 208.0), Color("6e4132"))
		draw_colored_polygon(_ellipse_poly(c, 225.0, 205.0), Color("c98a70"))
		draw_colored_polygon(_ellipse_poly(c + Vector2(0, -7), 219.0, 197.0), Color("e2ab90"))
		draw_colored_polygon(_ellipse_poly(c + Vector2(-40, -22), 130.0, 150.0), Color(1.0, 0.88, 0.8, 0.35))   # soft highlight
	# the crack between the cheeks


func _round_poly(r: Rect2, rt: float, rb: float, steps: int = 8) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var corners := [
		[Vector2(r.end.x - rt, r.position.y + rt), rt, -PI * 0.5, 0.0],
		[Vector2(r.end.x - rb, r.end.y - rb), rb, 0.0, PI * 0.5],
		[Vector2(r.position.x + rb, r.end.y - rb), rb, PI * 0.5, PI],
		[Vector2(r.position.x + rt, r.position.y + rt), rt, PI, PI * 1.5],
	]
	for c in corners:
		for i in steps:
			var a: float = lerpf(float(c[2]), float(c[3]), i / float(steps - 1))
			pts.append((c[0] as Vector2) + Vector2(cos(a), sin(a)) * float(c[1]))
	return pts


# Looking down into a toilet bowl: dark cavity, lighter porcelain at the walls, a glossy streak,
# the drain hole at the bottom, and a darker rim line.
func _draw_corner_caps(well: Rect2) -> void:
	var arc := _round_poly(well, 30.0, 56.0, 14)
	var corners := [well.position + Vector2(well.size.x, 0), well.end, well.position + Vector2(0, well.size.y), well.position]
	for k in 4:
		var poly := PackedVector2Array([corners[k]])
		poly.append_array(arc.slice(k * 14, (k + 1) * 14))
		if bg_tex != null:
			var uvs := PackedVector2Array()
			for p in poly:
				uvs.append(p / VIEW_SIZE)   # same picture as the background, so the cap is invisible
			draw_colored_polygon(poly, Color.WHITE, uvs, bg_tex)
		else:
			draw_colored_polygon(poly, Color("f4f7f9"))


func _draw_bowl_interior(well: Rect2) -> void:
	var pts := _round_poly(well, 30.0, 56.0)
	var cols := PackedColorArray()
	for p in pts:
		var t := clampf((p.y - well.position.y) / well.size.y, 0.0, 1.0)
		cols.append(Color("0b1116").lerp(Color("14232d"), t))
	draw_polygon(pts, cols)
	for i in 46:   # porcelain brightening toward the side walls
		var a := 0.18 * pow(1.0 - i / 46.0, 2.0)
		draw_line(Vector2(well.position.x + 2.0 + i, well.position.y + 30.0), Vector2(well.position.x + 2.0 + i, well.end.y - 56.0), Color(0.75, 0.82, 0.87, a))
		draw_line(Vector2(well.end.x - 2.0 - i, well.position.y + 30.0), Vector2(well.end.x - 2.0 - i, well.end.y - 56.0), Color(0.75, 0.82, 0.87, a))
	draw_line(Vector2(well.position.x + 12.0, well.position.y + 50.0), Vector2(well.position.x + 12.0, well.position.y + 260.0), Color(1, 1, 1, 0.16), 4.0)
	draw_circle(Vector2(well.position.x + 12.0, well.position.y + 284.0), 3.0, Color(1, 1, 1, 0.16))
	var drain := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		drain.append(Vector2(well.get_center().x, well.end.y - 19.0) + Vector2(cos(a) * 70.0, sin(a) * 11.0))
	draw_colored_polygon(drain, Color(0.01, 0.02, 0.03, 0.75))
	var rim := pts.duplicate()
	rim.append(pts[0])
	draw_polyline(rim, Color("6d818c"), 3.0)


func draw_block(o: Vector2, s: float, type: int, seed_v: int, mask: int = -1) -> void:
	var r := Rect2(o, Vector2(s, s))
	if turd_mode:
		var tex := turd_texs[type]
		if tex != null:
			draw_texture_rect(tex, r, false)
			return
		draw_texture_rect(_pixel_turd(type, maxi(mask, 0)), r, false)
	else:
		draw_style_box(classic_styles[type], r.grow(-1.0))
		draw_rect(Rect2(o + Vector2(4, 4), Vector2(s - 8.0, 3)), Color(1, 1, 1, 0.35))


func draw_preview(type: int, box: Rect2) -> void:
	var pcol := Color("0d1318") if turd_mode else Color("11121b")
	_box(box, pcol, Color("55666f") if turd_mode else Color("3a3f5c"), 10, 2)
	if type < 0:
		return
	var cells := piece_cells(type, 0)
	var mn := Vector2i(99, 99)
	var mx := Vector2i(-99, -99)
	for c in cells:
		mn = Vector2i(mini(mn.x, c.x), mini(mn.y, c.y))
		mx = Vector2i(maxi(mx.x, c.x), maxi(mx.y, c.y))
	var s := 28.0
	var dim_size := Vector2(mx - mn + Vector2i.ONE) * s
	var origin := box.position + (box.size - dim_size) * 0.5
	for c in cells:
		draw_block(origin + Vector2(c - mn) * s, s, type, c.x * 31 + c.y * 17 + type)


func _draw_panel() -> void:
	var tcol := Color("f4e6cc") if turd_mode else Color("f0f0f8")
	var scol := Color("b9c9d3") if turd_mode else Color("b8bcd8")   # label colour: bright enough to read on the dark panel
	var px := PANEL.position.x
	_text("TURDTRIS", Vector2(px, 120), 42, tcol)

	_text("NEXT", Vector2(px, 180), 20, scol)
	draw_preview(next_type if state != State.TITLE else -1, Rect2(px + 40, 192, 190, 100))

	var y := 352.0
	var lines_text := str(lines) if game_type == 0 else "%d / %d" % [lines, GOAL]
	for row in [["SCORE", str(score)], ["HIGH", str(high)], ["LEVEL", str(level)], ["LINES", lines_text]]:
		_text(row[0], Vector2(px, y), 20, scol)
		_text(row[1], Vector2(px, y + 38.0), 36, tcol)
		y += 76.0

	_text(("MUSIC - %s" if using_pad else "MUSIC  (%s)") % _p("music"), Vector2(px, 680), 18, scol)
	_text(str(SONGS[cur_song]["name"]) if music_enabled else "OFF", Vector2(px, 716), 26, tcol)


# Dimming for title / pause / game-over: follows the rounded corners of the bowl instead of a square
func _dim_well(well: Rect2, col: Color) -> void:
	draw_colored_polygon(_round_poly(well, 30.0, 56.0, 14), col)


const WIN_PROMPT_AT := 5.2   # the win screen shows its prompt (and accepts the button) from here
const LAUNCH_AT := 1.8      # seconds on the pad (3-2-1) before liftoff


func _rocket_top() -> float:
	var tl := maxf(0.0, win_t - LAUNCH_AT)
	var pad_y := BOARD_POS.y + BOARD_SIZE.y - 44.0
	return pad_y - 5.0 * CELL - 0.5 * 330.0 * tl * tl


# The victory screen: a rocket built out of turds counts down on a pad and blasts off, like the Game Boy ending.
func _draw_win_scene(well: Rect2, cx: float, w: float, brown: Color) -> void:
	_dim_well(well, Color(0.02, 0.03, 0.09, 0.9))
	for i in 46:   # twinkling stars
		var sp := Vector2(BOARD_POS.x + fposmod(i * 97.0, BOARD_SIZE.x - 12.0) + 6.0, BOARD_POS.y + fposmod(i * 173.0, BOARD_SIZE.y - 80.0) + 6.0)
		var tw := 0.35 + 0.65 * absf(sin(time * 2.0 + i))
		draw_rect(Rect2(sp.round(), Vector2(3, 3) if i % 3 != 0 else Vector2(6, 6)), Color(1, 1, 0.85, tw))
	var pad_y := BOARD_POS.y + BOARD_SIZE.y - 44.0
	var bx := BOARD_POS.x + BOARD_SIZE.x * 0.5 - 1.5 * CELL
	draw_rect(Rect2(BOARD_POS.x + 110, pad_y, BOARD_SIZE.x - 220, 14), Color("7d8b95"))
	draw_rect(Rect2(BOARD_POS.x + 110, pad_y, BOARD_SIZE.x - 220, 4), Color("c9d3d9"))
	var tl := maxf(0.0, win_t - LAUNCH_AT)
	var jitter := Vector2.ZERO
	if win_t > 0.9 and win_t < LAUNCH_AT + 0.4:
		jitter = Vector2(randf_range(-2.0, 2.0), randf_range(-1.0, 1.0))
	var top := _rocket_top()
	var o := Vector2(bx, top) + jitter
	# nose cone: stepped, three rows
	for r in 3:
		var half := 6.0 + 12.0 * r
		draw_rect(Rect2(o.x + 54.0 - half, o.y + r * 12.0, half * 2.0, 12.0), Color("e45c10"))
		draw_rect(Rect2(o.x + 54.0 - half, o.y + r * 12.0, minf(half * 2.0, 6.0), 12.0), Color("fca044"))
	var cells := [
		[0, 1, 10], [1, 1, 15], [2, 1, 6],
		[0, 2, 11], [1, 2, 15], [2, 2, 7],
		[0, 3, 11], [1, 3, 13], [2, 3, 7],
	]
	for c in cells:
		draw_block(o + Vector2(c[0], c[1]) * CELL, CELL, 0, 0, c[2])
	draw_block(o + Vector2(0, 4) * CELL, CELL, 4, 0, 0)   # fins
	draw_block(o + Vector2(2, 4) * CELL, CELL, 4, 0, 0)
	draw_rect(Rect2(o + Vector2(CELL + 6.0, 4.0 * CELL), Vector2(24, 14)), Color("2a1408"))   # nozzle
	var wc := o + Vector2(54.0, 2.5 * CELL)
	draw_rect(Rect2(wc - Vector2(15, 15), Vector2(30, 30)), Color.BLACK)   # porthole
	draw_rect(Rect2(wc - Vector2(12, 12), Vector2(24, 24)), Color("7fcdf8"))
	draw_rect(Rect2(wc - Vector2(9, 9), Vector2(9, 9)), Color("e8f6ff"))
	if win_t > 0.9:   # flame, a stack of shrinking pixel rows that flickers
		var flen := (3 + int(randf() * 3.0)) + (6 if tl > 0.0 else 0)
		for k in flen:
			var fw := maxf(6.0, 24.0 - k * 3.0)
			var fy := o.y + 4.0 * CELL + 14.0 + k * 6.0
			draw_rect(Rect2(o.x + 54.0 - fw * 0.5, fy, fw, 6.0), Color("f83800") if k % 3 == 2 else Color("fca044"))
			if fw > 10.0:
				draw_rect(Rect2(o.x + 54.0 - fw * 0.25, fy, fw * 0.5, 6.0), Color("fcfcfc") if k < 3 else Color("f8d878"))
	_text("ALL FLUSHED!", Vector2(cx, BOARD_POS.y + 90), 44, Color("e0a468"), w, 8, brown)
	if win_t < LAUNCH_AT:
		var count := int(ceil((LAUNCH_AT - win_t) / (LAUNCH_AT / 3.0)))
		_text(str(clampi(count, 1, 3)), Vector2(cx, BOARD_POS.y + 190), 80, Color.WHITE, w, 10, Color(0.1, 0.1, 0.3))
	elif tl > 0.0 and tl < 0.9:
		_text("BLAST OFF!", Vector2(cx, BOARD_POS.y + 190), 44, Color("ffe9a8"), w, 8, brown)
	if win_t > WIN_PROMPT_AT:
		_text("Score %d" % score, Vector2(cx, BOARD_POS.y + 340), 24, Color.WHITE, w)
		_text("%s for the menu" % _p("confirm"), Vector2(cx, BOARD_POS.y + 385), 18, Color(1, 1, 1, 0.6 + 0.4 * sin(time * 4.0)), w)
		_text("Game by ResidentEmil_", Vector2(cx, BOARD_POS.y + 450), 18, Color("ffe9a8"), w)
		_text("with assistance from Claude AI", Vector2(cx, BOARD_POS.y + 478), 16, Color("b9c9d3"), w)


func _draw_overlays() -> void:
	var well := Rect2(BOARD_POS, BOARD_SIZE)
	var cx := BOARD_POS.x
	var w := BOARD_SIZE.x
	var brown := Color("5c351d")
	match state:
		State.TITLE:
			_dim_well(well, Color(0, 0, 0, 0.6))
			_text("TURDTRIS", Vector2(cx, BOARD_POS.y + 240), 54, Color("c68a52"), w, 8, brown)
			_text("CALL OF DOODY", Vector2(cx, BOARD_POS.y + 284), 22, Color("ffe9a8"), w, 4, brown)
			var a := 0.6 + 0.4 * sin(time * 4.0)
			_text("Press %s" % _p("confirm"), Vector2(cx, BOARD_POS.y + 320), 20, Color(1, 1, 1, a), w)
		State.PAUSED:
			_dim_well(well, Color(0, 0, 0, 0.74))
			var items := ["RESUME", "RETURN TO TITLE"]
			var base_y := BOARD_POS.y + 330.0
			if pause_confirm:
				items = ["NO", "YES, QUIT"]
				_text("ARE YOU SURE?", Vector2(cx, BOARD_POS.y + 200), 38, Color.WHITE, w, 6, brown)
				_text("Return to the title screen?", Vector2(cx, BOARD_POS.y + 250), 17, Color(1, 1, 1, 0.85), w)
				_text("Your current game will be lost.", Vector2(cx, BOARD_POS.y + 276), 17, Color(1, 1, 1, 0.85), w)
				base_y = BOARD_POS.y + 360.0
			else:
				_text("PAUSED", Vector2(cx, BOARD_POS.y + 240), 46, Color.WHITE, w, 6, brown)
			for i in items.size():
				var iy := base_y + i * 62.0
				var sel := i == pause_row
				if sel:
					draw_rect(Rect2(cx + 24, iy - 38, w - 48, 54), Color(1, 1, 1, 0.08 + 0.04 * sin(time * 6.0)))
					draw_block(Vector2(cx + 32, iy - 33), 36.0, 0, 0)
				_text(str(items[i]), Vector2(cx, iy), 26, Color("ffe9a8") if sel else Color(0.78, 0.78, 0.78), w)
			_text(("UP/DOWN select  %s confirm  %s back" % [_p("confirm"), _p("back")]) if using_pad else "UP/DOWN select  ENTER confirm  P back", Vector2(cx, BOARD_POS.y + 660), 13, Color(1, 1, 1, 0.6), w)
		State.OVER:
			if won:
				_draw_win_scene(well, cx, w, brown)
			elif clog_progress >= float(ROWS):
				_dim_well(well, Color(0.2, 0.1, 0.05, 0.5))
				_text("CLOGGED!", Vector2(cx, BOARD_POS.y + 290), 48, Color("e0a468"), w, 8, brown)
				_text("Score %d" % score, Vector2(cx, BOARD_POS.y + 340), 24, Color.WHITE, w)
				_text("%s for the menu" % _p("confirm"), Vector2(cx, BOARD_POS.y + 385), 18, Color(1, 1, 1, 0.6 + 0.4 * sin(time * 4.0)), w)
	if popup_timer > 0.0 and popup_text != "":
		var al := minf(1.0, popup_timer * 2.0)
		var rise := (1.2 - popup_timer) * 30.0
		_text(popup_text, Vector2(cx, BOARD_POS.y + 220 - rise), 34, Color(1.0, 0.9, 0.35, al), w, 7, Color(0.3, 0.17, 0.08, al))
