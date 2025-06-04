extends Node2D

signal score_changed(new_score)
signal lives_changed(new_lives)
signal game_over
signal enemy_rate_changed(new_rate)
signal bomb_used
signal enemy_destroyed_effect(position, score_points)
signal stage_info_changed(stage_number, stage_name, progress)
signal powerup_effect_started(effect_type, duration)
signal powerup_effect_ended(effect_type)

# 音響効果シグナル
signal play_sound(sound_name)

@export var player_scene: PackedScene
@export var enemy_scene: PackedScene
@export var destroy_effect_scene: PackedScene = preload("res://scenes/DestroyEffect.tscn")

var score: int = 0
var max_lives: int = 5
var lives: int = 5
var enemy_rate: float = 0.02
var game_over_flag: bool = false
var game_started: bool = false
var bomb_cooldown: float = 0.0

# パワーアップ関連
var powerup_scene: PackedScene = preload("res://scenes/PowerUp.tscn")
var powerups: Array = []
var active_powerups: Dictionary = {}  # effect_type: timer_remaining

# 画面振動エフェクト関連
var screen_shake_timer: float = 0.0
var screen_shake_intensity: float = 0.0
var original_camera_position: Vector2 = Vector2.ZERO

# パフォーマンス最適化用
var cleanup_counter: int = 0
var cleanup_frequency: int = 60  # 60フレームに1回重いクリーンアップ

var enemies: Array = []
var player_bullets: Array = []
var enemy_bullets: Array = []

# オブジェクトプールの追加（将来的な最適化のため）
var bullet_pool: Array = []
var max_pool_size: int = 50

# パフォーマンス統計
var objects_cleaned_this_frame: int = 0

@onready var player: Area2D
@onready var ui: CanvasLayer
@onready var camera: Camera2D = $Camera2D
var sound_manager: Node
var high_score_manager: Node
var stage_manager: Node

func _ready():
	lives = max_lives
	score = 0
	enemy_rate = 0.05
	
	# 背景色を黒に設定
	RenderingServer.set_default_clear_color(Color.BLACK)
	
	# UIの参照を取得
	ui = $UI
	
	# サウンドマネージャーを作成
	var SoundManagerScript = preload("res://scripts/SoundManager.gd")
	sound_manager = SoundManagerScript.new()
	sound_manager.name = "SoundManager"
	add_child(sound_manager)
	
	# ハイスコアマネージャーを作成
	var HighScoreManagerScript = preload("res://scripts/HighScoreManager.gd")
	high_score_manager = HighScoreManagerScript.new()
	high_score_manager.name = "HighScoreManager"
	add_child(high_score_manager)
	
	# ステージマネージャーを作成
	var StageManagerScript = load("res://scripts/StageManager.gd")
	if StageManagerScript:
		stage_manager = StageManagerScript.new()
		stage_manager.name = "StageManager"
		add_child(stage_manager)
	else:
		print("Failed to load StageManager.gd")
	
	# プレイヤーの初期化
	spawn_player()
	
	# UIの更新
	emit_signal("score_changed", score)
	emit_signal("lives_changed", lives)
	emit_signal("enemy_rate_changed", enemy_rate)

func _process(delta):
	if not game_started or game_over_flag:
		return
	
	# パフォーマンス統計のリセット
	objects_cleaned_this_frame = 0
	
	# ステージ情報を更新
	if stage_manager and stage_manager.stage_active:
		var stage_config = stage_manager.stage_configs.get(stage_manager.current_stage, {})
		var stage_name = stage_config.get("name", "Stage " + str(stage_manager.current_stage))
		var progress = stage_manager.get_stage_progress()
		emit_signal("stage_info_changed", stage_manager.current_stage, stage_name, progress)
	
	# ボムクールダウンの更新
	if bomb_cooldown > 0:
		bomb_cooldown -= delta
	
	# 画面振動エフェクトの更新
	update_screen_shake(delta)
	
	# パワーアップタイマーの更新
	update_powerup_timers(delta)
	
	# パワーアップコリジョンの確認
	check_powerup_collisions()
	
	# ボム入力の処理
	if Input.is_action_just_pressed("bomb") and bomb_cooldown <= 0 and lives > 0:
		use_bomb()
		
	# 敵の生成（ステージ倍率を適用）
	var actual_enemy_rate = enemy_rate
	if stage_manager:
		actual_enemy_rate *= stage_manager.get_enemy_rate_multiplier()
	
	if randf() < actual_enemy_rate:
		spawn_enemy()
	
	# 弾丸の更新
	update_bullets(delta)
	
	# 衝突判定
	check_collisions()
	
	# 画面外オブジェクトの削除（最適化：頻度制御）
	cleanup_counter += 1
	if cleanup_counter >= cleanup_frequency or enemies.size() > 50:
		cleanup_objects()
		cleanup_counter = 0

func spawn_player():
	if player_scene:
		player = player_scene.instantiate()
		add_child(player)
		player.position = Vector2(240, 576)  # 画面下部中央
		player.bullet_fired.connect(_on_player_bullet_fired)

func spawn_enemy():
	if enemy_scene:
		var enemy = enemy_scene.instantiate()
		add_child(enemy)
		enemy.position = Vector2(randf_range(20, 460), -40)
		enemy.bullet_fired.connect(_on_enemy_bullet_fired)
		enemy.destroyed.connect(_on_enemy_destroyed)
		# GameManagerの参照を渡す（スコアベース敵選択用）
		enemy.game_manager = self
		enemies.append(enemy)

func _on_player_bullet_fired(bullet):
	add_child(bullet)
	player_bullets.append(bullet)
	emit_signal("play_sound", "shoot")

func _on_enemy_bullet_fired(bullet):
	add_child(bullet)
	enemy_bullets.append(bullet)

func add_enemy_bullet(bullet):
	# ボス弾などを直接enemy_bulletsリストに追加
	enemy_bullets.append(bullet)

func _on_enemy_destroyed(enemy):
	# より効率的な削除方法：インデックス検索して直接削除
	var enemy_index = enemies.find(enemy)
	if enemy_index != -1:
		enemies.remove_at(enemy_index)
	
	# 敵の色に応じたスコア計算
	var score_points = 10
	var enemy_color = "red"
	if is_instance_valid(enemy) and enemy.get("color_type") != null:
		enemy_color = enemy.color_type
		match enemy.color_type:
			"red": score_points = 10
			"yellow": score_points = 20
			"cyan": score_points = 30
			"blue": score_points = 25
			"green": score_points = 40
			"magenta": score_points = 50
	
	# 撃破エフェクトを生成
	if destroy_effect_scene:
		var effect = destroy_effect_scene.instantiate()
		add_child(effect)
		effect.global_position = enemy.global_position
		effect.set_particle_color(enemy_color)
		effect.set_score_points(score_points)
	
	# 撃破エフェクトシグナル発信
	emit_signal("enemy_destroyed_effect", enemy.global_position, score_points)
	emit_signal("play_sound", "enemy_destroyed")
	
	add_score(score_points)

func add_score(points: int):
	score += points
	emit_signal("score_changed", score)
	
	# スコアに応じて敵出現率を段階的に調整
	var old_rate = enemy_rate
	
	if score < 1000:
		enemy_rate = 0.02  # 初期段階：低頻度
	elif score < 3000:
		enemy_rate = 0.03 + (score - 1000) * 0.00001  # 段階的上昇
	elif score < 6000:
		enemy_rate = 0.05 + (score - 3000) * 0.000007  # より緩やかな上昇
	elif score < 10000:
		enemy_rate = 0.07 + (score - 6000) * 0.000005  # さらに緩やか
	else:
		enemy_rate = 0.09  # 最大値を0.09に制限
	
	# 敵出現率が変化した場合のみシグナル発信
	if abs(old_rate - enemy_rate) > 0.001:
		emit_signal("enemy_rate_changed", enemy_rate)

func take_damage():
	lives -= 1
	emit_signal("lives_changed", lives)
	
	# プレイヤーの被弾エフェクトを発動
	if is_instance_valid(player) and player.has_method("trigger_damage_flash"):
		player.trigger_damage_flash()
	
	# 画面振動エフェクト
	trigger_screen_shake(5.0, 0.2)
	emit_signal("play_sound", "player_hit")
	
	if lives <= 0:
		game_over_flag = true
		emit_signal("game_over")

func update_bullets(_delta):
	# プレイヤーの弾の更新（逆順でインデックス削除）
	for i in range(player_bullets.size() - 1, -1, -1):
		var bullet = player_bullets[i]
		if not is_instance_valid(bullet) or bullet.is_queued_for_deletion():
			player_bullets.remove_at(i)
		elif bullet.position.y < -10:
			bullet.queue_free()
			player_bullets.remove_at(i)
	
	# 敵の弾の更新（逆順でインデックス削除）
	for i in range(enemy_bullets.size() - 1, -1, -1):
		var bullet = enemy_bullets[i]
		if not is_instance_valid(bullet) or bullet.is_queued_for_deletion():
			enemy_bullets.remove_at(i)
		elif bullet.position.y > 650 or bullet.position.x < -10 or bullet.position.x > 490:
			bullet.queue_free()
			enemy_bullets.remove_at(i)

func check_collisions():
	# プレイヤーの弾と敵の衝突（逆順で安全な削除）
	for i in range(player_bullets.size() - 1, -1, -1):
		var bullet = player_bullets[i]
		if not is_instance_valid(bullet) or bullet.is_queued_for_deletion():
			player_bullets.remove_at(i)
			continue
		
		# Area2Dの重複検出を使用
		var overlapping_areas = bullet.get_overlapping_areas()
		var hit_target = false
		for area in overlapping_areas:
			# 通常の敵との衝突
			if is_instance_valid(area) and area in enemies:
				bullet.queue_free()
				player_bullets.remove_at(i)
				area.take_damage()
				hit_target = true
				break
			# ボスとの衝突
			elif is_instance_valid(area) and area.has_method("take_damage") and area.get_script() and area.get_script().get_path().get_file() == "Boss.gd":
				bullet.queue_free()
				player_bullets.remove_at(i)
				area.take_damage(1)  # ボスは1ダメージ
				hit_target = true
				break
		if hit_target:
			continue
	
	# 敵の弾とプレイヤーの衝突（逆順で安全な削除）
	if is_instance_valid(player):
		for i in range(enemy_bullets.size() - 1, -1, -1):
			var bullet = enemy_bullets[i]
			if not is_instance_valid(bullet) or bullet.is_queued_for_deletion():
				enemy_bullets.remove_at(i)
				continue
			
			# Area2Dの重複検出を使用
			var bullet_overlapping_areas = bullet.get_overlapping_areas()
			for area in bullet_overlapping_areas:
				if area == player:
					bullet.queue_free()
					enemy_bullets.remove_at(i)
					take_damage()
					break
		
		# 敵とプレイヤーの衝突（enemiesリストのクリーンアップも同時実行）
		var overlapping_areas = player.get_overlapping_areas()
		for area in overlapping_areas:
			if is_instance_valid(area) and area in enemies:
				area.take_damage()
				take_damage()
				break

func cleanup_objects():
	# 敵リストのクリーンアップ（逆順で安全な削除）
	for i in range(enemies.size() - 1, -1, -1):
		var enemy = enemies[i]
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			enemies.remove_at(i)
	
	# 弾丸リストは update_bullets と check_collisions で既にクリーンアップ済み
	# 必要に応じて追加のクリーンアップを実行
	if enemies.size() > 100:  # パフォーマンス対策：大量の敵がいる場合のみ
		enemies = enemies.filter(func(enemy): return is_instance_valid(enemy) and not enemy.is_queued_for_deletion())

func use_bomb():
	# ライフを1消費
	lives -= 1
	emit_signal("lives_changed", lives)
	
	# すべての敵と敵の弾を削除
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	for bullet in enemy_bullets:
		if is_instance_valid(bullet):
			bullet.queue_free()
	
	enemies.clear()
	enemy_bullets.clear()
	
	# ボム使用シグナル発信
	emit_signal("bomb_used")
	emit_signal("play_sound", "bomb")
	
	# クールダウン設定（0.5秒間ボム使用不可）
	bomb_cooldown = 0.5
	
	# ライフが0になったらゲームオーバー
	if lives <= 0:
		game_over_flag = true
		emit_signal("game_over")

func start_game():
	game_started = true
	game_over_flag = false
	
	# ステージ1を開始
	if stage_manager:
		stage_manager.start_stage(1)

func restart_game():
	# ゲーム状態をリセット
	game_over_flag = false
	game_started = true
	score = 0
	lives = max_lives
	enemy_rate = 0.02
	bomb_cooldown = 0.0
	
	# ステージをリセット
	if stage_manager:
		stage_manager.reset()
		stage_manager.start_stage(1)
	
	# すべてのオブジェクトを削除
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	for bullet in player_bullets:
		if is_instance_valid(bullet):
			bullet.queue_free()
	for bullet in enemy_bullets:
		if is_instance_valid(bullet):
			bullet.queue_free()
	
	enemies.clear()
	player_bullets.clear()
	enemy_bullets.clear()
	
	# プレイヤーをリセット
	if is_instance_valid(player):
		player.position = Vector2(240, 576)
	
	# UIを更新
	emit_signal("score_changed", score)
	emit_signal("lives_changed", lives)
	emit_signal("enemy_rate_changed", enemy_rate)

func trigger_screen_shake(intensity: float, duration: float):
	# 画面振動を開始
	screen_shake_intensity = intensity
	screen_shake_timer = duration

func update_screen_shake(delta):
	if screen_shake_timer > 0:
		screen_shake_timer -= delta
		
		# ランダムな振動を適用
		var shake_offset = Vector2(
			randf_range(-screen_shake_intensity, screen_shake_intensity),
			randf_range(-screen_shake_intensity, screen_shake_intensity)
		)
		
		# カメラに振動を適用
		if camera:
			camera.offset = shake_offset
	else:
		# 振動が終了したら位置をリセット
		if camera:
			camera.offset = Vector2.ZERO

# パワーアップ関連の関数
func spawn_powerup(position: Vector2, powerup_type: String):
	var powerup = powerup_scene.instantiate()
	powerup.position = position
	powerup.item_type = powerup_type
	powerup.powerup_collected.connect(_on_powerup_collected)
	add_child(powerup)
	powerups.append(powerup)

func _on_powerup_collected(item_type: String):
	apply_powerup_effect(item_type)
	play_sound.emit("powerup")

func apply_powerup_effect(item_type: String):
	match item_type:
		"P":  # Power - 攻撃力UP
			active_powerups["power"] = 30.0  # 30秒間
			emit_signal("powerup_effect_started", "power", 30.0)
			if is_instance_valid(player) and player.has_method("apply_power_boost"):
				player.apply_power_boost()
		"S":  # Speed - 移動速度UP
			active_powerups["speed"] = 30.0  # 30秒間
			emit_signal("powerup_effect_started", "speed", 30.0)
			if is_instance_valid(player) and player.has_method("apply_speed_boost"):
				player.apply_speed_boost()
		"R":  # Rapid - 連射速度UP
			active_powerups["rapid"] = 30.0  # 30秒間
			emit_signal("powerup_effect_started", "rapid", 30.0)
			if is_instance_valid(player) and player.has_method("apply_rapid_boost"):
				player.apply_rapid_boost()
		"B":  # Bomb - ボム回数+1
			# 即座に適用（持続効果なし）
			# 現在のボムシステムはライフ消費なので、ライフ+1で代用
			if lives < max_lives:
				lives += 1
				emit_signal("lives_changed", lives)
		"1UP":  # 1UP - ライフ+1
			lives += 1
			if lives > max_lives:
				max_lives = lives  # 最大ライフも増加
			emit_signal("lives_changed", lives)

func update_powerup_timers(delta):
	var expired_effects = []
	for effect_type in active_powerups.keys():
		active_powerups[effect_type] -= delta
		if active_powerups[effect_type] <= 0:
			expired_effects.append(effect_type)
	
	# 期限切れエフェクトの処理
	for effect_type in expired_effects:
		active_powerups.erase(effect_type)
		emit_signal("powerup_effect_ended", effect_type)
		
		# プレイヤーのブースト効果を終了
		if is_instance_valid(player):
			match effect_type:
				"power":
					if player.has_method("remove_power_boost"):
						player.remove_power_boost()
				"speed":
					if player.has_method("remove_speed_boost"):
						player.remove_speed_boost()
				"rapid":
					if player.has_method("remove_rapid_boost"):
						player.remove_rapid_boost()

func check_powerup_collisions():
	if not is_instance_valid(player):
		return
	
	# プレイヤーとパワーアップアイテムの衝突（逆順で安全な削除）
	for i in range(powerups.size() - 1, -1, -1):
		var powerup = powerups[i]
		if not is_instance_valid(powerup) or powerup.is_queued_for_deletion():
			powerups.remove_at(i)
			continue
		
		# Area2Dの重複検出を使用
		var overlapping_areas = powerup.get_overlapping_areas()
		for area in overlapping_areas:
			if area == player:
				powerup.collect()
				powerups.remove_at(i)
				break