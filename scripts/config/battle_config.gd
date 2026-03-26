class_name BattleConfig
extends Resource

var hero: Hero
var monster_id: MonsterLoader.MonsterID
var monster_override: Monster = null
var enemy_ref: WeakRef = null
var spawn_point_id: String = ""

static func create(p_hero: Hero, p_enemy: Enemy, p_spawn_point_id: String = "", p_monster: Monster = null) -> BattleConfig:
	var cfg := BattleConfig.new()
	cfg.hero = p_hero
	cfg.monster_id = p_enemy.monster_id
	cfg.spawn_point_id = p_spawn_point_id
	cfg.monster_override = p_monster
	return cfg
