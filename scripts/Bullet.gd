extends Area2D

var direction: Vector2 = Vector2.UP
var speed: float = 300.0
var lifetime: float = 5.0
var bullet_type: String = "player"  # "player" or "enemy"

# 弾のドットパターン
var bullet_pattern = [
	[0, 0, 1, 1, 1, 1, 0, 0],
	[0, 1, 0, 0, 0, 0, 1, 0],
	[1, 0, 0, 1, 1, 0, 0, 1],
	[1, 0, 1, 1, 1, 1, 0, 1],
	[1, 0, 1, 1, 1, 1, 0, 1],
	[1, 0, 0, 1, 1, 0, 0, 1],
	[0, 1, 0, 0, 0, 0, 1, 0],
	[0, 0, 1, 1, 1, 1, 0, 0]
]

func _ready():
	# 物理演算を無効にして、Area2Dのみで衝突判定
	set_physics_process(true)

func _physics_process(delta):
	# 物理演算ではなく、位置を直接変更
	position += direction.normalized() * speed * delta
	
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
	
	# 画面外チェック
	var screen_size = get_viewport().get_visible_rect().size
	if position.x < -20 or position.x > screen_size.x + 20 or \
	   position.y < -20 or position.y > screen_size.y + 20:
		queue_free()

func _draw():
	draw_pixel_art()

func draw_pixel_art():
	var pixel_size = 2
	
	for row in range(bullet_pattern.size()):
		for col in range(bullet_pattern[row].size()):
			if bullet_pattern[row][col] == 1:
				var rect = Rect2(
					Vector2((col - 4) * pixel_size, (row - 4) * pixel_size),
					Vector2(pixel_size, pixel_size)
				)
				draw_rect(rect, modulate)
