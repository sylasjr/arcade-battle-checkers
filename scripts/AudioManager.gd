class_name AudioManager
extends Node

var music_player: AudioStreamPlayer
var music_stream: AudioStream = null
var is_music_muted: bool = false
var is_sfx_muted: bool = false
var music_volume: float = 0.55 # Reduced by 30% from 0.8 default
var sfx_volume: float = 0.55   # Reduced by 30% from 0.8 default

# SFX Streams
var sfx_select: AudioStreamWAV
var sfx_move: AudioStreamWAV
var sfx_capture_punchy: AudioStreamWAV
var sfx_king: AudioStreamWAV
var sfx_win: AudioStreamWAV
var sfx_fire_ignite: AudioStreamWAV
var sfx_combo: AudioStreamWAV
var sfx_powerup: AudioStreamWAV
var sfx_bomb: AudioStreamWAV
var sfx_portal: AudioStreamWAV
var sfx_shield_absorb: AudioStreamWAV

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	add_child(music_player)

	# Ensure looping on track end
	music_player.finished.connect(_on_music_finished)

	var sound_candidates = [
		"res://audio/Tides_at_the_Cottage_Door.mp3",
		"res://Audio/Tides_at_the_Cottage_Door.mp3",
		"res://audio/nastelbom-soundtrack-443631.mp3",
		"res://Audio/nastelbom-soundtrack-443631.mp3"
	]
	
	for path in sound_candidates:
		if ResourceLoader.exists(path):
			music_stream = load(path)
			if music_stream is AudioStreamMP3:
				music_stream.loop = true
			music_player.stream = music_stream
			_apply_music_volume()
			music_player.play()
			break

	_generate_sfx()

func _on_music_finished() -> void:
	if not is_music_muted and music_player and music_stream:
		music_player.play()

func set_music_volume(linear_val: float) -> void:
	music_volume = clampf(linear_val, 0.0, 1.0)
	_apply_music_volume()

func set_sfx_volume(linear_val: float) -> void:
	sfx_volume = clampf(linear_val, 0.0, 1.0)

func _apply_music_volume() -> void:
	if not music_player:
		return
	if is_music_muted or music_volume <= 0.001:
		music_player.volume_db = -80.0
	else:
		# Convert linear 0.0-1.0 to dB scale (-35 dB to +2 dB)
		music_player.volume_db = linear_to_db(music_volume) - 4.0

func toggle_music(enabled: bool) -> void:
	is_music_muted = !enabled
	if music_player:
		if enabled:
			_apply_music_volume()
			if not music_player.playing and music_stream != null:
				music_player.play()
		else:
			music_player.stop()

func toggle_sfx(enabled: bool) -> void:
	is_sfx_muted = !enabled

func play_select() -> void:
	if not is_sfx_muted and sfx_select:
		_play_sfx(sfx_select, -4.0, randf_range(0.95, 1.05))

func play_move() -> void:
	if not is_sfx_muted and sfx_move:
		_play_sfx(sfx_move, -2.0, randf_range(0.92, 1.08))

func play_capture() -> void:
	if not is_sfx_muted and sfx_capture_punchy:
		_play_sfx(sfx_capture_punchy, 3.5, randf_range(0.96, 1.04))

func play_fire_ignite() -> void:
	if not is_sfx_muted and sfx_fire_ignite:
		_play_sfx(sfx_fire_ignite, 4.0)

func play_combo() -> void:
	if not is_sfx_muted and sfx_combo:
		_play_sfx(sfx_combo, 4.5)

func play_powerup(p_type: PowerUpManager.PowerType) -> void:
	if is_sfx_muted:
		return
	if p_type == PowerUpManager.PowerType.BOMB and sfx_bomb:
		_play_sfx(sfx_bomb, 5.0)
	elif p_type == PowerUpManager.PowerType.PORTAL and sfx_portal:
		_play_sfx(sfx_portal, 3.0)
	elif p_type == PowerUpManager.PowerType.SHIELD and sfx_shield_absorb:
		_play_sfx(sfx_shield_absorb, 3.5)
	elif sfx_powerup:
		_play_sfx(sfx_powerup, 3.0)

func play_king() -> void:
	if not is_sfx_muted and sfx_king:
		_play_sfx(sfx_king, 1.0)

func play_win() -> void:
	if not is_sfx_muted and sfx_win:
		_play_sfx(sfx_win, 3.0)

func _play_sfx(stream: AudioStreamWAV, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if is_sfx_muted or sfx_volume <= 0.001:
		return
	var p = AudioStreamPlayer.new()
	p.stream = stream
	var sfx_vol_db = linear_to_db(sfx_volume)
	p.volume_db = volume_db + sfx_vol_db
	p.pitch_scale = pitch_scale
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)

# --- Procedural SFX Generators ---

func _generate_sfx() -> void:
	sfx_select = _generate_tone(600.0, 0.04, 0.6, "sine", 850.0)
	sfx_move = _generate_tone(240.0, 0.07, 0.7, "triangle", 140.0)
	sfx_capture_punchy = _generate_juicy_impact()
	sfx_king = _generate_fanfare()
	sfx_win = _generate_win_jingle()
	sfx_fire_ignite = _generate_fire_whoosh()
	sfx_combo = _generate_combo_hit()
	sfx_powerup = _generate_powerup_jingle()
	sfx_bomb = _generate_bomb_blast()
	sfx_portal = _generate_portal_warp()
	sfx_shield_absorb = _generate_shield_clang()

func _generate_powerup_jingle() -> AudioStreamWAV:
	var sample_rate = 22050
	var notes = [587.33, 739.99, 880.0, 1174.66] # D major arpeggio
	var note_dur = 0.05
	var total_dur = note_dur * notes.size() + 0.1
	var num_samples = int(total_dur * sample_rate)
	var data = PackedByteArray()
	data.resize(num_samples)

	var phase = 0.0
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var note_idx = mini(int(t / note_dur), notes.size() - 1)
		var current_freq = notes[note_idx]

		phase = fmod(phase + current_freq / sample_rate, 1.0)
		var sample_val = sin(phase * TAU)
		var byte_val = clampi(int((sample_val * 0.7 + 1.0) * 127.5), 0, 255)
		data[i] = byte_val

	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _generate_bomb_blast() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.45
	var num_samples = int(duration * sample_rate)
	var data = PackedByteArray()
	data.resize(num_samples)

	var phase = 0.0
	for i in range(num_samples):
		var progress = float(i) / num_samples
		var bass_freq = lerp(120.0, 25.0, progress)
		phase = fmod(phase + bass_freq / sample_rate, 1.0)
		var bass = sin(phase * TAU) * exp(-progress * 6.0)
		var explosion_noise = randf_range(-1.0, 1.0) * exp(-progress * 10.0) * 0.9

		var composite = (bass * 0.7 + explosion_noise) * (1.0 - progress)
		var byte_val = clampi(int((composite * 1.2 + 1.0) * 127.5), 0, 255)
		data[i] = byte_val

	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _generate_portal_warp() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.35
	var num_samples = int(duration * sample_rate)
	var data = PackedByteArray()
	data.resize(num_samples)

	var phase = 0.0
	for i in range(num_samples):
		var progress = float(i) / num_samples
		var warp_freq = sin(progress * PI * 4.0) * 300.0 + 600.0
		phase = fmod(phase + warp_freq / sample_rate, 1.0)
		var sample_val = sin(phase * TAU) * (1.0 - progress)
		var byte_val = clampi(int((sample_val * 0.75 + 1.0) * 127.5), 0, 255)
		data[i] = byte_val

	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _generate_shield_clang() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.28
	var num_samples = int(duration * sample_rate)
	var data = PackedByteArray()
	data.resize(num_samples)

	var phase = 0.0
	for i in range(num_samples):
		var progress = float(i) / num_samples
		var freq = lerp(1200.0, 300.0, progress)
		phase = fmod(phase + freq / sample_rate, 1.0)
		var wave = (4.0 * abs(phase - 0.5) - 1.0) * exp(-progress * 14.0)
		var byte_val = clampi(int((wave * 0.8 + 1.0) * 127.5), 0, 255)
		data[i] = byte_val

	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _generate_combo_hit() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.35
	var num_samples = int(duration * sample_rate)
	var data = PackedByteArray()
	data.resize(num_samples)

	var phase1 = 0.0
	var phase2 = 0.0
	for i in range(num_samples):
		var progress = float(i) / num_samples
		var freq1 = lerp(450.0, 880.0, progress)
		var freq2 = lerp(900.0, 1760.0, progress)
		phase1 = fmod(phase1 + freq1 / sample_rate, 1.0)
		phase2 = fmod(phase2 + freq2 / sample_rate, 1.0)

		var wave = sin(phase1 * TAU) * 0.7 + sin(phase2 * TAU) * 0.3
		var punch = randf_range(-1.0, 1.0) * exp(-progress * 25.0) * 0.5
		var env = exp(-progress * 7.0) * (1.0 - progress)

		var composite = (wave + punch) * env
		var byte_val = clampi(int((composite * 1.2 + 1.0) * 127.5), 0, 255)
		data[i] = byte_val

	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _generate_fire_whoosh() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.55
	var num_samples = int(duration * sample_rate)
	var data = PackedByteArray()
	data.resize(num_samples)

	var phase_1 = 0.0
	var phase_2 = 0.0
	for i in range(num_samples):
		var progress = float(i) / num_samples
		var freq1 = lerp(140.0, 480.0, progress)
		var freq2 = lerp(210.0, 720.0, progress)
		phase_1 = fmod(phase_1 + freq1 / sample_rate, 1.0)
		phase_2 = fmod(phase_2 + freq2 / sample_rate, 1.0)

		var wave1 = sin(phase_1 * TAU)
		var wave2 = (4.0 * abs(phase_2 - 0.5) - 1.0) * 0.5
		var fire_noise = randf_range(-1.0, 1.0) * (sin(progress * PI)) * 0.6

		var envelope = sin(progress * PI)
		var composite = (wave1 + wave2 + fire_noise) * envelope * 0.85
		var byte_val = clampi(int((composite * 1.1 + 1.0) * 127.5), 0, 255)
		data[i] = byte_val

	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _generate_juicy_impact() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.26
	var num_samples = int(duration * sample_rate)
	var data = PackedByteArray()
	data.resize(num_samples)

	var phase_bass = 0.0
	var phase_pop = 0.0
	for i in range(num_samples):
		var progress = float(i) / num_samples

		var bass_freq = lerp(160.0, 35.0, progress)
		phase_bass = fmod(phase_bass + bass_freq / sample_rate, 1.0)
		var bass_wave = sin(phase_bass * TAU) * exp(-progress * 9.0)

		var pop_freq = lerp(900.0, 400.0, progress)
		phase_pop = fmod(phase_pop + pop_freq / sample_rate, 1.0)
		var pop_wave = sin(phase_pop * TAU) * exp(-progress * 22.0)

		var noise = randf_range(-1.0, 1.0) * exp(-progress * 28.0) * 0.45

		var composite = (bass_wave * 0.8 + pop_wave * 0.4 + noise) * (1.0 - progress)
		var byte_val = clampi(int((composite * 1.1 + 1.0) * 127.5), 0, 255)
		data[i] = byte_val

	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _generate_tone(freq: float, duration: float, volume: float = 0.5, wave_type: String = "sine", end_freq: float = -1.0) -> AudioStreamWAV:
	var sample_rate = 22050
	var num_samples = int(duration * sample_rate)
	var data = PackedByteArray()
	data.resize(num_samples)

	var phase = 0.0
	for i in range(num_samples):
		var progress = float(i) / num_samples
		var current_freq = freq
		if end_freq > 0.0:
			current_freq = lerp(freq, end_freq, progress)

		phase = fmod(phase + (current_freq / sample_rate), 1.0)
		var sample_val = 0.0
		if wave_type == "sine":
			sample_val = sin(phase * TAU)
		elif wave_type == "triangle":
			sample_val = 4.0 * abs(phase - 0.5) - 1.0

		var envelope = exp(-progress * 6.0) * (1.0 - progress)
		var byte_val = clampi(int((sample_val * envelope * volume + 1.0) * 127.5), 0, 255)
		data[i] = byte_val

	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _generate_fanfare() -> AudioStreamWAV:
	var sample_rate = 22050
	var notes = [440.0, 554.37, 659.25, 880.0]
	var note_dur = 0.07
	var total_dur = note_dur * notes.size() + 0.1
	var num_samples = int(total_dur * sample_rate)
	var data = PackedByteArray()
	data.resize(num_samples)

	var phase = 0.0
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var note_idx = mini(int(t / note_dur), notes.size() - 1)
		var current_freq = notes[note_idx]

		phase = fmod(phase + current_freq / sample_rate, 1.0)
		var sample_val = 4.0 * abs(phase - 0.5) - 1.0
		var note_progress = fmod(t, note_dur) / note_dur
		var note_env = 1.0 - note_progress * 0.5
		var overall_env = 1.0 - (float(i) / num_samples) * 0.3
		
		var byte_val = clampi(int((sample_val * note_env * overall_env * 0.6 + 1.0) * 127.5), 0, 255)
		data[i] = byte_val

	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _generate_win_jingle() -> AudioStreamWAV:
	var sample_rate = 22050
	var notes = [523.25, 659.25, 783.99, 1046.50]
	var note_dur = 0.12
	var total_dur = note_dur * notes.size() + 0.3
	var num_samples = int(total_dur * sample_rate)
	var data = PackedByteArray()
	data.resize(num_samples)

	var phase = 0.0
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var note_idx = mini(int(t / note_dur), notes.size() - 1)
		var current_freq = notes[note_idx]

		phase = fmod(phase + current_freq / sample_rate, 1.0)
		var sample_val = sin(phase * TAU)
		var byte_val = clampi(int((sample_val * (1.0 - float(i) / num_samples) * 0.7 + 1.0) * 127.5), 0, 255)
		data[i] = byte_val

	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav
