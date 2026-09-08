extends Resource
class_name BattleParty

const MAX_MEMBERS := 4

var _members: Array[Combatant] = []

func add_member(combatant: Combatant) -> bool:
	if combatant == null or has_member(combatant):
		return false
	if _members.size() >= MAX_MEMBERS:
		return false
	_members.append(combatant)
	return true

func remove_member(combatant: Combatant) -> bool:
	if not has_member(combatant):
		return false
	_members.erase(combatant)
	return true

func has_member(combatant: Combatant) -> bool:
	for member: Combatant in _members:
		if member == combatant:
			return true
	return false

func get_members() -> Array[Combatant]:
	return _members.duplicate()

func get_alive_members() -> Array[Combatant]:
	var living: Array[Combatant] = []
	for member: Combatant in _members:
		if member.is_alive():
			living.append(member)
	return living

func has_living_members() -> bool:
	for member: Combatant in _members:
		if member.is_alive():
			return true
	return false
