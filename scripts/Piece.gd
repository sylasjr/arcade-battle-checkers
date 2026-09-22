class_name Piece
extends Node2D

enum Player { RED = 1, BLACK = 2 }

@export var player: Player = Player.RED
@export var is_king: bool = false
@export var grid_pos: Vector2i = Vector2i.ZERO

var tile_w: float = 76.0
var tile_h: float = 62.0
var target_position: Vector2 = Vector2.ZERO
var is_moving: bool = false

# Arcade Battle Buffs
var has_shield: bool = false
var has_lightning: bool = false

# Streak & Fire state
var is_on_fire: bool = false
var flame_particles: CPUParticles2D = null
var flame_timer: float = 0.0

# Motion Ghost Trail system
var ghost_spawn_timer: float = 0.0
var move_speed: float = 0.26

# Texture & Theme Data
var theme_data: Dictionary = {}
var piece_texture: Texture2D = null

func _ready() -> void:
	update_appearance()

func _process(delta: float) -> void:
	if is_moving:
		ghost_spawn_timer += delta
		if ghost_spawn_timer >= 0.025:
			ghost_spawn_timer = 0.0
			spawn_balanced_ghost()

	if is_on_fire:
		flame_timer -= delta
		if flame_timer <= 0.0:
			extinguish_fire()

func setup(p_player: Player, p_grid_pos: Vector2i, p_tile_w: float, p_tile_h: float, p_theme: Dictionary = {}) -> void:
	player = p_player
	grid_pos = p_grid_pos
	tile_w = p_tile_w
	tile_h = p_tile_h
	theme_data = p_theme
	_load_current_texture()
	position = grid_to_world(grid_pos)
	# Y-sort so lower rows render in front of upper rows
	z_as_relative = false
	z_index = int(position.y)
	queue_redraw()

func apply_theme(p_theme: Dictionary) -> void:
	theme_data = p_theme
	_load_current_texture()
	queue_redraw()

func _load_current_texture() -> void:
	var tex_path = ""
	if is_king:
		if player == Player.RED:
			tex_path = theme_data.get("red_king_texture", "res://textures/runes/crimson_red_star.png")
		else:
			tex_path = theme_data.get("black_king_texture", "res://textures/runes/sand_light_star.png")
	else:
		if player == Player.RED:
			tex_path = theme_data.get("red_texture", "res://textures/runes/crimson_red_cross.png")
		else:
			tex_path = theme_data.get("black_texture", "res://textures/runes/sand_light_circle.png")

	if ResourceLoader.exists(tex_path):
		piece_texture = load(tex_path)

func grid_to_world(coord: Vector2i) -> Vector2:
	return Vector2(coord.x * tile_w + tile_w * 0.5, coord.y * tile_h + tile_h * 0.5)

func give_shield() -> void:
	has_shield = true
	queue_redraw()
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.22, 1.22), 0.15)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)

func break_shield() -> void:
	has_shield = false
	queue_redraw()
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.3, 0.7), 0.08)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.12)

func give_lightning() -> void:
	has_lightning = true
	queue_redraw()

func consume_lightning() -> void:
	has_lightning = false
	queue_redraw()

func ignite_fire(duration: float = 2.0) -> void:
	is_on_fire = true
	flame_timer = duration

	if flame_particles == null:
		flame_particles = CPUParticles2D.new()
		flame_particles.amount = 45
		flame_particles.lifetime = 0.55
		flame_particles.preprocess = 0.1
		flame_particles.explosiveness = 0.05
		flame_particles.direction = Vector2(0, -1)
		flame_particles.spread = 45.0
		flame_particles.gravity = Vector2(0, -60)
		flame_particles.initial_velocity_min = 40.0
		flame_particles.initial_velocity_max = 95.0
		flame_particles.scale_amount_min = 4.0
		flame_particles.scale_amount_max = 9.0
		flame_particles.hue_variation_min = -0.08
		flame_particles.hue_variation_max = 0.08

		var grad = Gradient.new()
		grad.colors = PackedColorArray([
			Color(1.0, 1.0, 0.3, 1.0),
			Color(1.0, 0.55, 0.0, 0.95),
			Color(0.9, 0.15, 0.05, 0.7),
			Color(0.2, 0.2, 0.2, 0.0)
		])
		grad.offsets = PackedFloat32Array([0.0, 0.25, 0.65, 1.0])
		flame_particles.color_ramp = grad
		flame_particles.z_index = 8
		add_child(flame_particles)

	flame_particles.emitting = true
	queue_redraw()

	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.28, 1.28), 0.18)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)

func extinguish_fire() -> void:
	is_on_fire = false
	if flame_particles:
		flame_particles.emitting = false
		var t = create_tween()
		t.tween_interval(0.6)
		t.tween_callback(func():
			if flame_particles:
				flame_particles.queue_free()
				flame_particles = null
		)
	queue_redraw()

func spawn_balanced_ghost() -> void:
	if not get_parent():
		return
	
	var ghost = MotionGhost.new()
	var main_col: Color
	if is_on_fire:
		main_col = Color(1.0, 0.5, 0.1)
	elif has_lightning:
		main_col = Color(0.2, 0.9, 1.0)
	elif player == Player.RED:
		main_col = theme_data.get("red_main", Color(0.55, 0.20, 0.25))
	else:
		main_col = theme_data.get("black_main", Color(0.95, 0.75, 0.45))
	
	ghost.setup(position, tile_w * 0.36, main_col)
	get_parent().add_child(ghost)

func move_to(new_grid_pos: Vector2i, animate: bool = true) -> void:
	grid_pos = new_grid_pos
	var target = grid_to_world(new_grid_pos)
	if animate:
		is_moving = true
		ghost_spawn_timer = 0.0
		z_index = 500 # Top elevation during transit

		spawn_balanced_ghost()

		var tween = create_tween().set_parallel(true)
		tween.tween_property(self, "position", target, move_speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
		# Semi-orthogonal jump arc: upward hop along Y
		var hop_y_offset = -14.0
		var scale_tween = create_tween().set_parallel(false)
		scale_tween.tween_property(self, "scale", Vector2(1.15, 1.15), move_speed * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		scale_tween.tween_property(self, "scale", Vector2(1.0, 1.0), move_speed * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

		tween.chain().tween_callback(func():
			is_moving = false
			z_index = int(position.y)
			queue_redraw()
		)
	else:
		position = target
		z_index = int(position.y)

func promote_to_king() -> void:
	is_king = true
	_load_current_texture()
	queue_redraw()
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.25, 1.25), 0.15)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)

func update_appearance() -> void:
	_load_current_texture()
	queue_redraw()

func _draw() -> void:
	var piece_draw_size = 58.0 # Pixel-perfect crisp size on 76x62 tiles
	var half_s = piece_draw_size * 0.5

	# Semi-orthogonal 3D Ground Shadow (compressed ellipse underneath)
	var shadow_offset = Vector2(0, 8) if is_moving else Vector2(0, 4)
	_draw_custom_ellipse(shadow_offset, half_s * 0.95, half_s * 0.65, Color(0, 0, 0, 0.38))

	# Fire aura ring
	if is_on_fire:
		_draw_custom_ellipse(Vector2.ZERO, half_s * 1.2, half_s * 0.9, Color(1.0, 0.6, 0.1, 0.4))
		draw_arc(Vector2.ZERO, half_s * 1.25, 0, TAU, 16, Color(1.0, 0.85, 0.2, 0.7), 2.5)

	# Shield Energy Dome
	if has_shield:
		_draw_custom_ellipse(Vector2.ZERO, half_s * 1.25, half_s * 0.95, Color(0.1, 0.85, 1.0, 0.35))
		draw_arc(Vector2.ZERO, half_s * 1.3, 0, TAU, 24, Color(0.4, 0.95, 1.0, 0.9), 3.0)

	# Lightning Aura
	if has_lightning:
		draw_arc(Vector2.ZERO, half_s * 1.15, 0, TAU, 16, Color(0.2, 0.9, 1.0, 0.85), 2.5)

	# Draw Precise Pixel Art Texture Sprite (Sits upright in the 3/4 semi-orthogonal tile)
	if piece_texture:
		var rect = Rect2(-half_s, -half_s - 4, piece_draw_size, piece_draw_size)
		draw_texture_rect(piece_texture, rect, false)
	else:
		draw_circle(Vector2.ZERO, half_s, Color(0.5, 0.2, 0.2) if player == Player.RED else Color(0.9, 0.8, 0.5))

	# Pixel King Crown
	if is_king:
		var gold = Color(1.0, 0.84, 0.0)
		var gold_border = Color(0.70, 0.55, 0.0)
		var crown_pts = PackedVector2Array([
			Vector2(-12, 0),
			Vector2(-14, -12),
			Vector2(-6, -7),
			Vector2(0, -16),
			Vector2(6, -7),
			Vector2(14, -12),
			Vector2(12, 0)
		])
		draw_colored_polygon(crown_pts, gold)
		draw_polyline(crown_pts, gold_border, 2.0, true)
		draw_rect(Rect2(-15, -13, 4, 4), Color.WHITE)
		draw_rect(Rect2(-2, -17, 4, 4), Color.WHITE)
		draw_rect(Rect2(11, -13, 4, 4), Color.WHITE)

func _draw_custom_ellipse(center: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts = PackedVector2Array()
	var num_pts = 20
	for i in range(num_pts):
		var angle = (float(i) / num_pts) * TAU
		pts.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	draw_colored_polygon(pts, col)


# Motion Blur Trail
class MotionGhost extends Node2D:
	var radius: float = 26.0
	var color: Color = Color.WHITE
	var current_alpha: float = 0.42

	func setup(p_pos: Vector2, p_radius: float, p_color: Color) -> void:
		position = p_pos
		radius = p_radius
		color = p_color
		z_index = 4

	func _ready() -> void:
		var tween = create_tween().set_parallel(true)
		tween.tween_property(self, "current_alpha", 0.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", Vector2(0.85, 0.85), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.chain().tween_callback(queue_free)

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var fill_col = Color(color.r, color.g, color.b, current_alpha)
		var rim_col = Color(1.0, 1.0, 1.0, current_alpha * 0.4)
		draw_circle(Vector2.ZERO, radius, fill_col)
		draw_arc(Vector2.ZERO, radius * 0.9, 0, TAU, 16, rim_col, 1.5)
