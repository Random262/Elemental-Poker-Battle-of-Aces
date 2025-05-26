# Пример: SettingsMenu.gd
extends Control

@onready var resolution_selector = $VBoxContainer/HBoxContainer/ResolutionSelector
@onready var volume_slider = $VBoxContainer/HBoxContainer2/VolumeSlider

var resolutions = [
	Vector2i(1152, 648),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080)
]

func _ready():
	MusicManager.play_music(preload("res://music/BGM_MAIN_MENU.mp3"))
	
	$Back.pressed.connect(on_back_pressed)
	
	get_window().connect("size_changed", Callable(self, "_on_window_resized"))
	on_window_resized()
	
	for res in resolutions:
		resolution_selector.add_item("%d x %d" % [res.x, res.y])
	resolution_selector.connect("item_selected", Callable(self, "_on_resolution_selected"))
	
	load_settings()
	
	volume_slider.min_value = -50  # тишина
	volume_slider.max_value = 0    # максимум
	volume_slider.value = AudioServer.get_bus_volume_db(0)
	volume_slider.connect("value_changed", Callable(self, "_on_volume_changed"))
	
func _on_resolution_selected(index):
	DisplayServer.window_set_size(resolutions[index])
	on_window_resized()
	
func _on_volume_changed(value):
	AudioServer.set_bus_volume_db(0, value)
	
func save_settings():
	var config = ConfigFile.new()
	config.set_value("display", "resolution_index", resolution_selector.get_selected_id())
	config.set_value("audio", "master_volume", volume_slider.value)
	config.save("user://settings.cfg")

func load_settings():
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		var res_index = config.get_value("display", "resolution_index", 0)

		if res_index >= 0 and res_index < resolutions.size():
			DisplayServer.window_set_size(resolutions[res_index])
			on_window_resized()
			resolution_selector.select(res_index)
		else:
			select_resolution_by_window_size()
	else:
		select_resolution_by_window_size()


func on_back_pressed():
	save_settings()
	MusicManager.current_position = MusicManager.music_player.get_playback_position()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func on_window_resized():
	var window = get_window()
	var primary_screen = DisplayServer.get_primary_screen()
	var screen_pos = DisplayServer.screen_get_position(primary_screen)
	var screen_size = DisplayServer.screen_get_size(primary_screen)
	var window_size = window.get_size()

	var new_pos = screen_pos + (screen_size - window_size) / 2
	window.set_position(new_pos)
	DisplayServer.window_set_current_screen(primary_screen)

func select_resolution_by_window_size():
	var current_size = get_window().get_size()
	for i in range(resolutions.size()):
		if resolutions[i] == current_size:
			resolution_selector.select(i)
			return

	var closest_index = 0
	var smallest_diff = abs(resolutions[0].x - current_size.x)
	for i in range(1, resolutions.size()):
		var diff = abs(resolutions[i].x - current_size.x)
		if diff < smallest_diff:
			smallest_diff = diff
			closest_index = i
	resolution_selector.select(closest_index)
