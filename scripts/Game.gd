extends Control

var suits = ["F", "W", "E", "A"]
var ranks = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]
var background = ["BG_F", "BG_W", "BG_E", "BG_A"]
#var background = ["BG_F"]
var selected_cards = []
var redraws_left = 2

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
var is_player_turn = true

func _ready():
	redraw_cards()
	redraw_enemy_cards()
	
	$Background.texture = load("res://textures/%s.png" % background[randi() % background.size()])
	$UI/RedrawButton.pressed.connect(on_redraw_pressed)
	$UI/EndTurnButton.pressed.connect(on_end_turn_pressed)
	for card in $PlayerArea/PlayerCards.get_children():
		card.mouse_entered.connect(func(): on_hover_card(card))
		card.mouse_exited.connect(func(): on_unhover_card(card))
		card.pressed.connect(
			func(): 
				if redraws_left > 0:
					toggle_card(card)
		)
	update_ui()

func toggle_card(card):
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
		texture_rect.texture = load("res://textures/%s_%s.png" % [rank, suit])
		card.remove_theme_stylebox_override("normal")
	selected_cards.clear()
	redraws_left -= 1
	check_combination()
	update_ui()

func redraw_cards():
	var slots = $PlayerArea/PlayerCards.get_children()
	var used = []
	for card in slots:
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
		texture_rect.texture = load("res://textures/%s_%s.png" % [rank, suit])
		card.remove_theme_stylebox_override("normal")
	selected_cards.clear()
	redraws_left = 2
	check_combination()
	update_ui()

func on_end_turn_pressed():
	if not is_player_turn:
		return  # Игрок уже передал ход

	is_player_turn = false  # Прекращаем ход игрока
	
	if player_comb_result.damage > 0:
		match player_comb_result.elem:
			"F":
				if enemy_shield > 0:
					enemy_hp = max(0, enemy_hp - max(floor(player_comb_result.damage*1.25) - enemy_shield, 0))
					enemy_shield = 0
				else:	
					enemy_hp = max(0, enemy_hp - floor(player_comb_result.damage*1.25))	
				$UI/PlayerResultLabel.text += " | Заклинание исполнено!"						
			"W":
				player_hp = min(100, player_hp + floor(player_comb_result.damage*water_coef))
				$UI/PlayerResultLabel.text += " | Заклинание исполнено!"
			"A":
				var flag = false
				if randf() < 0.5:
					player_comb_result.damage *= 2
					flag = true
				if enemy_shield > 0:
					enemy_hp = max(0, enemy_hp - max(player_comb_result.damage - enemy_shield, 0))
					enemy_shield = 0
					
				else:	
					enemy_hp = max(0, enemy_hp - player_comb_result.damage)	
				if flag:
					$UI/PlayerResultLabel.text += " | Двойной удар!"
				else:
					$UI/PlayerResultLabel.text += " | Заклинание исполнено!"	
					
			"E":
				player_shield += floor(player_comb_result.damage*earth_coef)
				$UI/PlayerResultLabel.text += " | Заклинание исполнено!"	
			"none":			
				if enemy_shield > 0:
					enemy_hp = max(0, enemy_hp - max(player_comb_result.damage - enemy_shield, 0))
					enemy_shield = 0
				else:	
					enemy_hp = max(0, enemy_hp - player_comb_result.damage)
				$UI/PlayerResultLabel.text += " | Заклинание исполнено!"
		player_comb_result.damage = 0
		
		update_ui()
	start_enemy_turn()
	
func generate_unique_card(used: Array):
	while true:
		var new_card = ranks[randi() % ranks.size()] + "_" + suits[randi() % suits.size()]
		if not new_card in used:
			used.append(new_card)
			return new_card
	return ""

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

	if is_straight and is_flush:
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
			return {"result": "Комбинация: " + result + " стихии огня" + " | Урон: " + str(floor(damage*1.25)),
			"damage": damage, "elem": elem, "comb": result}

		"W":
			return {"result": "Комбинация: " + result + " стихии воды" + " | Лечение: " + str(floor(damage*water_coef)),
			"damage": damage, "elem": elem, "comb": result}
		"A":
			return {"result": "Комбинация: " + result + " стихии воздуха"  + " | Урон: " + str(damage) + " | Возможен двойной удар",
			"damage": damage, "elem": elem, "comb": result}

		"E":
			return {"result": "Комбинация: " + result + " стихии земли"  + " | Щит: " + str(floor(damage*earth_coef)),
			"damage": damage, "elem": elem, "comb": result}
		null:
			return {"result": "Комбинация: " + result + " | Урон: " + str(damage), "damage": damage, "elem": elem, "comb": result}
	return {"result": "Комбинация: " + result + " | Урон: " + str(damage),
	"damage": damage, "elem": elem, "comb": result}

func update_ui():
	
	$UI/PlayerHPLabel.text = "HP Игрока: " + str(player_hp)
	$UI/EnemyHPLabel.text = "HP Врага: " + str(enemy_hp)
	$UI/PlayerBar.value = player_hp
	$UI/EnemyBar.value = enemy_hp
	$UI/PlayerShieldLabel.text = "Щит Игрока: " + str(player_shield)
	$UI/EnemyShieldLabel.text = "Щит Врага: " + str(enemy_shield)
	$UI/RedrawButton.text = "Перераздачи: " + str(redraws_left)
	$UI/RedrawButton.disabled = redraws_left <= 0

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
	is_player_turn = false
	update_ui()
	
	# Показываем карты противника на время его хода
	#show_enemy_cards()
	
	# Задержка перед ходом ИИ (для визуального эффекта)
	await get_tree().create_timer(0.2).timeout
	
	enemy_redraws_left = 2
	# ИИ делает ход
	for i in range(2):
		enemy_redraw_cards()
		await get_tree().create_timer(0.5).timeout
	
	# Проверяем комбинацию после хода
	var enemy_hand = []
	for card in $EnemyArea/EnemyCards.get_children():
		enemy_hand.append(card.text)
	
	var enemy_result = evaluate_poker_hand(enemy_hand)
	enemy_comb_result = enemy_result
	$UI/EnemyResultLabel.text = enemy_result.result + " | Заклинание исполнено!"
	$UI/EnemyResultLabel.visible = true
	
	if enemy_comb_result.damage > 0:
		match enemy_comb_result.elem:
			"F":
				if player_shield > 0:
					player_hp = max(0, player_hp - max(floor(enemy_comb_result.damage*1.25) - player_shield, 0))
					player_shield = 0
				else:	
					player_hp = max(0, player_hp - floor(enemy_comb_result.damage*1.25))							
			"W":
				enemy_hp = min(100, enemy_hp + floor(enemy_comb_result.damage*water_coef))
			"A":
				if randf() < 0.5:
					enemy_comb_result.damage *= 2
				if player_shield > 0:
					player_hp = max(0, player_hp - max(enemy_comb_result.damage - player_shield, 0))
					player_shield = 0
				else:	
					player_hp = max(0, player_hp - enemy_comb_result.damage)	
					
			"E":
				enemy_shield += enemy_comb_result.damage*earth_coef
					
			"none":			
				if player_shield > 0:
					player_hp = max(0, player_hp - max(enemy_comb_result.damage - player_shield, 0))
					player_shield = 0
				else:	
					player_hp = max(0, player_hp - enemy_comb_result.damage)
		enemy_comb_result.damage = 0

	# Скрываем карты противника
	#hide_enemy_cards()
	update_ui()
	if player_hp == 0 and enemy_hp == 0:
		$UI/Round.text = "Ничья"
		$UI/EndTurnButton.disabled = true
	elif player_hp == 0:
		$UI/Round.text = "Вы проиграли"
		$UI/EndTurnButton.disabled = true
	elif enemy_hp == 0:
		$UI/Round.text = "Вы выиграли"
		$UI/EndTurnButton.disabled = true
	else:
		await get_tree().create_timer(2.5).timeout
		is_player_turn = true
		redraws_left = 2
		enemy_redraws_left = 2
		redraw_cards()
		redraw_enemy_cards()
		enemy_hand = []
		for card in $EnemyArea/EnemyCards.get_children():
			enemy_hand.append(card.text)
		enemy_result = evaluate_poker_hand(enemy_hand)				
		update_ui()
		$UI/EnemyResultLabel.text = enemy_result.result

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
	
	# Оцениваем полезность карты
	var value = 0
	
	# Чем больше карт одного ранга, тем лучше
	value += rank_count * 10
	
	# Чем больше карт одной масти, тем лучше
	value += suit_count * 5
	
	# Старшие карты ценнее
	value += get_rank_value(card_text) * 0.5
	
	# Инвертируем значение (чем больше, тем лучше карта)
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
	for card in enemy_cards:
		if card.text != "??":
			current_hand.append(card.text)
	
	# Анализируем текущую комбинацию
	var hand_evaluation = evaluate_poker_hand(current_hand)
	var cards_to_redraw = []
	
	# Стратегия в зависимости от силы текущей комбинации
	match hand_evaluation.comb:
		"Роял-флеш", "Стрит-флеш", "Каре":
			# Не менять карты для сильных комбинаций
			return
		"Фулл-хаус":
			# Меняем одну карту не входящую в комбинацию
			cards_to_redraw = find_non_matching_cards(enemy_cards, current_hand, true)
		"Флеш":
			# Пытаемся улучшить до стрит-флеша
			cards_to_redraw = find_flush_improvement_cards(enemy_cards, current_hand)
		"Стрит":
			# Пытаемся улучшить до стрит-флеша
			cards_to_redraw = find_straight_improvement_cards(enemy_cards, current_hand)
		"Тройка":
			# Пытаемся сделать фулл-хаус или каре
			cards_to_redraw = find_non_matching_cards(enemy_cards, current_hand, false)
		"Две пары":
			# Пытаемся сделать фулл-хаус
			cards_to_redraw = find_weakest_pair_card(enemy_cards, current_hand)
		"Пара":
			# Пытаемся сделать тройку или две пары
			cards_to_redraw = find_non_pair_cards(enemy_cards, current_hand)
		_:
			# Для старшей карты - меняем 2-3 худшие карты
			cards_to_redraw = find_weakest_cards(enemy_cards, current_hand, 3)
	
	# Ограничиваем количество замен по оставшимся попыткам
	cards_to_redraw = cards_to_redraw.slice(0, enemy_redraws_left)
	
	# Выполняем замену карт
	if cards_to_redraw.size() > 0:
		var used_cards = []
		for card in enemy_cards:
			if card.text != "??" and not cards_to_redraw.has(card):
				used_cards.append(card.text)
		
		for card in cards_to_redraw:
			var new_card = generate_unique_card(used_cards)
			card.text = new_card
			var card_ = card.text.split("_")
			var texture_rect = card.get_node("TextureRect")
			texture_rect.texture = load("res://textures/%s_%s.png" % [card_[0], card_[1]])		
			used_cards.append(new_card)
		
		enemy_redraws_left -= cards_to_redraw.size()
		


		
# Вспомогательные функции для ИИ
func find_non_matching_cards(cards, current_hand, keep_pairs: bool):
	var counts = {}
	for card in current_hand:
		var rank = card.split("_")[0]
		counts[rank] = counts.get(rank, 0) + 1
	
	var to_redraw = []
	for i in range(cards.size()):
		var card_rank = cards[i].text.split("_")[0]
		if counts.get(card_rank, 0) <= (2 if keep_pairs else 1):
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

func find_weakest_pair_card(cards, current_hand):
	var rank_values = {}
	for card in current_hand:
		var rank = card.split("_")[0]
		rank_values[rank] = get_rank_value(rank)
	
	var pairs = []
	for rank in rank_values:
		if current_hand.filter(func(c): return c.split("_")[0] == rank).size() == 2:
			pairs.append(rank)
	
	if pairs.size() == 2:
		var weaker_pair = pairs[0] if get_rank_value(pairs[0]) < get_rank_value(pairs[1]) else pairs[1]
		for i in range(cards.size()):
			if cards[i].text.split("_")[0] == weaker_pair:
				return [cards[i]]
	
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
	
	return to_redraw.slice(0, 2)  # Меняем не более 2 карт

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
	for card in slots:
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
		texture_rect.texture = load("res://textures/%s_%s.png" % [rank, suit])
		card.remove_theme_stylebox_override("normal")
	selected_cards.clear()
	redraws_left = 2
	check_combination()
	update_ui()
