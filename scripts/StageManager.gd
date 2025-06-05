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

# ステージ移行期間管理
var is_stage_transitioning: bool = false
var transition_phase: String = ""  # "retreat", "clear_display", "bg_change", "spawn_delay"
var transition_timer: float = 0.0

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
	
	# 前のステージのボスが残っていれば削除
	if game_manager and is_instance_valid(game_manager):
		if is_instance_valid(game_manager.current_boss):
			print("Cleaning up previous stage boss")
			game_manager.current_boss.queue_free()
			game_manager.current_boss = null
	
	var config = stage_configs.get(current_stage, stage_configs[1])
	
	# 背景色を変更
	RenderingServer.set_default_clear_color(config.bg_color)
	
	emit_signal("stage_changed", current_stage)
	
	print("Starting ", config.name)

func _process(delta):
	if not stage_active:
		return
	
	# ステージ移行期間の処理
	if is_stage_transitioning:
		process_stage_transition(delta)
		return
		
	stage_timer += delta
	
	# ボス出現チェック
	if not is_boss_spawned and stage_timer >= BOSS_SPAWN_TIME:
		spawn_boss()
	
	# ステージ時間制限チェック
	if stage_timer >= STAGE_DURATION:
		if not is_boss_spawned:
			# ボスが出現していない場合はそのままクリア
			complete_stage()
		else:
			# ボスが出現済みの場合は強制的にクリア（ボス削除）
			force_stage_clear()

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
	
	# GameManagerにボスを登録
	if game_manager.has_method("register_boss"):
		game_manager.register_boss(boss)
	
	print("Boss spawned: ", config.boss_type, " with ", boss.max_health, " health")

func _on_boss_destroyed(score_points: int):
	# ボス撃破時の処理
	if game_manager:
		game_manager.add_score(score_points)
		game_manager.play_sound.emit("enemy_destroy")
		# GameManagerからボス登録を解除
		if game_manager.has_method("unregister_boss"):
			game_manager.unregister_boss()
		# 実績システムにボス撃破を通知
		if game_manager.achievement_manager:
			game_manager.achievement_manager.increment_stat("bosses_killed", 1)
	
	# ボス撃破フラグをリセット
	is_boss_spawned = false
	
	# 移行期間を開始
	start_stage_transition()

func complete_stage():
	stage_active = false
	emit_signal("stage_cleared")
	
	print("Stage ", current_stage, " cleared!")
	
	# 実績システムにステージクリアを通知
	if game_manager and game_manager.achievement_manager:
		game_manager.achievement_manager.on_stage_clear()
	
	# ステージクリア演出
	show_stage_clear_message()
	
	# 次のステージへ
	if current_stage < MAX_STAGES:
		await get_tree().create_timer(3.0).timeout
		# 次のステージ開始時に実績システムに通知
		if game_manager and game_manager.achievement_manager:
			game_manager.achievement_manager.on_stage_start()
		start_stage(current_stage + 1)
	else:
		emit_signal("all_stages_cleared")
		print("All stages cleared! Congratulations!")
		show_all_clear_message()

func force_stage_clear():
	# 時間切れによる強制ステージクリア（ボスを削除）
	print("Stage ", current_stage, " time limit reached - forcing clear")
	
	# ボスを強制削除
	if game_manager and is_instance_valid(game_manager):
		if is_instance_valid(game_manager.current_boss):
			print("Removing boss due to time limit")
			game_manager.current_boss.queue_free()
			game_manager.current_boss = null
	
	# ボス状態をリセット
	is_boss_spawned = false
	
	# 通常のステージクリア処理を実行
	complete_stage()

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
	is_stage_transitioning = false
	transition_phase = ""
	transition_timer = 0.0
	RenderingServer.set_default_clear_color(Color.BLACK)

# ステージ移行期間開始
func start_stage_transition():
	print("Starting stage transition")
	is_stage_transitioning = true
	transition_phase = "retreat"
	transition_timer = 0.0
	
	# すべての敵に撤退を指示
	if game_manager:
		for enemy in game_manager.enemies:
			if is_instance_valid(enemy) and enemy.has_method("start_retreat"):
				enemy.start_retreat()

# ステージ移行期間の処理
func process_stage_transition(delta):
	transition_timer += delta
	
	match transition_phase:
		"retreat":
			# 敵の撤退フェーズ：敵が画面から消えるまで待つ
			if are_all_enemies_gone():
				print("All enemies retreated, showing stage clear")
				transition_phase = "clear_display"
				transition_timer = 0.0
				show_stage_clear_message()
		
		"clear_display":
			# ステージクリア表示フェーズ：3秒間表示
			if transition_timer >= 3.0:
				print("Stage clear message finished, changing background")
				transition_phase = "bg_change"
				transition_timer = 0.0
				change_stage_background()
		
		"bg_change":
			# 背景変更フェーズ：即座に次へ
			transition_phase = "spawn_delay"
			transition_timer = 0.0
		
		"spawn_delay":
			# 敵出現待機フェーズ：3秒待機
			if transition_timer >= 3.0:
				print("Spawn delay finished, completing stage transition")
				complete_stage_transition()

# すべての敵が画面から消えたかチェック
func are_all_enemies_gone() -> bool:
	if not game_manager:
		return true
	
	for enemy in game_manager.enemies:
		if is_instance_valid(enemy):
			# 敵が画面内にまだいる場合はfalse
			if enemy.position.y < 700:
				return false
	
	return true

# 背景色を次のステージに変更
func change_stage_background():
	var next_stage = current_stage + 1
	if next_stage <= MAX_STAGES:
		var next_config = stage_configs.get(next_stage, stage_configs[1])
		RenderingServer.set_default_clear_color(next_config.bg_color)
		print("Background changed to stage ", next_stage, " color")

# ステージ移行期間完了
func complete_stage_transition():
	is_stage_transitioning = false
	transition_phase = ""
	transition_timer = 0.0
	
	# 通常のステージクリア処理を実行
	complete_stage()