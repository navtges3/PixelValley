class_name Quest
extends RefCounted

var title: String
var description: String
var monsters: Dictionary
var total_monsters: int
var monsters_slain: int
var reward: String
var penalty: Dictionary
var completed: bool = false
var failed: bool = false

func init_quest(t, d, m, r, p) -> Quest:
	title = t
	description = d
	for monster_name in m.keys():
		total_monsters += m[monster_name]
		monsters[monster_name] = {
			"objective": m[monster_name],
			"slain": 0
		}
	reward = r
	penalty = p
	return self

func slay_monster(monster_name: String) -> bool:
	if monster_name in monsters:
		monsters_slain += 1
		monsters[monster_name]["slain"] += 1
	if monsters_slain >= total_monsters:
		completed = true
	return completed

func get_monster() -> String:
	var candidates := []
	for monster_name in monsters.keys():
		var data = monsters[monster_name]
		if data["slain"] < data["objective"]:
			candidates.append(monster_name)
	if candidates.size() == 0:
		return ""
	return candidates[randi() % candidates.size()]

func fail_quest() -> void:
	failed = true
	completed = false
	for penalty_name in penalty.keys():
		if penalty_name == "village":
			GameState.village.take_damage(penalty[penalty_name])

func is_complete() -> bool:
	return completed

func get_save_data() -> Dictionary:
	return {
		"title": title,
		"description": description,
		"monsters": monsters,
		"total_monsters": total_monsters,
		"monsters_slain": monsters_slain,
		"reward": reward,
		"penalty": penalty,
		"completed": completed,
		"failed": failed
	}

func load_from_data(data: Dictionary) -> void:
	title = data.get("title", "")
	description = data.get("description", "")
	monsters = data.get("monsters", {})
	total_monsters = data.get("total_monsters", 0)
	monsters_slain = data.get("monsters_slain", 0)
	reward = data.get("reward", "")
	penalty = data.get("penalty", {})
	completed = data.get("completed", false)
	failed = data.get("failed", false)
