extends Node

enum BattleState { PLAYER_TURN, MONSTER_TURN, RESOLVING, VICTORY, DEFEAT }

var hero: Hero
var monster: Monster
var current_quest: Quest
var is_test_battle: bool = false

var state = BattleState.PLAYER_TURN

signal monster_slain(monster_name: String)
signal new_monster(monster_ref: Monster)
signal player_turn()
signal monster_turn()
signal quest_completed()
signal hero_defeated()
signal battle_log_updated(msg: String)
signal monster_updated(monster_ref: Monster)
signal hero_updated(hero_ref: Hero)

func setup_battle(config: BattleConfig) -> void:
	hero = config.hero
	current_quest = config.quest
	is_test_battle = config.is_test_battle
	
	emit_signal("hero_updated", hero)
	
	get_new_monster()
	start_player_turn()

func start_player_turn() -> void:
	state = BattleState.PLAYER_TURN
	emit_signal("battle_log_updated", "%s's turn!\n" % hero.get_colored_name())
	emit_signal("player_turn")

func get_hero_abilities() -> Array[Ability]:
	return hero.inventory.equipped_weapon.abilities

func player_ability_selected(ability: Ability) -> void:
	if state != BattleState.PLAYER_TURN:
		return
	# Find the ability by name
	var output = ability.use(hero, monster)
	if output:
		emit_signal("battle_log_updated", output)
		emit_signal("monster_updated", monster)
		emit_signal("hero_updated", hero)
		end_player_turn()

func get_hero_items() -> Array[ItemStack]:
	return hero.inventory.potions

func player_item_selected(item_stack: ItemStack) -> void:
	if state != BattleState.PLAYER_TURN:
		return
	var result := hero.use_item(item_stack)
	emit_signal("battle_log_updated", result)
	emit_signal("hero_updated", hero)
	end_player_turn()

func meditate() -> void:
	if state != BattleState.PLAYER_TURN:
		return
	if hero.rest_cooldown > 0:
		return
	hero.meditate()
	emit_signal("battle_log_updated", "%s takes a meditates recovering health and energy.\n" % hero.get_colored_name())
	emit_signal("hero_updated", hero)
	end_player_turn()

func end_player_turn() -> void:
	if state != BattleState.PLAYER_TURN:
		return
	hero.update_cooldown()
	hero.process_active_effects()
	emit_signal("hero_updated", hero)

	if monster.is_alive():
		state = BattleState.MONSTER_TURN
		emit_signal("monster_turn")
		await get_tree().create_timer(0.5).timeout
		enemy_turn()
	else:
		var experience = monster.calculate_experience()
		emit_signal("battle_log_updated", "%s defeated %s!\n" % [hero.get_colored_name(), monster.get_colored_name()])
		emit_signal("battle_log_updated", "%s gains %d experience and %d gold.\n" % [hero.get_colored_name(), experience, monster.gold])
		hero.inventory.gold += monster.gold
		hero.gain_experience(experience)
		emit_signal("hero_updated", hero)
		if current_quest.slay_monster(monster.name):
			end_battle(true)
		else:
			emit_signal("monster_slain", monster.name)

func get_new_monster() -> void:
	var quest_monster = current_quest.get_monster()
	if quest_monster:
		monster = quest_monster.duplicate(true)
		emit_signal("new_monster", monster)
		emit_signal("battle_log_updated", "A new monster appears: %s!\n" % quest_monster.name)
		emit_signal("monster_updated", monster)
	else:
		emit_signal("battle_log_updated", "No more monsters to fight!\n")
		end_battle(true)

func enemy_turn() -> void:
	emit_signal("battle_log_updated", "Enemy turn...\n")
	var monster_ability = monster.choose_ability(hero)
	var output = monster_ability.use(monster, hero)
	emit_signal("battle_log_updated", output)
	emit_signal("hero_updated", hero)
	end_enemy_turn()

func end_enemy_turn() -> void:
	monster.update_cooldown()
	monster.process_active_effects()
	emit_signal("monster_updated", monster)
	if hero.is_alive():
		start_player_turn()
	else:
		end_battle(false)

func end_battle(player_won: bool) -> void:
	state = BattleState.VICTORY if player_won else BattleState.DEFEAT
	emit_signal("battle_log_updated", "%s wins!\n" % hero.get_colored_name() if player_won else "%s loses!\n" % hero.get_colored_name())
	if player_won and current_quest.is_complete():
		# skip victory popup if quest is complete
		emit_signal("battle_log_updated", "Quest completed: %s\n" % current_quest.title)
		emit_signal("quest_completed")
	elif not player_won:
		emit_signal("hero_defeated")
