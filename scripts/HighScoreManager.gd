extends Node

const SAVE_PATH = "user://highscores.save"
const MAX_SCORES = 10

# ハイスコアデータ構造
var high_scores: Array = []

func _ready():
	load_high_scores()

# ハイスコアを読み込む
func load_high_scores():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var save_data = file.get_var()
			if save_data is Array:
				high_scores = save_data
			file.close()
			print("High scores loaded: ", high_scores.size(), " entries")
		else:
			print("Failed to open high score file")
			initialize_default_scores()
	else:
		print("No high score file found, initializing defaults")
		initialize_default_scores()

# デフォルトのハイスコアを初期化
func initialize_default_scores():
	high_scores.clear()
	for i in range(MAX_SCORES):
		high_scores.append({
			"rank": i + 1,
			"score": (10 - i) * 1000,
			"date": "2024/01/01",
			"stage": 1
		})
	save_high_scores()

# ハイスコアを保存
func save_high_scores():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(high_scores)
		file.close()
		print("High scores saved")
	else:
		print("Failed to save high scores")

# 新しいスコアがハイスコアかチェック
func is_high_score(score: int) -> bool:
	if high_scores.size() < MAX_SCORES:
		return true
	
	for entry in high_scores:
		if score > entry.score:
			return true
	
	return false

# ハイスコアランクを取得（0ベース、-1はランク外）
func get_high_score_rank(score: int) -> int:
	for i in range(high_scores.size()):
		if score > high_scores[i].score:
			return i
	
	if high_scores.size() < MAX_SCORES:
		return high_scores.size()
	
	return -1

# 新しいハイスコアを追加
func add_high_score(score: int, stage: int = 1) -> int:
	var rank = get_high_score_rank(score)
	if rank == -1:
		return -1
	
	var date = Time.get_datetime_string_from_system().split("T")[0]
	var new_entry = {
		"rank": rank + 1,
		"score": score,
		"date": date,
		"stage": stage
	}
	
	# 適切な位置に挿入
	high_scores.insert(rank, new_entry)
	
	# MAX_SCORESを超える分を削除
	while high_scores.size() > MAX_SCORES:
		high_scores.pop_back()
	
	# ランクを更新
	for i in range(high_scores.size()):
		high_scores[i].rank = i + 1
	
	save_high_scores()
	return rank

# ハイスコアリストを取得
func get_high_scores() -> Array:
	return high_scores

# 特定のランクのスコアを取得
func get_score_at_rank(rank: int) -> int:
	if rank >= 0 and rank < high_scores.size():
		return high_scores[rank].score
	return 0