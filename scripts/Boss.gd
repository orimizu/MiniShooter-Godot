extends Area2D

signal boss_destroyed(score_points)

@export var boss_type: String = "green_boss"
@export var max_health: int = 50
@export var move_speed: float = 50.0
@export var score_points: int = 1000

var current_health: int
var movement_direction: int = 1
var attack_timer: float = 0.0
var attack_rate: float = 1.0
var current_phase: int = 1
var boss_patterns = {
	"green_boss": {
		"color1": Color.GREEN,
		"color2": Color(0, 0.8, 0),
		"phases": [
			{"health_threshold": 35, "attack_pattern": "8_way", "attack_rate": 1.5, "move_speed": 30},
			{"health_threshold": 15, "attack_pattern": "16_way", "attack_rate": 1.0, "move_speed": 50},
			{"health_threshold": 0, "attack_pattern": "24_way", "attack_rate": 0.7, "move_speed": 80}
		]
	}
}

var bullet_scene = preload("res://scenes/Bullet.tscn")

func _ready():
	current_health = max_health
	# コリジョンシェイプを設定
	var collision = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 16  # 通常敵の16pxよりやや大きく
	collision.shape = circle_shape
	add_child(collision)
	
	# 32x32サイズで描画（Area2Dなのでcustom_minimum_sizeは不要）
	
	# 初期値の再設定（StageManagerで設定される前のデフォルト）
	if boss_type in boss_patterns:
		var pattern_config = boss_patterns[boss_type]["phases"][0]
		attack_rate = pattern_config["attack_rate"]
		move_speed = pattern_config["move_speed"]
	
	print("Boss created: ", boss_type, " with ", max_health, " health")

func _physics_process(delta):
	# 左右移動
	position.x += movement_direction * move_speed * delta
	
	# 画面端で反転
	if position.x <= 32:
		movement_direction = 1
	elif position.x >= 480 - 32:
		movement_direction = -1
	
	# 攻撃タイマー
	attack_timer += delta
	if attack_timer >= attack_rate:
		attack_timer = 0.0
		fire_bullets()
	
	# フェーズチェック
	check_phase_change()

func _draw():
	var pattern = boss_patterns.get(boss_type, boss_patterns["green_boss"])
	var color1 = pattern.color1
	var color2 = pattern.color2
	
	# 32x32のボスパターンを描画
	var boss_pattern = [
		[0,0,0,1,1,1,1,0,0,0,0,1,1,1,1,0,0,0,0,1,1,1,1,0,0,0,0,1,1,1,1,0],
		[0,0,1,2,2,2,2,1,0,0,1,2,2,2,2,1,0,0,1,2,2,2,2,1,0,0,1,2,2,2,2,1],
		[0,1,2,1,1,1,1,2,1,1,2,1,1,1,1,2,1,1,2,1,1,1,1,2,1,1,2,1,1,1,1,2],
		[1,2,1,2,2,2,2,1,2,2,1,2,2,2,2,1,2,2,1,2,2,2,2,1,2,2,1,2,2,2,2,1],
		[1,2,1,2,2,2,2,1,2,2,1,2,2,2,2,1,2,2,1,2,2,2,2,1,2,2,1,2,2,2,2,1],
		[1,2,1,2,2,2,2,1,2,2,1,2,2,2,2,1,2,2,1,2,2,2,2,1,2,2,1,2,2,2,2,1],
		[1,2,1,2,2,2,2,1,2,2,1,2,2,2,2,1,2,2,1,2,2,2,2,1,2,2,1,2,2,2,2,1],
		[0,1,2,1,1,1,1,2,1,1,2,1,1,1,1,2,1,1,2,1,1,1,1,2,1,1,2,1,1,1,1,2],
		[0,0,1,2,2,2,2,1,0,0,1,2,2,2,2,1,0,0,1,2,2,2,2,1,0,0,1,2,2,2,2,1],
		[0,0,0,1,1,1,1,0,0,0,0,1,1,1,1,0,0,0,0,1,1,1,1,0,0,0,0,1,1,1,1,0],
		[0,0,1,2,2,2,2,1,0,0,1,2,2,2,2,1,0,0,1,2,2,2,2,1,0,0,1,2,2,2,2,1],
		[0,1,2,1,1,1,1,2,1,1,2,1,1,1,1,2,1,1,2,1,1,1,1,2,1,1,2,1,1,1,1,2],
		[1,2,1,2,2,2,2,1,2,2,1,2,2,2,2,1,2,2,1,2,2,2,2,1,2,2,1,2,2,2,2,1],
		[1,2,1,2,2,2,2,1,2,2,1,2,2,2,2,1,2,2,1,2,2,2,2,1,2,2,1,2,2,2,2,1],
		[1,2,1,2,2,2,2,1,2,2,1,2,2,2,2,1,2,2,1,2,2,2,2,1,2,2,1,2,2,2,2,1],
		[1,2,1,2,2,2,2,1,2,2,1,2,2,2,2,1,2,2,1,2,2,2,2,1,2,2,1,2,2,2,2,1],
		[0,1,2,1,1,1,1,2,1,1,2,1,1,1,1,2,1,1,2,1,1,1,1,2,1,1,2,1,1,1,1,2],
		[0,0,1,2,2,2,2,1,0,0,1,2,2,2,2,1,0,0,1,2,2,2,2,1,0,0,1,2,2,2,2,1],
		[0,0,0,1,1,1,1,0,0,0,0,1,1,1,1,0,0,0,0,1,1,1,1,0,0,0,0,1,1,1,1,0],
		[0,0,1,2,2,2,2,1,0,0,1,2,2,2,2,1,0,0,1,2,2,2,2,1,0,0,1,2,2,2,2,1],
		[0,1,2,1,1,1,1,2,1,1,2,1,1,1,1,2,1,1,2,1,1,1,1,2,1,1,2,1,1,1,1,2],
		[1,2,1,2,2,2,2,1,2,2,1,2,2,2,2,1,2,2,1,2,2,2,2,1,2,2,1,2,2,2,2,1],
		[1,2,1,2,2,2,2,1,2,2,1,2,2,2,2,1,2,2,1,2,2,2,2,1,2,2,1,2,2,2,2,1],
		[1,2,1,2,2,2,2,1,2,2,1,2,2,2,2,1,2,2,1,2,2,2,2,1,2,2,1,2,2,2,2,1],
		[1,2,1,2,2,2,2,1,2,2,1,2,2,2,2,1,2,2,1,2,2,2,2,1,2,2,1,2,2,2,2,1],
		[0,1,2,1,1,1,1,2,1,1,2,1,1,1,1,2,1,1,2,1,1,1,1,2,1,1,2,1,1,1,1,2],
		[0,0,1,2,2,2,2,1,0,0,1,2,2,2,2,1,0,0,1,2,2,2,2,1,0,0,1,2,2,2,2,1],
		[0,0,0,1,1,1,1,0,0,0,0,1,1,1,1,0,0,0,0,1,1,1,1,0,0,0,0,1,1,1,1,0],
		[0,0,1,2,2,2,2,1,0,0,1,2,2,2,2,1,0,0,1,2,2,2,2,1,0,0,1,2,2,2,2,1],
		[0,1,2,1,1,1,1,2,1,1,2,1,1,1,1,2,1,1,2,1,1,1,1,2,1,1,2,1,1,1,1,2],
		[1,2,1,2,2,2,2,1,2,2,1,2,2,2,2,1,2,2,1,2,2,2,2,1,2,2,1,2,2,2,2,1],
		[0,1,2,1,1,1,1,2,1,1,2,1,1,1,1,2,1,1,2,1,1,1,1,2,1,1,2,1,1,1,1,2]
	]
	
	# パターンを描画
	for y in range(32):
		for x in range(32):
			var pixel = boss_pattern[y][x]
			if pixel == 1:
				draw_rect(Rect2(x - 16, y - 16, 1, 1), color1)
			elif pixel == 2:
				draw_rect(Rect2(x - 16, y - 16, 1, 1), color2)
	
	# 体力バーを描画
	draw_health_bar()

func draw_health_bar():
	var bar_width = 60
	var bar_height = 4
	var bar_x = -bar_width / 2
	var bar_y = -25
	
	# 背景
	draw_rect(Rect2(bar_x, bar_y, bar_width, bar_height), Color.BLACK)
	
	# 体力バー
	var health_ratio = float(current_health) / float(max_health)
	var health_width = bar_width * health_ratio
	var health_color = Color.RED
	if health_ratio > 0.6:
		health_color = Color.GREEN
	elif health_ratio > 0.3:
		health_color = Color.YELLOW
	
	draw_rect(Rect2(bar_x, bar_y, health_width, bar_height), health_color)

func fire_bullets():
	var pattern_config = boss_patterns[boss_type]["phases"][current_phase - 1]
	var pattern = pattern_config["attack_pattern"]
	
	match pattern:
		"8_way":
			fire_8_way()
		"16_way":
			fire_16_way()
		"24_way":
			fire_24_way()

func fire_8_way():
	for i in range(8):
		var angle = i * PI / 4  # 45度間隔
		create_bullet(angle)

func fire_16_way():
	for i in range(16):
		var angle = i * PI / 8  # 22.5度間隔
		create_bullet(angle)

func fire_24_way():
	for i in range(24):
		var angle = i * PI / 12  # 15度間隔
		create_bullet(angle)

func create_bullet(angle: float):
	var bullet = bullet_scene.instantiate()
	bullet.position = global_position
	bullet.direction = Vector2(cos(angle), sin(angle))
	bullet.speed = 100.0  # ボス弾はやや遅め
	bullet.bullet_type = "enemy"
	bullet.modulate = Color.RED  # ボス弾は赤色
	
	# GameManagerに弾丸を追加
	var game_manager = get_parent()
	game_manager.add_child(bullet)
	if game_manager.has_method("add_enemy_bullet"):
		game_manager.add_enemy_bullet(bullet)

func take_damage(damage: int):
	current_health -= damage
	
	# ダメージエフェクト
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	
	if current_health <= 0:
		destroy_boss()
	else:
		check_phase_change()

func check_phase_change():
	var pattern_config = boss_patterns[boss_type]["phases"]
	var new_phase = current_phase
	
	for i in range(pattern_config.size()):
		var phase = pattern_config[i]
		if current_health > phase["health_threshold"]:
			new_phase = i + 1
			break
		else:
			new_phase = pattern_config.size()
	
	if new_phase != current_phase:
		current_phase = new_phase
		var phase_data = pattern_config[current_phase - 1]
		attack_rate = phase_data["attack_rate"]
		move_speed = phase_data["move_speed"]
		print("Boss phase changed to: ", current_phase)

func destroy_boss():
	emit_signal("boss_destroyed", score_points)
	print("Boss defeated! Score: ", score_points)
	queue_free()

func get_health_ratio() -> float:
	return float(current_health) / float(max_health)