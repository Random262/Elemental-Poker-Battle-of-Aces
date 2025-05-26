# MiniGame.gd
extends Node
class_name MiniGame

signal minigame_end()
var minigame_start
var click_count = 0
var is_your_turn_mn = false
var active_button
var active_num
var buttons
var window
var trigger_timer: Timer
var reaction_timer: Timer
var texture_path = "res://textures/misc/"
var active_textures = ["chose_turn_fire_button_ul.png", "chose_turn_air_button_ur.png",
"chose_turn_earth_button_dl.png", "chose_turn_water_button_dr.png"]

func setup(_buttons, _trigger_timer: Timer, _reaction_timer: Timer, _window):
	buttons = _buttons
	trigger_timer = _trigger_timer
	reaction_timer = _reaction_timer
	window = _window
	minigame_start = false
	
	trigger_timer.timeout.connect(_on_trigger_timeout)
	reaction_timer.timeout.connect(_on_reaction_timeout)

	for button in buttons:
		button.pressed.connect(_on_button_pressed.bind(button))

func start_game():
	_start_next_trigger()

func _start_next_trigger():
	trigger_timer.wait_time = randf_range(3.0, 5.0)	
	trigger_timer.start()
	
func _on_trigger_timeout():
	is_your_turn_mn = false
	active_num = [0, 1, 2 ,3].pick_random()
	active_button = buttons[active_num]
	active_button.texture_normal = load(texture_path + active_textures[active_num])
	active_button.texture_hover = load(texture_path + active_textures[active_num])
	minigame_start = true
	reaction_timer.start(1.0)
	

func _on_reaction_timeout():
	window.visible = true
	window.modulate.a = 0.0
	var tween = create_tween()
	window.texture = load("res://textures/misc/chose_turn_all_grey.png")
	tween.tween_property(window, "modulate:a", 1, 2)
	emit_signal("minigame_end")
	return

func _on_button_pressed(button: TextureButton):
	if not minigame_start:
		return
	click_count += 1
	window.visible = true
	window.modulate.a = 0.0
	var tween = create_tween()
	if button == active_button and reaction_timer.time_left > 0 and click_count < 2:
		is_your_turn_mn = true
		window.texture = load("res://textures/misc/chose_turn_all.png")
		tween.tween_property(window, "modulate:a", 1, 2)
	else:
		is_your_turn_mn = false
		window.texture = load("res://textures/misc/chose_turn_all_grey.png")
		tween.tween_property(window, "modulate:a", 1, 2)
	reaction_timer.stop()
	emit_signal("minigame_end")

