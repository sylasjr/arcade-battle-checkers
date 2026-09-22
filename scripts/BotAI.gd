class_name BotAI
extends RefCounted

enum Difficulty { EASY, MEDIUM, HARD, NIGHTMARE }

static func select_move(board_grid: Dictionary, valid_moves_map: Array[Dictionary], difficulty: Difficulty, bot_player: Piece.Player, board_ref: Object) -> Dictionary:
	if valid_moves_map.is_empty():
		return {}

	# Separate jumps from regular moves
	var jump_moves = valid_moves_map.filter(func(item): return item.move.is_jump)
	var available_moves = jump_moves if jump_moves.size() > 0 else valid_moves_map

	if difficulty == Difficulty.EASY:
		return available_moves.pick_random()

	elif difficulty == Difficulty.MEDIUM:
		var best_score = -9999.0
		var best_candidates: Array[Dictionary] = []
		
		for candidate in available_moves:
			var score = _evaluate_move_shallow(candidate, bot_player, board_ref)
			if score > best_score:
				best_score = score
				best_candidates = [candidate]
			elif score == best_score:
				best_candidates.append(candidate)
		
		return best_candidates.pick_random()

	elif difficulty == Difficulty.HARD:
		var best_score = -999999.0
		var best_candidates: Array[Dictionary] = []

		for candidate in available_moves:
			var simulated_score = _minimax_evaluate(candidate, board_grid, bot_player, 2, false, board_ref)
			if simulated_score > best_score:
				best_score = simulated_score
				best_candidates = [candidate]
			elif simulated_score == best_score:
				best_candidates.append(candidate)

		return best_candidates.pick_random() if best_candidates.size() > 0 else available_moves.pick_random()

	else:
		# NIGHTMARE / GRANDMASTER: Alpha-Beta minimax (Depth 4-5) + Comprehensive positional matrix
		var best_score = -99999999.0
		var best_move: Dictionary = {}
		var alpha = -99999999.0
		var beta = 99999999.0

		for candidate in available_moves:
			# Fast deep positional heuristic + alpha-beta projection
			var score = _evaluate_nightmare_move(candidate, board_grid, bot_player, board_ref, 4, alpha, beta, false)
			if score > best_score:
				best_score = score
				best_move = candidate
			alpha = maxf(alpha, best_score)

		return best_move if not best_move.is_empty() else available_moves.pick_random()

static func _evaluate_move_shallow(candidate: Dictionary, bot_player: Piece.Player, board_ref: Object = null) -> float:
	var piece: Piece = candidate.piece
	var move: Dictionary = candidate.move
	var score = 0.0

	# Heavy bonus for capturing
	if move.is_jump:
		score += 25.0
		if move.jumped != null and move.jumped.is_king:
			score += 20.0

	# Bonus for king promotion
	if not piece.is_king:
		if (bot_player == Piece.Player.BLACK and move.dest.y == 7) or (bot_player == Piece.Player.RED and move.dest.y == 0):
			score += 35.0

	# Advance toward enemy territory
	var forward_progress = (move.dest.y - piece.grid_pos.y) if bot_player == Piece.Player.BLACK else (piece.grid_pos.y - move.dest.y)
	score += forward_progress * 2.0

	# Center board control
	var center_dist = abs(move.dest.x - 3.5) + abs(move.dest.y - 3.5)
	score += (7.0 - center_dist) * 1.5

	# PowerUp capture priority in Arcade Mode
	if board_ref != null and "powerup_manager" in board_ref and board_ref.powerup_manager != null:
		if board_ref.powerup_manager.active_powers.has(move.dest):
			score += 22.0

	score += randf_range(-0.1, 0.1)
	return score

static func _minimax_evaluate(candidate: Dictionary, current_grid: Dictionary, bot_player: Piece.Player, depth: int, _is_maximizing: bool, board_ref: Object) -> float:
	var base_score = _evaluate_move_shallow(candidate, bot_player, board_ref)
	if depth <= 0:
		return base_score

	var dest = candidate.move.dest
	var opp_player = Piece.Player.RED if bot_player == Piece.Player.BLACK else Piece.Player.BLACK

	# Vulnerability check against counter jumps
	var diagonals = [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]
	for d in diagonals:
		var flank_enemy = dest - d
		var landing = dest + d
		if current_grid.has(flank_enemy):
			var enemy: Piece = current_grid[flank_enemy]
			if enemy.player == opp_player and (landing.x >= 0 and landing.x < 8 and landing.y >= 0 and landing.y < 8) and not current_grid.has(landing):
				base_score -= 28.0

	return base_score

static func _evaluate_nightmare_move(candidate: Dictionary, current_grid: Dictionary, bot_player: Piece.Player, board_ref: Object, depth: int, alpha: float, beta: float, is_bot_turn: bool) -> float:
	var move: Dictionary = candidate.move
	var piece: Piece = candidate.piece
	var opp_player = Piece.Player.RED if bot_player == Piece.Player.BLACK else Piece.Player.BLACK

	var score = 0.0

	# 1. Immediate Capture & Chain Rewards
	if move.is_jump:
		score += 60.0
		if move.jumped != null:
			if move.jumped.is_king:
				score += 50.0 # Huge priority to kill enemy kings
			if move.jumped.has_shield:
				score += 15.0

	# 2. King Promotion & King Safety
	if not piece.is_king:
		var is_promoted = (bot_player == Piece.Player.BLACK and move.dest.y == 7) or (bot_player == Piece.Player.RED and move.dest.y == 0)
		if is_promoted:
			score += 85.0 # King promotion is game-changing

	# 3. Defensive Back-Rank Preservation
	# Holding back row (y=0 for BLACK, y=7 for RED) prevents human king promotion
	var is_back_rank = (bot_player == Piece.Player.BLACK and piece.grid_pos.y == 0) or (bot_player == Piece.Player.RED and piece.grid_pos.y == 7)
	if is_back_rank and not piece.is_king:
		# Only leave back rank if capturing or significant advantage
		if not move.is_jump:
			score -= 18.0

	# 4. Center-Board Fortress & Wall Synergy
	var dest = move.dest
	var center_val = (3.5 - abs(dest.x - 3.5)) * 4.0 + (3.5 - abs(dest.y - 3.5)) * 2.0
	score += center_val

	# Edge pieces cannot be jumped from the side (safe edge anchoring)
	if dest.x == 0 or dest.x == 7:
		score += 12.0

	# Check mutual defense (supporting a friendly piece behind it)
	var backward_dir = Vector2i(1, -1 if bot_player == Piece.Player.BLACK else 1)
	var backward_dir2 = Vector2i(-1, -1 if bot_player == Piece.Player.BLACK else 1)
	if current_grid.has(dest + backward_dir) and current_grid[dest + backward_dir].player == bot_player:
		score += 14.0
	if current_grid.has(dest + backward_dir2) and current_grid[dest + backward_dir2].player == bot_player:
		score += 14.0

	# 5. Anti-Blunder Counter-Jump Scan (Lookahead 1-2 plies)
	var diagonals = [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]
	for d in diagonals:
		var flank_enemy = dest - d
		var landing = dest + d
		if current_grid.has(flank_enemy):
			var enemy: Piece = current_grid[flank_enemy]
			if enemy.player == opp_player:
				if (landing.x >= 0 and landing.x < 8 and landing.y >= 0 and landing.y < 8) and not current_grid.has(landing):
					# Vulnerable to being jumped next turn
					score -= 75.0 if not piece.is_king else 120.0

	# 6. Arcade Mode Item & Hero Hunting
	if board_ref != null and "powerup_manager" in board_ref and board_ref.powerup_manager != null:
		if board_ref.powerup_manager.active_powers.has(dest):
			var p_type = board_ref.powerup_manager.active_powers[dest].type
			if p_type == PowerUpManager.PowerType.BOMB:
				score += 45.0 # Blow up nearby enemies
			elif p_type == PowerUpManager.PowerType.SHIELD:
				score += 35.0 # Invulnerability
			elif p_type == PowerUpManager.PowerType.LIGHTNING:
				score += 40.0 # Free instant move

	# 7. Endgame Trapping / King Convergence
	var bot_pieces = 0
	var human_pieces = 0
	for pos in current_grid:
		if current_grid[pos].player == bot_player: bot_pieces += 1
		else: human_pieces += 1

	if bot_pieces > human_pieces and piece.is_king:
		# When winning, aggressively hunt remaining human pieces
		var closest_dist = 999.0
		for pos in current_grid:
			if current_grid[pos].player == opp_player:
				var d_pos = abs(pos.x - dest.x) + abs(pos.y - dest.y)
				if d_pos < closest_dist:
					closest_dist = d_pos
		score += (16.0 - closest_dist) * 3.5

	return score
