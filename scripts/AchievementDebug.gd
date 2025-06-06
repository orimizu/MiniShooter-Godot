extends Node

# Debug script to test achievements manually
# Add this as an autoload or call from GameManager for testing

var achievement_manager: Node
var game_manager: Node

func _ready():
	# Wait for game to initialize
	await get_tree().process_frame
	setup_debug()

func setup_debug():
	game_manager = get_node("/root/Main")
	if game_manager and game_manager.get("achievement_manager"):
		achievement_manager = game_manager.achievement_manager
		print("AchievementDebug: Connected to AchievementManager")
		
		# Print current achievement status
		print_achievement_status()
	else:
		print("AchievementDebug: Failed to find AchievementManager")

func print_achievement_status():
	if not achievement_manager:
		return
	
	print("=== ACHIEVEMENT STATUS ===")
	var achievements = achievement_manager.get_all_achievements()
	for achievement in achievements:
		var status = "LOCKED"
		if achievement.progress.unlocked:
			status = "UNLOCKED (" + achievement.progress.unlock_date + ")"
		else:
			status = "PROGRESS: " + str(achievement.progress.progress) + "/" + str(achievement.definition.target)
		
		print(achievement.definition.name + " - " + status)
	
	var count = achievement_manager.get_achievement_count()
	print("Total: " + str(count.unlocked) + "/" + str(count.total) + " unlocked")
	print("========================")

# Manual testing functions
func debug_unlock_first_kill():
	if achievement_manager:
		achievement_manager.increment_stat("enemies_killed", 1)
		print("Debug: Incremented enemies_killed")

func debug_unlock_score_rookie():
	if achievement_manager:
		achievement_manager.update_max_stat("max_score", 10000)
		print("Debug: Set max_score to 10000")

func debug_unlock_boss_slayer():
	if achievement_manager:
		achievement_manager.increment_stat("bosses_killed", 5)
		print("Debug: Set bosses_killed to 5")

func debug_reset_achievements():
	if achievement_manager:
		achievement_manager.reset_all_achievements()
		print("Debug: Reset all achievements")

# Input handling for debug testing
func _input(event):
	if not achievement_manager:
		return
	
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				debug_unlock_first_kill()
			KEY_F2:
				debug_unlock_score_rookie()
			KEY_F3:
				debug_unlock_boss_slayer()
			KEY_F4:
				debug_reset_achievements()
			KEY_F5:
				print_achievement_status()

# Print usage instructions
func _notification(what):
	if what == NOTIFICATION_READY:
		await get_tree().create_timer(2.0).timeout
		print("AchievementDebug Controls:")
		print("F1 - Unlock First Kill")
		print("F2 - Unlock Score Rookie") 
		print("F3 - Unlock Boss Slayer")
		print("F4 - Reset All Achievements")
		print("F5 - Print Achievement Status")