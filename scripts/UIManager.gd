extends CanvasLayer

@onready var score_label = $GameInfo/InfoPanel/VBoxContainer/ScoreLabel
@onready var enemy_rate_label = $GameInfo/InfoPanel/VBoxContainer/EnemyRateLabel
@onready var lives_label = $GameInfo/InfoPanel/VBoxContainer/LivesLabel
@onready var stage_label = $GameInfo/InfoPanel/VBoxContainer/StageLabel
@onready var stage_progress = $GameInfo/InfoPanel/VBoxContainer/StageProgress
@onready var main_stage_progress_bar = $StageProgressBar
@onready var start_screen = $StartScreen
@onready var game_over_screen = $GameOverScreen
@onready var start_button = $StartScreen/Panel/VBoxContainer/StartButton
@onready var high_score_button = $StartScreen/Panel/VBoxContainer/HighScoreButton
@onready var restart_button = $GameOverScreen/Panel/VBoxContainer/RestartButton
@onready var view_high_scores_button = $GameOverScreen/Panel/VBoxContainer/ViewHighScoresButton
@onready var final_score_label = $GameOverScreen/Panel/VBoxContainer/FinalScoreLabel
@onready var flash_effect = $FlashEffect

var game_manager: Node2D
var high_score_screen: Control
var is_new_high_score: bool = false
var new_high_score_rank: int = -1

func _ready():
	game_manager = get_parent()
	
	# シグナルを接続
	game_manager.score_changed.connect(_on_score_changed)
	game_manager.lives_changed.connect(_on_lives_changed)
	game_manager.enemy_rate_changed.connect(_on_enemy_rate_changed)
	game_manager.game_over.connect(_on_game_over)
	game_manager.bomb_used.connect(_on_bomb_used)
	game_manager.enemy_destroyed_effect.connect(_on_enemy_destroyed_effect)
	game_manager.play_sound.connect(_on_play_sound)
	game_manager.stage_info_changed.connect(_on_stage_info_changed)
	
	# ボタンのシグナルを接続
	start_button.pressed.connect(_on_start_button_pressed)
	high_score_button.pressed.connect(_on_high_score_button_pressed)
	restart_button.pressed.connect(_on_restart_button_pressed)
	view_high_scores_button.pressed.connect(_on_view_high_scores_button_pressed)
	
	# ハイスコア画面を作成
	create_high_score_screen()
	
	# プログレスバーのスタイルを設定
	setup_progress_bar_style()
	
	# 初期状態でスタート画面を表示
	show_start_screen()

func _on_score_changed(new_score):
	score_label.text = "★ " + str(new_score).pad_zeros(6)

func _on_lives_changed(new_lives):
	var hearts = ""
	for i in range(new_lives):
		hearts += "♥"
	if new_lives <= 0:
		hearts = "💀"
	lives_label.text = hearts + " x" + str(new_lives)
	
	# ダメージを受けた時の赤フラッシュ
	if new_lives < game_manager.max_lives and new_lives > 0:
		flash_damage()

func _on_enemy_rate_changed(new_rate):
	var difficulty_level = ""
	if new_rate < 0.03:
		difficulty_level = "難易度: ★☆☆☆☆"
	elif new_rate < 0.05:
		difficulty_level = "難易度: ★★☆☆☆"
	elif new_rate < 0.07:
		difficulty_level = "難易度: ★★★☆☆"
	elif new_rate < 0.09:
		difficulty_level = "難易度: ★★★★☆"
	else:
		difficulty_level = "難易度: ★★★★★"
	enemy_rate_label.text = difficulty_level

func _on_game_over():
	# ハイスコアチェック
	check_high_score()
	show_game_over_screen()

func _on_start_button_pressed():
	hide_start_screen()
	game_manager.start_game()

func _on_high_score_button_pressed():
	if high_score_screen:
		high_score_screen.visible = true
		high_score_screen.display_high_scores()

func _on_restart_button_pressed():
	hide_game_over_screen()
	game_manager.restart_game()

func _on_view_high_scores_button_pressed():
	if high_score_screen:
		if is_new_high_score:
			high_score_screen.show_with_new_score(game_manager.score, new_high_score_rank)
		else:
			high_score_screen.visible = true
			high_score_screen.display_high_scores()

func show_start_screen():
	start_screen.visible = true
	game_over_screen.visible = false

func hide_start_screen():
	start_screen.visible = false

func show_game_over_screen():
	final_score_label.text = "Score: " + str(game_manager.score)
	
	# ハイスコアの場合は特別な表示
	if is_new_high_score:
		var rank_text = ""
		match new_high_score_rank:
			0:
				rank_text = "NEW HIGH SCORE! #1"
				final_score_label.add_theme_color_override("font_color", Color.GOLD)
			1:
				rank_text = "NEW HIGH SCORE! #2"
				final_score_label.add_theme_color_override("font_color", Color.SILVER)
			2:
				rank_text = "NEW HIGH SCORE! #3"
				final_score_label.add_theme_color_override("font_color", Color("#CD7F32"))
			_:
				rank_text = "NEW HIGH SCORE! #" + str(new_high_score_rank + 1)
				final_score_label.add_theme_color_override("font_color", Color.CYAN)
		
		final_score_label.text = rank_text + "\nScore: " + str(game_manager.score)
		
		# 新記録エフェクト
		play_new_record_effect()
	else:
		final_score_label.remove_theme_color_override("font_color")
	
	game_over_screen.visible = true

func hide_game_over_screen():
	game_over_screen.visible = false
	is_new_high_score = false
	new_high_score_rank = -1

func _on_bomb_used():
	# フラッシュエフェクトを実行
	flash_screen()

func flash_screen():
	if not flash_effect:
		print("Flash effect not found!")
		return
	
	print("Flash screen triggered!")
	
	# 瞬間的に白いフラッシュを表示
	flash_effect.modulate = Color.WHITE
	flash_effect.modulate.a = 1.0  # 完全な白
	flash_effect.visible = true
	
	# Tweenを作成してフェードアウト
	var tween = create_tween()
	# 0.2秒かけてフェードアウト
	tween.tween_property(flash_effect, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): 
		flash_effect.visible = false
		print("Flash effect finished")
	)

func flash_damage():
	if not flash_effect:
		print("Flash effect not found!")
		return
	
	print("Damage flash triggered!")
	
	# 瞬間的に赤いフラッシュを表示
	flash_effect.modulate = Color(1, 0, 0)  # 赤色
	flash_effect.modulate.a = 0.5  # 半透明
	flash_effect.visible = true
	
	# Tweenを作成してフェードアウト
	var tween = create_tween()
	# 0.3秒かけてフェードアウト
	tween.tween_property(flash_effect, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): 
		flash_effect.visible = false
		print("Damage flash finished")
	)

func _on_enemy_destroyed_effect(position: Vector2, score_points: int):
	# スコアポップアップエフェクトを作成
	create_score_popup(position, score_points)

func create_score_popup(world_position: Vector2, points: int):
	# スコアポップアップラベルを動的作成
	var popup_label = Label.new()
	popup_label.text = "+" + str(points)
	popup_label.add_theme_color_override("font_color", Color.YELLOW)
	popup_label.position = world_position - Vector2(20, 10)
	popup_label.z_index = 50
	
	# UIに追加
	add_child(popup_label)
	
	# アニメーション効果
	var tween = create_tween()
	tween.parallel().tween_property(popup_label, "position", popup_label.position + Vector2(0, -50), 1.0)
	tween.parallel().tween_property(popup_label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(func(): popup_label.queue_free())

func _on_play_sound(sound_name: String):
	# SoundManagerを使用して実際のサウンドを再生
	if game_manager.sound_manager:
		game_manager.sound_manager.play_sound(sound_name)
	else:
		# フォールバック（SoundManagerが無い場合）
		print("♪ Sound: ", sound_name)

func create_high_score_screen():
	var high_score_scene = preload("res://scenes/HighScoreScreen.tscn")
	high_score_screen = high_score_scene.instantiate()
	add_child(high_score_screen)
	high_score_screen.visible = false
	
	# GameManagerのhigh_score_managerを設定
	if game_manager and game_manager.get("high_score_manager") != null:
		high_score_screen.high_score_manager = game_manager.high_score_manager

func check_high_score():
	if game_manager.high_score_manager:
		var score = game_manager.score
		if game_manager.high_score_manager.is_high_score(score):
			is_new_high_score = true
			new_high_score_rank = game_manager.high_score_manager.add_high_score(score)
		else:
			is_new_high_score = false
			new_high_score_rank = -1

func play_new_record_effect():
	# 新記録達成時の特別なエフェクト
	var tween = create_tween()
	tween.set_loops(5)
	tween.tween_property(final_score_label, "scale", Vector2(1.2, 1.2), 0.3)
	tween.tween_property(final_score_label, "scale", Vector2(1.0, 1.0), 0.3)
	
	# 特別なフラッシュ
	flash_screen()
	await get_tree().create_timer(0.5).timeout
	flash_screen()

func _on_stage_info_changed(stage_number: int, stage_name: String, progress: float):
	stage_label.text = stage_name
	stage_progress.value = progress * 100.0  # 0-1を0-100に変換
	
	# メインのステージ進行バーを更新
	if main_stage_progress_bar:
		main_stage_progress_bar.value = progress * 100.0
		
		# ステージごとに色を変更
		match stage_number:
			1:
				main_stage_progress_bar.modulate = Color(0.2, 1, 0.2, 0.9)  # 緑
			2:
				main_stage_progress_bar.modulate = Color(0.2, 0.6, 1, 0.9)  # 青
			3:
				main_stage_progress_bar.modulate = Color(1, 1, 0.2, 0.9)  # 黄
			4:
				main_stage_progress_bar.modulate = Color(1, 0.3, 0.2, 0.9)  # 赤
			5:
				main_stage_progress_bar.modulate = Color(0.8, 0.2, 1, 0.9)  # 紫
		
		# ボス戦が近づいたら点滅効果
		if progress > 0.9:  # 90%以上
			var tween = create_tween()
			tween.set_loops()
			tween.tween_property(main_stage_progress_bar, "modulate:a", 0.5, 0.3)
			tween.tween_property(main_stage_progress_bar, "modulate:a", 0.9, 0.3)

func show_stage_clear(stage_number: int):
	# ステージクリアメッセージを表示
	var clear_label = Label.new()
	clear_label.text = "STAGE " + str(stage_number) + " CLEAR!"
	clear_label.add_theme_font_size_override("font_size", 48)
	clear_label.add_theme_color_override("font_color", Color.GOLD)
	clear_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	add_child(clear_label)
	
	# アニメーション
	var tween = create_tween()
	tween.tween_property(clear_label, "scale", Vector2(1.5, 1.5), 0.5)
	tween.parallel().tween_property(clear_label, "modulate:a", 0.0, 2.0)
	tween.tween_callback(func(): clear_label.queue_free())
	
	# 特別なフラッシュ
	flash_screen()

func show_all_stages_clear():
	# 全ステージクリアメッセージを表示
	var clear_label = Label.new()
	clear_label.text = "ALL STAGES CLEAR!\nCONGRATULATIONS!"
	clear_label.add_theme_font_size_override("font_size", 64)
	clear_label.add_theme_color_override("font_color", Color(1, 0.84, 0))  # ゴールド
	clear_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	clear_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(clear_label)
	
	# 豪華なアニメーション
	var tween = create_tween()
	tween.set_loops(3)
	tween.tween_property(clear_label, "scale", Vector2(1.2, 1.2), 0.5)
	tween.tween_property(clear_label, "scale", Vector2(1.0, 1.0), 0.5)
	
	# 連続フラッシュ
	for i in range(5):
		await get_tree().create_timer(0.3).timeout
		flash_screen()

func setup_progress_bar_style():
	if main_stage_progress_bar:
		# プログレスバーを目立たせる
		var style_box_bg = StyleBoxFlat.new()
		style_box_bg.bg_color = Color(0, 0, 0, 0.5)
		style_box_bg.border_width_top = 2
		style_box_bg.border_width_bottom = 2
		style_box_bg.border_width_left = 2
		style_box_bg.border_width_right = 2
		style_box_bg.border_color = Color(1, 1, 1, 0.8)
		
		var style_box_fill = StyleBoxFlat.new()
		style_box_fill.bg_color = Color(1, 1, 1, 1)
		style_box_fill.corner_radius_top_left = 2
		style_box_fill.corner_radius_top_right = 2
		style_box_fill.corner_radius_bottom_left = 2
		style_box_fill.corner_radius_bottom_right = 2
		
		main_stage_progress_bar.add_theme_stylebox_override("background", style_box_bg)
		main_stage_progress_bar.add_theme_stylebox_override("fill", style_box_fill)

