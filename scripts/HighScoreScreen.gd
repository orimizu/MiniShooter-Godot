extends Control

@onready var score_list = $Panel/VBoxContainer/ScoreList
@onready var back_button = $Panel/VBoxContainer/BackButton

var high_score_manager: Node

func _ready():
	back_button.pressed.connect(_on_back_button_pressed)
	
	# HighScoreManagerを取得を試みる
	get_high_score_manager()

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
	
	var high_scores = high_score_manager.get_high_scores()
	
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