extends Resource
class_name EncounterDefinition

const MAX_ENEMIES := 4

@export var id: String = ""
@export var name: String = ""
@export var monster_ids: Array[MonsterLoader.MonsterID] = []
@export var monster_templates: Array[Monster] = []

func create_enemy_party() -> BattleParty:
	var party := BattleParty.new()
	# monster_ids first — matches get_lead_monster_id() / get_lead_world_visual() priority.
	for monster_id: MonsterLoader.MonsterID in monster_ids:
		if party.get_members().size() >= MAX_ENEMIES:
			break
		var enemy := MonsterLoader.new_monster(monster_id)
		if enemy != null:
			party.add_member(enemy)
	# Templates fill remaining capacity.
	for template: Monster in monster_templates:
		if template != null and party.get_members().size() < MAX_ENEMIES:
			party.add_member(template.duplicate(true))
	return party

func get_lead_monster_id() -> MonsterLoader.MonsterID:
	if not monster_ids.is_empty():
		return monster_ids[0]                                                                                                            
	if not monster_templates.is_empty() and monster_templates[0] != null:
		return monster_templates[0].monster_id                                                                                           
	push_warning("EncounterDefinition '%s': get_lead_monster_id called on an empty encounter." % id)
	return MonsterLoader.MonsterID.GOBLIN

func get_lead_world_visual() -> SpriteFrames:
	if not monster_templates.is_empty() and monster_templates[0] != null:
		return monster_templates[0].world_visual                                                                                         
	if not monster_ids.is_empty():
		var lead := MonsterLoader.new_monster(monster_ids[0])                                                                            
		if lead != null:                                                                                                                 
			return lead.world_visual                                                                                                     
	return null
