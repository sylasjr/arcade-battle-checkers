extends Control

signal restart_requested
signal menu_requested
signal theme_changed_request
signal diff_changed_request(new_diff: BotAI.Difficulty)
signal ult_activated_request
signal music_toggled(is_enabled: bool)
signal sfx_toggled(is_enabled: bool)
signal music_volume_changed(volume: float)
signal sfx_volume_changed(volume: float)

@onready var mode_label: Label = $Panel/VBoxContainer/ModeLabel
@onready var turn_label: Label = $Panel/VBoxContainer/TurnLabel
@onready var score_label: Label = $Panel/VBoxContainer/ScoreLabel
@onready var theme_btn: Button = $Panel/VBoxContainer/ThemeBtn
@onready var diff_btn: Button = $Panel/VBoxContainer/DiffBtn
@onready var restart_button: Button = $Panel/VBoxContainer/RestartButton
@onready var menu_button: Button = $Panel/VBoxContainer/MenuButton

# Hero & Ultimate UI in Sidebar
@onready var hero_card: PanelContainer = $Panel/VBoxContainer/HeroCard
@onready var hero_label: Label = $Panel/VBoxContainer/HeroCard/HeroBox/HeroHeader/HeroLabel
@onready var hero_desc: Label = $Panel/VBoxContainer/HeroCard/HeroBox/HeroDesc
@onready var energy_label: Label = $Panel/VBoxContainer/HeroCard/HeroBox/EnergyContainer/EnergyLabel
@onready var ult_bar: ProgressBar = $Panel/VBoxContainer/HeroCard/HeroBox/EnergyContainer/UltProgressBar
@onready var ult_btn: Button = $Panel/VBoxContainer/HeroCard/HeroBox/UltButton
@onready var target_hint: Label = $Panel/VBoxContainer/HeroCard/HeroBox/TargetHint

@onready var music_check: CheckBox = $Panel/VBoxContainer/MusicBox/MusicCheck
@onready var music_slider: HSlider = $Panel/VBoxContainer/MusicBox/MusicSlider
@onready var sfx_check: CheckBox = $Panel/VBoxContainer/SfxBox/SfxCheck
@onready var sfx_slider: HSlider = $Panel/VBoxContainer/SfxBox/SfxSlider

@onready var win_dialog: PanelContainer = $WinDialog
@onready var win_label: Label = $WinDialog/VBox/WinLabel
@onready var play_again_btn: Button = $WinDialog/VBox/PlayAgainButton
@onready var win_menu_btn: Button = $WinDialog/VBox/WinMenuButton

var is_single_player: bool = false
var is_arcade_mode: bool = true
var current_diff: BotAI.Difficulty = BotAI.Difficulty.MEDIUM
var diff_names = ["EASY", "MEDIUM", "HARD", "💀 NIGHTMARE"]
var ready_pulse_tween: Tween = null

func _ready() -> void:
	win_dialog.visible = false
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	theme_btn.pressed.connect(func(): emit_signal("theme_changed_request"))
	diff_btn.pressed.connect(_on_diff_pressed)
	ult_btn.pressed.connect(func(): emit_signal("ult_activated_request"))
	play_again_btn.pressed.connect(_on_restart_pressed)
	win_menu_btn.pressed.connect(_on_menu_pressed)
	music_check.toggled.connect(_on_music_toggled)
	sfx_check.toggled.connect(_on_sfx_toggled)
	music_slider.value_changed.connect(func(val): emit_signal("music_volume_changed", val))
	sfx_slider.value_changed.connect(func(val): emit_signal("sfx_volume_changed", val))

func set_mode_display(single_player: bool, arcade: bool, diff: BotAI.Difficulty) -> void:
	is_single_player = single_player
	is_arcade_mode = arcade
	current_diff = diff
	diff_btn.visible = single_player
	hero_card.visible = is_arcade_mode
	
	if is_arcade_mode:
		mode_label.text = "ARCADE: VS BOT" if is_single_player else "ARCADE: 2P"
	else:
		mode_label.text = "CLASSIC: VS BOT" if is_single_player else "CLASSIC: 2P"
	
	_update_diff_button_style()

func update_hero_ui(hero_name: String, hero_icon: String, ult_name: String, desc_text: String, energy_val: float, is_ready: bool, is_targeting: bool = false) -> void:
	if not hero_card.visible:
		return
	hero_label.text = "%s %s" % [hero_icon, hero_name]
	hero_desc.text = desc_text
	ult_bar.value = energy_val
	target_hint.visible = is_targeting

	ult_btn.pivot_offset = ult_btn.size * 0.5

	if is_targeting:
		if ready_pulse_tween != null and ready_pulse_tween.is_valid():
			ready_pulse_tween.kill()
		ult_btn.disabled = false
		ult_btn.scale = Vector2.ONE
		ult_btn.text = "🎯 SELECT ENEMY TO CAST"
		ult_btn.modulate = Color(1.0, 0.3, 0.3)
		energy_label.text = "🎯 SELECT ENEMY TARGET"
		energy_label.modulate = Color(1.0, 0.3, 0.3)
	elif is_ready:
		ult_btn.disabled = false
		ult_btn.text = "⚡ CAST: %s ⚡" % ult_name
		energy_label.text = "✨ ULTIMATE READY! (100%) ✨"
		
		if ready_pulse_tween == null or not ready_pulse_tween.is_valid():
			ready_pulse_tween = create_tween().set_loops()
			# Vibrant multi-color & scale pulse between Electric Cyan and Radiant Gold
			ready_pulse_tween.tween_property(ult_btn, "scale", Vector2(1.06, 1.06), 0.45).set_trans(Tween.TRANS_SINE)
			ready_pulse_tween.parallel().tween_property(ult_btn, "modulate", Color(0.2, 1.0, 0.85), 0.45).set_trans(Tween.TRANS_SINE)
			ready_pulse_tween.parallel().tween_property(energy_label, "modulate", Color(0.2, 1.0, 0.85), 0.45).set_trans(Tween.TRANS_SINE)
			
			ready_pulse_tween.tween_property(ult_btn, "scale", Vector2(1.0, 1.0), 0.45).set_trans(Tween.TRANS_SINE)
			ready_pulse_tween.parallel().tween_property(ult_btn, "modulate", Color(1.0, 0.88, 0.15), 0.45).set_trans(Tween.TRANS_SINE)
			ready_pulse_tween.parallel().tween_property(energy_label, "modulate", Color(1.0, 0.88, 0.15), 0.45).set_trans(Tween.TRANS_SINE)
	else:
		if ready_pulse_tween != null and ready_pulse_tween.is_valid():
			ready_pulse_tween.kill()
		ult_btn.scale = Vector2.ONE
		ult_btn.disabled = true
		ult_btn.text = "🔒 %s (%d%%)" % [ult_name, int(energy_val)]
		ult_btn.modulate = Color(0.65, 0.65, 0.7)
		energy_label.text = "⚡ ULTIMATE: %d%%" % int(energy_val)
		energy_label.modulate = Color(0.4, 0.85, 1.0)

func _on_diff_pressed() -> void:
	var next_val = (int(current_diff) + 1) % 4
	current_diff = BotAI.Difficulty.values()[next_val]
	_update_diff_button_style()
	emit_signal("diff_changed_request", current_diff)

func _update_diff_button_style() -> void:
	if not is_single_player:
		return
	diff_btn.text = "AI: " + diff_names[current_diff]
	if current_diff == BotAI.Difficulty.NIGHTMARE:
		diff_btn.modulate = Color(1.0, 0.25, 0.25)
	elif current_diff == BotAI.Difficulty.HARD:
		diff_btn.modulate = Color(1.0, 0.65, 0.2)
	elif current_diff == BotAI.Difficulty.MEDIUM:
		diff_btn.modulate = Color(0.4, 0.8, 1.0)
	else:
		diff_btn.modulate = Color(0.6, 1.0, 0.6)

func update_theme_label(theme_name: String) -> void:
	if theme_btn:
		theme_btn.text = "Theme: " + theme_name

func update_turn(player: Piece.Player) -> void:
	if player == Piece.Player.RED:
		turn_label.text = "TURN: RED (P1)"
		turn_label.modulate = Color(1.0, 0.4, 0.4)
	else:
		if is_single_player:
			turn_label.text = "TURN: BOT"
		else:
			turn_label.text = "TURN: BLACK (P2)"
		turn_label.modulate = Color(0.4, 0.8, 1.0)

func update_counts(red_count: int, black_count: int) -> void:
	score_label.text = "R: %d | B: %d" % [red_count, black_count]

func show_game_over(winner: Piece.Player) -> void:
	var winner_name = "RED" if winner == Piece.Player.RED else "BLACK"
	win_label.text = "🏆 %s WINS!" % winner_name
	win_dialog.visible = true

func _on_restart_pressed() -> void:
	win_dialog.visible = false
	emit_signal("restart_requested")

func _on_menu_pressed() -> void:
	win_dialog.visible = false
	emit_signal("menu_requested")

func _on_music_toggled(button_pressed: bool) -> void:
	emit_signal("music_toggled", button_pressed)

func _on_sfx_toggled(button_pressed: bool) -> void:
	emit_signal("sfx_toggled", button_pressed)

func sync_audio_ui(music_on: bool, sfx_on: bool, music_vol: float = 0.28, sfx_vol: float = 0.14) -> void:
	if music_check:
		music_check.button_pressed = music_on
	if sfx_check:
		sfx_check.button_pressed = sfx_on
	if music_slider:
		music_slider.value = music_vol
	if sfx_slider:
		sfx_slider.value = sfx_vol
