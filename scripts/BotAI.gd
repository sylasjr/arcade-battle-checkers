class_name BotAI
extends RefCounted

enum Difficulty { EASY, MEDIUM, HARD }

static func select_move(board_grid: Dictionary, valid_moves_map: Array[Dictionary], difficulty: Difficulty, bot_player: Piece.Player, board_ref: Object) -> Dictionary:
	if valid_moves_map.is_empty():
		return {}

	# Separate jumps from regular moves
	var jump_moves = valid_moves_map.filter(func(item): return item.move.is_jump)
	var available_moves = jump_moves if jump_moves.size() > 0 else valid_moves_map

	if difficulty == Difficulty.EASY:
		# Easy: Pick random available move (prioritizes jump if forced)
		return available_moves.pick_random()

	elif difficulty == Difficulty.MEDIUM:
		# Medium: Greedily evaluate moves (jumps, kinging, advancing, avoiding back row vacancy)
		var best_score = -9999.0
		var best_candidates: Array[Dictionary] = []
		
		for candidate in available_moves:
			var score = _evaluate_move_shallow(candidate, bot_player)
			if score > best_score:
				best_score = score
				best_candidates = [candidate]
			elif score == best_score:
				best_candidates.append(candidate)
		
		return best_candidates.pick_random()

	else:
		# Hard: Minimax with depth 3 evaluation
		var best_score = -999999.0
		var best_candidates: Array[Dictionary] = []

		for candidate in available_moves:
			# Simulate move state
			var simulated_score = _minimax_evaluate(candidate, board_grid, bot_player, 2, false, board_ref)
			if simulated_score > best_score:
				best_score = simulated_score
				best_candidates = [candidate]
			elif simulated_score == best_score:
				best_candidates.append(candidate)

		return best_candidates.pick_random() if best_candidates.size() > 0 else available_moves.pick_random()

static func _evaluate_move_shallow(candidate: Dictionary, bot_player: Piece.Player) -> float:
	var piece: Piece = candidate.piece
	var move: Dictionary = candidate.move
	var score = 0.0

	# Heavy bonus for capturing
	if move.is_jump:
		score += 15.0
		if move.jumped != null and move.jumped.is_king:
			score += 12.0 # Extra bonus for killing an enemy king!

	# Bonus for king promotion
	if not piece.is_king:
		if (bot_player == Piece.Player.BLACK and move.dest.y == 7) or (bot_player == Piece.Player.RED and move.dest.y == 0):
			score += 20.0

	# Advance toward enemy territory
	var forward_progress = (move.dest.y - piece.grid_pos.y) if bot_player == Piece.Player.BLACK else (piece.grid_pos.y - move.dest.y)
	score += forward_progress * 1.5

	# Prefer center control
	var center_dist = abs(move.dest.x - 3.5)
	score += (4.0 - center_dist) * 0.8

	# Small random tie-breaker
	score += randf_range(-0.2, 0.2)
	return score

static func _minimax_evaluate(candidate: Dictionary, current_grid: Dictionary, bot_player: Piece.Player, depth: int, is_maximizing: bool, board_ref: Object) -> float:
	var base_score = _evaluate_move_shallow(candidate, bot_player)
	if depth <= 0:
		return base_score

	# Penalize moving out into immediate counter-jump positions
	var dest = candidate.move.dest
	var opp_player = Piece.Player.RED if bot_player == Piece.Player.BLACK else Piece.Player.BLACK

	# Check neighboring diagonals for vulnerable flank
	var diagonals = [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]
	for d in diagonals:
		var flank_enemy = dest - d
		var landing = dest + d
		if current_grid.has(flank_enemy):
			var enemy: Piece = current_grid[flank_enemy]
			if enemy.player == opp_player and (landing.x >= 0 and landing.x < 8 and landing.y >= 0 and landing.y < 8) and not current_grid.has(landing):
				base_score -= 10.0 # Danger of being jumped back!

	return base_score
