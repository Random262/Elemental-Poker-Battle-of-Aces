extends Control

var suits = ["F", "W", "E", "A"]
var suits_villain
var ranks = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]
var bg_element = ["FIRE", "WATER", "EARTH", "AIR"]
var background = ["BG_FIRE", "BG_WATER", "BG_EARTH", "BG_AIR"]
var selected_cards = []
var redraws_left = 2
var turn_count = 0
var match_over = false 
var earth_coef = 0.75
var water_coef = 0.75

var player_hp = 100
var enemy_hp = 100
var player_shield = 0
var enemy_shield = 0
var player_comb_result = {}
var enemy_comb_result = {}
var enemy_cards = []
var enemy_redraws_left = 2
var is_player_turn
var first_turn
var random_bg_element
var settings_button_flag = false


@onready var battle_bgm = $Battle_BGM
@onready var battle_sfx = $Battle_SFX
@onready var battle_elements_sfx = $Battle_Elements_SFX

#$UI/RedrawButton.disabled = true

func _ready():
	match_enemy_texture()
	
	var tween = create_tween()
	tween.tween_property(battle_bgm, "volume_db", 0, 1.5)
	battle_sfx.volume_db = -10	
	
	battle_bgm.stream = load("res://music/BGM_BATTLE_%s.mp3" % random_bg_element)
	battle_bgm.play()
	$Background.texture = load("res://textures/backgrounds/BG_%s.png" % random_bg_element)
	
	play_minigame()
	await minigame_function_end
	await get_tree().create_timer(3).timeout
	clear_minigame()
	await get_tree().create_timer(2).timeout
	
	battle_sfx.stream = load("res://sounds/deal_cards.mp3")
	battle_sfx.play()
	redraw_cards()
	redraw_enemy_cards()
	
	$UI/RedrawButton.pressed.connect(on_redraw_pressed)
	$UI/EndTurnButton.pressed.connect(on_end_turn_pressed)
	$UI/SettingButton.pressed.connect(on_settings_button_pressed)
	$UI/SettingsToMenu.pressed.connect(on_settings_to_menu_pressed)
	for card in $PlayerArea/PlayerCards.get_children():
		card.mouse_entered.connect(func(): on_hover_card(card))
		card.mouse_exited.connect(func(): on_unhover_card(card))
		card.pressed.connect(
			func(): 
				if redraws_left > 0:
					battle_sfx.stream = load("res://sounds/pull_card.mp3")
					battle_sfx.play()
					toggle_card(card)
		)
	update_ui()
	
	if is_player_turn:
		player_turn()
	else:
		start_enemy_turn()	
	
func match_enemy_texture():
	match BattleState.start_mode:
		"puppet":
			$HeroEnemy.texture = load("res://textures/heroes/puppet_zero.png")
			random_bg_element = bg_element[randi() % bg_element.size()]
			suits_villain = ["F", "W", "E", "A"]
		"fire_villain":
			$HeroEnemy.texture = load("res://textures/heroes/villain_fire.png")
			random_bg_element = "FIRE"
			suits_villain = ["F", "E"]
		"water_villain":
			$HeroEnemy.texture = load("res://textures/heroes/villain_water.png")
			random_bg_element = "WATER"
			suits_villain = ["W", "A"]
		"earth_villain":
			$HeroEnemy.texture = load("res://textures/heroes/villain_earth.png")
			random_bg_element = "EARTH"
			suits_villain = ["E", "A"]
		"air_villain":
			$HeroEnemy.texture = load("res://textures/heroes/villain_air.png")
			random_bg_element = "AIR"
			suits_villain = ["W", "A"]
		"dark_villain":
			$HeroEnemy.texture = load("res://textures/heroes/villain_dark.png")
			random_bg_element = bg_element[randi() % bg_element.size()]
			suits_villain = ["F", "W", "E", "A"]
	return

func player_turn():
	$Your_turn.stream = load("res://sounds/your_turn.wav")
	turn_label.visible = true	
	$Your_turn.play()
	is_player_turn = true
	redraws_left = 2
	$UI/RedrawButton.disabled = false
	$UI/EndTurnButton.disabled = false
	turn_count += 1
	print(turn_count, "pl")	
	update_ui()
	return

@onready var screen = $Minigame/Screen
@onready var turn_label = $Minigame/WhoseTurn
@onready var mn_el = [$Minigame/Fire, $Minigame/Air, $Minigame/Earth, $Minigame/Water]
var MiniGame = preload("res://scripts/MiniGame.gd")
@onready var trigger_timer = $Minigame/Trigger_timer
@onready var reaction_timer = $Minigame/Reaction_timer
@onready var window = $Minigame/Window
var mini_game = MiniGame.new()
signal minigame_function_end()

func play_minigame():
	$Minigame.visible = true
	turn_label.modulate.a = 0.0
	mn_el[0].modulate.a = 0.0
	mn_el[1].modulate.a = 0.0
	mn_el[2].modulate.a = 0.0
	mn_el[3].modulate.a = 0.0
	screen.modulate.a = 0.95
	var tween = create_tween().set_parallel(true)
	tween.tween_property(turn_label, "modulate:a", 1, 2)
	tween.tween_property(mn_el[0], "modulate:a", 1, 2)
	tween.tween_property(mn_el[1], "modulate:a", 1, 2)
	tween.tween_property(mn_el[2], "modulate:a", 1, 2)
	tween.tween_property(mn_el[3], "modulate:a", 1, 2)
	
	add_child(mini_game)
	mini_game.setup(mn_el, trigger_timer, reaction_timer, window)
	mini_game.start_game()
	await mini_game.minigame_end
	create_tween().tween_property(turn_label, "modulate:a", 0, 0.5)
	await get_tree().create_timer(0.5).timeout
	turn_label.visible = false
	if mini_game.is_your_turn_mn:
		turn_label.text = "УСПЕХ"
		$Minigame/Minigame_SFX.stream = load("res://sounds/minigame_win.wav")
	else:
		turn_label.text = "ПРОВАЛ"
		$Minigame/Minigame_SFX.stream = load("res://sounds/minigame_lose.wav")
	turn_label.visible = true	
	$Minigame/Minigame_SFX.play()
	create_tween().tween_property(turn_label, "modulate:a", 1, 1)
	await get_tree().create_timer(1).timeout
	is_player_turn = mini_game.is_your_turn_mn
	first_turn = mini_game.is_your_turn_mn
	emit_signal("minigame_function_end")
	return

func clear_minigame():
	var tween = create_tween().set_parallel(true)
	tween.tween_property(screen, "modulate:a", 0, 2)
	tween.tween_property(turn_label, "modulate:a", 0, 1.5)
	for k in mn_el:
		k.visible = false
	tween.tween_property(window, "modulate:a", 0, 1.5)
	await get_tree().create_timer(2).timeout
	$Minigame.visible = false
	return

func toggle_card(card):
	if not is_player_turn:
		return
	if selected_cards.has(card):
		selected_cards.erase(card)
		card.position.y += 20
		card.remove_theme_stylebox_override("normal")
	else:
		selected_cards.append(card)
		card.position.y -= 20
		var frame = StyleBoxFlat.new()
		frame.set_border_width_all(5)
		frame.border_color = Color.REBECCA_PURPLE 
		frame.bg_color = Color(0, 0, 0, 0)
		card.add_theme_stylebox_override("normal", frame)


func on_hover_card(card):
	if redraws_left > 0:
		card.modulate = Color(1.1, 1.1, 1.1)

func on_unhover_card(card):
	card.modulate = Color(1, 1, 1)

func on_redraw_pressed():
	if selected_cards.size() == 0:
		return
	if redraws_left <= 0:
		return
	var used = []
	for card in selected_cards:
		var new_card = ""
		var rank = ""
		var suit = ""
		card.position.y += 20
		while true:
			rank = ranks[randi() % ranks.size()]
			suit = suits[randi() % suits.size()]	
			new_card = rank + "_" + suit 
			if not new_card in used:
				used.append(new_card)
				break
		card.text = new_card
		var texture_rect = card.get_node("TextureRect")
		texture_rect.texture = load("res://textures/cards/%s_%s.png" % [rank, suit])
		var front = card.get_node("TextureRect")
		var back = card.get_node("Back")
		flip(card, front, back, false)
		card.remove_theme_stylebox_override("normal")
	selected_cards.clear()
	redraws_left -= 1
	check_combination()
	update_ui()
	

func redraw_cards():
	var slots = $PlayerArea/PlayerCards.get_children()
	var used = []
	for card in slots:
		card.get_node("Back").visible = true
		var new_card = ""
		var rank = ""
		var suit = ""
		while true:
			rank = ranks[randi() % ranks.size()]
			suit = suits[randi() % suits.size()]	
			new_card = rank + "_" + suit 
			if not new_card in used:
				used.append(new_card)
				break
		card.text = new_card		
		var texture_rect = card.get_node("TextureRect")					
		texture_rect.texture = load("res://textures/cards/%s_%s.png" % [rank, suit])
		var front = card.get_node("TextureRect")
		var back = card.get_node("Back")
		flip(card, front, back, false)
		card.remove_theme_stylebox_override("normal")
	selected_cards.clear()
	redraws_left = 2
	check_combination()
	update_ui()

func flip(card, front, back, is_face_up):
	front.visible = is_face_up
	back.visible = !is_face_up
	var start_pos = card.global_position
	var target_pos = start_pos + Vector2(30,0)
	card.pivot_offset = card.size / 2
	var tween = create_tween().set_parallel(true)
	tween.tween_property(card, "scale:x", 0.0, 0.3).set_trans(Tween.TRANS_SINE)
	tween.chain().tween_callback(func():
		is_face_up = !is_face_up
		front.visible = is_face_up
		back.visible = !is_face_up
	)
	
	var return_pos = start_pos
	tween.tween_property(card, "scale:x", 1.0, 0.3).set_trans(Tween.TRANS_SINE)

func play_battle_elements_sfx(sound):
	battle_elements_sfx.stream = load("res://sounds/%s.wav" % sound)
	battle_elements_sfx.play()
	return
	
func on_end_turn_pressed():
	if not is_player_turn:
		return  # Игрок уже передал ход

	for card in selected_cards:
		card.position.y = 0
	selected_cards.clear()
	
	is_player_turn = false  # Прекращаем ход игрока	
	update_ui()
	if turn_count % 2 == 0:
		round_end()
	else:
		start_enemy_turn()
	
func generate_unique_card(used: Array):
	while true:
		var new_card = ranks[randi() % ranks.size()] + "_" + suits[randi() % suits.size()]
		if not new_card in used:
			used.append(new_card)
			return new_card
	return ""

func generate_unique_card_villain(used: Array):
	while true:
		var new_card = ranks[randi() % ranks.size()] + "_" + suits_villain[randi() % suits_villain.size()]
		if not new_card in used:
			used.append(new_card)
			return new_card
	return ""

func on_settings_button_pressed():
	var tween = create_tween().set_parallel(true)
	if not settings_button_flag:
		$UI/SettingsToMenu.visible = true
		tween.tween_property($UI/SettingsToMenu, "position", Vector2(211, 361), 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property($UI/SettingsToMenu, "modulate:a", 1.0, 0.3)
		settings_button_flag = true
	else:
		tween.tween_property($UI/SettingsToMenu, "position", Vector2(211, 406), 0.2)
		tween.tween_property($UI/SettingsToMenu, "modulate:a", 0.0, 0.2)
		tween.chain().tween_callback(func(): $UI/SettingsToMenu.visible = false)
		settings_button_flag = false
	return

func on_settings_to_menu_pressed():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	return

func check_combination():
	# Получаем карты игрока и противника
	var player_hand = get_cards_from_area($PlayerArea/PlayerCards)
	
	# Оцениваем комбинации
	var player_result = evaluate_poker_hand(player_hand)
	
	player_comb_result = player_result
	$UI/PlayerResultLabel.text = player_comb_result.result
	update_ui()
	
	
func get_cards_from_area(area, check_visible = false):
	var hand = []
	for card in area.get_children():
		if not check_visible or card.modulate == Color(1, 1, 1):
			if card.text != "??" and card.text.length() >= 2:
				hand.append(card.text)
	return hand	

func evaluate_poker_hand(hand):
	hand.sort_custom(func(a, b): return get_rank_value(a) < get_rank_value(b))
	var ranks_only = []
	var suits_only = []
	for c in hand:
		var card_ = c.split("_")
		ranks_only.append(card_[0])
		suits_only.append(card_[1])

	var counts = {}
	for r in ranks_only:
		counts[r] = counts.get(r, 0) + 1

	var values = counts.values()
	values.sort()
	var is_flush = suits_only.all(func(s): return s == suits_only[0])
	var is_straight = is_consecutive(ranks_only)
	suits_only.sort()
	var elem = is_elem(suits_only)
	var result = ""
	var damage = 0
	if 5 in values:
		result = "Покер"
		damage = 60
	elif is_straight and is_flush:
		result = "Стрит-флеш"
		damage = 50
	elif 4 in values:
		result = "Каре"
		damage = 40
	elif 3 in values and 2 in values:
		result = "Фулл-хаус"
		damage = 35
	elif is_flush:
		result = "Флеш"
		damage = 30
	elif is_straight:
		result = "Стрит"
		damage = 25
	elif 3 in values:
		result = "Сет"
		damage = 20
	elif values.count(2) == 2:
		result = "Две пары"
		damage = 15
	elif 2 in values:
		result = "Пара"
		damage = 10
	else:
		var highest = get_rank_value(ranks_only[ranks_only.size() - 1])
		result = "Старшая карта"
		damage = int(highest / 2)

	var comb_text = "" 
	match elem:
		"F":
			return {"result": result + " ОГНЯ" + "  |  Урон:  " + str(floor(damage*1.25)),
			"damage": damage, "elem": elem, "comb": result}

		"W":
			return {"result": result + " ВОДЫ" + "  |  Лечение:  " + str(floor(damage*water_coef)),
			"damage": damage, "elem": elem, "comb": result}
		"A":
			return {"result": result + " ВОЗДУХА"  + "  |  Урон:  " + str(damage) + "  |  Возможен двойной удар",
			"damage": damage, "elem": elem, "comb": result}

		"E":
			return {"result": result + " ЗЕМЛИ"  + "  |  Щит:  " + str(floor(damage*earth_coef)),
			"damage": damage, "elem": elem, "comb": result}
		null:
			return {"result": result + "  |  Урон:  " + str(damage), "damage": damage, "elem": elem, "comb": result}
	return {"result": result + "  |  Урон:  " + str(damage),
	"damage": damage, "elem": elem, "comb": result}

func update_ui():
	
	$HeroPlayer/PlayerHPLabel.text = str(player_hp)
	$HeroEnemy/EnemyHPLabel.text = str(enemy_hp)
	$HeroPlayer/PlayerShieldLabel.text = str(player_shield)
	$HeroEnemy/EnemyShieldLabel.text = str(enemy_shield)
	$UI/RedrawButton/Label.text = str(redraws_left)
	if redraws_left <= 0:
		$UI/RedrawButton.disabled = true 

func get_rank_value(card_str):
	var rank = card_str.split("_")[0]
	var val_map = {"2":2, "3":3, "4":4, "5":5, "6":6, "7":7, "8":8,
				   "9":9, "10":10, "J":11, "Q":12, "K":13, "A":14}
	return val_map.get(rank, 0)

func is_consecutive(rank_list):
	var val_list = []
	for r in rank_list:
		val_list.append(get_rank_value(r))
	val_list.sort()
	for i in range(val_list.size() - 1):
		if val_list[i+1] != val_list[i] + 1:
			return false
	return true

func is_elem(suits_):
	if suits_[0] == suits_[3] :
		return suits_[0]
	elif suits_[1] == suits_[4]:	
		return suits_[1]
	return "none"

func is_elem_buff(elem, damage):
	
	return
	
func start_enemy_turn():
	$UI/EndTurnButton.disabled = true
	$UI/RedrawButton.disabled = true
	
	turn_count += 1
	is_player_turn = false
	update_ui()
	
	# Показываем карты противника на время его хода
	#show_enemy_cards()
	
	# Задержка перед ходом ИИ (для визуального эффекта)
	await get_tree().create_timer(1).timeout
	
	enemy_redraws_left = 2
	# ИИ делает ход
	
	if BattleState.start_mode == "puppet":
		enemy_redraw_cards()
		await get_tree().create_timer(1.5).timeout
	else:
		for i in range(2):
			enemy_redraw_cards()
			await get_tree().create_timer(1.5).timeout		
	
	# Проверяем комбинацию после хода
	var enemy_hand = []
	for card in $EnemyArea/EnemyCards.get_children():
		enemy_hand.append(card.text)
	
	var enemy_result = evaluate_poker_hand(enemy_hand)
	enemy_comb_result = enemy_result
	$UI/EnemyResultLabel.text = enemy_result.result
	#$UI/EnemyResultLabel.text = enemy_result.result + " | Заклинание исполнено!"
	$UI/EnemyResultLabel.visible = true
	#print(turn_count, "en")
	if turn_count % 2 == 0:
		round_end()
	else:
		player_turn()
		is_player_turn = true
	return		

func count_player_comb_damage():
	if player_comb_result.damage > 0:
		var old_enemy_hp = enemy_hp
		match player_comb_result.elem:
			"F":
				if enemy_shield > 0:
					enemy_hp = max(0, enemy_hp - max(floor(player_comb_result.damage*1.25) - enemy_shield, 0))
					enemy_shield = max(enemy_shield - player_comb_result.damage*1.25, 0)
					#$HeroPlayerAttackTexture/DamageLabel.text = "-" + str(floor(player_comb_result.damage*1.25) - enemy_shield)
				else:	
					enemy_hp = max(0, enemy_hp - floor(player_comb_result.damage*1.25))
					#$HeroPlayerAttackTexture/DamageLabel.text = "-" + str(floor(player_comb_result.damage*1.25))
				$HeroPlayerAttackTexture/DamageLabel.text = "-" + str(old_enemy_hp - enemy_hp)
				battle_elements_sfx.stream = load("res://sounds/fire.wav")	
				$HeroPlayerAttack.play("attack_enemy")					
			"W":
				player_hp = min(100, player_hp + floor(player_comb_result.damage*water_coef))
				play_battle_elements_sfx("water")
			"A":
				var flag = false
				if randf() < 0.5:
					player_comb_result.damage *= 2
					flag = true
				if enemy_shield > 0:
					enemy_hp = max(0, enemy_hp - max(player_comb_result.damage - enemy_shield, 0))
					enemy_shield = max(enemy_shield - player_comb_result.damage, 0)
					#$HeroPlayerAttackTexture/DamageLabel.text = "-" + str(player_comb_result.damage - enemy_shield)				
				else:	
					enemy_hp = max(0, enemy_hp - player_comb_result.damage)
					#$HeroPlayerAttackTexture/DamageLabel.text = "-" + str(player_comb_result.damage)
				$HeroPlayerAttackTexture/DamageLabel.text = "-" + str(old_enemy_hp - enemy_hp)	
				if flag:
					$UI/PlayerResultLabel.text = player_comb_result.comb + " ВОЗДУХА"  + "  |  Урон:  " + str(player_comb_result.damage) + "  |  Двойной удар"
					battle_elements_sfx.stream = load("res://sounds/air.wav")
				else:
					$UI/PlayerResultLabel.text = player_comb_result.comb + " ВОЗДУХА"  + "  |  Урон:  " + str(player_comb_result.damage) + "  |  Промах"
					battle_elements_sfx.stream = load("res://sounds/air_miss.wav")
				$HeroPlayerAttack.play("attack_enemy")
					
			"E":
				player_shield += floor(player_comb_result.damage*earth_coef)
				play_battle_elements_sfx("earth")
			"none":			
				if enemy_shield > 0:
					enemy_hp = max(0, enemy_hp - max(player_comb_result.damage - enemy_shield, 0))
					enemy_shield = max(enemy_shield - player_comb_result.damage, 0)
					#$HeroPlayerAttackTexture/DamageLabel.text = "-" + str(player_comb_result.damage - enemy_shield)
				else:	
					enemy_hp = max(0, enemy_hp - player_comb_result.damage)
					#$HeroPlayerAttackTexture/DamageLabel.text = "-" + str(player_comb_result.damage)
				$HeroPlayerAttackTexture/DamageLabel.text = "-" + str(old_enemy_hp - enemy_hp)
				battle_elements_sfx.stream = load("res://sounds/hit.wav")
				$HeroPlayerAttack.play("attack_enemy")
		player_comb_result.damage = 0
	update_ui()
	return
	
func count_enemy_comb_damage():
	if enemy_comb_result.damage > 0:
		var old_player_hp = player_hp
		match enemy_comb_result.elem:
			"F":
				if player_shield > 0:
					player_hp = max(0, player_hp - max(floor(enemy_comb_result.damage*1.25) - player_shield, 0))
					player_shield = max(player_shield - enemy_comb_result.damage, 0)
					#$HeroEnemyAttackTexture/DamageLabelPlayer.text = "-" + str(floor(enemy_comb_result.damage*1.25) - player_shield)
				else:	
					player_hp = max(0, player_hp - floor(enemy_comb_result.damage*1.25))
					#$HeroEnemyAttackTexture/DamageLabelPlayer.text = "-" + str(floor(enemy_comb_result.damage*1.25))
				$HeroEnemyAttackTexture/DamageLabelPlayer.text = "-" + str(old_player_hp - player_hp)
				battle_elements_sfx.stream = load("res://sounds/fire.wav")
				$EnemyPlayerAttack.play("attack_player")
				
			"W":
				enemy_hp = min(100, enemy_hp + floor(enemy_comb_result.damage*water_coef))
				play_battle_elements_sfx("water")
			"A":
				if randf() < 0.5:
					enemy_comb_result.damage *= 2
					$UI/EnemyResultLabel.text = enemy_comb_result.comb + " ВОЗДУХА"  + "  |  Урон:  " + str(enemy_comb_result.damage) + "  |  Двойной удар"	
					battle_elements_sfx.stream = load("res://sounds/air.wav")
				else:
					$UI/EnemyResultLabel.text = enemy_comb_result.comb + " ВОЗДУХА"  + "  |  Урон:  " + str(enemy_comb_result.damage) + "  |  Промах"	
					battle_elements_sfx.stream = load("res://sounds/air_miss.wav")
				if player_shield > 0:
					player_hp = max(0, player_hp - max(enemy_comb_result.damage - player_shield, 0))
					player_shield = max(player_shield - enemy_comb_result.damage, 0)
				else:	
					player_hp = max(0, player_hp - enemy_comb_result.damage)
				$HeroEnemyAttackTexture/DamageLabelPlayer.text = "-" + str(old_player_hp - player_hp)
				$EnemyPlayerAttack.play("attack_player")
			"E":
				enemy_shield += floor(enemy_comb_result.damage*earth_coef)
				play_battle_elements_sfx("earth")
					
			"none":			
				if player_shield > 0:
					player_hp = max(0, player_hp - max(enemy_comb_result.damage - player_shield, 0))
					player_shield = max(player_shield - enemy_comb_result.damage, 0)
					#$HeroEnemyAttackTexture/DamageLabelPlayer.text = "-" + str(enemy_comb_result.damage - player_shield)
				else:	
					player_hp = max(0, player_hp - enemy_comb_result.damage)
					#$HeroEnemyAttackTexture/DamageLabelPlayer.text = "-" + str(enemy_comb_result.damage)
				$HeroEnemyAttackTexture/DamageLabelPlayer.text = "-" + str(old_player_hp - player_hp)
				battle_elements_sfx.stream = load("res://sounds/hit.wav")
				$EnemyPlayerAttack.play("attack_player")
				
		enemy_comb_result.damage = 0
	update_ui()
	return

func round_end():
	if first_turn:
		count_enemy_comb_damage()
		await get_tree().create_timer(1.5).timeout
		count_player_comb_damage()		
	else:
		count_player_comb_damage()
		await get_tree().create_timer(1.5).timeout
		count_enemy_comb_damage()

	# Скрываем карты противника
	#hide_enemy_cards()
	update_ui()
	if player_hp == 0 or enemy_hp == 0:
		await get_tree().create_timer(1.5).timeout
		var round_text = ""
		var round_texture = ""
		if player_hp == 0 and enemy_hp == 0:
			round_text = "НИЧЬЯ"
			round_texture =	"res://textures/misc/shield_draw.png"
			play_battle_sfx_result("draw")	
		elif enemy_hp == 0:
			round_text = "ПОБЕДА"
			round_texture = "res://textures/misc/shield_win.png"
			play_battle_sfx_result("win")
		elif player_hp == 0:
			round_text = "ПОРАЖЕНИЕ"
			round_texture = "res://textures/misc/shield_lose.png"
			play_battle_sfx_result("lose")
			
		$UI/Round.text = round_text
		#$UI/RoundResultIcon.visible = true
		$UI/RoundResultIcon.texture = load(round_texture)
		show_overlay()
		#$UI/ToMenu.visible = true	
		$UI/RedrawButton.disabled = true
		$UI/EndTurnButton.disabled = true
		match_over = true	
	else:
		await get_tree().create_timer(2.5).timeout
		redraws_left = 2
		enemy_redraws_left = 2
		redraw_cards()
		redraw_enemy_cards()
		var enemy_hand = []
		for card in $EnemyArea/EnemyCards.get_children():
			enemy_hand.append(card.text)
		var enemy_result = evaluate_poker_hand(enemy_hand)				
		update_ui()
		$UI/EnemyResultLabel.text = enemy_result.result
		first_turn = !first_turn
		if first_turn:
			player_turn()
		else:
			start_enemy_turn()	
	return

func play_battle_sfx_result(sound):
	var tween = create_tween()
	tween.tween_property(battle_bgm, "volume_db", -15, 1)
	battle_sfx.volume_db = 0
	battle_sfx.stream = load("res://sounds/%s.wav" % sound)
	battle_sfx.play()
	tween.tween_property(battle_bgm, "volume_db", 0, 5)
	return

func _input(event):
	if not match_over:
		return
		
	if event is InputEventMouseButton and event.pressed:
			get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

@onready var fade = $UI/FadeOverlay
@onready var round_shield = $UI/RoundResultIcon
@onready var label_round = $UI/Round
@onready var label_to_menu = $UI/ToMenu

func show_overlay():
	fade.modulate.a = 0.0
	round_shield.visible = false
	fade.visible = true
	
	# Затемнение
	var tween = create_tween()
	tween.tween_property(fade, "modulate:a", 0.8, 0.5)  # затемняем до 70% за 1 сек

	# Показываем картинку после затемнения
	tween.tween_callback(Callable(self, "show_image_and_labels"))

func show_image_and_labels():
	for node in [round_shield, label_round, label_to_menu]:
		node.visible = true
		node.modulate.a = 0.0
	var tween = create_tween().set_parallel(true)
	tween.tween_property(round_shield, "modulate:a", 1, 0.5)
	tween.tween_property(label_round, "modulate:a", 1, 0.5)
	tween.chain().tween_property(label_to_menu, "modulate:a", 1.2, 0.7)
	tween.chain().tween_callback(blink_label_forever)

func blink_label_forever():
	var tween = create_tween().set_loops()  # бесконечно
	tween.tween_property(label_to_menu, "modulate:a", 0.3, 0.8)
	tween.tween_property(label_to_menu, "modulate:a", 1.4, 0.5)

			
func ai_select_cards_to_redraw():
	var cards = $EnemyArea/EnemyCards.get_children()
	var card_values = []
	
	# Анализируем текущие карты
	for card in cards:
		var value = evaluate_single_card(card.text, cards)
		card_values.append({
			"card": card,
			"value": value
		})
	
	# Сортируем карты по их полезности (чем меньше value, тем хуже карта)
	card_values.sort_custom(func(a, b): return a["value"] < b["value"])
	
	# Определяем сколько карт менять (1-2 в зависимости от ситуации)
	var cards_to_change = []
	var change_count = determine_optimal_change_count(card_values)
	
	# Берем худшие карты для замены
	for i in range(change_count):
		cards_to_change.append(card_values[i]["card"])
	
	return cards_to_change

func evaluate_single_card(card_text, all_cards):
	if card_text == "??":
		return 100  # Максимально плохая "карта"
	
	var card_ = card_text.split("_")
	var rank = card_[0]
	var suit = card_[1]
	
	# Анализируем комбинации
	var rank_count = 0
	var suit_count = 0
	
	for c in all_cards:
		if c.text == "??":
			continue
			
		if c.text.split("_")[0] == rank:
			rank_count += 1
		
		if c.text[-1] == suit:
			suit_count += 1
	
	var value = 0
	
	value += rank_count * 10
	
	value += suit_count * 5
	
	value += get_rank_value(card_text) * 0.5
	
	return -value

func determine_optimal_change_count(card_values):
	# Если есть очень плохие карты - меняем 2
	if card_values[0]["value"] < -15 or card_values[1]["value"] < -10:
		return min(2, enemy_redraws_left)
	
	# Если все карты средние - меняем 1
	return 1
	
func show_enemy_cards():
	for card in $EnemyArea/EnemyCards.get_children():
		card.modulate = Color(1, 1, 1)
		# Добавляем текст карты поверх текстуры
		var label = Label.new()
		label.text = card.text
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_font_size_override("font_size", 20)
		card.add_child(label)

func hide_enemy_cards():
	for card in $EnemyArea/EnemyCards.get_children():
		card.modulate = Color(0.5, 0.5, 0.5)
		# Удаляем текст карты
		for child in card.get_children():
			if child is Label:
				child.queue_free()
				
func enemy_redraw_cards():
	# Получаем текущие карты противника
	var enemy_cards = $EnemyArea/EnemyCards.get_children()
	var current_hand = []
	var cur_hand = []
	var hand_suit = []
	for card in enemy_cards:
		if card.text != "??":
			hand_suit.append(card.text.split("_")[1])
			current_hand.append(card.text)
			cur_hand.append(card.text)
		
	# Анализируем текущую комбинацию
	var hand_evaluation = evaluate_poker_hand(cur_hand)
	var cards_to_redraw = []
	# Стратегия в зависимости от силы текущей комбинации
	match hand_evaluation.comb:
		"Стрит-флеш", "Покер", "Каре":
			# Не менять карты для сильных комбинаций
			return
		"Фулл-хаус":
			# Меняем одну карту не входящую в комбинацию
			#cards_to_redraw = find_non_matching_cards(enemy_cards, current_hand, true)
			return
		"Флеш":
			# Пытаемся улучшить до стрит-флеша
			#cards_to_redraw = find_flush_improvement_cards(enemy_cards, current_hand)
			return
		"Стрит":
			# Пытаемся улучшить до стрит-флеша
			#cards_to_redraw = find_straight_improvement_cards(enemy_cards, current_hand)
			return
		"Сет":
			# Пытаемся сделать фулл-хаус или каре
			cards_to_redraw = find_non_matching_cards(enemy_cards, current_hand)
		"Две пары":
			# Пытаемся сделать фулл-хаус
			cards_to_redraw = find_non_two_pair_card(enemy_cards, current_hand)
		"Пара":
			# Пытаемся сделать тройку или две пары
			cards_to_redraw = find_non_pair_cards(enemy_cards, current_hand)
		"Старшая карта":
			# Для старшей карты - меняем 2-3 худшие карты
			#cards_to_redraw = find_weakest_cards(enemy_cards, current_hand, 3)
			cards_to_redraw = enemy_cards
	# Ограничиваем количество замен по оставшимся попыткам
	#cards_to_redraw = cards_to_redraw.slice(0, enemy_redraws_left)
	# Выполняем замену карт
	#print(cards_to_redraw)
	if cards_to_redraw.size() > 0:
		var used_cards = []
		for card in enemy_cards:
			if card.text != "??" and not cards_to_redraw.has(card):
				used_cards.append(card.text)
		
		for card in cards_to_redraw:

			var new_card = generate_unique_card_villain(used_cards)
			card.text = new_card
			var card_ = card.text.split("_")
			var texture_rect = card.get_node("TextureRect")
			texture_rect.texture = load("res://textures/cards/%s_%s.png" % [card_[0], card_[1]])
			var front = card.get_node("TextureRect")
			var back = card.get_node("Back")
			flip(card, front, back, false)		
			used_cards.append(new_card)
		
		enemy_redraws_left -= cards_to_redraw.size()
		
		var sec_hand = []
		for card in enemy_cards:
			if card.text != "??":
				sec_hand.append(card.text)
		
		var res = evaluate_poker_hand(sec_hand)
		
		$UI/EnemyResultLabel.text = res.result

		
# Вспомогательные функции для ИИ
func find_non_matching_cards(cards, current_hand):
	var counts = {}
	
	for card in current_hand:
		var rank = card.split("_")[0]
		counts[rank] = counts.get(rank, 0) + 1
	var to_redraw = []
	for i in range(cards.size()):
		var card_rank = cards[i].text.split("_")[0]
		if counts.get(card_rank, 0) < 3:
			to_redraw.append(cards[i])
	return to_redraw

func find_flush_improvement_cards(cards, current_hand):
	var suit_counts = {}
	for card in current_hand:
		var suit = card[-1]
		suit_counts[suit] = suit_counts.get(suit, 0) + 1
	
	var flush_suit = ""
	for suit in suit_counts:
		if suit_counts[suit] >= 3:
			flush_suit = suit
			break
	
	var to_redraw = []
	if flush_suit != "":
		for card in cards:
			if card.text[-1] != flush_suit:
				to_redraw.append(card)
	
	return to_redraw.slice(0, 2)  # Меняем не более 2 карт

func find_straight_improvement_cards(cards, current_hand):
	var ranks_ = []
	for card in current_hand:
		ranks_.append(card.split("_")[0])
	
	# Находим разрывы в последовательности
	var gaps = []
	for i in range(1, ranks_.size()):
		var diff = get_rank_value(ranks_[i]) - get_rank_value(ranks_[i-1])
		if diff > 1:
			gaps.append(i)
	
	var to_redraw = []
	if gaps.size() == 1:
		# Меняем карту рядом с разрывом
		var gap_pos = gaps[0]
		if gap_pos < ranks_.size() - 1:
			to_redraw.append(cards[gap_pos])
		else:
			to_redraw.append(cards[gap_pos-1])
	
	return to_redraw

func find_non_two_pair_card(cards, current_hand):
	var counts = {}
	var first_index = {}
	var i = 0
	for card in current_hand:
		var rank = card.split("_")[0]
		counts[rank] = counts.get(rank, 0) + 1
		if not first_index.has(rank):
			first_index[rank] = i
		i += 1	
	for num in counts:
		if counts[num] == 1:
			return [cards[first_index[num]]]
			
	return []

func find_non_pair_cards(cards, current_hand):
	var pair_rank = ""
	for card in current_hand:
		var rank = card.split("_")[0]
		if current_hand.filter(func(c): return c.split("_")[0] == rank).size() == 2:
			pair_rank = rank
			break
	
	var to_redraw = []
	for card in cards:
		if card.text.split("_")[0] != pair_rank:
			to_redraw.append(card)
	
	return to_redraw.slice(0, 3)  # Меняем не более 2 карт

func find_weakest_cards(cards, current_hand, max_cards: int):
	var card_values = []
	for i in range(cards.size()):
		var value = get_rank_value(cards[i].text)
		card_values.append({"card": cards[i], "value": value})
	
	card_values.sort_custom(func(a, b): return a["value"] < b["value"])
	var to_redraw = []
	for i in range(min(max_cards, card_values.size())):
		to_redraw.append(card_values[i]["card"])
	
	return to_redraw

func redraw_enemy_cards():
	var slots = $EnemyArea/EnemyCards.get_children()
	var used = []
	var new_hand = []
	for card in slots:
		var new_card = ""
		var rank = ""
		var suit = ""
		while true:
			rank = ranks[randi() % ranks.size()]
			suit = suits_villain[randi() % suits_villain.size()]	
			new_card = rank + "_" + suit
			if not new_card in used:
				used.append(new_card)
				break
		card.text = new_card
		new_hand.append(new_card)
				
		var texture_rect = card.get_node("TextureRect")
		texture_rect.texture = load("res://textures/cards/%s_%s.png" % [rank, suit])
		var front = card.get_node("TextureRect")
		var back = card.get_node("Back")
		flip(card, front, back, false)
		card.remove_theme_stylebox_override("normal")
	selected_cards.clear()
	redraws_left = 2
	
	var res = evaluate_poker_hand(new_hand)
	$UI/EnemyResultLabel.text = res.result
	
	check_combination()
	update_ui()
