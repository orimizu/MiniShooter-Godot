extends CanvasLayer

# 難易度選択画面 - Phase 3 実装
# プレイヤーが4段階の難易度から選択できるUI

signal difficulty_selected(difficulty)

@onready var difficulty_container = $Panel/VBoxContainer/DifficultyContainer
@onready var back_button = $Panel/VBoxContainer/BackButton
@onready var start_button = $Panel/VBoxContainer/StartButton
@onready var description_label = $Panel/VBoxContainer/DescriptionLabel
@onready var title_label = $Panel/VBoxContainer/TitleLabel

var settings_manager: Node
var selected_difficulty = SettingsManager.Difficulty.NORMAL
var difficulty_buttons: Array = []

func _ready():
	# SettingsManagerの参照を取得
	settings_manager = get_node("/root/Main/SettingsManager")
	if not settings_manager:
		print("Warning: SettingsManager not found!")
		return
	
	setup_ui()
	setup_difficulty_buttons()
	
	# 現在の難易度を初期選択として設定
	selected_difficulty = settings_manager.get_current_difficulty()
	update_ui_for_selected_difficulty()
	
	# ボタンイベントの接続
	back_button.pressed.connect(_on_back_pressed)
	start_button.pressed.connect(_on_start_pressed)

func setup_ui():
	# タイトル設定
	title_label.text = "SELECT DIFFICULTY"
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# 説明ラベル設定
	description_label.text = "Choose your challenge level"
	description_label.add_theme_font_size_override("font_size", 16)
	description_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# ボタンスタイル設定
	start_button.text = "START GAME"
	back_button.text = "BACK"

func setup_difficulty_buttons():
	# 既存のボタンをクリア
	for child in difficulty_container.get_children():
		child.queue_free()
	difficulty_buttons.clear()
	
	# 各難易度のボタンを作成
	var difficulties = settings_manager.get_all_difficulties()
	for difficulty in difficulties:
		var config = settings_manager.get_difficulty_config(difficulty)
		var button = create_difficulty_button(difficulty, config)
		difficulty_container.add_child(button)
		difficulty_buttons.append(button)

func create_difficulty_button(difficulty: SettingsManager.Difficulty, config: Dictionary) -> Button:
	var button = Button.new()
	button.text = config.display_name
	button.custom_minimum_size = Vector2(300, 60)
	
	# ボタンスタイル
	button.add_theme_font_size_override("font_size", 20)
	
	# ボタンイベント
	button.pressed.connect(func(): _on_difficulty_selected(difficulty))
	button.mouse_entered.connect(func(): _on_difficulty_hovered(difficulty))
	
	# カスタムプロパティとして難易度を保存
	button.set_meta("difficulty", difficulty)
	
	return button

func _on_difficulty_selected(difficulty: SettingsManager.Difficulty):
	selected_difficulty = difficulty
	settings_manager.set_difficulty(difficulty)
	update_ui_for_selected_difficulty()

func _on_difficulty_hovered(difficulty: SettingsManager.Difficulty):
	var config = settings_manager.get_difficulty_config(difficulty)
	description_label.text = config.description

func update_ui_for_selected_difficulty():
	var current_config = settings_manager.get_difficulty_config(selected_difficulty)
	
	# 選択状態を視覚的に表示
	for button in difficulty_buttons:
		var button_difficulty = button.get_meta("difficulty")
		if button_difficulty == selected_difficulty:
			button.add_theme_color_override("font_color", current_config.color)
			button.add_theme_color_override("font_pressed_color", current_config.color)
			# 選択されたボタンを強調
			var tween = create_tween()
			tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1)
		else:
			button.remove_theme_color_override("font_color")
			button.remove_theme_color_override("font_pressed_color")
			button.scale = Vector2(1.0, 1.0)
	
	# 説明テキストを更新
	description_label.text = current_config.description
	description_label.add_theme_color_override("font_color", current_config.color)

func _on_start_pressed():
	emit_signal("difficulty_selected", selected_difficulty)
	hide()

func _on_back_pressed():
	hide()

func show_screen():
	visible = true
	# 現在の設定を再読み込み
	if settings_manager:
		selected_difficulty = settings_manager.get_current_difficulty()
		update_ui_for_selected_difficulty()

func hide_screen():
	visible = false

# デバッグ用：難易度情報を表示
func _input(event):
	if event.is_action_pressed("ui_accept") and visible:
		print("Selected difficulty: ", settings_manager.get_difficulty_config(selected_difficulty).name)