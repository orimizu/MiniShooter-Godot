extends Node

signal achievement_unlocked(achievement_id, achievement_data)
signal achievement_progress_updated(achievement_id, current, target)

const SAVE_PATH = "user://achievements.save"

# 実績定義
var achievement_definitions = {
	# 撃破系実績
	"first_kill": {
		"name": "First Blood",
		"description": "初めて敵を撃破",
		"icon": "🗡️",
		"target": 1,
		"category": "combat",
		"stat_key": "enemies_killed",
		"bonus_score": 100,
		"difficulty_specific": false
	},
	"enemy_hunter": {
		"name": "Enemy Hunter",
		"description": "敵を100体撃破",
		"icon": "🏹",
		"target": 100,
		"category": "combat",
		"stat_key": "enemies_killed",
		"bonus_score": 500,
		"difficulty_specific": false
	},
	"destroyer": {
		"name": "Destroyer",
		"description": "敵を500体撃破",
		"icon": "💀",
		"target": 500,
		"category": "combat",
		"stat_key": "enemies_killed",
		"bonus_score": 1000,
		"difficulty_specific": false
	},
	"boss_slayer": {
		"name": "Boss Slayer",
		"description": "ボスを5体撃破",
		"icon": "👑",
		"target": 5,
		"category": "boss",
		"stat_key": "bosses_killed",
		"bonus_score": 1000,
		"difficulty_specific": false
	},
	
	# スコア系実績
	"score_rookie": {
		"name": "Score Rookie",
		"description": "10,000点到達",
		"icon": "⭐",
		"target": 10000,
		"category": "score",
		"stat_key": "max_score",
		"bonus_score": 200,
		"difficulty_specific": false
	},
	"score_master": {
		"name": "Score Master",
		"description": "50,000点到達",
		"icon": "🌟",
		"target": 50000,
		"category": "score",
		"stat_key": "max_score",
		"bonus_score": 500,
		"difficulty_specific": false
	},
	"score_legend": {
		"name": "Score Legend",
		"description": "100,000点到達",
		"icon": "💫",
		"target": 100000,
		"category": "score",
		"stat_key": "max_score",
		"bonus_score": 1000,
		"difficulty_specific": false
	},
	
	# クリア系実績
	"first_clear": {
		"name": "First Victory",
		"description": "初回ステージクリア",
		"icon": "🎯",
		"target": 1,
		"category": "clear",
		"stat_key": "stages_cleared",
		"bonus_score": 300,
		"difficulty_specific": false
	},
	"all_stages": {
		"name": "Stage Master",
		"description": "全5ステージクリア",
		"icon": "🏆",
		"target": 5,
		"category": "clear",
		"stat_key": "total_stages_cleared",
		"bonus_score": 2000,
		"difficulty_specific": false
	},
	
	# 特殊系実績
	"survivor": {
		"name": "Survivor",
		"description": "ライフを失わずに1ステージクリア",
		"icon": "💖",
		"target": 1,
		"category": "special",
		"stat_key": "perfect_stages",
		"bonus_score": 1500,
		"difficulty_specific": false
	}
}

# プレイヤー進捗
var player_progress = {}

# 統計データ
var stats = {
	"enemies_killed": 0,
	"bosses_killed": 0,
	"stages_cleared": 0,
	"total_stages_cleared": 0,
	"max_score": 0,
	"perfect_stages": 0,
	"current_stage_damage": 0  # 現在のステージでのダメージ数
}

# 一時的な統計（ステージごとにリセット）
var temp_stats = {
	"stage_enemies_killed": 0,
	"stage_damage_taken": 0
}

func _ready():
	load_achievements()
	print("AchievementManager initialized with ", achievement_definitions.size(), " achievements")

func load_achievements():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var save_data = file.get_var()
			if save_data and save_data is Dictionary:
				if "progress" in save_data:
					player_progress = save_data.progress
				if "stats" in save_data:
					stats = save_data.stats
				print("Achievements loaded successfully")
			file.close()
		else:
			print("Failed to open achievements file")
			initialize_defaults()
	else:
		print("No achievements file found, initializing defaults")
		initialize_defaults()

func initialize_defaults():
	player_progress.clear()
	for achievement_id in achievement_definitions:
		player_progress[achievement_id] = {
			"unlocked": false,
			"unlock_date": "",
			"progress": 0
		}
	save_achievements()

func save_achievements():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var save_data = {
			"progress": player_progress,
			"stats": stats,
			"version": "1.0"
		}
		file.store_var(save_data)
		file.close()
		print("Achievements saved successfully")
	else:
		print("Failed to save achievements")

func increment_stat(stat_name: String, amount: int = 1):
	if stat_name in stats:
		stats[stat_name] += amount
		check_achievements_for_stat(stat_name)
		save_achievements()

func update_max_stat(stat_name: String, value: int):
	if stat_name in stats:
		if value > stats[stat_name]:
			stats[stat_name] = value
			check_achievements_for_stat(stat_name)
			save_achievements()

func check_achievements_for_stat(stat_name: String):
	for achievement_id in achievement_definitions:
		var achievement = achievement_definitions[achievement_id]
		
		# この統計に関連する実績のみチェック
		if achievement.stat_key != stat_name:
			continue
		
		# 既に解除済みならスキップ
		if player_progress[achievement_id].unlocked:
			continue
		
		# 進捗を更新
		var current_value = stats[stat_name]
		player_progress[achievement_id].progress = current_value
		
		# 目標達成チェック
		if current_value >= achievement.target:
			unlock_achievement(achievement_id)
		else:
			# 進捗更新シグナル
			emit_signal("achievement_progress_updated", achievement_id, current_value, achievement.target)

func unlock_achievement(achievement_id: String):
	if achievement_id not in achievement_definitions:
		print("Unknown achievement: ", achievement_id)
		return
	
	if player_progress[achievement_id].unlocked:
		print("Achievement already unlocked: ", achievement_id)
		return
	
	# 実績を解除
	player_progress[achievement_id].unlocked = true
	player_progress[achievement_id].unlock_date = Time.get_datetime_string_from_system().split("T")[0]
	
	var achievement_data = achievement_definitions[achievement_id]
	print("Achievement unlocked: ", achievement_data.name)
	
	# 解除シグナルを発信
	emit_signal("achievement_unlocked", achievement_id, achievement_data)
	
	# 保存
	save_achievements()

func get_achievement_count() -> Dictionary:
	var unlocked = 0
	var total = achievement_definitions.size()
	
	for achievement_id in player_progress:
		if player_progress[achievement_id].unlocked:
			unlocked += 1
	
	return {"unlocked": unlocked, "total": total}

func get_achievements_by_category(category: String) -> Array:
	var achievements = []
	for achievement_id in achievement_definitions:
		if achievement_definitions[achievement_id].category == category:
			achievements.append({
				"id": achievement_id,
				"definition": achievement_definitions[achievement_id],
				"progress": player_progress.get(achievement_id, {})
			})
	return achievements

func get_all_achievements() -> Array:
	var achievements = []
	for achievement_id in achievement_definitions:
		achievements.append({
			"id": achievement_id,
			"definition": achievement_definitions[achievement_id],
			"progress": player_progress.get(achievement_id, {})
		})
	return achievements

# ステージ開始時に呼ぶ
func on_stage_start():
	temp_stats.stage_enemies_killed = 0
	temp_stats.stage_damage_taken = 0

# ステージクリア時に呼ぶ
func on_stage_clear():
	increment_stat("stages_cleared", 1)
	increment_stat("total_stages_cleared", 1)
	
	# パーフェクトクリアチェック
	if temp_stats.stage_damage_taken == 0:
		increment_stat("perfect_stages", 1)

# プレイヤーがダメージを受けた時に呼ぶ
func on_player_damaged():
	temp_stats.stage_damage_taken += 1

# スコアが更新された時に呼ぶ
func on_score_updated(new_score: int):
	update_max_stat("max_score", new_score)

# デバッグ用：実績をリセット
func reset_all_achievements():
	initialize_defaults()
	stats = {
		"enemies_killed": 0,
		"bosses_killed": 0,
		"stages_cleared": 0,
		"total_stages_cleared": 0,
		"max_score": 0,
		"perfect_stages": 0,
		"current_stage_damage": 0
	}
	save_achievements()
	print("All achievements reset")

# デバッグ用：特定の実績を解除
func debug_unlock_achievement(achievement_id: String):
	if achievement_id in achievement_definitions:
		unlock_achievement(achievement_id)
	else:
		print("Achievement not found: ", achievement_id)