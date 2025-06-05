extends Area2D

signal bullet_fired(bullet)
signal destroyed(enemy)

@export var bullet_scene: PackedScene

var speed: float = 100.0
var fire_rate: float = 60.0
var fire_counter: float = 0.0
var move_pattern: int = 0
var enemy_color1: Color = Color.RED
var enemy_color2: Color = Color.BLUE
var wave_counter: float = 0.0
var wave_speed: float = 2.0
var angle: float = 0.0
var speed_change_rate: float = 80.0
var speed_change_counter: float = 0.0
var velocity: Vector2 = Vector2.ZERO

# 体力システム
var max_hp: int = 1
var current_hp: int = 1
var color_type: String = "red"
var game_manager: Node2D

# ボス撃破後の撤退状態
var is_retreating: bool = false
var retreat_speed_multiplier: float = 3.0

# 敵のドットパターン
var enemy_patterns = {
	"red": [
		[0, 0, 1, 1, 1, 1, 0, 0],
		[0, 0, 0, 1, 1, 0, 0, 0],
		[0, 0, 1, 1, 1, 1, 0, 9],
		[1, 1, 1, 2, 2, 1, 1, 1],
		[1, 1, 1, 2, 2, 1, 1, 1],
		[0, 0, 2, 1, 1, 2, 0, 0],
		[0, 0, 2, 1, 1, 2, 0, 0],
		[0, 0, 0, 1, 1, 0, 0, 0]
	],
	"yellow": [
		[0, 1, 1, 0, 0, 1, 1, 0],
		[2, 1, 1, 0, 0, 1, 1, 2],
		[2, 1, 1, 0, 0, 1, 1, 2],
		[2, 1, 2, 0, 0, 2, 1, 2],
		[2, 1, 1, 2, 2, 1, 1, 2],
		[2, 1, 1, 1, 1, 1, 1, 2],
		[0, 2, 1, 1, 1, 1, 2, 0],
		[0, 0, 2, 2, 2, 2, 0, 0]
	],
	"cyan": [
		[0, 0, 0, 1, 1, 0, 0, 0],
		[0, 0, 1, 1, 1, 1, 0, 0],
		[0, 1, 2, 0, 0, 2, 1, 0],
		[1, 1, 0, 2, 2, 0, 1, 1],
		[1, 1, 0, 2, 2, 0, 1, 1],
		[0, 1, 2, 0, 0, 2, 1, 0],
		[0, 0, 1, 1, 1, 1, 0, 0],
		[0, 0, 0, 1, 1, 0, 0, 0]
	],
	"blue": [
		[2, 0, 0, 0, 0, 0, 0, 2],
		[2, 1, 0, 0, 0, 0, 1, 2],
		[1, 1, 0, 0, 0, 0, 1, 1],
		[1, 1, 1, 0, 0, 1, 1, 1],
		[2, 1, 1, 2, 2, 1, 1, 2],
		[0, 2, 1, 1, 1, 1, 2, 0],
		[0, 0, 2, 1, 1, 2, 0, 0],
		[0, 0, 0, 1, 1, 0, 0, 0]
	],
	"green": [
		[2, 2, 0, 0, 0, 0, 2, 2],
		[1, 1, 0, 1, 1, 0, 1, 1],
		[1, 1, 0, 1, 1, 0, 1, 1],
		[1, 1, 1, 1, 1, 1, 1, 1],
		[0, 1, 0, 1, 1, 0, 1, 0],
		[0, 0, 2, 1, 1, 2, 0, 0],
		[2, 2, 0, 0, 0, 0, 2, 2],
		[0, 2, 2, 0, 0, 2, 2, 0]
	],
	"magenta": [
		[0, 0, 0, 2, 2, 0, 0, 0],
		[0, 0, 0, 2, 2, 0, 0, 0],
		[1, 0, 0, 2, 2, 0, 0, 1],
		[1, 0, 1, 2, 2, 1, 0, 1],
		[1, 0, 0, 2, 2, 0, 0, 1],
		[0, 1, 0, 2, 2, 0, 1, 0],
		[0, 0, 1, 2, 2, 1, 0, 0],
		[0, 0, 0, 1, 1, 0, 0, 0]
	]
}

var current_pattern: Array = []

func _ready():
	initialize_enemy()

func _physics_process(delta):
	update_movement(delta)
	update_shooting(delta)
	
	# 位置を直接更新（物理演算なし）
	position += velocity * delta
	
	# 画面外チェック（下端のみで削除）
	if position.y > 700:
		queue_free()

func _draw():
	draw_pixel_art()

func initialize_enemy():
	# GameManagerの参照を取得
	game_manager = get_parent()
	
	# ランダムな設定
	move_pattern = randi_range(0, 3)
	angle = randf() * PI * 2
	wave_speed = randf_range(1.0, 3.0)
	speed_change_rate = randf_range(50.0, 120.0)
	
	# ステージマネージャーから敵タイプを取得（存在する場合）
	if game_manager and is_instance_valid(game_manager) and game_manager.get("stage_manager") != null:
		color_type = game_manager.stage_manager.get_enemy_type_for_spawn()
	else:
		# フォールバック：スコアベースの敵タイプ選択
		color_type = get_random_enemy_type()
	
	current_pattern = enemy_patterns[color_type]
	
	# 色別の特性設定
	match color_type:
		"red":
			enemy_color1 = Color.RED
			enemy_color2 = Color.WHITE
			max_hp = 1
			speed = randf_range(60.0, 100.0)
			fire_rate = randf_range(40.0, 70.0)
		"yellow":
			enemy_color1 = Color.YELLOW
			enemy_color2 = Color.RED
			max_hp = 2
			speed = randf_range(100.0, 150.0)  # 高速
			fire_rate = randf_range(30.0, 50.0)
		"cyan":
			enemy_color1 = Color.CYAN
			enemy_color2 = Color.RED
			max_hp = 3
			speed = randf_range(50.0, 90.0)
			fire_rate = randf_range(20.0, 40.0)  # 高頻度射撃
		"blue":
			enemy_color1 = Color.BLUE
			enemy_color2 = Color.CYAN
			max_hp = 2
			speed = randf_range(40.0, 120.0)  # 速度変化型
			fire_rate = randf_range(50.0, 80.0)
		"green":
			enemy_color1 = Color.GREEN
			enemy_color2 = Color.YELLOW
			max_hp = 4
			speed = randf_range(70.0, 110.0)
			fire_rate = randf_range(60.0, 90.0)
		"magenta":
			enemy_color1 = Color.MAGENTA
			enemy_color2 = Color.ORANGE
			max_hp = 5  # 最強
			speed = randf_range(80.0, 120.0)
			fire_rate = randf_range(25.0, 45.0)  # 高頻度射撃
	
	# 体力を最大値に設定
	current_hp = max_hp
	
	# 難易度設定を適用
	apply_difficulty_settings()

func get_random_enemy_type() -> String:
	var current_score = 0
	if game_manager and is_instance_valid(game_manager) and game_manager.get("score") != null:
		current_score = game_manager.score
	
	# スコア段階に応じた敵タイプの重み付け確率
	var enemy_weights = {}
	
	if current_score < 1000:
		# 0-1000: 赤・黄の弱い敵のみ
		enemy_weights = {
			"red": 60,     # 60%
			"yellow": 40   # 40%
		}
	elif current_score < 2000:
		# 1000-2000: 弱い敵 + 極低頻度で中程度の敵
		enemy_weights = {
			"red": 45,     # 45%
			"yellow": 35,  # 35%
			"cyan": 12,    # 12%
			"blue": 8      # 8%
		}
	elif current_score < 3000:
		# 2000-3000: シアン・青が低頻度、緑・マゼンダが極低頻度
		enemy_weights = {
			"red": 30,     # 30%
			"yellow": 25,  # 25%
			"cyan": 20,    # 20%
			"blue": 15,    # 15%
			"green": 7,    # 7%
			"magenta": 3   # 3%
		}
	else:
		# 3000以上: すべての敵が登場、強い敵の頻度も上昇
		enemy_weights = {
			"red": 20,     # 20%
			"yellow": 20,  # 20%
			"cyan": 25,    # 25%
			"blue": 15,    # 15%
			"green": 12,   # 12%
			"magenta": 8   # 8%
		}
	
	# 重み付きランダム選択
	var total_weight = 0
	for weight in enemy_weights.values():
		total_weight += weight
	
	var random_value = randi_range(1, total_weight)
	var cumulative_weight = 0
	
	for enemy_type in enemy_weights.keys():
		cumulative_weight += enemy_weights[enemy_type]
		if random_value <= cumulative_weight:
			return enemy_type
	
	# フォールバック（念のため）
	return "red"

func update_movement(delta):
	# 撤退中の場合は下方向へ高速移動
	if is_retreating:
		velocity = Vector2(0, speed * retreat_speed_multiplier)
		return
	
	match move_pattern:
		0:  # まっすぐ
			velocity = Vector2(0, speed)
		1:  # 揺れ
			velocity = Vector2(sin(wave_counter) * speed * 0.5, speed)
			wave_counter += wave_speed * delta
		2:  # 斜め
			velocity = Vector2(cos(angle) * speed, sin(angle) * speed)
			# 画面端で跳ね返り（左右のみ）
			if position.x <= 20 or position.x >= 460:
				angle = PI - angle
		3:  # バック
			if position.y > 320:
				velocity = Vector2(0, -speed * 0.5)
			else:
				velocity = Vector2(0, speed)
	
	# 青色の敵は速度変化
	if enemy_color1 == Color.BLUE:
		speed_change_counter += delta
		if speed_change_counter >= speed_change_rate / 60.0:
			speed = randf_range(50.0, 200.0)
			speed_change_counter = 0.0

func update_shooting(delta):
	# 撤退中は弾を撃たない
	if is_retreating:
		return
		
	fire_counter += delta
	if fire_counter >= fire_rate / 60.0:
		shoot()
		fire_counter = 0.0

func shoot():
	if not bullet_scene:
		return
	
	# 16方向弾幕
	for i in range(16):
		var bullet_angle = (i * PI * 2) / 16
		var bullet = bullet_scene.instantiate()
		bullet.position = global_position
		bullet.direction = Vector2(cos(bullet_angle), sin(bullet_angle))
		
		# 基本弾速に難易度倍率を適用
		var base_bullet_speed = 120.0
		var bullet_speed_multiplier = get_meta("bullet_speed_multiplier", 1.0)
		bullet.speed = base_bullet_speed * bullet_speed_multiplier
		
		bullet.modulate = Color.LIGHT_PINK
		emit_signal("bullet_fired", bullet)

func take_damage():
	current_hp -= 1
	
	# ダメージエフェクト（一瞬白くする）
	modulate = Color.WHITE
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.1)
	
	# 体力が0になったら撃破
	if current_hp <= 0:
		# パワーアップアイテムのドロップ判定（10%確率）
		drop_powerup()
		emit_signal("destroyed", self)
		queue_free()

func drop_powerup():
	var drop_chance = randf()
	if drop_chance <= 0.1:  # 10%確率
		var powerup_types = ["P", "S", "R", "B"]
		# 1UPは超レア（1%確率）
		if randf() <= 0.01:
			powerup_types.append("1UP")
		
		var selected_type = powerup_types[randi() % powerup_types.size()]
		
		# パワーアップを生成してGameManagerに通知
		if game_manager and is_instance_valid(game_manager) and game_manager.has_method("spawn_powerup"):
			game_manager.spawn_powerup(global_position, selected_type)

func draw_pixel_art():
	var pixel_size = 3
	
	# 体力に応じて色の透明度を変更（ダメージ表現）
	var hp_ratio = float(current_hp) / float(max_hp)
	var alpha = 0.5 + (hp_ratio * 0.5)  # 体力が減ると薄くなる
	
	for row in range(current_pattern.size()):
		for col in range(current_pattern[row].size()):
			if current_pattern[row][col] == 1:
				var rect = Rect2(
					Vector2((col - 4) * pixel_size, (row - 4) * pixel_size),
					Vector2(pixel_size, pixel_size)
				)
				var color1 = enemy_color1
				color1.a = alpha
				draw_rect(rect, color1)
			if current_pattern[row][col] == 2:
				var rect = Rect2(
					Vector2((col - 4) * pixel_size, (row - 4) * pixel_size),
					Vector2(pixel_size, pixel_size)
				)
				var color2 = enemy_color2
				color2.a = alpha
				draw_rect(rect, color2)

func apply_difficulty_settings():
	# GameManagerから難易度設定を取得して適用
	var health_multiplier = get_meta("difficulty_health_multiplier", 1.0)
	var speed_multiplier = get_meta("difficulty_speed_multiplier", 1.0) 
	var bullet_speed_multiplier = get_meta("difficulty_bullet_speed_multiplier", 1.0)
	
	# 体力を難易度に応じて調整
	max_hp = int(max_hp * health_multiplier)
	current_hp = max_hp
	
	# 移動速度を難易度に応じて調整
	speed *= speed_multiplier
	
	# 弾速は射撃時に適用されるため、メタデータとして保存
	set_meta("bullet_speed_multiplier", bullet_speed_multiplier)
	
	print("Enemy difficulty applied: HP=", max_hp, " Speed=", speed, " BulletSpeed=", bullet_speed_multiplier)

# 撤退開始関数
func start_retreat():
	is_retreating = true
	print("Enemy ", color_type, " starting retreat")
