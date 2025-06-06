extends Area2D

signal powerup_collected(item_type)

@export var item_type: String = "P"
@export var fall_speed: float = 50.0

var item_configs = {
	"P": {"name": "Power", "color": Color(1.0, 0.2, 0.2), "description": "Bullet Count UP! (Permanent)"},      # 明るい赤
	"S": {"name": "Size", "color": Color(0.2, 0.5, 1.0), "description": "Double Damage! (30s)"},    # 明るい青
	"R": {"name": "Rapid", "color": Color(1.0, 1.0, 0.2), "description": "Piercing Bullets! (10s)"},         # 明るい黄色
	"B": {"name": "Bomb", "color": Color(0.2, 1.0, 0.2), "description": "Life +1"},                # 明るい緑
	"1UP": {"name": "1UP", "color": Color(1.0, 0.2, 1.0), "description": "Extra Life!"}            # 明るいマゼンタ
}

func _ready():
	# コリジョンシェイプを設定（24x24サイズに対応）
	var collision = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 15  # 24x24サイズに適したコリジョン
	collision.shape = circle_shape
	add_child(collision)
	
	# 自動削除タイマー（10秒後）
	var timer = Timer.new()
	timer.wait_time = 10.0
	timer.one_shot = true
	timer.timeout.connect(_on_timeout)
	add_child(timer)
	timer.start()
	
	# 視認性向上のための軽い点滅エフェクト
	var blink_timer = Timer.new()
	blink_timer.wait_time = 0.5
	blink_timer.timeout.connect(_on_blink)
	add_child(blink_timer)
	blink_timer.start()
	
	print("PowerUp created: ", item_type)

func _physics_process(delta):
	# 下に落下
	position.y += fall_speed * delta
	
	# 画面外で削除
	if position.y > 700:
		queue_free()

func _draw():
	var config = item_configs.get(item_type, item_configs["P"])
	var color = config.color
	
	# 8x8のアイテムパターンを3倍サイズ（24x24）で描画
	var item_pattern = get_item_pattern(item_type)
	var pixel_size = 3  # 3x3ピクセルで描画
	
	for y in range(8):
		for x in range(8):
			var pixel = item_pattern[y][x]
			if pixel == 1:
				draw_rect(Rect2((x - 4) * pixel_size, (y - 4) * pixel_size, pixel_size, pixel_size), color)
			elif pixel == 2:
				draw_rect(Rect2((x - 4) * pixel_size, (y - 4) * pixel_size, pixel_size, pixel_size), Color.WHITE)

func get_item_pattern(type: String) -> Array:
	match type:
		"P":  # Power アイテム - P字形 (8x8)
			return [
				[1,1,1,1,1,1,0,0],
				[1,2,2,2,2,2,1,0],
				[1,2,2,2,2,2,1,0],
				[1,1,1,1,1,1,0,0],
				[1,2,2,2,0,0,0,0],
				[1,2,2,2,0,0,0,0],
				[1,2,2,2,0,0,0,0],
				[1,1,1,1,0,0,0,0]
			]
		"S":  # Speed アイテム - S字形 (8x8)
			return [
				[0,1,1,1,1,1,1,0],
				[1,2,2,2,2,2,2,1],
				[1,2,2,0,0,0,0,0],
				[0,1,1,1,1,0,0,0],
				[0,0,0,1,1,1,1,0],
				[0,0,0,0,0,2,2,1],
				[1,2,2,2,2,2,2,1],
				[0,1,1,1,1,1,1,0]
			]
		"R":  # Rapid アイテム - R字形 (8x8)
			return [
				[1,1,1,1,1,1,0,0],
				[1,2,2,2,2,2,1,0],
				[1,2,2,2,2,2,1,0],
				[1,1,1,1,1,1,0,0],
				[1,2,2,1,1,0,0,0],
				[1,2,2,2,1,0,0,0],
				[1,2,2,2,2,1,0,0],
				[1,1,1,1,1,1,0,0]
			]
		"B":  # Bomb アイテム - 爆弾形 (8x8)
			return [
				[0,0,1,1,0,0,0,0],
				[0,1,2,2,1,0,0,0],
				[1,2,2,2,2,1,0,0],
				[1,2,2,2,2,2,1,0],
				[1,2,2,2,2,2,1,0],
				[1,2,2,2,2,2,1,0],
				[0,1,2,2,2,1,0,0],
				[0,0,1,1,1,0,0,0]
			]
		"1UP":  # 1UP アイテム - ハート形 (8x8)
			return [
				[0,1,1,0,1,1,0,0],
				[1,2,2,1,2,2,1,0],
				[1,2,2,2,2,2,1,0],
				[1,2,2,2,2,2,1,0],
				[0,1,2,2,2,1,0,0],
				[0,0,1,2,1,0,0,0],
				[0,0,0,1,0,0,0,0],
				[0,0,0,0,0,0,0,0]
			]
		_:
			return get_item_pattern("P")  # デフォルト

func _on_timeout():
	# タイムアウトで点滅して消える
	var tween = create_tween()
	tween.set_loops(5)
	tween.tween_property(self, "modulate:a", 0.3, 0.2)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	tween.tween_callback(func(): queue_free())

func _on_blink():
	# 軽い点滅エフェクト（透明度を1.0→0.8→1.0）
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.8, 0.1)
	tween.tween_property(self, "modulate:a", 1.0, 0.1)

func collect():
	emit_signal("powerup_collected", item_type)
	queue_free()