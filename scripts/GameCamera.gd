extends Camera2D

var shake_strength: float = 0.0
var shake_decay: float = 8.0
var rng = RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()

func trigger_shake(intensity: float = 8.0) -> void:
	shake_strength = intensity

func _process(delta: float) -> void:
	if shake_strength > 0:
		shake_strength = lerp(shake_strength, 0.0, shake_decay * delta)
		offset = Vector2(
			rng.randf_range(-shake_strength, shake_strength),
			rng.randf_range(-shake_strength, shake_strength)
		)
		if shake_strength < 0.1:
			shake_strength = 0.0
			offset = Vector2.ZERO
