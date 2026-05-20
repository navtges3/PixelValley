extends Node

const HERO_PATHS := {
	Hero.HeroClass.KNIGHT:   "res://resources/characters/heroes/knight/knight.tres",
	Hero.HeroClass.ASSASSIN: "res://resources/characters/heroes/assassin/assassin.tres",
	Hero.HeroClass.PRINCESS: "res://resources/characters/heroes/princess/princess.tres",
}

func new_hero(hero_class: Hero.HeroClass) -> Hero:
	if not HERO_PATHS.has(hero_class):
		push_error("HeroLoader: unknown hero class %d" % hero_class)
		return null
	return (load(HERO_PATHS[hero_class]) as Hero).duplicate(true)

func apply_visual(hero: Hero) -> void:
	if not HERO_PATHS.has(hero.hero_class):
		push_error("HeroLoader: unknown hero class %d", hero.hero_class)
		return
	var template := load(HERO_PATHS[hero.hero_class]) as Hero
	hero.portrait = template.portrait
	hero.world_visual = template.world_visual
	hero.battle_visual = template.battle_visual
	hero.battle_height = template.battle_height
	hero.hand_positions = template.hand_positions
