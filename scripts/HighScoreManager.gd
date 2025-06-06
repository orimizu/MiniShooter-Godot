extends Node

const SAVE_PATH = "user://highscores.save"
const MAX_SCORES = 10

# 難易度別ハイスコアデータ構造
var high_scores_by_difficulty = {
	0: [],  # EASY
	1: [],  # NORMAL
	2: [],  # HARD
	3: []   # LUNATIC
}

# 後方互換性のための旧ハイスコア（NORMAL扱い）
var high_scores: Array = []

func _ready():
	load_high_scores()

# ハイスコアを読み込む
func load_high_scores():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var save_data = file.get_var()
			if save_data is Dictionary and "by_difficulty" in save_data:
				# 新形式：難易度別データ
				high_scores_by_difficulty = save_data.by_difficulty
				# 後方互換性のため、NORMALを旧形式にもコピー
				high_scores = high_scores_by_difficulty.get(1, [])
				print("Difficulty-based high scores loaded")
			elif save_data is Array:
				# 旧形式：配列データをNORMALに移行
				high_scores = save_data
				high_scores_by_difficulty[1] = save_data
				print("Legacy high scores migrated to NORMAL difficulty")
				# 新形式で保存し直す
				save_high_scores()
			file.close()
		else:
			print("Failed to open high score file")
			initialize_default_scores()
	else:
		print("No high score file found, initializing defaults")
		initialize_default_scores()

# デフォルトのハイスコアを初期化
func initialize_default_scores():
	high_scores.clear()
	# 全難易度のハイスコアをクリア
	for difficulty in high_scores_by_difficulty.keys():
		high_scores_by_difficulty[difficulty].clear()
	save_high_scores()

# ハイスコアを保存
func save_high_scores():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var save_data = {
			"by_difficulty": high_scores_by_difficulty,
			"version": "3.0"
		}
		file.store_var(save_data)
		file.close()
		print("Difficulty-based high scores saved successfully")
	else:
		print("Failed to save high scores")

# 新しいスコアがハイスコアかチェック（難易度対応）
func is_high_score(score: int, difficulty: int = 1) -> bool:
	var difficulty_scores = high_scores_by_difficulty.get(difficulty, [])
	if difficulty_scores.size() < MAX_SCORES:
		return true
	
	for entry in difficulty_scores:
		if score > entry.score:
			return true
	
	return false

# 後方互換性のための関数（NORMAL難易度として扱う）
func is_high_score_legacy(score: int) -> bool:
	return is_high_score(score, 1)

# ハイスコアランクを取得（難易度対応）
func get_high_score_rank(score: int, difficulty: int = 1) -> int:
	var difficulty_scores = high_scores_by_difficulty.get(difficulty, [])
	for i in range(difficulty_scores.size()):
		if score > difficulty_scores[i].score:
			return i
	
	if difficulty_scores.size() < MAX_SCORES:
		return difficulty_scores.size()
	
	return -1

# 新しいハイスコアを追加（難易度対応）
func add_high_score(score: int, stage: int = 1, difficulty: int = 1) -> int:
	var rank = get_high_score_rank(score, difficulty)
	if rank == -1:
		return -1
	
	var date = Time.get_datetime_string_from_system().split("T")[0]
	var new_entry = {
		"rank": rank + 1,
		"score": score,
		"date": date,
		"stage": stage,
		"difficulty": difficulty
	}
	
	# 難易度別のスコアリストに挿入
	var difficulty_scores = high_scores_by_difficulty.get(difficulty, [])
	difficulty_scores.insert(rank, new_entry)
	
	# MAX_SCORESを超える分を削除
	while difficulty_scores.size() > MAX_SCORES:
		difficulty_scores.pop_back()
	
	# ランクを更新
	for i in range(difficulty_scores.size()):
		difficulty_scores[i].rank = i + 1
	
	high_scores_by_difficulty[difficulty] = difficulty_scores
	
	# 後方互換性：NORMALの場合は旧形式にもコピー
	if difficulty == 1:
		high_scores = difficulty_scores.duplicate()
	
	save_high_scores()
	return rank

# 後方互換性のための関数
func add_high_score_legacy(score: int, stage: int = 1) -> int:
	return add_high_score(score, stage, 1)

# ハイスコアリストを取得（難易度対応）
func get_high_scores(difficulty: int = 1) -> Array:
	return high_scores_by_difficulty.get(difficulty, [])

# 後方互換性のための関数
func get_high_scores_legacy() -> Array:
	return high_scores

# 難易度名を取得
func get_difficulty_name(difficulty: int) -> String:
	match difficulty:
		0: return "EASY"
		1: return "NORMAL"
		2: return "HARD"
		3: return "LUNATIC"
		_: return "UNKNOWN"

# 特定のランクのスコアを取得
func get_score_at_rank(rank: int) -> int:
	if rank >= 0 and rank < high_scores.size():
		return high_scores[rank].score
	return 0