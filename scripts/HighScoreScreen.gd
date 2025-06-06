extends Control

@onready var score_list = $Panel/VBoxContainer/ScoreList
@onready var back_button = $Panel/VBoxContainer/BackButton

var high_score_manager: Node
var current_difficulty_display: int = 1  # デフォルトはNORMAL
var difficulty_buttons: Array = []

func _ready():
	back_button.pressed.connect(_on_back_button_pressed)
	
	# HighScoreManagerを取得を試みる
	get_high_score_manager()
	
	# 難易度選択ボタンを作成
	setup_difficulty_buttons()

func get_high_score_manager():
	# HighScoreManagerを取得
	var game_manager = get_node("/root/Main")
	if game_manager and is_instance_valid(game_manager) and game_manager.get("high_score_manager") != null:
		high_score_manager = game_manager.high_score_manager
		return true
	return false

func display_high_scores():
	# HighScoreManagerが無い場合は再取得を試みる
	if not high_score_manager:
		if not get_high_score_manager():
			print("Failed to get HighScoreManager")
			return
	
	# 既存のエントリをクリア
	for child in score_list.get_children():
		child.queue_free()
	
	var high_scores = high_score_manager.get_high_scores(current_difficulty_display)
	
	# ヘッダー行を追加
	var header = HBoxContainer.new()
	score_list.add_child(header)
	
	var rank_header = Label.new()
	rank_header.text = "Rank"
	rank_header.custom_minimum_size.x = 60
	rank_header.add_theme_color_override("font_color", Color.YELLOW)
	header.add_child(rank_header)
	
	var score_header = Label.new()
	score_header.text = "Score"
	score_header.custom_minimum_size.x = 120
	score_header.add_theme_color_override("font_color", Color.YELLOW)
	header.add_child(score_header)
	
	var stage_header = Label.new()
	stage_header.text = "Stage"
	stage_header.custom_minimum_size.x = 60
	stage_header.add_theme_color_override("font_color", Color.YELLOW)
	header.add_child(stage_header)
	
	var date_header = Label.new()
	date_header.text = "Date"
	date_header.custom_minimum_size.x = 100
	date_header.add_theme_color_override("font_color", Color.YELLOW)
	header.add_child(date_header)
	
	# セパレーター
	var separator = HSeparator.new()
	score_list.add_child(separator)
	
	# スコアエントリを表示
	for i in range(high_scores.size()):
		var entry = high_scores[i]
		var row = HBoxContainer.new()
		score_list.add_child(row)
		
		var rank_label = Label.new()
		rank_label.text = str(entry.rank)
		rank_label.custom_minimum_size.x = 60
		
		# トップ3は特別な色
		match i:
			0:
				rank_label.add_theme_color_override("font_color", Color.GOLD)
			1:
				rank_label.add_theme_color_override("font_color", Color.SILVER)
			2:
				rank_label.add_theme_color_override("font_color", Color("#CD7F32"))  # ブロンズ
		
		row.add_child(rank_label)
		
		var score_label = Label.new()
		score_label.text = str(entry.score).pad_zeros(7)
		score_label.custom_minimum_size.x = 120
		row.add_child(score_label)
		
		var stage_label = Label.new()
		stage_label.text = str(entry.stage)
		stage_label.custom_minimum_size.x = 60
		row.add_child(stage_label)
		
		var date_label = Label.new()
		date_label.text = entry.date
		date_label.custom_minimum_size.x = 100
		row.add_child(date_label)

func show_with_new_score(score: int, rank: int):
	visible = true
	display_high_scores()
	
	# 新記録の行をハイライト
	if rank >= 0 and rank < score_list.get_child_count() - 2:  # ヘッダーとセパレーターを除く
		var highlight_row = score_list.get_child(rank + 2)  # +2 for header and separator
		if highlight_row:
			# 点滅エフェクト
			var tween = create_tween()
			tween.set_loops(3)
			tween.tween_property(highlight_row, "modulate", Color(2, 2, 0), 0.3)
			tween.tween_property(highlight_row, "modulate", Color.WHITE, 0.3)

func _on_back_button_pressed():
	visible = false

func setup_difficulty_buttons():
	# 難易度選択ボタンを動的に作成してback_buttonの前に挿入
	var vbox = back_button.get_parent()
	var back_button_index = back_button.get_index()
	
	# 難易度ボタンコンテナ
	var difficulty_container = HBoxContainer.new()
	difficulty_container.add_theme_constant_override("separation", 10)
	vbox.add_child(difficulty_container)
	vbox.move_child(difficulty_container, back_button_index)
	
	# 各難易度ボタンを作成
	var difficulties = [0, 1, 2, 3]  # EASY, NORMAL, HARD, LUNATIC
	var difficulty_names = ["EASY", "NORMAL", "HARD", "LUNATIC"]
	var difficulty_colors = [Color.GREEN, Color.CYAN, Color.YELLOW, Color.RED]
	
	for i in range(difficulties.size()):
		var difficulty = difficulties[i]
		var button = Button.new()
		button.text = difficulty_names[i]
		button.custom_minimum_size = Vector2(80, 30)
		button.add_theme_font_size_override("font_size", 14)
		
		# ボタンイベント
		button.pressed.connect(func(): _on_difficulty_button_pressed(difficulty))
		
		difficulty_container.add_child(button)
		difficulty_buttons.append(button)
	
	# 初期選択状態を設定
	update_difficulty_button_states()

func _on_difficulty_button_pressed(difficulty: int):
	current_difficulty_display = difficulty
	update_difficulty_button_states()
	display_high_scores()

func update_difficulty_button_states():
	# 選択状態を視覚的に表示
	var difficulty_colors = [Color.GREEN, Color.CYAN, Color.YELLOW, Color.RED]
	
	for i in range(difficulty_buttons.size()):
		var button = difficulty_buttons[i]
		if i == current_difficulty_display:
			button.add_theme_color_override("font_color", difficulty_colors[i])
			button.modulate = Color(1.2, 1.2, 1.2)
		else:
			button.remove_theme_color_override("font_color")
			button.modulate = Color(0.7, 0.7, 0.7)