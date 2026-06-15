extends Node

const SONGS = {
	"MENU_MUSIC": preload("res://Music/MainMenu.wav"),
	"COMBAT_MUSIC_1": preload("res://Music/Combat.wav"),
	"COMBAT_MUSIC_2": preload("res://Music/Combat2.wav"),
	"SHOP_MUSIC": preload("res://Music/Shop.wav"),
	"BOSS_MUSIC": preload("res://Music/BossFight.wav"),
	"GHOST_MUSIC": preload("res://Music/Ghosts.wav")
}

@onready var current_player: AudioStreamPlayer = $MusicA
@onready var other_player: AudioStreamPlayer = $MusicB

var current_song: AudioStream = null

# tweens
var music_tween: Tween
var pitch_tween: Tween
var muff_tween: Tween

# pitch system
var target_pitch := 1.0

# muffling system
var music_bus_index: int
var lowpass: AudioEffectLowPassFilter


func _ready():
	current_player.volume_db = 0
	other_player.volume_db = -40

	current_player.pitch_scale = 1.0
	other_player.pitch_scale = 1.0

	# --- safe audio bus setup ---
	music_bus_index = AudioServer.get_bus_index("Music")

	if music_bus_index == -1:
		push_error("Music bus not found!")
		return

	if AudioServer.get_bus_effect_count(music_bus_index) == 0:
		push_error("No effects on Music bus!")
		return

	lowpass = AudioServer.get_bus_effect(music_bus_index, 0)

	set_music_muffle(0.0)


# 🎵 CROSSFADE MUSIC (FIXED STABLE VERSION)
func play_music(song: AudioStream, fade_time := 1.0):
	if current_song == song:
		return

	current_song = song

	if music_tween and music_tween.is_running():
		music_tween.kill()

	# prepare new track QUIET first (important)
	other_player.stream = song
	other_player.volume_db = -40
	other_player.pitch_scale = target_pitch
	other_player.play()

	music_tween = create_tween()

	# fade OUT old
	music_tween.parallel().tween_property(current_player, "volume_db", -40, fade_time)

	# fade IN new
	music_tween.parallel().tween_property(other_player, "volume_db", 0, fade_time)

	await music_tween.finished

	current_player.stop()

	var temp = current_player
	current_player = other_player
	other_player = temp

	current_player.pitch_scale = target_pitch
	other_player.pitch_scale = target_pitch


# 🔇 FADE OUT MUSIC (SAFE)
func fade_out_music(fade_time := 2.5):
	if music_tween and music_tween.is_running():
		music_tween.kill()

	music_tween = create_tween()

	music_tween.parallel().tween_property(current_player, "volume_db", -40, fade_time)
	music_tween.parallel().tween_property(other_player, "volume_db", -40, fade_time)

	await music_tween.finished

	current_player.stop()
	other_player.stop()
	current_song = null


# 🎚️ PITCH CONTROL (SAFE + NO STACKING)
func set_music_pitch(pitch: float, tween_time := 1.2):
	target_pitch = pitch

	if pitch_tween and pitch_tween.is_running():
		pitch_tween.kill()

	pitch_tween = create_tween()

	pitch_tween.parallel().tween_property(current_player, "pitch_scale", pitch, tween_time)
	pitch_tween.parallel().tween_property(other_player, "pitch_scale", pitch, tween_time)


# 🎧 MUFFLE CONTROL (LINEAR + STRONG)
func set_music_muffle(amount: float, tween_time := 0.25):
	# amount: 0 = clear, 1 = fully muffled

	var cutoff = lerp(20000.0, 100.0, amount)

	if muff_tween and muff_tween.is_running():
		muff_tween.kill()

	muff_tween = create_tween()

	muff_tween.tween_method(
		func(value):
			lowpass.cutoff_hz = value,
		lowpass.cutoff_hz,
		cutoff,
		tween_time
	)
