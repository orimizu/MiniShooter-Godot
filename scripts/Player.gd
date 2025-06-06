extends Area2D

signal bullet_fired(bullet)

@export var speed: float = 200.0
@export var bullet_scene: PackedScene

var shoot_timer: float = 0.0
var shoot_interval: float = 0.1  # 元の射撃間隔に戻す
var game_manager: Node2D

# パワーアップ関連
var power_level: int = 0  # Pアイテムで増加する弾数レベル（0-5）
var bullet_double_damage: bool = false  # Sアイテムによる弾丸2倍ダメージ
var bullet_piercing: bool = false  # Rアイテムによる弾丸貫通（敵弾消去）

# 当たり判定可視化関連
var show_hitbox: bool = true  # 十字マーク表示のON/OFF
var hitbox_flash_timer: float = 0.0  # 被弾フラッシュのタイマー
var hitbox_flash_scale: float = 1.0  # フラッシュ時のスケール効果

# プレイヤーのドットパターン (8x8)
var player_pattern = [
	[0, 0, 0, 2, 2, 0, 0, 0],
	[0, 0, 0, 1, 1, 0, 0, 0],
	[0, 0, 1, 1, 1, 1, 0, 0],
	[0, 0, 0, 1, 1, 0, 0, 0],
	[0, 0, 1, 1, 1, 1, 0, 0],
	[2, 0, 1, 2, 2, 1, 0, 2],
	[2, 1, 1, 1, 1, 1, 1, 2],
	[2, 0, 0, 0, 0, 0, 0, 2]
]

func _ready():
	game_manager = get_parent()

func _physics_process(delta):
	handle_movement(delta)
	handle_shooting(delta)
	update_hitbox_effects(delta)

func _draw():
	draw_pixel_art()
	if show_hitbox:
		draw_hitbox()

func handle_movement(delta):
	var input_vector = Vector2.ZERO
	
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1
	if Input.is_action_pressed("move_up"):
		input_vector.y -= 1
	if Input.is_action_pressed("move_down"):
		input_vector.y += 1
	
	# 位置を直接更新（物理演算なし）
	var velocity = input_vector.normalized() * speed * delta
	position += velocity
	
	# 画面境界チェック
	var screen_size = get_viewport().get_visible_rect().size
	position.x = clamp(position.x, 16, screen_size.x - 16)
	position.y = clamp(position.y, 16, screen_size.y - 16)

func handle_shooting(delta):
	shoot_timer -= delta
	
	if Input.is_action_pressed("shoot") and shoot_timer <= 0:
		shoot()
		shoot_timer = shoot_interval

func shoot():
	if not bullet_scene or not game_manager:
		return
	
	var score = game_manager.score
	var total_power = power_level  # Pアイテムによる追加パワー
	
	# スコアベースのパワーアップ段階を計算
	var score_power = 0
	if score >= 1000:
		score_power += 1
	if score >= 3000:
		score_power += 1
	if score >= 6000:
		score_power += 1
	
	# 合計パワーレベル（最大8段階）
	var effective_power = min(total_power + score_power, 8)
	
	# パワーレベルに応じた射撃パターン
	match effective_power:
		0:  # 3WAY（初期状態）
			create_bullet(Vector2(0, -1))  # 前方
			create_bullet(Vector2(0.5, -0.866))  # 右前30度
			create_bullet(Vector2(-0.5, -0.866))  # 左前30度
		1:  # 5WAY
			create_bullet(Vector2(0, -1))  # 前方
			create_bullet(Vector2(0.5, -0.866))  # 右前30度
			create_bullet(Vector2(-0.5, -0.866))  # 左前30度
			create_bullet(Vector2(0.5, 0.866))  # 右後30度
			create_bullet(Vector2(-0.5, 0.866))  # 左後30度
		2:  # 7WAY
			create_bullet(Vector2(0, -1))  # 前方
			create_bullet(Vector2(0.5, -0.866))  # 右前30度
			create_bullet(Vector2(-0.5, -0.866))  # 左前30度
			create_bullet(Vector2(0.5, 0.866))  # 右後30度
			create_bullet(Vector2(-0.5, 0.866))  # 左後30度
			create_bullet(Vector2(1, 0))  # 右
			create_bullet(Vector2(-1, 0))  # 左
		3:  # 9WAY
			create_bullet(Vector2(0, -1))  # 前方
			create_bullet(Vector2(0.5, -0.866))  # 右前30度
			create_bullet(Vector2(-0.5, -0.866))  # 左前30度
			create_bullet(Vector2(0.5, 0.866))  # 右後30度
			create_bullet(Vector2(-0.5, 0.866))  # 左後30度
			create_bullet(Vector2(1, 0))  # 右
			create_bullet(Vector2(-1, 0))  # 左
			create_bullet(Vector2(0.707, -0.707))  # 右前45度
			create_bullet(Vector2(-0.707, -0.707))  # 左前45度
		4:  # 11WAY
			create_bullet(Vector2(0, -1))  # 前方
			create_bullet(Vector2(0.5, -0.866))  # 右前30度
			create_bullet(Vector2(-0.5, -0.866))  # 左前30度
			create_bullet(Vector2(0.5, 0.866))  # 右後30度
			create_bullet(Vector2(-0.5, 0.866))  # 左後30度
			create_bullet(Vector2(1, 0))  # 右
			create_bullet(Vector2(-1, 0))  # 左
			create_bullet(Vector2(0.707, -0.707))  # 右前45度
			create_bullet(Vector2(-0.707, -0.707))  # 左前45度
			create_bullet(Vector2(0.707, 0.707))  # 右後45度
			create_bullet(Vector2(-0.707, 0.707))  # 左後45度
		5:  # 13WAY
			create_bullet(Vector2(0, -1))  # 前方
			create_bullet(Vector2(0.5, -0.866))  # 右前30度
			create_bullet(Vector2(-0.5, -0.866))  # 左前30度
			create_bullet(Vector2(0.5, 0.866))  # 右後30度
			create_bullet(Vector2(-0.5, 0.866))  # 左後30度
			create_bullet(Vector2(1, 0))  # 右
			create_bullet(Vector2(-1, 0))  # 左
			create_bullet(Vector2(0.707, -0.707))  # 右前45度
			create_bullet(Vector2(-0.707, -0.707))  # 左前45度
			create_bullet(Vector2(0.707, 0.707))  # 右後45度
			create_bullet(Vector2(-0.707, 0.707))  # 左後45度
			create_bullet(Vector2(0.866, -0.5))  # 右前60度
			create_bullet(Vector2(-0.866, -0.5))  # 左前60度
		6:  # 15WAY
			create_bullet(Vector2(0, -1))  # 前方
			create_bullet(Vector2(0.5, -0.866))  # 右前30度
			create_bullet(Vector2(-0.5, -0.866))  # 左前30度
			create_bullet(Vector2(0.5, 0.866))  # 右後30度
			create_bullet(Vector2(-0.5, 0.866))  # 左後30度
			create_bullet(Vector2(1, 0))  # 右
			create_bullet(Vector2(-1, 0))  # 左
			create_bullet(Vector2(0.707, -0.707))  # 右前45度
			create_bullet(Vector2(-0.707, -0.707))  # 左前45度
			create_bullet(Vector2(0.707, 0.707))  # 右後45度
			create_bullet(Vector2(-0.707, 0.707))  # 左後45度
			create_bullet(Vector2(0.866, -0.5))  # 右前60度
			create_bullet(Vector2(-0.866, -0.5))  # 左前60度
			create_bullet(Vector2(0.866, 0.5))  # 右後60度
			create_bullet(Vector2(-0.866, 0.5))  # 左後60度
		7:  # 17WAY
			create_bullet(Vector2(0, -1))  # 前方
			create_bullet(Vector2(0.5, -0.866))  # 右前30度
			create_bullet(Vector2(-0.5, -0.866))  # 左前30度
			create_bullet(Vector2(0.5, 0.866))  # 右後30度
			create_bullet(Vector2(-0.5, 0.866))  # 左後30度
			create_bullet(Vector2(1, 0))  # 右
			create_bullet(Vector2(-1, 0))  # 左
			create_bullet(Vector2(0.707, -0.707))  # 右前45度
			create_bullet(Vector2(-0.707, -0.707))  # 左前45度
			create_bullet(Vector2(0.707, 0.707))  # 右後45度
			create_bullet(Vector2(-0.707, 0.707))  # 左後45度
			create_bullet(Vector2(0.866, -0.5))  # 右前60度
			create_bullet(Vector2(-0.866, -0.5))  # 左前60度
			create_bullet(Vector2(0.866, 0.5))  # 右後60度
			create_bullet(Vector2(-0.866, 0.5))  # 左後60度
			create_bullet(Vector2(0.259, -0.966))  # 右前15度
			create_bullet(Vector2(-0.259, -0.966))  # 左前15度
		_:  # 18WAY（最大）
			create_bullet(Vector2(0, -1))  # 前方
			create_bullet(Vector2(0.5, -0.866))  # 右前30度
			create_bullet(Vector2(-0.5, -0.866))  # 左前30度
			create_bullet(Vector2(0.5, 0.866))  # 右後30度
			create_bullet(Vector2(-0.5, 0.866))  # 左後30度
			create_bullet(Vector2(1, 0))  # 右
			create_bullet(Vector2(-1, 0))  # 左
			create_bullet(Vector2(0.707, -0.707))  # 右前45度
			create_bullet(Vector2(-0.707, -0.707))  # 左前45度
			create_bullet(Vector2(0.707, 0.707))  # 右後45度
			create_bullet(Vector2(-0.707, 0.707))  # 左後45度
			create_bullet(Vector2(0.866, -0.5))  # 右前60度
			create_bullet(Vector2(-0.866, -0.5))  # 左前60度
			create_bullet(Vector2(0.866, 0.5))  # 右後60度
			create_bullet(Vector2(-0.866, 0.5))  # 左後60度
			create_bullet(Vector2(0.259, -0.966))  # 右前15度
			create_bullet(Vector2(-0.259, -0.966))  # 左前15度
			create_bullet(Vector2(0, 1))  # 後方

func create_bullet(direction: Vector2):
	var bullet = bullet_scene.instantiate()
	bullet.position = global_position
	bullet.direction = direction
	bullet.speed = 400.0
	bullet.modulate = Color.YELLOW
	
	# Sアイテム効果：弾の2倍ダメージ
	if bullet_double_damage:
		bullet.set_meta("double_damage", true)
		bullet.modulate = Color.CYAN  # 2倍ダメージ弾は青色
	
	# Rアイテム効果：弾丸貫通（敵弾消去）
	if bullet_piercing:
		bullet.set_meta("piercing", true)
		if not bullet_double_damage:  # 2倍ダメージ効果がない場合のみ色変更
			bullet.modulate = Color.MAGENTA  # 貫通弾は紫色
	
	emit_signal("bullet_fired", bullet)

func draw_pixel_art():
	var pixel_size = 4
	
	for row in range(player_pattern.size()):
		for col in range(player_pattern[row].size()):
			var pixel_value = player_pattern[row][col]
			if pixel_value > 0:
				var color = Color.WHITE
				if pixel_value == 2:
					color = Color.RED
				
				var rect = Rect2(
					Vector2((col - 4) * pixel_size, (row - 4) * pixel_size),
					Vector2(pixel_size, pixel_size)
				)
				draw_rect(rect, color)

func update_hitbox_effects(delta):
	# 被弾フラッシュエフェクトのタイマー更新
	if hitbox_flash_timer > 0:
		hitbox_flash_timer -= delta
		hitbox_flash_scale = 1.0 + (hitbox_flash_timer * 3.0)  # スケール効果
		queue_redraw()  # フラッシュ中は継続的に再描画
	else:
		hitbox_flash_scale = 1.0

func draw_hitbox():
	# 当たり判定の十字マークを描画
	var hitbox_color = Color.CYAN
	var flash_alpha = 1.0
	
	# フラッシュ効果中は色と透明度を変更
	if hitbox_flash_timer > 0:
		hitbox_color = Color.RED
		flash_alpha = 1.0
	else:
		hitbox_color = Color.CYAN
		flash_alpha = 0.8
	hitbox_color.a = flash_alpha
	
	var scale = hitbox_flash_scale
	var thickness = 1.5 * scale  # 線の太さ
	var length = 6 * scale  # 線の長さ
	
	# 十字マークを描画
	# 縦線
	draw_rect(Rect2(Vector2(-thickness/2, -length/2), Vector2(thickness, length)), hitbox_color)
	# 横線
	draw_rect(Rect2(Vector2(-length/2, -thickness/2), Vector2(length, thickness)), hitbox_color)

func trigger_damage_flash():
	# 被弾時のフラッシュエフェクトを開始
	hitbox_flash_timer = 0.3  # 0.3秒間フラッシュ
	queue_redraw()  # 即座に再描画を要求

# パワーアップ効果のメソッド群
func apply_power_boost():
	# パワーアップ（弾数増加）
	power_level = min(5, power_level + 1)  # 最大5段階まで
	print("Power Boost applied! Bullet count increased to level ", power_level)

func apply_size_boost():
	# 2倍ダメージブースト（弾のダメージ2倍）
	bullet_double_damage = true
	print("Double Damage applied! Bullets now deal 2x damage.")

func apply_rapid_boost():
	# 弾丸貫通（敵弾消去）
	bullet_piercing = true
	print("Piercing Bullets applied! Player bullets can destroy enemy bullets.")

func remove_power_boost():
	# パワーブースト効果を解除
	power_level = max(0, power_level - 1)
	print("Power Boost expired. Level decreased to ", power_level)

func remove_size_boost():
	# 2倍ダメージ効果を解除
	bullet_double_damage = false
	print("Double Damage expired. Bullet damage reset to normal.")

func remove_rapid_boost():
	# 弾丸貫通効果を解除
	bullet_piercing = false
	print("Piercing Bullets expired. Bullets no longer destroy enemy bullets.")

func reset_powerup_effects():
	# パワーアップ効果をリセット（デフォルト値に戻す）
	power_level = 0
	bullet_double_damage = false
	bullet_piercing = false
	speed = 200.0
	shoot_interval = 0.1
	print("All power-up effects reset to default values.")
