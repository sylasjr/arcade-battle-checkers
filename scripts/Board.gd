class_name Board
extends Node2D

signal turn_changed(current_player: Piece.Player)
signal piece_selected(piece: Piece)
signal game_over(winner: Piece.Player)
signal piece_count_updated(red_count: int, black_count: int)

# Audio & Juice signals
signal piece_moved
signal piece_captured(world_pos: Vector2, victim_player: Piece.Player)
signal king_promoted
signal piece_ignited(world_pos: Vector2)
signal combo_scored(streak_count: int)
signal powerup_triggered(power_type: PowerUpManager.PowerType, world_pos: Vector2)
signal energy_gained(player: Piece.Player, amount: float)

const BOARD_SIZE = 8
const TILE_SIZE = 80.0

@export var piece_scene: PackedScene = preload("res://scenes/Piece.tscn")

var grid: Dictionary = {}
var current_player: Piece.Player = Piece.Player.RED
var selected_piece: Piece = null
var valid_moves: Array[Dictionary] = []
var is_multi_jumping: bool = false
var bot_enabled: bool = false
var bot_player: Piece.Player = Piece.Player.BLACK
var bot_difficulty: BotAI.Difficulty = BotAI.Difficulty.MEDIUM

# Game Mode & PowerUps
var is_arcade_mode: bool = true
var powerup_manager: PowerUpManager = PowerUpManager.new()
var hero_manager: HeroManager = null # Injected by Main

# Targeting state for Ultimate abilities
var is_targeting_ult: bool = false
var targeting_hero_class: HeroManager.HeroClass = HeroManager.HeroClass.PYROMANCER

# Streak tracking
var current_turn_kills: int = 0
var turn_counter: int = 0

# Visual highlights & Themes
var hovered_tile: Vector2i = Vector2i(-1, -1)
var theme_data: Dictionary = {}

func _ready() -> void:
	start_new_game()

func apply_theme(p_theme: Dictionary) -> void:
	theme_data = p_theme
	for p in grid.values():
		if is_instance_valid(p):
			p.apply_theme(p_theme)
	queue_redraw()

func start_new_game() -> void:
	for p in grid.values():
		if is_instance_valid(p):
			p.queue_free()
	grid.clear()
	powerup_manager.clear()
	selected_piece = null
	valid_moves.clear()
	is_multi_jumping = false
	is_targeting_ult = false
	current_turn_kills = 0
	turn_counter = 0
	current_player = Piece.Player.RED

	if hero_manager:
		hero_manager.reset_energy()

	for y in range(BOARD_SIZE):
		for x in range(BOARD_SIZE):
			if (x + y) % 2 != 0:
				if y < 3:
					spawn_piece(Piece.Player.BLACK, Vector2i(x, y))
				elif y > 4:
					spawn_piece(Piece.Player.RED, Vector2i(x, y))

	# Spawn initial power-ups if in Arcade Mode
	if is_arcade_mode:
		_spawn_arcade_powerup()

	emit_counts()
	emit_signal("turn_changed", current_player)
	queue_redraw()

func spawn_piece(player: Piece.Player, pos: Vector2i) -> Piece:
	var p: Piece = piece_scene.instantiate()
	add_child(p)
	p.setup(player, pos, TILE_SIZE, theme_data)
	grid[pos] = p
	return p

func _spawn_arcade_powerup() -> void:
	var empty_tiles: Array[Vector2i] = []
	for y in range(BOARD_SIZE):
		for x in range(BOARD_SIZE):
			var pos = Vector2i(x, y)
			if (x + y) % 2 != 0 and not grid.has(pos) and not powerup_manager.active_powers.has(pos):
				empty_tiles.append(pos)
	powerup_manager.spawn_random_powerup(empty_tiles)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var mouse_tile = world_to_grid(to_local(event.position))
		if mouse_tile != hovered_tile:
			hovered_tile = mouse_tile
			queue_redraw()

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if bot_enabled and current_player == bot_player:
			return
		var click_pos = world_to_grid(to_local(event.position))
		handle_click(click_pos)

func world_to_grid(world_pos: Vector2) -> Vector2i:
	var x = int(floor(world_pos.x / TILE_SIZE))
	var y = int(floor(world_pos.y / TILE_SIZE))
	return Vector2i(x, y)

func is_in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < BOARD_SIZE and pos.y >= 0 and pos.y < BOARD_SIZE

func handle_click(clicked_pos: Vector2i) -> void:
	if not is_in_bounds(clicked_pos):
		return

	# If currently aiming an Ultimate Ability
	if is_targeting_ult:
		_execute_targeted_ult(clicked_pos)
		return

	if is_multi_jumping:
		for move in valid_moves:
			if move.dest == clicked_pos:
				execute_move(selected_piece, move)
				return
		return

	if selected_piece != null:
		for move in valid_moves:
			if move.dest == clicked_pos:
				execute_move(selected_piece, move)
				return

	if grid.has(clicked_pos):
		var piece = grid[clicked_pos]
		if piece.player == current_player:
			select_piece(piece)
			return

	deselect_piece()

func select_piece(piece: Piece) -> void:
	selected_piece = piece
	valid_moves = get_piece_moves(piece)
	
	var all_jumps = get_all_jumps_for_player(current_player)
	if all_jumps.size() > 0:
		valid_moves = valid_moves.filter(func(m): return m.is_jump)

	emit_signal("piece_selected", piece)
	queue_redraw()

func deselect_piece() -> void:
	selected_piece = null
	valid_moves.clear()
	queue_redraw()

func get_piece_moves(piece: Piece) -> Array[Dictionary]:
	var moves: Array[Dictionary] = []
	var dirs: Array[Vector2i] = []

	if piece.is_king or piece.has_lightning:
		dirs = [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]
	elif piece.player == Piece.Player.RED:
		dirs = [Vector2i(-1, -1), Vector2i(1, -1)]
	else:
		dirs = [Vector2i(-1, 1), Vector2i(1, 1)]

	for d in dirs:
		var target_pos = piece.grid_pos + d
		if is_in_bounds(target_pos) and not grid.has(target_pos):
			moves.append({
				"dest": target_pos,
				"jumped": null,
				"is_jump": false
			})
		elif is_in_bounds(target_pos) and grid.has(target_pos):
			var victim: Piece = grid[target_pos]
			if victim.player != piece.player:
				var jump_landing = target_pos + d
				if is_in_bounds(jump_landing) and not grid.has(jump_landing):
					moves.append({
						"dest": jump_landing,
						"jumped": victim,
						"is_jump": true
					})

	return moves

func get_all_jumps_for_player(p_player: Piece.Player) -> Array[Dictionary]:
	var jumps: Array[Dictionary] = []
	for pos in grid:
		var p: Piece = grid[pos]
		if p.player == p_player:
			for m in get_piece_moves(p):
				if m.is_jump:
					jumps.append({ "piece": p, "move": m })
	return jumps

func execute_move(piece: Piece, move: Dictionary) -> void:
	var old_pos = piece.grid_pos
	var new_pos = move.dest
	grid.erase(old_pos)
	grid[new_pos] = piece

	piece.move_to(new_pos)

	# Consume lightning overcharge if used
	if piece.has_lightning:
		piece.consume_lightning()

	if not move.is_jump:
		emit_signal("piece_moved")
		if is_arcade_mode and hero_manager:
			hero_manager.add_energy(current_player, 15.0)
			emit_signal("energy_gained", current_player, 15.0)

	# Handle capture
	if move.is_jump and move.jumped != null:
		current_turn_kills += 1
		var jumped_piece: Piece = move.jumped
		
		# Check if victim has an Energy Shield!
		if jumped_piece.has_shield:
			jumped_piece.break_shield()
			emit_signal("powerup_triggered", PowerUpManager.PowerType.SHIELD, to_global(jumped_piece.position))
		else:
			var victim_world_pos = to_global(jumped_piece.position)
			var victim_player = jumped_piece.player
			grid.erase(jumped_piece.grid_pos)
			
			var tween = create_tween()
			tween.tween_property(jumped_piece, "scale", Vector2(1.3, 0.3), 0.08)
			tween.tween_property(jumped_piece, "scale", Vector2.ZERO, 0.12)
			tween.parallel().tween_property(jumped_piece, "modulate:a", 0.0, 0.12)
			tween.tween_callback(jumped_piece.queue_free)

			emit_signal("piece_captured", victim_world_pos, victim_player)
			emit_counts()

			if is_arcade_mode and hero_manager:
				var e_gain = 35.0 if current_turn_kills == 1 else 60.0
				hero_manager.add_energy(current_player, e_gain)
				emit_signal("energy_gained", current_player, e_gain)

			if current_turn_kills >= 2:
				emit_signal("combo_scored", current_turn_kills)
				piece.ignite_fire(2.0)
				emit_signal("piece_ignited", to_global(piece.position))

	# Check and trigger Power-Up landing
	if is_arcade_mode and powerup_manager.active_powers.has(new_pos):
		_handle_powerup_landing(piece, new_pos)

	# Check King Promotion
	var promoted = false
	if not piece.is_king:
		if (piece.player == Piece.Player.RED and new_pos.y == 0) or (piece.player == Piece.Player.BLACK and new_pos.y == BOARD_SIZE - 1):
			piece.promote_to_king()
			promoted = true
			emit_signal("king_promoted")

	# Multi-jump continuation
	if move.is_jump and not promoted:
		var next_jumps = get_piece_moves(piece).filter(func(m): return m.is_jump)
		if next_jumps.size() > 0:
			selected_piece = piece
			valid_moves = next_jumps
			is_multi_jumping = true
			queue_redraw()
			return

	is_multi_jumping = false
	current_turn_kills = 0
	deselect_piece()
	switch_turn()

func _handle_powerup_landing(piece: Piece, pos: Vector2i) -> void:
	var p_data = powerup_manager.get_power(pos)
	var p_type = p_data.type
	emit_signal("powerup_triggered", p_type, to_global(piece.position))

	if p_type == PowerUpManager.PowerType.BOMB:
		# Bomb explodes adjacent cross enemies
		var cross_dirs = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]
		for d in cross_dirs:
			var target_pos = pos + d
			if grid.has(target_pos):
				var adj_p: Piece = grid[target_pos]
				if adj_p.player != piece.player:
					if adj_p.has_shield:
						adj_p.break_shield()
					else:
						grid.erase(target_pos)
						emit_signal("piece_captured", to_global(adj_p.position), adj_p.player)
						adj_p.queue_free()
		emit_counts()

	elif p_type == PowerUpManager.PowerType.PORTAL:
		var dest_portal = p_data.linked_portal
		if dest_portal != Vector2i(-1, -1) and not grid.has(dest_portal):
			grid.erase(pos)
			grid[dest_portal] = piece
			piece.move_to(dest_portal, true)

	elif p_type == PowerUpManager.PowerType.SHIELD:
		piece.give_shield()

	elif p_type == PowerUpManager.PowerType.LIGHTNING:
		piece.give_lightning()

	powerup_manager.remove_power(pos)
	queue_redraw()

func switch_turn() -> void:
	turn_counter += 1
	current_turn_kills = 0
	current_player = Piece.Player.BLACK if current_player == Piece.Player.RED else Piece.Player.RED
	emit_signal("turn_changed", current_player)

	# Spawn occasional new powerups in Arcade Mode every 3 turns
	if is_arcade_mode and turn_counter % 3 == 0:
		_spawn_arcade_powerup()

	queue_redraw()
	check_game_over()

	if bot_enabled and current_player == bot_player:
		trigger_bot_turn()

func check_game_over() -> void:
	var red_pieces = 0
	var black_pieces = 0
	var red_has_moves = false
	var black_has_moves = false

	for pos in grid:
		var p: Piece = grid[pos]
		if p.player == Piece.Player.RED:
			red_pieces += 1
			if get_piece_moves(p).size() > 0:
				red_has_moves = true
		else:
			black_pieces += 1
			if get_piece_moves(p).size() > 0:
				black_has_moves = true

	if red_pieces == 0 or (current_player == Piece.Player.RED and not red_has_moves):
		emit_signal("game_over", Piece.Player.BLACK)
	elif black_pieces == 0 or (current_player == Piece.Player.BLACK and not black_has_moves):
		emit_signal("game_over", Piece.Player.RED)

# --- Hero Ultimate System ---

func activate_ultimate_request() -> void:
	if not hero_manager or not hero_manager.is_ult_ready(current_player):
		return

	var h_data = hero_manager.get_hero_data(current_player)
	var h_class = hero_manager.get_hero(current_player)

	if h_class == HeroManager.HeroClass.TITAN:
		# Titan instantly shields 2 friendly pieces
		hero_manager.consume_ult(current_player)
		_cast_titan_ult()
	else:
		# Pyromancer / Void Rogue enter targeting mode
		is_targeting_ult = true
		targeting_hero_class = h_class
		queue_redraw()

func _cast_titan_ult() -> void:
	var friendlies: Array[Piece] = []
	for pos in grid:
		var p: Piece = grid[pos]
		if p.player == current_player and not p.has_shield:
			friendlies.append(p)
	friendlies.shuffle()
	for i in range(mini(2, friendlies.size())):
		friendlies[i].give_shield()
		emit_signal("powerup_triggered", PowerUpManager.PowerType.SHIELD, to_global(friendlies[i].position))
	queue_redraw()

func _execute_targeted_ult(clicked_pos: Vector2i) -> void:
	is_targeting_ult = false
	
	if not grid.has(clicked_pos):
		queue_redraw()
		return

	var target_p: Piece = grid[clicked_pos]
	var opp_player = Piece.Player.BLACK if current_player == Piece.Player.RED else Piece.Player.RED

	if targeting_hero_class == HeroManager.HeroClass.PYROMANCER:
		# Meteor strike obliterates enemy checker
		if target_p.player == opp_player:
			hero_manager.consume_ult(current_player)
			grid.erase(clicked_pos)
			emit_signal("piece_captured", to_global(target_p.position), target_p.player)
			emit_signal("piece_ignited", to_global(target_p.position))
			target_p.queue_free()
			emit_counts()
			switch_turn()

	elif targeting_hero_class == HeroManager.HeroClass.VOID_ROGUE:
		# Swap friendly with enemy
		if target_p.player == opp_player:
			var friendly_pieces: Array[Piece] = []
			for pos in grid:
				if grid[pos].player == current_player:
					friendly_pieces.append(grid[pos])
			if friendly_pieces.size() > 0:
				hero_manager.consume_ult(current_player)
				var my_p = friendly_pieces.pick_random()
				var my_old_pos = my_p.grid_pos
				grid[clicked_pos] = my_p
				grid[my_old_pos] = target_p
				my_p.move_to(clicked_pos, true)
				target_p.move_to(my_old_pos, true)
				emit_signal("powerup_triggered", PowerUpManager.PowerType.PORTAL, to_global(my_p.position))
				switch_turn()

	queue_redraw()

func trigger_bot_turn() -> void:
	await get_tree().create_timer(0.55).timeout
	if current_player != bot_player:
		return

	# Bot automatically activates Ultimate if ready!
	if is_arcade_mode and hero_manager and hero_manager.is_ult_ready(bot_player):
		var bot_h = hero_manager.get_hero(bot_player)
		if bot_h == HeroManager.HeroClass.TITAN:
			hero_manager.consume_ult(bot_player)
			_cast_titan_ult()
		elif bot_h == HeroManager.HeroClass.PYROMANCER:
			var enemies: Array[Piece] = []
			for pos in grid:
				if grid[pos].player == Piece.Player.RED:
					enemies.append(grid[pos])
			if enemies.size() > 0:
				var victim = enemies.pick_random()
				hero_manager.consume_ult(bot_player)
				grid.erase(victim.grid_pos)
				emit_signal("piece_captured", to_global(victim.position), victim.player)
				emit_signal("piece_ignited", to_global(victim.position))
				victim.queue_free()
				emit_counts()
				switch_turn()
				return

	var all_bot_moves: Array[Dictionary] = []
	for pos in grid:
		var p: Piece = grid[pos]
		if p.player == bot_player:
			for m in get_piece_moves(p):
				all_bot_moves.append({ "piece": p, "move": m })

	if all_bot_moves.size() > 0:
		var chosen = BotAI.select_move(grid, all_bot_moves, bot_difficulty, bot_player, self)
		if not chosen.is_empty():
			execute_move(chosen.piece, chosen.move)
			while is_multi_jumping and selected_piece != null and valid_moves.size() > 0:
				await get_tree().create_timer(0.35).timeout
				var sub_moves: Array[Dictionary] = []
				for m in valid_moves:
					sub_moves.append({ "piece": selected_piece, "move": m })
				var next_chosen = BotAI.select_move(grid, sub_moves, bot_difficulty, bot_player, self)
				if not next_chosen.is_empty():
					execute_move(selected_piece, next_chosen.move)

func emit_counts() -> void:
	var red = 0
	var black = 0
	for pos in grid:
		if grid[pos].player == Piece.Player.RED:
			red += 1
		else:
			black += 1
	emit_signal("piece_count_updated", red, black)

func _draw() -> void:
	var light_tile = theme_data.get("board_light", Color(0.93, 0.87, 0.77))
	var dark_tile = theme_data.get("board_dark", Color(0.24, 0.28, 0.36))
	var board_border = theme_data.get("board_border", Color(0.12, 0.14, 0.18))
	var inner_border = theme_data.get("board_inner_border", Color(0.18, 0.20, 0.26))
	var select_glow = theme_data.get("glow_color", Color(0.2, 0.8, 1.0, 0.4))
	var valid_move_dot = Color(0.2, 0.9, 0.4, 0.7)

	var total_w = BOARD_SIZE * TILE_SIZE
	draw_rect(Rect2(-14, -14, total_w + 28, total_w + 28), board_border)
	draw_rect(Rect2(-7, -7, total_w + 14, total_w + 14), inner_border)

	for y in range(BOARD_SIZE):
		for x in range(BOARD_SIZE):
			var is_dark = (x + y) % 2 != 0
			var tile_rect = Rect2(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
			draw_rect(tile_rect, dark_tile if is_dark else light_tile)

			if is_dark:
				draw_rect(Rect2(x * TILE_SIZE + 2, y * TILE_SIZE + 2, 4, 4), Color(1, 1, 1, 0.04))

			if hovered_tile == Vector2i(x, y) and is_dark:
				draw_rect(tile_rect, Color(1, 1, 1, 0.12))

	# Draw Power-Up Orbs on Tiles
	if is_arcade_mode:
		for pos in powerup_manager.active_powers:
			var p_data = powerup_manager.active_powers[pos]
			var center = Vector2(pos.x * TILE_SIZE + TILE_SIZE * 0.5, pos.y * TILE_SIZE + TILE_SIZE * 0.5)
			var icon_color: Color
			if p_data.type == PowerUpManager.PowerType.BOMB:
				icon_color = Color(1.0, 0.3, 0.2, 0.8)
			elif p_data.type == PowerUpManager.PowerType.PORTAL:
				icon_color = Color(0.8, 0.3, 1.0, 0.8)
			elif p_data.type == PowerUpManager.PowerType.SHIELD:
				icon_color = Color(0.2, 0.9, 1.0, 0.8)
			else:
				icon_color = Color(1.0, 0.9, 0.1, 0.8)

			draw_circle(center, 16, icon_color)
			draw_arc(center, 20, 0, TAU, 16, Color(1, 1, 1, 0.85), 2.0)
			# Pixel star badge in center
			draw_rect(Rect2(center.x - 4, center.y - 4, 8, 8), Color.WHITE)

	# Highlight Selected Piece
	if selected_piece != null:
		var p_pos = selected_piece.grid_pos
		var sel_rect = Rect2(p_pos.x * TILE_SIZE, p_pos.y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
		draw_rect(sel_rect, select_glow)

	# Targeting Ultimate Reticle overlay
	if is_targeting_ult:
		draw_rect(Rect2(0, 0, total_w, total_w), Color(1.0, 0.1, 0.1, 0.12))
		if is_in_bounds(hovered_tile):
			var reticle_rect = Rect2(hovered_tile.x * TILE_SIZE, hovered_tile.y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
			draw_rect(reticle_rect, Color(1.0, 0.2, 0.2, 0.5))

	for move in valid_moves:
		var center = Vector2(move.dest.x * TILE_SIZE + TILE_SIZE * 0.5, move.dest.y * TILE_SIZE + TILE_SIZE * 0.5)
		if move.is_jump:
			draw_circle(center, 18, Color(1.0, 0.3, 0.3, 0.75))
			draw_arc(center, 24, 0, TAU, 16, Color(1.0, 0.4, 0.4), 3.0)
		else:
			draw_circle(center, 14, valid_move_dot)
			draw_arc(center, 18, 0, TAU, 16, Color(0.2, 0.9, 0.4), 2.0)
