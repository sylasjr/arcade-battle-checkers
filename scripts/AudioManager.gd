class_name AudioManager
extends Node

var music_player: AudioStreamPlayer
var music_stream: AudioStream = null
var is_music_muted: bool = false
var is_sfx_muted: bool = false
var music_volume: float = 0.28
var sfx_volume: float = 0.14   # 50% lower than music volume by default

# Soothing Procedural SFX Streams
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

	# Ensure seamless looping on track end
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
		music_player.volume_db = linear_to_db(music_volume) - 6.0

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

# --- Soothing SFX Playback Triggers ---

func play_select() -> void:
	if not is_sfx_muted and sfx_select:
		_play_sfx(sfx_select, -6.0, randf_range(0.97, 1.03))

func play_move() -> void:
	if not is_sfx_muted and sfx_move:
		_play_sfx(sfx_move, -5.0, randf_range(0.96, 1.04))

func play_capture() -> void:
	if not is_sfx_muted and sfx_capture_punchy:
		_play_sfx(sfx_capture_punchy, -4.0, randf_range(0.97, 1.03))

func play_fire_ignite() -> void:
	if not is_sfx_muted and sfx_fire_ignite:
		_play_sfx(sfx_fire_ignite, -5.0)

func play_combo() -> void:
	if not is_sfx_muted and sfx_combo:
		_play_sfx(sfx_combo, -5.0)

func play_powerup(p_type: PowerUpManager.PowerType) -> void:
	if is_sfx_muted:
		return
	if p_type == PowerUpManager.PowerType.BOMB and sfx_bomb:
		_play_sfx(sfx_bomb, -4.0)
	elif p_type == PowerUpManager.PowerType.PORTAL and sfx_portal:
		_play_sfx(sfx_portal, -5.0)
	elif p_type == PowerUpManager.PowerType.SHIELD and sfx_shield_absorb:
		_play_sfx(sfx_shield_absorb, -5.0)
	elif sfx_powerup:
		_play_sfx(sfx_powerup, -5.0)

func play_king() -> void:
	if not is_sfx_muted and sfx_king:
		_play_sfx(sfx_king, -5.0)

func play_win() -> void:
	if not is_sfx_muted and sfx_win:
		_play_sfx(sfx_win, -6.0)

func _play_sfx(stream: AudioStreamWAV, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if is_sfx_muted or sfx_volume <= 0.001 or stream == null:
		return
	var p = AudioStreamPlayer.new()
	p.stream = stream
	# Applies soothing sfx volume scaling
	var sfx_vol_db = linear_to_db(sfx_volume) - 6.0
	p.volume_db = volume_db + sfx_vol_db
	p.pitch_scale = pitch_scale
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)

# --- 16-Bit Smooth Waveform Helper ---

func _create_16bit_wav(samples: Array[float], sample_rate: int = 22050) -> AudioStreamWAV:
	var num_samples = samples.size()
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	for i in range(num_samples):
		var s = clampf(samples[i], -0.98, 0.98)
		var val_16 = int(s * 32767.0)
		data.encode_s16(i * 2, val_16)

	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

# --- Soothing Procedural SFX Generators ---

func _generate_sfx() -> void:
	sfx_select = _generate_soft_bubble()
	sfx_move = _generate_soft_wooden_tap()
	sfx_capture_punchy = _generate_gentle_wood_knock()
	sfx_king = _generate_soothing_fanfare()
	sfx_win = _generate_peaceful_win()
	sfx_fire_ignite = _generate_calm_whoosh()
	sfx_combo = _generate_gentle_combo()
	sfx_powerup = _generate_soothing_powerup()
	sfx_bomb = _generate_deep_warm_rumble()
	sfx_portal = _generate_ethereal_portal()
	sfx_shield_absorb = _generate_crystal_shield()

# 1. Soft bubble / marimba note for Selection
func _generate_soft_bubble() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.07
	var num_samples = int(duration * sample_rate)
	var samples: Array[float] = []
	samples.resize(num_samples)

	var phase = 0.0
	for i in range(num_samples):
		var progress = float(i) / float(num_samples)
		var freq = lerp(480.0, 580.0, sin(progress * PI * 0.5))
		phase = fmod(phase + freq / sample_rate, 1.0)
		
		# Pure warm sine with gentle attack and soft exponential release
		var attack = clampf(progress / 0.15, 0.0, 1.0)
		var decay = exp(-progress * 7.5) * (1.0 - progress)
		var wave = sin(phase * TAU) + 0.18 * sin(phase * 2.0 * TAU)
		samples[i] = wave * attack * decay * 0.65

	return _create_16bit_wav(samples, sample_rate)

# 2. Warm tactile wooden tap for Piece Move
func _generate_soft_wooden_tap() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.09
	var num_samples = int(duration * sample_rate)
	var samples: Array[float] = []
	samples.resize(num_samples)

	var phase1 = 0.0
	var phase2 = 0.0
	for i in range(num_samples):
		var progress = float(i) / float(num_samples)
		var freq1 = lerp(185.0, 120.0, progress)
		var freq2 = lerp(95.0, 60.0, progress)
		phase1 = fmod(phase1 + freq1 / sample_rate, 1.0)
		phase2 = fmod(phase2 + freq2 / sample_rate, 1.0)

		var attack = clampf(progress / 0.08, 0.0, 1.0)
		var decay = exp(-progress * 9.0) * (1.0 - progress)
		var wave = sin(phase1 * TAU) * 0.65 + sin(phase2 * TAU) * 0.35
		samples[i] = wave * attack * decay * 0.7

	return _create_16bit_wav(samples, sample_rate)

# 3. Satisfying, warm wooden knock / soft thud for Capture
func _generate_gentle_wood_knock() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.18
	var num_samples = int(duration * sample_rate)
	var samples: Array[float] = []
	samples.resize(num_samples)

	var phase_sub = 0.0
	var phase_body = 0.0
	for i in range(num_samples):
		var progress = float(i) / float(num_samples)
		var sub_freq = lerp(115.0, 48.0, progress)
		var body_freq = lerp(260.0, 140.0, progress)
		phase_sub = fmod(phase_sub + sub_freq / sample_rate, 1.0)
		phase_body = fmod(phase_body + body_freq / sample_rate, 1.0)

		var attack = clampf(progress / 0.06, 0.0, 1.0)
		var decay = exp(-progress * 6.5) * (1.0 - progress)
		var wave = sin(phase_sub * TAU) * 0.6 + sin(phase_body * TAU) * 0.35
		samples[i] = wave * attack * decay * 0.75

	return _create_16bit_wav(samples, sample_rate)

# 4. Celesta / Harp sparkle for Power-Up
func _generate_soothing_powerup() -> AudioStreamWAV:
	var sample_rate = 22050
	var notes = [587.33, 739.99, 880.0, 1174.66] # D major harmonic chime
	var note_dur = 0.06
	var total_dur = note_dur * notes.size() + 0.15
	var num_samples = int(total_dur * sample_rate)
	var samples: Array[float] = []
	samples.resize(num_samples)
	samples.fill(0.0)

	for n in range(notes.size()):
		var start_sample = int(n * note_dur * sample_rate)
		var freq = notes[n]
		var note_len = int(0.22 * sample_rate)
		var phase = 0.0
		for i in range(note_len):
			var idx = start_sample + i
			if idx >= num_samples:
				break
			var note_prog = float(i) / float(note_len)
			phase = fmod(phase + freq / sample_rate, 1.0)
			
			var attack = clampf(note_prog / 0.05, 0.0, 1.0)
			var decay = exp(-note_prog * 5.5) * (1.0 - note_prog)
			# Pure bell tone with warm soft second harmonic
			var wave = sin(phase * TAU) * 0.75 + sin(phase * 2.0 * TAU) * 0.2
			samples[idx] += wave * attack * decay * 0.35

	return _create_16bit_wav(samples, sample_rate)

# 5. Deep warm cinematic rumble (Bomb)
func _generate_deep_warm_rumble() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.38
	var num_samples = int(duration * sample_rate)
	var samples: Array[float] = []
	samples.resize(num_samples)

	var phase = 0.0
	for i in range(num_samples):
		var progress = float(i) / float(num_samples)
		var bass_freq = lerp(78.0, 32.0, progress)
		phase = fmod(phase + bass_freq / sample_rate, 1.0)
		
		var attack = clampf(progress / 0.08, 0.0, 1.0)
		var decay = exp(-progress * 4.5) * (1.0 - progress)
		var wave = sin(phase * TAU) * 0.75 + sin(phase * 0.5 * TAU) * 0.25
		samples[i] = wave * attack * decay * 0.7

	return _create_16bit_wav(samples, sample_rate)

# 6. Ethereal singing bowl / cosmic hum (Portal)
func _generate_ethereal_portal() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.32
	var num_samples = int(duration * sample_rate)
	var samples: Array[float] = []
	samples.resize(num_samples)

	var phase1 = 0.0
	var phase2 = 0.0
	for i in range(num_samples):
		var progress = float(i) / float(num_samples)
		var freq1 = 432.0 + sin(progress * PI) * 60.0
		var freq2 = 436.0 + sin(progress * PI) * 60.0
		phase1 = fmod(phase1 + freq1 / sample_rate, 1.0)
		phase2 = fmod(phase2 + freq2 / sample_rate, 1.0)

		var env = sin(progress * PI)
		var wave = sin(phase1 * TAU) * 0.5 + sin(phase2 * TAU) * 0.5
		samples[i] = wave * env * 0.55

	return _create_16bit_wav(samples, sample_rate)

# 7. Singing crystal chime / soft bell (Shield)
func _generate_crystal_shield() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.26
	var num_samples = int(duration * sample_rate)
	var samples: Array[float] = []
	samples.resize(num_samples)

	var phase = 0.0
	for i in range(num_samples):
		var progress = float(i) / float(num_samples)
		var freq = 880.0
		phase = fmod(phase + freq / sample_rate, 1.0)

		var attack = clampf(progress / 0.04, 0.0, 1.0)
		var decay = exp(-progress * 6.0) * (1.0 - progress)
		var wave = sin(phase * TAU) * 0.75 + sin(phase * 2.0 * TAU) * 0.25
		samples[i] = wave * attack * decay * 0.6

	return _create_16bit_wav(samples, sample_rate)

# 8. Gentle kalimba triad (Combo)
func _generate_gentle_combo() -> AudioStreamWAV:
	var sample_rate = 22050
	var notes = [523.25, 659.25, 783.99] # C5, E5, G5
	var note_dur = 0.07
	var total_dur = note_dur * notes.size() + 0.18
	var num_samples = int(total_dur * sample_rate)
	var samples: Array[float] = []
	samples.resize(num_samples)
	samples.fill(0.0)

	for n in range(notes.size()):
		var start_sample = int(n * note_dur * sample_rate)
		var freq = notes[n]
		var note_len = int(0.24 * sample_rate)
		var phase = 0.0
		for i in range(note_len):
			var idx = start_sample + i
			if idx >= num_samples:
				break
			var note_prog = float(i) / float(note_len)
			phase = fmod(phase + freq / sample_rate, 1.0)
			
			var attack = clampf(note_prog / 0.06, 0.0, 1.0)
			var decay = exp(-note_prog * 5.0) * (1.0 - note_prog)
			var wave = sin(phase * TAU) * 0.8 + sin(phase * 2.0 * TAU) * 0.18
			samples[idx] += wave * attack * decay * 0.38

	return _create_16bit_wav(samples, sample_rate)

# 9. Calm gentle warm air whoosh (Fire)
func _generate_calm_whoosh() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.35
	var num_samples = int(duration * sample_rate)
	var samples: Array[float] = []
	samples.resize(num_samples)

	var phase = 0.0
	for i in range(num_samples):
		var progress = float(i) / float(num_samples)
		var freq = lerp(220.0, 440.0, sin(progress * PI))
		phase = fmod(phase + freq / sample_rate, 1.0)

		var env = sin(progress * PI)
		var wave = sin(phase * TAU) * 0.7 + sin(phase * 0.5 * TAU) * 0.3
		samples[i] = wave * env * 0.5

	return _create_16bit_wav(samples, sample_rate)

# 10. Warm music box fanfare for King promotion
func _generate_soothing_fanfare() -> AudioStreamWAV:
	var sample_rate = 22050
	var notes = [440.0, 554.37, 659.25, 880.0] # A major music box
	var note_dur = 0.08
	var total_dur = note_dur * notes.size() + 0.25
	var num_samples = int(total_dur * sample_rate)
	var samples: Array[float] = []
	samples.resize(num_samples)
	samples.fill(0.0)

	for n in range(notes.size()):
		var start_sample = int(n * note_dur * sample_rate)
		var freq = notes[n]
		var note_len = int(0.3 * sample_rate)
		var phase = 0.0
		for i in range(note_len):
			var idx = start_sample + i
			if idx >= num_samples:
				break
			var note_prog = float(i) / float(note_len)
			phase = fmod(phase + freq / sample_rate, 1.0)
			
			var attack = clampf(note_prog / 0.05, 0.0, 1.0)
			var decay = exp(-note_prog * 4.5) * (1.0 - note_prog)
			var wave = sin(phase * TAU) * 0.8 + sin(phase * 2.0 * TAU) * 0.2
			samples[idx] += wave * attack * decay * 0.35

	return _create_16bit_wav(samples, sample_rate)

# 11. Peaceful celesta victory jingle
func _generate_peaceful_win() -> AudioStreamWAV:
	var sample_rate = 22050
	var notes = [523.25, 659.25, 783.99, 1046.50] # C major celesta
	var note_dur = 0.12
	var total_dur = note_dur * notes.size() + 0.35
	var num_samples = int(total_dur * sample_rate)
	var samples: Array[float] = []
	samples.resize(num_samples)
	samples.fill(0.0)

	for n in range(notes.size()):
		var start_sample = int(n * note_dur * sample_rate)
		var freq = notes[n]
		var note_len = int(0.42 * sample_rate)
		var phase = 0.0
		for i in range(note_len):
			var idx = start_sample + i
			if idx >= num_samples:
				break
			var note_prog = float(i) / float(note_len)
			phase = fmod(phase + freq / sample_rate, 1.0)
			
			var attack = clampf(note_prog / 0.04, 0.0, 1.0)
			var decay = exp(-note_prog * 4.0) * (1.0 - note_prog)
			var wave = sin(phase * TAU) * 0.82 + sin(phase * 2.0 * TAU) * 0.18
			samples[idx] += wave * attack * decay * 0.36

	return _create_16bit_wav(samples, sample_rate)
