# MainMenu.gd
extends Control
@onready var menu_bgm = $MENU_BGM



var background = ["BG_FIRE", "BG_WATER", "BG_EARTH", "BG_AIR"]

func _ready():
	#var tween = create_tween()
	#tween.tween_property(menu_bgm, "volume_db", 0, 1.5)
	SettingManager.load_settings()
	
	MusicManager.play_music(preload("res://music/BGM_MAIN_MENU.mp3"))
	
	$Background.texture = load("res://textures/main_menu/%s.png" % background[randi() % background.size()])
	$CenteringMain/MainButtons/StartGame.pressed.connect(_on_start_game_pressed)
	$CenteringMain/MainButtons/Settings.pressed.connect(_on_settings_pressed)
	$CenteringMain/MainButtons/Exit.pressed.connect(_on_exit_pressed)
	pass


func _on_start_game_pressed():
	MusicManager.current_position = MusicManager.music_player.get_playback_position()
	get_tree().change_scene_to_file("res://scenes/Adventure.tscn")

func _on_settings_pressed():
	MusicManager.current_position = MusicManager.music_player.get_playback_position()
	get_tree().change_scene_to_file("res://scenes/SettingsMenu.tscn")

func _on_exit_pressed():
	get_tree().quit()

