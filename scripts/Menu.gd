extends Control

signal play_arcade_selected(is_single_player: bool, difficulty: BotAI.Difficulty)
signal play_classic_selected(is_single_player: bool, difficulty: BotAI.Difficulty)
signal theme_changed_request
signal music_toggled(is_enabled: bool)
signal sfx_toggled(is_enabled: bool)

@onready var arcade_single_btn: Button = $VBoxContainer/ArcadeSingleBtn
@onready var arcade_multi_btn: Button = $VBoxContainer/ArcadeMultiBtn
@onready var classic_single_btn: Button = $VBoxContainer/ClassicRow/ClassicSingleBtn
@onready var classic_multi_btn: Button = $VBoxContainer/ClassicRow/ClassicMultiBtn

@onready var diff_btn: Button = $VBoxContainer/DiffContainer/DiffBtn
@onready var theme_btn: Button = $VBoxContainer/ThemeBtn
@onready var music_check: CheckBox = $VBoxContainer/AudioContainer/MusicCheck
@onready var sfx_check: CheckBox = $VBoxContainer/AudioContainer/SfxCheck

var current_diff: BotAI.Difficulty = BotAI.Difficulty.MEDIUM
var diff_names = ["EASY", "MEDIUM", "HARD"]

func _ready() -> void:
	arcade_single_btn.pressed.connect(func(): emit_signal("play_arcade_selected", true, current_diff))
	arcade_multi_btn.pressed.connect(func(): emit_signal("play_arcade_selected", false, current_diff))
	classic_single_btn.pressed.connect(func(): emit_signal("play_classic_selected", true, current_diff))
	classic_multi_btn.pressed.connect(func(): emit_signal("play_classic_selected", false, current_diff))
	
	diff_btn.pressed.connect(_on_diff_pressed)
	theme_btn.pressed.connect(func(): emit_signal("theme_changed_request"))
	music_check.toggled.connect(func(val): emit_signal("music_toggled", val))
	sfx_check.toggled.connect(func(val): emit_signal("sfx_toggled", val))
	_update_diff_label()

func _on_diff_pressed() -> void:
	var next_val = (int(current_diff) + 1) % 3
	current_diff = BotAI.Difficulty.values()[next_val]
	_update_diff_label()

func _update_diff_label() -> void:
	diff_btn.text = "AI Level: " + diff_names[current_diff]

func update_theme_label(theme_name: String) -> void:
	if theme_btn:
		theme_btn.text = "Theme: " + theme_name

func set_audio_states(music_on: bool, sfx_on: bool) -> void:
	if music_check:
		music_check.button_pressed = music_on
	if sfx_check:
		sfx_check.button_pressed = sfx_on
