extends Node

# 設定管理システム - Phase 3 難易度選択システム基盤
# 設定の保存・読み込み、デフォルト値管理を担当

signal settings_changed

# 難易度定義
enum Difficulty {
	EASY,
	NORMAL, 
	HARD,
	LUNATIC
}

# 設定データ構造
var settings_data = {
	"difficulty": Difficulty.NORMAL,
	"master_volume": 1.0,
	"sound_effects": true,
	"show_hitbox": true,
	"screen_shake": true,
	"version": "1.0"
}

# 難易度別設定
var difficulty_configs = {
	Difficulty.EASY: {
		"name": "EASY",
		"display_name": "🟢 EASY",
		"description": "Relaxed gameplay for beginners",
		"enemy_spawn_multiplier": 0.7,
		"enemy_health_multiplier": 0.8,
		"enemy_speed_multiplier": 0.8,
		"bullet_speed_multiplier": 0.8,
		"boss_health_multiplier": 0.33,  # ボスHP 1/3
		"color": Color(0.2, 1.0, 0.2)
	},
	Difficulty.NORMAL: {
		"name": "NORMAL", 
		"display_name": "🔵 NORMAL",
		"description": "Standard balanced experience",
		"enemy_spawn_multiplier": 1.0,
		"enemy_health_multiplier": 1.0,
		"enemy_speed_multiplier": 1.0,
		"bullet_speed_multiplier": 1.0,
		"boss_health_multiplier": 1.0,  # ボスHP 標準
		"color": Color(0.2, 0.5, 1.0)
	},
	Difficulty.HARD: {
		"name": "HARD",
		"display_name": "🟡 HARD", 
		"description": "Challenging gameplay for experienced players",
		"enemy_spawn_multiplier": 1.3,
		"enemy_health_multiplier": 1.2,
		"enemy_speed_multiplier": 1.2,
		"bullet_speed_multiplier": 1.2,
		"boss_health_multiplier": 1.5,  # ボスHP 1.5倍
		"color": Color(1.0, 1.0, 0.2)
	},
	Difficulty.LUNATIC: {
		"name": "LUNATIC",
		"display_name": "🔴 LUNATIC",
		"description": "Extreme difficulty for masters only",
		"enemy_spawn_multiplier": 1.5,
		"enemy_health_multiplier": 1.5,
		"enemy_speed_multiplier": 1.5,
		"bullet_speed_multiplier": 1.5,
		"boss_health_multiplier": 2.0,  # ボスHP 2倍
		"color": Color(1.0, 0.2, 0.2)
	}
}

var save_path = "user://settings.save"

func _ready():
	load_settings()

func get_current_difficulty() -> Difficulty:
	return settings_data.difficulty

func get_difficulty_config(difficulty: Difficulty = -1) -> Dictionary:
	if difficulty == -1:
		difficulty = get_current_difficulty()
	return difficulty_configs.get(difficulty, difficulty_configs[Difficulty.NORMAL])

func set_difficulty(difficulty: Difficulty):
	if difficulty in difficulty_configs:
		settings_data.difficulty = difficulty
		save_settings()
		emit_signal("settings_changed")
		print("Difficulty changed to: ", get_difficulty_config(difficulty).name)

func get_setting(key: String, default_value = null):
	return settings_data.get(key, default_value)

func set_setting(key: String, value):
	settings_data[key] = value
	save_settings()
	emit_signal("settings_changed")

func save_settings():
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(settings_data)
		file.store_string(json_string)
		file.close()
		print("Settings saved successfully")
	else:
		print("Failed to save settings")

func load_settings():
	var file = FileAccess.open(save_path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if parse_result == OK:
			var loaded_data = json.data
			if typeof(loaded_data) == TYPE_DICTIONARY:
				# マージして欠損値をデフォルトで補完
				for key in settings_data.keys():
					if key in loaded_data:
						settings_data[key] = loaded_data[key]
				print("Settings loaded successfully")
				return
	
	# ファイルが存在しないか読み込み失敗時はデフォルト設定を保存
	print("Loading default settings")
	save_settings()

func reset_to_defaults():
	settings_data = {
		"difficulty": Difficulty.NORMAL,
		"master_volume": 1.0,
		"sound_effects": true,
		"show_hitbox": true,
		"screen_shake": true,
		"version": "1.0"
	}
	save_settings()
	emit_signal("settings_changed")
	print("Settings reset to defaults")

func get_all_difficulties() -> Array:
	return [Difficulty.EASY, Difficulty.NORMAL, Difficulty.HARD, Difficulty.LUNATIC]

# デバッグ用：設定内容を表示
func print_current_settings():
	print("=== Current Settings ===")
	for key in settings_data.keys():
		print(key, ": ", settings_data[key])
	print("Current difficulty config: ", get_difficulty_config())