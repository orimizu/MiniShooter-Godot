extends Control

@onready var achievement_list = $Panel/VBoxContainer/ScrollContainer/AchievementList
@onready var back_button = $Panel/VBoxContainer/BackButton
@onready var progress_label = $Panel/VBoxContainer/HeaderContainer/ProgressLabel
@onready var category_container = $Panel/VBoxContainer/CategoryContainer

var achievement_manager: Node
var current_category: String = "all"
var category_buttons: Dictionary = {}

# カテゴリ定義
var categories = {
	"all": {"name": "All", "color": Color.WHITE},
	"combat": {"name": "Combat", "color": Color.RED},
	"boss": {"name": "Boss", "color": Color.PURPLE},
	"score": {"name": "Score", "color": Color.YELLOW},
	"clear": {"name": "Clear", "color": Color.GREEN},
	"special": {"name": "Special", "color": Color.MAGENTA}
}

func _ready():
	back_button.pressed.connect(_on_back_button_pressed)
	
	# AchievementManagerを取得
	get_achievement_manager()
	
	# カテゴリボタンを作成
	setup_category_buttons()
	
	# 初期表示
	display_achievements()

func get_achievement_manager():
	var game_manager = get_node("/root/Main")
	if game_manager and is_instance_valid(game_manager) and game_manager.get("achievement_manager") != null:
		achievement_manager = game_manager.achievement_manager
		return true
	return false

func setup_category_buttons():
	# カテゴリボタンを動的に作成
	for category_id in categories:
		var button = Button.new()
		button.text = categories[category_id].name
		button.custom_minimum_size = Vector2(80, 30)
		button.add_theme_font_size_override("font_size", 14)
		
		# ボタンイベント
		button.pressed.connect(func(): _on_category_button_pressed(category_id))
		
		category_container.add_child(button)
		category_buttons[category_id] = button
	
	# 初期選択状態を設定
	update_category_button_states()

func _on_category_button_pressed(category: String):
	current_category = category
	update_category_button_states()
	display_achievements()

func update_category_button_states():
	for category_id in category_buttons:
		var button = category_buttons[category_id]
		if category_id == current_category:
			button.add_theme_color_override("font_color", categories[category_id].color)
			button.modulate = Color(1.2, 1.2, 1.2)
		else:
			button.remove_theme_color_override("font_color")
			button.modulate = Color(0.7, 0.7, 0.7)

func display_achievements():
	if not achievement_manager:
		if not get_achievement_manager():
			print("Failed to get AchievementManager")
			return
	
	# 既存のエントリをクリア
	for child in achievement_list.get_children():
		child.queue_free()
	
	# 実績リストを取得
	var achievements = []
	if current_category == "all":
		achievements = achievement_manager.get_all_achievements()
	else:
		achievements = achievement_manager.get_achievements_by_category(current_category)
	
	# 進捗を更新
	update_progress_display()
	
	# 各実績を表示
	for achievement_data in achievements:
		create_achievement_entry(achievement_data)

func create_achievement_entry(achievement_data: Dictionary):
	var container = PanelContainer.new()
	container.custom_minimum_size = Vector2(400, 80)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	container.add_child(hbox)
	
	# アイコン部分
	var icon_container = VBoxContainer.new()
	icon_container.custom_minimum_size = Vector2(60, 60)
	icon_container.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(icon_container)
	
	var icon_label = Label.new()
	icon_label.text = achievement_data.definition.icon
	icon_label.add_theme_font_size_override("font_size", 32)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_container.add_child(icon_label)
	
	# テキスト部分
	var text_container = VBoxContainer.new()
	text_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(text_container)
	
	var name_label = Label.new()
	name_label.text = achievement_data.definition.name
	name_label.add_theme_font_size_override("font_size", 18)
	text_container.add_child(name_label)
	
	var desc_label = Label.new()
	desc_label.text = achievement_data.definition.description
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	text_container.add_child(desc_label)
	
	# 進捗バー（未解除の場合）
	if not achievement_data.progress.unlocked:
		var progress_container = HBoxContainer.new()
		text_container.add_child(progress_container)
		
		var progress_bar = ProgressBar.new()
		progress_bar.custom_minimum_size = Vector2(200, 16)
		progress_bar.max_value = achievement_data.definition.target
		progress_bar.value = achievement_data.progress.progress
		progress_bar.show_percentage = false
		progress_container.add_child(progress_bar)
		
		var progress_label = Label.new()
		progress_label.text = " %d/%d" % [achievement_data.progress.progress, achievement_data.definition.target]
		progress_label.add_theme_font_size_override("font_size", 12)
		progress_container.add_child(progress_label)
		
		# 未解除はグレーアウト
		container.modulate = Color(0.6, 0.6, 0.6)
		icon_label.modulate = Color(0.4, 0.4, 0.4)
	else:
		# 解除済みの場合
		var unlock_label = Label.new()
		unlock_label.text = "✓ Unlocked: " + achievement_data.progress.unlock_date
		unlock_label.add_theme_font_size_override("font_size", 12)
		unlock_label.add_theme_color_override("font_color", Color.GREEN)
		text_container.add_child(unlock_label)
		
		# カテゴリ色でハイライト
		var category_color = categories.get(achievement_data.definition.category, {}).get("color", Color.WHITE)
		name_label.add_theme_color_override("font_color", category_color)
	
	# ボーナススコア表示
	var bonus_label = Label.new()
	bonus_label.text = "+" + str(achievement_data.definition.bonus_score)
	bonus_label.add_theme_font_size_override("font_size", 16)
	bonus_label.add_theme_color_override("font_color", Color.GOLD)
	bonus_label.custom_minimum_size = Vector2(60, 20)
	bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(bonus_label)
	
	achievement_list.add_child(container)
	
	# セパレーター
	var separator = HSeparator.new()
	achievement_list.add_child(separator)

func update_progress_display():
	if not achievement_manager:
		return
	
	var count = achievement_manager.get_achievement_count()
	progress_label.text = "Progress: %d/%d (%d%%)" % [
		count.unlocked, 
		count.total,
		int((float(count.unlocked) / float(count.total)) * 100)
	]
	
	# 進捗に応じて色を変更
	var ratio = float(count.unlocked) / float(count.total)
	if ratio == 1.0:
		progress_label.add_theme_color_override("font_color", Color.GOLD)
	elif ratio >= 0.75:
		progress_label.add_theme_color_override("font_color", Color.GREEN)
	elif ratio >= 0.5:
		progress_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		progress_label.add_theme_color_override("font_color", Color.WHITE)

func _on_back_button_pressed():
	visible = false

func show_screen():
	visible = true
	display_achievements()