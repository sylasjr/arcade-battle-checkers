class_name ComboBanner
extends Control

@onready var label: Label = $ComboLabel

var streak_names = {
	2: "2x COMBO!",
	3: "3x MEGA COMBO!!",
	4: "4x ULTRA COMBO!!!",
	5: "5x MONSTER KILL!!!!"
}

func _ready() -> void:
	visible = false
	pivot_offset = size * 0.5

func trigger_combo(count: int) -> void:
	if count < 2:
		return

	var text_content = streak_names.get(count, "%dx GODLIKE COMBO!!!!" % count)
	label.text = text_content

	# Rainbow / Fire color based on combo scale
	if count == 2:
		label.modulate = Color(1.0, 0.85, 0.2) # Gold
	elif count == 3:
		label.modulate = Color(1.0, 0.45, 0.1) # Fire Orange
	else:
		label.modulate = Color(1.0, 0.15, 0.5) # Hot Neon Pink

	visible = true
	scale = Vector2(0.3, 0.3)
	rotation_degrees = randf_range(-10.0, 10.0)
	modulate.a = 1.0

	# Slam into screen with punchy overshoot
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.25, 1.25), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation_degrees", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Slight float & fade out
	var fade_tween = create_tween().set_parallel(false)
	fade_tween.tween_interval(0.55)
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fade_tween.tween_callback(func(): visible = false)
