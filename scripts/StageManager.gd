extends Node

signal stage_changed(stage_number)
signal stage_cleared()
signal all_stages_cleared()
signal boss_spawned(boss)

const MAX_STAGES = 5
const STAGE_DURATION = 60.0  # 各ステージ60秒
const BOSS_SPAWN_TIME = 55.0  # 55秒でボス出現

var current_stage: int = 1
var stage_timer: float = 0.0
var is_boss_spawned: bool = false
var stage_active: bool = false
var game_manager: Node2D

# ステージごとの設定
var stage_configs = {
	1: {
		"name": "Stage 1 - Green Fields",
		"bg_color": Color(0.1, 0.3, 0.1),
		"enemy_weights": {"red": 0.5, "yellow": 0.3, "cyan": 0.2},
		"enemy_rate_multiplier": 1.0,
		"boss_type": "green_boss"
	},
	2: {
		"name": "Stage 2 - Blue Ocean", 
		"bg_color": Color(0.1, 0.2, 0.4),
		"enemy_weights": {"blue": 0.4, "cyan": 0.4, "yellow": 0.2},
		"enemy_rate_multiplier": 1.2,
		"boss_type": "blue_boss"
	},
	3: {
		"name": "Stage 3 - Yellow Desert",
		"bg_color": Color(0.3, 0.3, 0.1),
		"enemy_weights": {"yellow": 0.5, "red": 0.3, "green": 0.2},
		"enemy_rate_multiplier": 1.4,
		"boss_type": "yellow_boss"
	},
	4: {
		"name": "Stage 4 - Red Volcano",
		"bg_color": Color(0.3, 0.1, 0.1),
		"enemy_weights": {"red": 0.4, "magenta": 0.3, "green": 0.3},
		"enemy_rate_multiplier": 1.6,
		"boss_type": "red_boss"
	},
	5: {
		"name": "Stage 5 - Purple Void",
		"bg_color": Color(0.2, 0.1, 0.3),
		"enemy_weights": {"magenta": 0.5, "cyan": 0.25, "green": 0.25},
		"enemy_rate_multiplier": 2.0,
		"boss_type": "final_boss"
	}
}

func _ready():
	game_manager = get_parent()

func start_stage(stage_number: int):
	current_stage = stage_number
	stage_timer = 0.0
	is_boss_spawned = false
	stage_active = true
	
	var config = stage_configs.get(current_stage, stage_configs[1])
	
	# 背景色を変更
	RenderingServer.set_default_clear_color(config.bg_color)
	
	emit_signal("stage_changed", current_stage)
	
	print("Starting ", config.name)

func _process(delta):
	if not stage_active:
		return
		
	stage_timer += delta
	
	# ボス出現チェック
	if not is_boss_spawned and stage_timer >= BOSS_SPAWN_TIME:
		spawn_boss()
	
	# ステージ時間制限チェック（ボスなしでクリア）
	if stage_timer >= STAGE_DURATION and not is_boss_spawned:
		complete_stage()

func spawn_boss():
	is_boss_spawned = true
	var config = stage_configs.get(current_stage, stage_configs[1])
	
	# ボスを生成
	var boss_scene = load("res://scenes/Boss.tscn")
	var boss = boss_scene.instantiate()
	boss.boss_type = config.boss_type
	boss.position = Vector2(240, 100)  # 画面上部中央
	
	# ボス設定
	match config.boss_type:
		"green_boss":
			boss.max_health = 50
			boss.score_points = 1000
		"blue_boss":
			boss.max_health = 75
			boss.score_points = 1500
		"yellow_boss":
			boss.max_health = 100
			boss.score_points = 2000
		"red_boss":
			boss.max_health = 125
			boss.score_points = 3000
		"final_boss":
			boss.max_health = 150
			boss.score_points = 5000
	
	# ボスの破壊シグナルを接続
	boss.boss_destroyed.connect(_on_boss_destroyed)
	
	# GameManagerに追加
	game_manager.add_child(boss)
	
	print("Boss spawned: ", config.boss_type, " with ", boss.max_health, " health")

func _on_boss_destroyed(score_points: int):
	# ボス撃破時の処理
	if game_manager:
		game_manager.add_score(score_points)
		game_manager.play_sound.emit("enemy_destroy")
	
	# ステージクリア
	await get_tree().create_timer(1.0).timeout
	complete_stage()

func complete_stage():
	stage_active = false
	emit_signal("stage_cleared")
	
	print("Stage ", current_stage, " cleared!")
	
	# ステージクリア演出
	show_stage_clear_message()
	
	# 次のステージへ
	if current_stage < MAX_STAGES:
		await get_tree().create_timer(3.0).timeout
		start_stage(current_stage + 1)
	else:
		emit_signal("all_stages_cleared")
		print("All stages cleared! Congratulations!")
		show_all_clear_message()

func show_stage_clear_message():
	# UIマネージャーにステージクリアメッセージを表示させる
	if game_manager and is_instance_valid(game_manager) and game_manager.get("ui") != null:
		game_manager.ui.show_stage_clear(current_stage)

func show_all_clear_message():
	# UIマネージャーに全ステージクリアメッセージを表示させる
	if game_manager and is_instance_valid(game_manager) and game_manager.get("ui") != null:
		game_manager.ui.show_all_stages_clear()

func get_enemy_type_for_spawn() -> String:
	var config = stage_configs.get(current_stage, stage_configs[1])
	var weights = config.enemy_weights
	
	# 重み付きランダム選択
	var total_weight = 0.0
	for weight in weights.values():
		total_weight += weight
	
	var random_value = randf() * total_weight
	var accumulated = 0.0
	
	for enemy_type in weights:
		accumulated += weights[enemy_type]
		if random_value <= accumulated:
			return enemy_type
	
	return "red"  # デフォルト

func get_enemy_rate_multiplier() -> float:
	var config = stage_configs.get(current_stage, stage_configs[1])
	return config.enemy_rate_multiplier

func get_current_stage() -> int:
	return current_stage

func get_stage_progress() -> float:
	if not stage_active:
		return 0.0
	return stage_timer / STAGE_DURATION

func is_boss_phase() -> bool:
	return is_boss_spawned

func reset():
	current_stage = 1
	stage_timer = 0.0
	is_boss_spawned = false
	stage_active = false
	RenderingServer.set_default_clear_color(Color.BLACK)