extends Control

signal hero_chosen(player: Piece.Player, hero_class: HeroManager.HeroClass)
signal selection_completed

@onready var prompt_label: Label = $VBox/PromptLabel
@onready var pyro_btn: Button = $VBox/HeroContainer/PyroBtn
@onready var rogue_btn: Button = $VBox/HeroContainer/RogueBtn
@onready var titan_btn: Button = $VBox/HeroContainer/TitanBtn

var selecting_player: Piece.Player = Piece.Player.RED
var is_single_player_mode: bool = true

func _ready() -> void:
	visible = false
	pyro_btn.pressed.connect(func(): _pick_hero(HeroManager.HeroClass.PYROMANCER))
	rogue_btn.pressed.connect(func(): _pick_hero(HeroManager.HeroClass.VOID_ROGUE))
	titan_btn.pressed.connect(func(): _pick_hero(HeroManager.HeroClass.TITAN))

func start_selection(is_single_player: bool) -> void:
	is_single_player_mode = is_single_player
	selecting_player = Piece.Player.RED
	prompt_label.text = "SELECT P1 (RED) COMMANDER"
	visible = true

func _pick_hero(h_class: HeroManager.HeroClass) -> void:
	emit_signal("hero_chosen", selecting_player, h_class)
	
	if is_single_player_mode:
		# Bot picks random hero automatically
		var bot_pick = HeroManager.HeroClass.values().pick_random()
		emit_signal("hero_chosen", Piece.Player.BLACK, bot_pick)
		visible = false
		emit_signal("selection_completed")
	else:
		if selecting_player == Piece.Player.RED:
			selecting_player = Piece.Player.BLACK
			prompt_label.text = "SELECT P2 (BLACK) COMMANDER"
		else:
			visible = false
			emit_signal("selection_completed")
