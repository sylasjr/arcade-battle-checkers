extends Node2D

@onready var board: Board = $Board
@onready var ui: Control = $UI
@onready var menu: Control = $Menu
@onready var hero_select: Control = $HeroSelect
@onready var combo_banner: ComboBanner = $ComboBanner
@onready var theme_manager: ThemeManager = $ThemeManager
@onready var audio_manager: AudioManager = $AudioManager
@onready var camera: Camera2D = $Camera2D
@onready var background: ColorRect = $Background

var hero_manager: HeroManager = HeroManager.new()
var explosion_script = preload("res://scripts/CaptureExplosion.gd")

var is_music_enabled: bool = true
var is_sfx_enabled: bool = true
var current_bot_diff: BotAI.Difficulty = BotAI.Difficulty.MEDIUM
var is_arcade_mode: bool = true
var pending_is_single_player: bool = true

func _ready() -> void:
	board.hero_manager = hero_manager

	theme_manager.theme_changed.connect(_on_theme_changed)
	_on_theme_changed(theme_manager.get_theme_data())

	show_menu()

	# Menu signals
	menu.play_arcade_selected.connect(_on_start_arcade_mode)
	menu.play_classic_selected.connect(_on_start_classic_mode)
	menu.theme_changed_request.connect(theme_manager.next_theme)
	menu.music_toggled.connect(_on_music_toggled)
	menu.sfx_toggled.connect(_on_sfx_toggled)
	menu.music_volume_changed.connect(_on_music_volume_changed)
	menu.sfx_volume_changed.connect(_on_sfx_volume_changed)

	# Hero Select signals
	hero_select.hero_chosen.connect(_on_hero_chosen)
	hero_select.selection_completed.connect(_on_hero_selection_done)

	# In-game UI signals
	ui.restart_requested.connect(board.start_new_game)
	ui.menu_requested.connect(show_menu)
	ui.theme_changed_request.connect(theme_manager.next_theme)
	ui.diff_changed_request.connect(_on_diff_changed)
	ui.ult_activated_request.connect(board.activate_ultimate_request)
	ui.music_toggled.connect(_on_music_toggled)
	ui.sfx_toggled.connect(_on_sfx_toggled)
	ui.music_volume_changed.connect(_on_music_volume_changed)
	ui.sfx_volume_changed.connect(_on_sfx_volume_changed)

	# Board signals
	board.turn_changed.connect(_on_turn_changed)
	board.piece_count_updated.connect(ui.update_counts)
	board.game_over.connect(ui.show_game_over)
	board.piece_selected.connect(func(_p): audio_manager.play_select())
	board.piece_moved.connect(audio_manager.play_move)
	board.piece_captured.connect(_on_piece_captured)
	board.piece_ignited.connect(_on_piece_ignited)
	board.combo_scored.connect(_on_combo_scored)
	board.powerup_triggered.connect(_on_powerup_triggered)
	board.energy_gained.connect(_on_energy_gained)
	board.king_promoted.connect(_on_king_promoted)
	board.ultimate_targeting_changed.connect(func(_targeting): _update_hero_hud())
	board.game_over.connect(func(_winner): audio_manager.play_win())

func _on_theme_changed(t_data: Dictionary) -> void:
	background.color = t_data.get("bg_color", Color(0.08, 0.09, 0.12))
	board.apply_theme(t_data)
	var t_name = t_data.get("name", "Classic")
	menu.update_theme_label(t_name)
	ui.update_theme_label(t_name)

func show_menu() -> void:
	menu.visible = true
	hero_select.visible = false
	ui.visible = false
	board.visible = false
	board.set_process_unhandled_input(false)
	_sync_audio_states()

func _on_start_arcade_mode(is_single_player: bool, diff: BotAI.Difficulty) -> void:
	is_arcade_mode = true
	pending_is_single_player = is_single_player
	current_bot_diff = diff
	menu.visible = false
	hero_select.start_selection(is_single_player)

func _on_start_classic_mode(is_single_player: bool, diff: BotAI.Difficulty) -> void:
	is_arcade_mode = false
	pending_is_single_player = is_single_player
	current_bot_diff = diff
	menu.visible = false
	_launch_game()

func _on_hero_chosen(player: Piece.Player, h_class: HeroManager.HeroClass) -> void:
	if player == Piece.Player.RED:
		hero_manager.p1_hero = h_class
	else:
		hero_manager.p2_hero = h_class

func _on_hero_selection_done() -> void:
	hero_select.visible = false
	_launch_game()

func _launch_game() -> void:
	ui.visible = true
	board.visible = true
	board.set_process_unhandled_input(true)
	
	board.is_arcade_mode = is_arcade_mode
	board.bot_enabled = pending_is_single_player
	board.bot_difficulty = current_bot_diff
	
	ui.set_mode_display(pending_is_single_player, is_arcade_mode, current_bot_diff)
	_sync_audio_states()
	
	board.start_new_game()
	_update_hero_hud()

func _on_turn_changed(player: Piece.Player) -> void:
	ui.update_turn(player)
	_update_hero_hud()

func _on_energy_gained(player: Piece.Player, _amount: float) -> void:
	_update_hero_hud()

func _update_hero_hud() -> void:
	if not is_arcade_mode:
		return
	var h_data = hero_manager.get_hero_data(board.current_player)
	var energy = hero_manager.get_energy(board.current_player)
	var is_ready = hero_manager.is_ult_ready(board.current_player)
	ui.update_hero_ui(h_data.name, h_data.icon, h_data.ult_name, h_data.desc, energy, is_ready, board.is_targeting_ult)

func _on_diff_changed(new_diff: BotAI.Difficulty) -> void:
	current_bot_diff = new_diff
	board.bot_difficulty = new_diff

func _on_music_toggled(enabled: bool) -> void:
	is_music_enabled = enabled
	audio_manager.toggle_music(enabled)
	_sync_audio_states()

func _on_sfx_toggled(enabled: bool) -> void:
	is_sfx_enabled = enabled
	audio_manager.toggle_sfx(enabled)
	_sync_audio_states()

func _on_music_volume_changed(vol: float) -> void:
	audio_manager.set_music_volume(vol)
	_sync_audio_states()

func _on_sfx_volume_changed(vol: float) -> void:
	audio_manager.set_sfx_volume(vol)
	_sync_audio_states()

func _sync_audio_states() -> void:
	ui.sync_audio_ui(is_music_enabled, is_sfx_enabled, audio_manager.music_volume, audio_manager.sfx_volume)
	menu.set_audio_states(is_music_enabled, is_sfx_enabled, audio_manager.music_volume, audio_manager.sfx_volume)

func _on_piece_captured(world_pos: Vector2, victim_player: Piece.Player) -> void:
	audio_manager.play_capture()
	if camera and camera.has_method("trigger_shake"):
		camera.trigger_shake(8.0)

	var explosion = explosion_script.new()
	var victim_color = theme_manager.get_theme_data().get("red_main", Color(0.95, 0.3, 0.25)) if victim_player == Piece.Player.RED else theme_manager.get_theme_data().get("black_main", Color(0.3, 0.5, 0.9))
	explosion.setup(victim_color)
	explosion.position = world_pos
	add_child(explosion)
	_update_hero_hud()

func _on_powerup_triggered(p_type: PowerUpManager.PowerType, world_pos: Vector2) -> void:
	audio_manager.play_powerup(p_type)
	if camera and camera.has_method("trigger_shake"):
		camera.trigger_shake(10.0 if p_type == PowerUpManager.PowerType.BOMB else 5.0)

func _on_combo_scored(count: int) -> void:
	combo_banner.trigger_combo(count)
	audio_manager.play_combo()
	if camera and camera.has_method("trigger_shake"):
		camera.trigger_shake(12.0)
	_update_hero_hud()

func _on_piece_ignited(world_pos: Vector2) -> void:
	audio_manager.play_fire_ignite()
	if camera and camera.has_method("trigger_shake"):
		camera.trigger_shake(14.0)

func _on_king_promoted() -> void:
	audio_manager.play_king()
	if camera and camera.has_method("trigger_shake"):
		camera.trigger_shake(4.0)
