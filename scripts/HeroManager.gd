class_name HeroManager
extends RefCounted

enum HeroClass { PYROMANCER, VOID_ROGUE, TITAN }

const HERO_INFO = {
	HeroClass.PYROMANCER: {
		"name": "Pyromancer",
		"icon": "🔥",
		"ult_name": "METEOR STRIKE",
		"desc": "Calls a flaming meteor on any 1 enemy piece!",
		"color": Color(1.0, 0.35, 0.1)
	},
	HeroClass.VOID_ROGUE: {
		"name": "Void Rogue",
		"icon": "⚡",
		"ult_name": "SHADOW SWAP",
		"desc": "Swap positions with an opponent piece!",
		"color": Color(0.7, 0.25, 1.0)
	},
	HeroClass.TITAN: {
		"name": "Titan Knight",
		"icon": "🛡️",
		"ult_name": "IRON WALL",
		"desc": "Grant 2 friendly pieces energy shields!",
		"color": Color(0.2, 0.8, 0.95)
	}
}

var p1_hero: HeroClass = HeroClass.PYROMANCER
var p2_hero: HeroClass = HeroClass.VOID_ROGUE

var p1_energy: float = 0.0
var p2_energy: float = 0.0

const MAX_ENERGY = 100.0

func reset_energy() -> void:
	p1_energy = 25.0 # Start with slight charge for excitement
	p2_energy = 25.0

func add_energy(player: Piece.Player, amount: float) -> void:
	if player == Piece.Player.RED:
		p1_energy = clampf(p1_energy + amount, 0.0, MAX_ENERGY)
	else:
		p2_energy = clampf(p2_energy + amount, 0.0, MAX_ENERGY)

func get_energy(player: Piece.Player) -> float:
	return p1_energy if player == Piece.Player.RED else p2_energy

func is_ult_ready(player: Piece.Player) -> bool:
	return get_energy(player) >= MAX_ENERGY

func consume_ult(player: Piece.Player) -> void:
	if player == Piece.Player.RED:
		p1_energy = 0.0
	else:
		p2_energy = 0.0

func get_hero(player: Piece.Player) -> HeroClass:
	return p1_hero if player == Piece.Player.RED else p2_hero

func get_hero_data(player: Piece.Player) -> Dictionary:
	return HERO_INFO[get_hero(player)]
