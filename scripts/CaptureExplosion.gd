class_name CaptureExplosion
extends Node2D

var color: Color = Color.WHITE

func setup(p_color: Color) -> void:
	color = p_color

func _ready() -> void:
	# 1. Shockwave ring effect
	var shockwave = ShockwaveRing.new()
	shockwave.color = color
	add_child(shockwave)

	# 2. Main Particle Burst (CPUParticles2D for guaranteed compatibility)
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.lifetime = 0.65
	particles.amount = 36
	particles.direction = Vector2.ZERO
	particles.spread = 180.0
	particles.gravity = Vector2(0, 180) # mild gravity
	particles.initial_velocity_min = 90.0
	particles.initial_velocity_max = 240.0
	particles.scale_amount_min = 4.0
	particles.scale_amount_max = 8.0
	particles.color = color
	particles.hue_variation_min = -0.1
	particles.hue_variation_max = 0.1

	# Color ramp curve to fade out smoothly
	var grad = Gradient.new()
	grad.colors = PackedColorArray([color, Color(1, 1, 1, 1), Color(color.r, color.g, color.b, 0)])
	grad.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
	particles.color_ramp = grad

	add_child(particles)

	# 3. Gold spark stars
	var sparks = CPUParticles2D.new()
	sparks.emitting = true
	sparks.one_shot = true
	sparks.explosiveness = 0.9
	sparks.lifetime = 0.5
	sparks.amount = 16
	sparks.direction = Vector2.ZERO
	sparks.spread = 180.0
	sparks.gravity = Vector2.ZERO
	sparks.initial_velocity_min = 120.0
	sparks.initial_velocity_max = 280.0
	sparks.scale_amount_min = 3.0
	sparks.scale_amount_max = 5.0
	sparks.color = Color(1.0, 0.88, 0.2)
	add_child(sparks)

	# Auto-free after animation finishes
	get_tree().create_timer(1.0).timeout.connect(queue_free)


# Sub-node for expanding shockwave ring
class ShockwaveRing extends Node2D:
	var radius: float = 10.0
	var alpha: float = 1.0
	var color: Color = Color.WHITE

	func _ready() -> void:
		var tween = create_tween()
		tween.tween_property(self, "radius", 55.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(self, "alpha", 0.0, 0.35)
		tween.tween_callback(queue_free)

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(color.r, color.g, color.b, alpha), 4.0, true)
