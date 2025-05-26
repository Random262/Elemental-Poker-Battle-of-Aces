extends Node

var resolution_index = 0
var master_volume = 0.0

func load_settings():
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:

		var res_index = config.get_value("display", "resolution_index", 0)
		var resolutions = [
			Vector2i(1152, 648),
			Vector2i(1366, 768),
			Vector2i(1600, 900),
			Vector2i(1920, 1080)
		]
		if res_index >= 0 and res_index < resolutions.size():
			DisplayServer.window_set_size(resolutions[res_index])
			on_window_resized(resolutions[res_index])
		
		var volume_db = config.get_value("audio", "master_volume", 0.0)
		AudioServer.set_bus_volume_db(0, volume_db)

func on_window_resized(window_size: Vector2i):
	var mouse_pos = DisplayServer.mouse_get_position()
	var screen_count = DisplayServer.get_screen_count()
	for i in screen_count:
		var screen_pos = DisplayServer.screen_get_position(i)
		var screen_size = DisplayServer.screen_get_size(i)
		if Rect2(screen_pos, screen_size).has_point(mouse_pos):
			var new_pos = screen_pos + (screen_size - window_size) / 2
			get_window().set_position(new_pos)
			DisplayServer.window_set_current_screen(i)
			break
