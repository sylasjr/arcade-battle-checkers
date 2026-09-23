extends Control

signal play_arcade_selected(is_single_player: bool, difficulty: BotAI.Difficulty)
signal play_classic_selected(is_single_player: bool, difficulty: BotAI.Difficulty)
signal theme_changed_request
signal music_toggled(is_enabled: bool)
signal sfx_toggled(is_enabled: bool)
signal music_volume_changed(volume: float)
signal sfx_volume_changed(volume: float)

@onready var arcade_single_btn: Button = $VBoxContainer/ArcadeSingleBtn
@onready var arcade_multi_btn: Button = $VBoxContainer/ArcadeMultiBtn
@onready var classic_single_btn: Button = $VBoxContainer/ClassicRow/ClassicSingleBtn
@onready var classic_multi_btn: Button = $VBoxContainer/ClassicRow/ClassicMultiBtn

@onready var diff_btn: Button = $VBoxContainer/DiffContainer/DiffBtn
@onready var theme_btn: Button = $VBoxContainer/ThemeBtn
@onready var music_check: CheckBox = $VBoxContainer/AudioBox/MusicRow/MusicCheck
@onready var music_slider: HSlider = $VBoxContainer/AudioBox/MusicRow/MusicSlider
@onready var sfx_check: CheckBox = $VBoxContainer/AudioBox/SfxRow/SfxCheck
@onready var sfx_slider: HSlider = $VBoxContainer/AudioBox/SfxRow/SfxSlider

var current_diff: BotAI.Difficulty = BotAI.Difficulty.MEDIUM
var diff_names = ["EASY", "MEDIUM", "HARD", "💀 NIGHTMARE"]

func _ready() -> void:
	arcade_single_btn.pressed.connect(func(): emit_signal("play_arcade_selected", true, current_diff))
	arcade_multi_btn.pressed.connect(func(): emit_signal("play_arcade_selected", false, current_diff))
	classic_single_btn.pressed.connect(func(): emit_signal("play_classic_selected", true, current_diff))
	classic_multi_btn.pressed.connect(func(): emit_signal("play_classic_selected", false, current_diff))
	
	diff_btn.pressed.connect(_on_diff_pressed)
	theme_btn.pressed.connect(func(): emit_signal("theme_changed_request"))
	music_check.toggled.connect(func(val): emit_signal("music_toggled", val))
	sfx_check.toggled.connect(func(val): emit_signal("sfx_toggled", val))
	music_slider.value_changed.connect(func(val): emit_signal("music_volume_changed", val))
	sfx_slider.value_changed.connect(func(val): emit_signal("sfx_volume_changed", val))
	_update_diff_label()

func _on_diff_pressed() -> void:
	var next_val = (int(current_diff) + 1) % 4
	current_diff = BotAI.Difficulty.values()[next_val]
	_update_diff_label()

func _update_diff_label() -> void:
	diff_btn.text = "AI Level: " + diff_names[current_diff]
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

func set_audio_states(music_on: bool, sfx_on: bool, music_vol: float = 0.55, sfx_vol: float = 0.55) -> void:
	if music_check:
		music_check.button_pressed = music_on
	if sfx_check:
		sfx_check.button_pressed = sfx_on
	if music_slider:
		music_slider.value = music_vol
	if sfx_slider:
		sfx_slider.value = sfx_vol
