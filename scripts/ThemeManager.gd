class_name ThemeManager
extends Node

enum ThemeType { CLASSIC_PIXEL, CYBERPUNK_NEON, RETRO_WOOD, MAGMA_INFERNO }

var current_theme: ThemeType = ThemeType.CLASSIC_PIXEL

signal theme_changed(theme_data: Dictionary)

const THEMES = {
	ThemeType.CLASSIC_PIXEL: {
		"name": "Classic Pixel",
		"bg_color": Color(0.08, 0.09, 0.12),
		"board_light": Color(0.92, 0.88, 0.78),
		"board_dark": Color(0.22, 0.26, 0.35),
		"board_border": Color(0.12, 0.14, 0.18),
		"board_inner_border": Color(0.18, 0.20, 0.26),
		"red_texture": "res://textures/piece_dark.png",
		"black_texture": "res://textures/piece_light.png",
		"red_main": Color(0.55, 0.20, 0.25),
		"black_main": Color(0.95, 0.75, 0.45),
		"glow_color": Color(0.2, 0.8, 1.0, 0.4)
	},
	ThemeType.CYBERPUNK_NEON: {
		"name": "Cyberpunk Neon",
		"bg_color": Color(0.04, 0.02, 0.08),
		"board_light": Color(0.15, 0.12, 0.25),
		"board_dark": Color(0.06, 0.04, 0.14),
		"board_border": Color(0.9, 0.0, 0.6),
		"board_inner_border": Color(0.0, 0.9, 0.95),
		"red_texture": "res://textures/piece_neon_magenta.png",
		"black_texture": "res://textures/piece_neon_cyan.png",
		"red_main": Color(1.0, 0.05, 0.55),
		"black_main": Color(0.0, 0.85, 0.95),
		"glow_color": Color(0.0, 1.0, 0.8, 0.5)
	},
	ThemeType.RETRO_WOOD: {
		"name": "Retro Wood",
		"bg_color": Color(0.12, 0.08, 0.05),
		"board_light": Color(0.85, 0.72, 0.52),
		"board_dark": Color(0.42, 0.26, 0.14),
		"board_border": Color(0.24, 0.14, 0.08),
		"board_inner_border": Color(0.32, 0.18, 0.10),
		"red_texture": "res://textures/piece_dark.png",
		"black_texture": "res://textures/piece_light.png",
		"red_main": Color(0.55, 0.20, 0.25),
		"black_main": Color(0.95, 0.75, 0.45),
		"glow_color": Color(1.0, 0.75, 0.2, 0.4)
	},
	ThemeType.MAGMA_INFERNO: {
		"name": "Magma Inferno",
		"bg_color": Color(0.08, 0.03, 0.02),
		"board_light": Color(0.35, 0.12, 0.08),
		"board_dark": Color(0.14, 0.04, 0.02),
		"board_border": Color(0.85, 0.25, 0.05),
		"board_inner_border": Color(0.95, 0.65, 0.1),
		"red_texture": "res://textures/piece_magma.png",
		"black_texture": "res://textures/piece_ash.png",
		"red_main": Color(1.0, 0.35, 0.05),
		"black_main": Color(0.35, 0.30, 0.32),
		"glow_color": Color(1.0, 0.4, 0.0, 0.5)
	}
}

func get_theme_data(theme_enum: ThemeType = current_theme) -> Dictionary:
	return THEMES.get(theme_enum, THEMES[ThemeType.CLASSIC_PIXEL])

func set_theme(theme_enum: ThemeType) -> void:
	current_theme = theme_enum
	emit_signal("theme_changed", get_theme_data(current_theme))

func next_theme() -> void:
	var next_idx = (int(current_theme) + 1) % THEMES.size()
	set_theme(ThemeType.values()[next_idx])
