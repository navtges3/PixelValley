extends Node

enum BattleState { PLAYER_TURN, MONSTER_TURN, RESOLVING, VICTORY, DEFEAT }

var hero: HeroInstance
var monster: Monster
var current_quest: Quest

var state = BattleState.PLAYER_TURN

signal monster_slain(monster_name: String)
signal new_monster(monster_ref: Monster)
signal player_turn()
signal monster_turn()
signal quest_completed()
signal hero_defeated()
signal battle_log_updated(msg: String)
signal monster_updated(monster_ref: Monster)
signal hero_updated(hero_ref: HeroInstance)

func start_battle(hero_ref: HeroInstance, current_quest_ref: Quest) -> void:
	hero = hero_ref
	current_quest = current_quest_ref
	emit_signal("hero_updated", hero)
	get_new_monster()
	start_player_turn()

func start_player_turn() -> void:
	state = BattleState.PLAYER_TURN
	emit_signal("battle_log_updated", "Your turn!")
	emit_signal("player_turn")

func player_ability_selected(ability_name: String) -> void:
	if state != BattleState.PLAYER_TURN:
		return
	# Find the ability by name
	var result := hero.use_ability(ability_name, monster)
	emit_signal("battle_log_updated", result.message)
	if result.success:
		emit_signal("monster_updated", monster)
		emit_signal("hero_updated", hero)
		end_player_turn()

func rest() -> void:
	if state != BattleState.PLAYER_TURN:
		return
	hero.rest()
	emit_signal("battle_log_updated", "You take a rest recovering health and energy.")
	emit_signal("hero_updated", hero)
	end_player_turn()

func end_player_turn() -> void:
	if state != BattleState.PLAYER_TURN:
		return

	hero.update_cooldown()
	emit_signal("hero_updated", hero)

	if monster.is_alive():
		state = BattleState.MONSTER_TURN
		emit_signal("monster_turn")
		await get_tree().create_timer(0.5).timeout
		enemy_turn()
	else:
		var experience = monster.calculate_experience()
		emit_signal("battle_log_updated", "You defeated %s! You gain %d experience." % [monster.name, experience])
		hero.gain_experience(experience)
		emit_signal("hero_updated", hero)

		if current_quest.slay_monster(monster.name):
			end_battle(true)
		else:
			emit_signal("monster_slain", monster.name)

func get_new_monster() -> void:
	var new_monster_name = current_quest.get_monster()
	if new_monster_name == "":
		emit_signal("battle_log_updated", "No more monsters to fight!")
		end_battle(true)
	else:
		monster = MonsterLoader.get_monster(new_monster_name, hero.level)
		emit_signal("new_monster", monster)
		emit_signal("battle_log_updated", "A new monster appears: %s!" % new_monster_name)

func enemy_turn() -> void:
	emit_signal("battle_log_updated", "Enemy turn...")
	var damage = monster.get_attack_damage()
	hero.take_damage(damage)
	emit_signal("battle_log_updated", "%s took %d damage" % [hero.hero_name, damage])
	emit_signal("hero_updated", hero)

	if hero.is_alive():
		start_player_turn()
	else:
		end_battle(false)

func end_battle(player_won: bool) -> void:
	state = BattleState.VICTORY if player_won else BattleState.DEFEAT
	emit_signal("battle_log_updated", "You win!" if player_won else "You lose!")
	if player_won and current_quest.is_complete():
		# skip victory popup if quest is complete
		emit_signal("battle_log_updated", "Quest completed: %s" % current_quest.title)
		emit_signal("quest_completed")
	elif not player_won:
		emit_signal("hero_defeated")
