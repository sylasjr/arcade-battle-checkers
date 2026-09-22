class_name PowerUpManager
extends RefCounted

enum PowerType { BOMB, PORTAL, SHIELD, LIGHTNING }

const POWER_ICONS = {
	PowerType.BOMB: "💣",
	PowerType.PORTAL: "🌀",
	PowerType.SHIELD: "🛡️",
	PowerType.LIGHTNING: "⚡"
}

# Vector2i (grid pos) -> Dictionary { "type": PowerType, "linked_portal": Vector2i }
var active_powers: Dictionary = {}

func clear() -> void:
	active_powers.clear()

func spawn_random_powerup(valid_empty_tiles: Array[Vector2i]) -> void:
	if valid_empty_tiles.is_empty() or active_powers.size() >= 4:
		return

	var pick_type = PowerType.values().pick_random()

	if pick_type == PowerType.PORTAL:
		# Portals need 2 empty tiles
		if valid_empty_tiles.size() >= 2:
			valid_empty_tiles.shuffle()
			var p1 = valid_empty_tiles.pop_back()
			var p2 = valid_empty_tiles.pop_back()
			active_powers[p1] = { "type": PowerType.PORTAL, "linked_portal": p2 }
			active_powers[p2] = { "type": PowerType.PORTAL, "linked_portal": p1 }
	else:
		var tile = valid_empty_tiles.pick_random()
		active_powers[tile] = { "type": pick_type, "linked_portal": Vector2i(-1, -1) }

func get_power(pos: Vector2i) -> Dictionary:
	return active_powers.get(pos, {})

func remove_power(pos: Vector2i) -> void:
	if active_powers.has(pos):
		var p_data = active_powers[pos]
		if p_data.type == PowerType.PORTAL and p_data.linked_portal != Vector2i(-1, -1):
			active_powers.erase(p_data.linked_portal)
		active_powers.erase(pos)
