extends Control

signal restart_requested
signal menu_requested
signal theme_changed_request
signal diff_changed_request(new_diff: BotAI.Difficulty)
signal ult_activated_request
signal music_toggled(is_enabled: bool)
signal sfx_toggled(is_enabled: bool)

@onready var mode_label: Label = $TopBar/VBox/TopRow/ModeLabel
@onready var diff_btn: Button = $TopBar/VBox/TopRow/DiffBtn
@onready var turn_label: Label = $TopBar/VBox/ScoreRow/TurnLabel
@onready var score_label: Label = $TopBar/VBox/ScoreRow/ScoreLabel

# Hero & Ultimate UI in BottomDeck
@onready var hero_box: VBoxContainer = $BottomDeck/VBox/HeroBox
@onready var hero_label: Label = $BottomDeck/VBox/HeroBox/HeroLabel
@onready var ult_bar: ProgressBar = $BottomDeck/VBox/HeroBox/UltProgressBar
@onready var ult_btn: Button = $BottomDeck/VBox/HeroBox/UltButton

@onready var theme_btn: Button = $BottomDeck/VBox/ButtonRow/ThemeBtn
@onready var restart_button: Button = $BottomDeck/VBox/ButtonRow/RestartButton
@onready var menu_button: Button = $BottomDeck/VBox/ButtonRow/MenuButton
@onready var music_check: CheckBox = $BottomDeck/VBox/AudioRow/MusicCheck
@onready var sfx_check: CheckBox = $BottomDeck/VBox/AudioRow/SfxCheck

@onready var win_dialog: PanelContainer = $WinDialog
@onready var win_label: Label = $WinDialog/VBox/WinLabel
@onready var play_again_btn: Button = $WinDialog/VBox/PlayAgainButton
@onready var win_menu_btn: Button = $WinDialog/VBox/WinMenuButton

var is_single_player: bool = false
var is_arcade_mode: bool = true
var current_diff: BotAI.Difficulty = BotAI.Difficulty.MEDIUM
var diff_names = ["EASY", "MED", "HARD"]

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

func set_mode_display(single_player: bool, arcade: bool, diff: BotAI.Difficulty) -> void:
	is_single_player = single_player
	is_arcade_mode = arcade
	current_diff = diff
	diff_btn.visible = single_player
	hero_box.visible = is_arcade_mode
	
	if is_arcade_mode:
		mode_label.text = "ARCADE: VS BOT" if is_single_player else "ARCADE: 2P"
	else:
		mode_label.text = "CLASSIC: VS BOT" if is_single_player else "CLASSIC: 2P"
	
	if is_single_player:
		diff_btn.text = "AI: " + diff_names[current_diff]

func update_hero_ui(hero_name: String, hero_icon: String, ult_name: String, energy_val: float, is_ready: bool) -> void:
	if not hero_box.visible:
		return
	hero_label.text = "%s %s" % [hero_icon, hero_name]
	ult_bar.value = energy_val
	if is_ready:
		ult_btn.disabled = false
		ult_btn.text = "⚡ %s (READY!)" % ult_name
		ult_btn.modulate = Color(1.0, 1.0, 0.2)
	else:
		ult_btn.disabled = true
		ult_btn.text = "🔒 %s (%d%%)" % [ult_name, int(energy_val)]
		ult_btn.modulate = Color(0.7, 0.7, 0.7)

func _on_diff_pressed() -> void:
	var next_val = (int(current_diff) + 1) % 3
	current_diff = BotAI.Difficulty.values()[next_val]
	diff_btn.text = "AI: " + diff_names[current_diff]
	emit_signal("diff_changed_request", current_diff)

func update_theme_label(theme_name: String) -> void:
	if theme_btn:
		theme_btn.text = theme_name

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

func sync_audio_ui(music_on: bool, sfx_on: bool) -> void:
	if music_check:
		music_check.button_pressed = music_on
	if sfx_check:
		sfx_check.button_pressed = sfx_on
