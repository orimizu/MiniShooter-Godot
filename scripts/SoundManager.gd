extends Node

# 各サウンド用のAudioStreamPlayer
var shoot_player: AudioStreamPlayer
var enemy_destroyed_player: AudioStreamPlayer
var player_hit_player: AudioStreamPlayer
var bomb_player: AudioStreamPlayer
var powerup_player: AudioStreamPlayer

# サウンドジェネレーター設定
var sample_rate = 44100
var mix_rate = 44100.0

func _ready():
	# 各サウンドプレイヤーを作成
	shoot_player = create_audio_player()
	enemy_destroyed_player = create_audio_player()
	player_hit_player = create_audio_player()
	bomb_player = create_audio_player()
	powerup_player = create_audio_player()
	
	# サウンドを生成
	shoot_player.stream = generate_shoot_sound()
	enemy_destroyed_player.stream = generate_explosion_sound()
	player_hit_player.stream = generate_hit_sound()
	bomb_player.stream = generate_bomb_sound()
	powerup_player.stream = generate_powerup_sound()

func create_audio_player() -> AudioStreamPlayer:
	var player = AudioStreamPlayer.new()
	add_child(player)
	player.volume_db = -10  # 音量調整
	return player

func play_sound(sound_name: String):
	match sound_name:
		"shoot":
			# 射撃音は既に再生中なら新しい音を再生しない
			if not shoot_player.playing:
				shoot_player.play()
		"enemy_destroyed":
			enemy_destroyed_player.play()
		"player_hit":
			player_hit_player.play()
		"bomb":
			bomb_player.play()
		"powerup":
			powerup_player.play()

# シューティング音（敵撃破音に似た高音版）
func generate_shoot_sound() -> AudioStreamWAV:
	var audio = AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.mix_rate = mix_rate
	audio.stereo = false
	
	var duration = 0.10  # 0.15秒に延長
	var base_frequency = 2000.0  # より高音に（300Hz → 800Hz）
	var samples = []
	
	for i in range(int(mix_rate * duration)):
		var t = float(i) / mix_rate
		# エクスポネンシャル減衰（敵撃破音と同じ）
		var envelope = exp(-t * 15.0) * 0.08  # 音量を8%に（半分に）
		# 周波数も時間とともに低下
		var frequency = base_frequency * (1.0 - t * 2.0)
		# ノイズとサイン波のミックス（敵撃破音と同じ比率）
		var noise = (randf() - 0.5) * 2.0
		var sine = sin(2.0 * PI * frequency * t)
		var sample = (noise * 0.7 + sine * 0.3) * envelope
		samples.append(int(sample * 32767))
	
	audio.data = pack_int16_array(samples)
	return audio

# 爆発音（中音、パルス波）
func generate_explosion_sound() -> AudioStreamWAV:
	var audio = AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.mix_rate = mix_rate
	audio.stereo = false
	
	var duration = 0.2
	var base_frequency = 150.0
	var samples = []
	
	for i in range(int(mix_rate * duration)):
		var t = float(i) / mix_rate
		# エクスポネンシャル減衰
		var envelope = exp(-t * 10.0)
		# 周波数も時間とともに低下
		var frequency = base_frequency * (1.0 - t * 2.0)
		# ノイズとサイン波のミックス
		var noise = (randf() - 0.5) * 2.0
		var sine = sin(2.0 * PI * frequency * t)
		var sample = (noise * 0.7 + sine * 0.3) * envelope
		samples.append(int(sample * 32767))
	
	audio.data = pack_int16_array(samples)
	return audio

# ヒット音（低音、鈍い音）
func generate_hit_sound() -> AudioStreamWAV:
	var audio = AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.mix_rate = mix_rate
	audio.stereo = false
	
	var duration = 0.5
	var frequency = 30.0
	var samples = []
	
	for i in range(int(mix_rate * duration)):
		var t = float(i) / mix_rate
		# 急激な立ち上がりと減衰
		var envelope = 0.0
		if t < 0.01:
			envelope = t * 100.0  # 急激な立ち上がり
		else:
			envelope = exp(-(t - 0.01) * 15.0)  # 急激な減衰
		
		# 低周波の矩形波
		var square = 1.0 if sin(2.0 * PI * frequency * t) > 0 else -1.0
		# フィルタリング効果のため少しサイン波をミックス
		var sine = sin(2.0 * PI * frequency * 0.5 * t)
		var sample = (square * 0.6 + sine * 0.4) * envelope
		samples.append(int(sample * 32767))
	
	audio.data = pack_int16_array(samples)
	return audio

# ボム音（超低音、長い）
func generate_bomb_sound() -> AudioStreamWAV:
	var audio = AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.mix_rate = mix_rate
	audio.stereo = false
	
	var duration = 0.5
	var base_frequency = 50.0
	var samples = []
	
	for i in range(int(mix_rate * duration)):
		var t = float(i) / mix_rate
		# 複雑なエンベロープ
		var envelope = 0.0
		if t < 0.05:
			envelope = t * 20.0  # 立ち上がり
		elif t < 0.1:
			envelope = 1.0  # 維持
		else:
			envelope = exp(-(t - 0.1) * 3.0)  # ゆっくり減衰
		
		# 複数の周波数を重ねる
		var sample = 0.0
		sample += sin(2.0 * PI * base_frequency * t) * 0.5
		sample += sin(2.0 * PI * base_frequency * 2.0 * t) * 0.3
		sample += sin(2.0 * PI * base_frequency * 0.5 * t) * 0.2
		# ランブル効果のためのノイズ
		sample += (randf() - 0.5) * 0.3
		sample *= envelope
		
		samples.append(int(sample * 32767))
	
	audio.data = pack_int16_array(samples)
	return audio

# int配列をPackedByteArrayに変換
func pack_int16_array(samples: Array) -> PackedByteArray:
	var bytes = PackedByteArray()
	bytes.resize(samples.size() * 2)
	
	for i in range(samples.size()):
		var value = samples[i]
		# リトルエンディアンで16ビット整数をバイト配列に変換
		bytes[i * 2] = value & 0xFF
		bytes[i * 2 + 1] = (value >> 8) & 0xFF
	
	return bytes

# パワーアップ音（上昇する明るい音）
func generate_powerup_sound() -> AudioStreamWAV:
	var audio = AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.mix_rate = mix_rate
	audio.stereo = false
	
	var duration = 0.4
	var num_samples = int(duration * mix_rate)
	var samples = []
	
	for i in range(num_samples):
		var t = float(i) / mix_rate
		var progress = t / duration
		
		# 上昇する音程（400Hz → 800Hz）
		var frequency = 400.0 + (progress * 400.0)
		
		# エンベロープ（フェードイン・アウト）
		var envelope = 1.0
		if progress < 0.1:
			envelope = progress / 0.1
		elif progress > 0.8:
			envelope = (1.0 - progress) / 0.2
		
		# ハーモニクスを含む明るい音
		var sample = 0.0
		sample += sin(2.0 * PI * frequency * t) * 0.6        # 基音
		sample += sin(2.0 * PI * frequency * 2.0 * t) * 0.3  # 2倍音
		sample += sin(2.0 * PI * frequency * 3.0 * t) * 0.1  # 3倍音
		sample *= envelope * 0.7  # 音量調整
		
		samples.append(int(sample * 32767))
	
	audio.data = pack_int16_array(samples)
	return audio
