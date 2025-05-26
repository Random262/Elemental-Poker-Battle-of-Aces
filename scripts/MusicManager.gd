extends Node

var music_player: AudioStreamPlayer
var current_stream: AudioStream
var current_position: float = 0.0
var is_playing = false

func _ready():
	music_player = AudioStreamPlayer.new()
	add_child(music_player)

func play_music(stream: AudioStream):
	if current_stream != stream:
		current_stream = stream
		current_position = 0
		is_playing = false

	if not is_playing:
		music_player.volume_db = -25
		music_player.stream = current_stream
		music_player.stream.loop = true
		music_player.play(current_position)
		create_tween().tween_property(MusicManager.music_player, "volume_db", 0, 1.5)
		is_playing = true

func stop_music(reset_position = false):
	if music_player.playing:
		if reset_position:
			current_position = 0
		else:
			current_position = music_player.get_playback_position()
		music_player.stop()
		is_playing = false
