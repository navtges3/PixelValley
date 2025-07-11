extends Node

enum BattleState { PLAYER_TURN, MONSTER_TURN, RESOLVING, VICTORY, DEFEAT }

var hero: HeroInstance
var monster_ui: MonsterUI
var current_quest: Quest
var battle_log: RichTextLabel

var state = BattleState.PLAYER_TURN

signal monster_slain(monster_name: String)
signal new_monster(monster_ref: Monster)
signal player_turn()
signal monster_turn()
signal quest_completed()
signal hero_defeated()

func start_battle(hero_ref: HeroInstance, monster_ui_ref: MonsterUI, current_quest_ref: Quest, battle_log_ref: RichTextLabel) -> void:
	hero = hero_ref
	monster_ui = monster_ui_ref
	current_quest = current_quest_ref
	battle_log = battle_log_ref
	get_new_monster()
	start_player_turn()

func start_player_turn() -> void:
	log_battle("Your turn!")
	state = BattleState.PLAYER_TURN
	emit_signal("player_turn")

func player_ability_selected(ability_name: String) -> void:
	if state != BattleState.PLAYER_TURN:
		return
	# Find the ability by name
	var ability = hero.get_ability_by_name(ability_name)
	if ability and hero.can_use_ability(ability_name):
		log_battle("Hero uses %s!" % ability_name)
		if ability is AttackAbility:
			var monster_health = monster_ui.monster.current_hp
			if ability.apply_attack(monster_ui.monster, hero.attack_modifier):
				hero.use_energy(ability.energy_cost)
				log_battle("%s took %d damage" % [monster_ui.monster.name, monster_health - monster_ui.monster.current_hp])
			end_player_turn()
		elif ability is UtilityAbility:
			if ability.apply_utility(hero):
				hero.use_energy(ability.energy_cost)
				log_battle("%s applied %s to self." % [hero.hero_name, ability.utility_effect])
			end_player_turn()
		else:
			log_battle("Unknown ability type.")
	else:
		state = BattleState.PLAYER_TURN
		log_battle("You can't use %s." % ability_name)

func rest() -> void:
	if state != BattleState.PLAYER_TURN:
		return
	hero.rest()
	log_battle("You take a rest recovering health and energy.")
	end_player_turn()

func end_player_turn() -> void:
	if state != BattleState.PLAYER_TURN:
		return
	hero.update_cooldown()
	if monster_ui.monster.is_alive():
		state = BattleState.MONSTER_TURN
		emit_signal("monster_turn")
		await get_tree().create_timer(0.5).timeout
		enemy_turn()
	else:
		var experience = monster_ui.monster.calculate_experience()
		log_battle("You defeated %s! You gain %d experience." % [monster_ui.monster.name, experience])
		hero.gain_experience(experience)
		if current_quest.slay_monster(monster_ui.monster.name):
			end_battle(true)
		else:
			emit_signal("monster_slain", monster_ui.monster.name)

func get_new_monster() -> void:
	var new_monster_name = current_quest.get_monster()
	if new_monster_name == "":
		log_battle("No more monsters to fight!")
		end_battle(true)
	else:
		emit_signal("new_monster", MonsterLoader.get_monster(new_monster_name, hero.level))
		log_battle("A new monster appears: %s!" % new_monster_name)

func enemy_turn() -> void:
	log_battle("Enemy turn...")
	var damage = monster_ui.monster.get_attack_damage()
	hero.take_damage(damage)
	log_battle("%s took %d damage" % [hero.hero_name, damage])

	if hero.is_alive():
		start_player_turn()
	else:
		end_battle(false)

func end_battle(player_won: bool) -> void:
	if player_won:
		state = BattleState.VICTORY
		log_battle("You win!")
		if current_quest.is_complete():
			# skip victory popup if quest is complete
			log_battle("Quest completed: %s" % current_quest.title)
			emit_signal("quest_completed")
	else:
		state = BattleState.DEFEAT
		log_battle("You lose!")
		emit_signal("hero_defeated")

func _on_victory_popup_visibility_changed(visible: bool) -> void:
	if not visible:
		print("Victory popup closed, getting new monster.")
		get_new_monster()
		start_player_turn()

func log_battle(message: String) -> void:
	if battle_log:
		battle_log.append_text("%s\n" % message)
