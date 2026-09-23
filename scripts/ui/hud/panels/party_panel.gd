extends Control
class_name PartyPanel

@onready var active_list: VBoxContainer = $ScrollContainer/VBox/ActiveList
@onready var reserve_list: VBoxContainer = $ScrollContainer/VBox/ReserveList
@onready var detail_list: VBoxContainer = $ScrollContainer/VBox/DetailList

var _selected_id: StringName = &""

func get_default_focus_target() -> Control:
	return null # restore last-focused like InventoryPanel does

func refresh() -> void:
	var party := GameState.party
	if party == null or party.members.is_empty():
		return
	if party.get_member_by_id(_selected_id) == null:
		_selected_id = party.members[0].hero_id
	for list: VBoxContainer in [active_list, reserve_list, detail_list]:
		for child in list.get_children():
			child.queue_free()
	var active := party.get_active_members()
	for i: int in active.size():
		active_list.add_child(_active_row(party, active[i], i, active.size()))
	for hero: Hero in party.members:
		if hero not in active:
			reserve_list.add_child(_reserve_row(party, hero))
	_build_detail(party, party.get_member_by_id(_selected_id))

func _active_row(party: Party, hero: Hero, i: int, count: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	var select := Button.new()
	select.text = "%d. %s Lv%d  %d/%d HP" % [i + 1, hero.name, hero.level, hero.current_hp, hero.max_hp]
	select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	select.pressed.connect(_select.bind(hero.hero_id))
	row.add_child(select)
	row.add_child(_button("▲", party.move_active_member.bind(hero, -1), i > 0))
	row.add_child(_button("▼", party.move_active_member.bind(hero, 1), i < count - 1))
	row.add_child(_button("Remove", party.remove_from_active_party.bind(hero),
		not party.is_leader(hero) and count > 1))
	return row

func _reserve_row(party: Party, hero: Hero) -> HBoxContainer:
	var row := HBoxContainer.new()
	var state := "" if hero.is_alive() else "  (Downed)"
	var select := Button.new()
	select.text = "%s Lv%d%s" % [hero.name, hero.level, state]
	select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	select.pressed.connect(_select.bind(hero.hero_id))
	row.add_child(select)
	var has_room := party.active_member_ids.size() < Party.MAX_ACTIVE_MEMBERS
	row.add_child(_button("Add", party.add_to_active_party.bind(hero),
		party.is_eligible(hero) and has_room))
	return row

func _build_detail(party: Party, hero: Hero) -> void:
	_add_label("%s the %s, Lv %d" % [hero.name, hero.get_class_name(), hero.level])
	_add_label("HP %d/%d  ATK %d  MAG %d  DEF %d  RES %d  INIT %d" % [
		hero.current_hp, hero.max_hp, hero.attack, hero.magic,
		hero.defense, hero.resist, hero.initiative])
	var weapon := hero.equipped_weapon
	_add_label("Weapon: %s" % (weapon.name if weapon != null else "None"))
	if weapon != null and hero.hero_id not in party.active_member_ids:
		detail_list.add_child(_button("Unequip", party.unequip_weapon.bind(hero)))
	for weapon_id: String in party.inventory.weapon_stash:
		var stashed := ItemLoader.get_item(weapon_id) as Weapon
		if stashed == null:
			continue
		var row := HBoxContainer.new()
		row.add_child(_button("Equip", party.equip_weapon.bind(hero, weapon_id)))
		row.add_child(_make_label(stashed.name))
		detail_list.add_child(row)

func _button(text: String, action: Callable, enabled: bool = true) -> Button:
	var button := Button.new()
	button.text = text
	button.disabled = not enabled
	button.pressed.connect(_run.bind(action))
	return button

func _run(action: Callable) -> void:
	action.call()
	SaveManager.save_party()   # persist on every change
	refresh()

func _select(hero_id: StringName) -> void:
	_selected_id = hero_id
	refresh()
