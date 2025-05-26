extends Control

@onready var scroll_container = $ScrollContainer
const button_width = 576 
var current_index = 0  
var settings_button_flag

func _ready():
	MusicManager.play_music(preload("res://music/BGM_MAIN_MENU.mp3"))
	
	settings_button_flag = false
	$SettingButton.pressed.connect(on_settings_button_pressed)
	$SettingsToMenu.pressed.connect(on_settings_to_menu_pressed)
	
	#$Prev.pressed.connect(_on_buttonprev_pressed)
	#$Next.pressed.connect(_on_buttonnext_pressed)
	$ScrollContainer/HBoxContainer/First.pressed.connect(_on_first_pressed)
	$ScrollContainer/HBoxContainer/Second.pressed.connect(_on_second_pressed)
	$ScrollContainer/HBoxContainer/Third.pressed.connect(_on_third_pressed)
	$ScrollContainer/HBoxContainer/Fourth.pressed.connect(_on_fourth_pressed)
	$ScrollContainer/HBoxContainer/Fifth.pressed.connect(_on_fifth_pressed)
	$ScrollContainer/HBoxContainer/Sixth.pressed.connect(_on_sixth_pressed)
	pass 

func _on_first_pressed():
	MusicManager.stop_music(true)
	BattleState.start_mode = "puppet"
	get_tree().change_scene_to_file("res://scenes/Game.tscn")
	return

func _on_second_pressed():
	MusicManager.stop_music(true)
	BattleState.start_mode = "fire_villain"
	get_tree().change_scene_to_file("res://scenes/Game.tscn")
	return

func _on_third_pressed():
	MusicManager.stop_music(true)
	BattleState.start_mode = "water_villain"
	get_tree().change_scene_to_file("res://scenes/Game.tscn")
	return

func _on_fourth_pressed():
	MusicManager.stop_music(true)
	BattleState.start_mode = "earth_villain"
	get_tree().change_scene_to_file("res://scenes/Game.tscn")
	return

func _on_fifth_pressed():
	MusicManager.stop_music(true)
	BattleState.start_mode = "air_villain"
	get_tree().change_scene_to_file("res://scenes/Game.tscn")
	return
	
func _on_sixth_pressed():
	MusicManager.stop_music(true)
	BattleState.start_mode = "dark_villain"
	get_tree().change_scene_to_file("res://scenes/Game.tscn")
	return


func on_settings_button_pressed():
	var tween = create_tween().set_parallel(true)
	if not settings_button_flag:
		$SettingsToMenu.visible = true
		tween.tween_property($SettingsToMenu, "position", Vector2(1112, 554), 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property($SettingsToMenu, "modulate:a", 1.0, 0.3)
		settings_button_flag = true
	else:
		tween.tween_property($SettingsToMenu, "position", Vector2(1112, 559), 0.2)
		tween.tween_property($SettingsToMenu, "modulate:a", 0.0, 0.2)
		tween.chain().tween_callback(func(): $SettingsToMenu.visible = false)
		settings_button_flag = false
	return

func on_settings_to_menu_pressed():
	MusicManager.current_position = MusicManager.music_player.get_playback_position()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	return


func _on_buttonnext_pressed():
	if current_index < 2:
		current_index += 1
		scroll_to_index(current_index)

func _on_buttonprev_pressed():
	if current_index > 0:
		current_index -= 1
		scroll_to_index(current_index)

func scroll_to_index(index: int):
	var target_scroll = index * button_width * 2  # по 2 кнопки за раз
	scroll_container.scroll_horizontal = target_scroll
