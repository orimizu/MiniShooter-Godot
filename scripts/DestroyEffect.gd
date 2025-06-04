extends CPUParticles2D

# スコアポップアップ表示用のLabel
var score_label: Label

func _ready():
	# スコア表示用のラベルを作成
	score_label = Label.new()
	add_child(score_label)
	score_label.add_theme_font_size_override("font_size", 24)
	score_label.position = Vector2(-20, -30)
	score_label.modulate = Color.YELLOW
	
	# パーティクル開始
	emitting = true
	
	# 一定時間後に自動削除
	await get_tree().create_timer(1.5).timeout
	queue_free()

func set_score_points(points: int):
	if score_label:
		score_label.text = "+" + str(points)

func set_particle_color(enemy_color: String):
	# 敵の色に応じてパーティクルの色を変更
	var gradient = Gradient.new()
	gradient.set_offset(0, 0)
	gradient.set_offset(1, 0.3)
	gradient.set_offset(2, 0.7)
	gradient.set_offset(3, 1)
	
	match enemy_color:
		"red":
			gradient.set_color(0, Color.WHITE)
			gradient.set_color(1, Color(1, 0.5, 0.3))
			gradient.set_color(2, Color(1, 0.2, 0))
			gradient.set_color(3, Color(0.5, 0, 0, 0))
		"yellow":
			gradient.set_color(0, Color.WHITE)
			gradient.set_color(1, Color(1, 1, 0.3))
			gradient.set_color(2, Color(1, 0.8, 0))
			gradient.set_color(3, Color(0.5, 0.4, 0, 0))
		"cyan":
			gradient.set_color(0, Color.WHITE)
			gradient.set_color(1, Color(0.3, 1, 1))
			gradient.set_color(2, Color(0, 0.8, 1))
			gradient.set_color(3, Color(0, 0.4, 0.5, 0))
		"blue":
			gradient.set_color(0, Color.WHITE)
			gradient.set_color(1, Color(0.3, 0.5, 1))
			gradient.set_color(2, Color(0, 0.2, 1))
			gradient.set_color(3, Color(0, 0, 0.5, 0))
		"green":
			gradient.set_color(0, Color.WHITE)
			gradient.set_color(1, Color(0.3, 1, 0.3))
			gradient.set_color(2, Color(0, 1, 0))
			gradient.set_color(3, Color(0, 0.5, 0, 0))
		"magenta":
			gradient.set_color(0, Color.WHITE)
			gradient.set_color(1, Color(1, 0.3, 1))
			gradient.set_color(2, Color(1, 0, 1))
			gradient.set_color(3, Color(0.5, 0, 0.5, 0))
		_:
			# デフォルトカラー（白→オレンジ→赤）
			gradient.set_color(0, Color.WHITE)
			gradient.set_color(1, Color(1, 0.8, 0.2))
			gradient.set_color(2, Color(1, 0.4, 0))
			gradient.set_color(3, Color(1, 0, 0, 0))
	
	color_ramp = gradient

func _on_ScoreLabel_item_rect_changed():
	# スコアラベルの位置を調整
	if score_label:
		score_label.position = Vector2(-score_label.size.x / 2, -40)