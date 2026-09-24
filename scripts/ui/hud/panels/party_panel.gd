extends Control
class_name PartyPanel

@onready var active_list: VBoxContainer = $ScrollContainer/VBox/ActiveList
@onready var reserve_list: VBoxContainer = $ScrollContainer/VBox/ReserveList
@onready var detail_list: VBoxContainer = $ScrollContainer/VBox/DetailList

const COLOR_HEADER    := Color(0.95, 0.92, 0.80)
const COLOR_SUBTEXT   := Color(0.72, 0.67, 0.57)
const COLOR_GOLD      := Color(0.95, 0.80, 0.25)
const COLOR_COMMON    := Color(0.85, 0.85, 0.85)
const COLOR_RARE      := Color(0.30, 0.65, 1.00)
const COLOR_LEGENDARY := Color(1.00, 0.75, 0.20)
const COLOR_EQUIPPED  := Color(0.30, 0.90, 0.45)
const COLOR_DOWNED    := Color(0.90, 0.35, 0.35)
const COLOR_SELECTED  := Color(0.95, 0.80, 0.25)

var _selected_id: StringName = &""
var _focus_controls: Dictionary[String, Control] = {}
var _last_focus_key: String = ""

func get_default_focus_target() -> Control:
	var party := GameState.party
	if party == null or party.members.is_empty():
		return null
	if not _last_focus_key.is_empty() and _focus_controls.has(_last_focus_key):
		var target := _focus_controls[_last_focus_key]
		if _is_focusable(target):
			return target
	# Fall back to the selected hero's select button
	if not _selected_id.is_empty():
		var sel_key := "active:%s:select" % _selected_id
		if _focus_controls.has(sel_key) and _is_focusable(_focus_controls[sel_key]):
			return _focus_controls[sel_key]
		var res_key := "reserve:%s:select" % _selected_id
		if _focus_controls.has(res_key) and _is_focusable(_focus_controls[res_key]):
			return _focus_controls[res_key]
	# Fall back to the first active row's select button
	var active := party.get_active_members()
	if not active.is_empty():
		var first_key := "active:%s:select" % active[0].hero_id
		if _focus_controls.has(first_key) and _is_focusable(_focus_controls[first_key]):
			return _focus_controls[first_key]
	for key: String in _focus_controls:
		var ctrl := _focus_controls[key]
		if _is_focusable(ctrl):
			return ctrl
	return null

func refresh() -> void:
	var party := GameState.party
	if party == null or party.members.is_empty():
		return
	if party.get_member_by_id(_selected_id) == null:
		_selected_id = party.members[0].hero_id
	_focus_controls.clear()
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
	_restore_default_focus.call_deferred()

func _active_row(party: Party, hero: Hero, i: int, count: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	var prefix := "▶ " if hero.hero_id == _selected_id else "  "
	var leader_tag := " (Leader)" if party.is_leader(hero) else ""
	var downed_tag := " (Downed)" if not hero.is_alive() else ""
	var select := Button.new()
	select.text = "%s%d. %s Lv%d  %d/%d HP%s%s" % [
		prefix, i + 1, hero.name, hero.level, hero.current_hp, hero.max_hp, leader_tag, downed_tag
	]
	select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	select.add_theme_font_size_override("font_size", 11)
	if hero.hero_id == _selected_id:
		select.add_theme_color_override("font_color", COLOR_SELECTED)
	elif not hero.is_alive():
		select.add_theme_color_override("font_color", COLOR_DOWNED)
	select.pressed.connect(_select.bind(hero.hero_id))
	_register_focus(select, "active:%s:select" % hero.hero_id)
	row.add_child(select)

	var up_btn := _button("▲", party.move_active_member.bind(hero, -1), i > 0, ThemeManager.GRAY_BUTTON)
	_register_focus(up_btn, "active:%s:up" % hero.hero_id)
	row.add_child(up_btn)

	var down_btn := _button("▼", party.move_active_member.bind(hero, 1), i < count - 1, ThemeManager.GRAY_BUTTON)
	_register_focus(down_btn, "active:%s:down" % hero.hero_id)
	row.add_child(down_btn)

	var remove_btn := _button("Remove", party.remove_from_active_party.bind(hero),
		not party.is_leader(hero) and count > 1, ThemeManager.RED_BUTTON)
	_register_focus(remove_btn, "active:%s:remove" % hero.hero_id)
	row.add_child(remove_btn)

	return row

func _reserve_row(party: Party, hero: Hero) -> HBoxContainer:
	var row := HBoxContainer.new()
	var prefix := "▶ " if hero.hero_id == _selected_id else "  "
	var downed_tag := " (Downed)" if not hero.is_alive() else ""
	var select := Button.new()
	select.text = "%s%s Lv%d%s" % [prefix, hero.name, hero.level, downed_tag]
	select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	select.add_theme_font_size_override("font_size", 11)
	if hero.hero_id == _selected_id:
		select.add_theme_color_override("font_color", COLOR_SELECTED)
	elif not hero.is_alive():
		select.add_theme_color_override("font_color", COLOR_DOWNED)
	select.pressed.connect(_select.bind(hero.hero_id))
	_register_focus(select, "reserve:%s:select" % hero.hero_id)
	row.add_child(select)

	var has_room := party.active_member_ids.size() < Party.MAX_ACTIVE_MEMBERS
	var add_btn := _button("Add", party.add_to_active_party.bind(hero),
		party.is_eligible(hero) and has_room, ThemeManager.GREEN_BUTTON)
	_register_focus(add_btn, "reserve:%s:add" % hero.hero_id)
	row.add_child(add_btn)

	return row

func _build_detail(party: Party, hero: Hero) -> void:
	if hero == null:
		return
	_add_label("%s the %s, Lv %d" % [hero.name, hero.get_class_name(), hero.level], COLOR_HEADER, 14)
	_add_label("HP %d/%d  ATK %d  MAG %d  DEF %d  RES %d  INIT %d" % [
		hero.current_hp, hero.max_hp, hero.attack, hero.magic,
		hero.defense, hero.resist, hero.initiative], COLOR_SUBTEXT, 12)
	var weapon := hero.equipped_weapon
	_add_label("Weapon: %s" % (weapon.name if weapon != null else "None"),
		COLOR_EQUIPPED if weapon != null else COLOR_SUBTEXT, 12)
	if weapon != null and hero.hero_id not in party.active_member_ids:
		var unequip_btn := _button("Unequip", party.unequip_weapon.bind(hero), true, ThemeManager.RED_BUTTON)
		_register_focus(unequip_btn, "detail:unequip")
		detail_list.add_child(unequip_btn)
	if party.inventory.weapon_stash.is_empty():
		_add_label("No weapons in stash", COLOR_SUBTEXT, 12)
	else:
		for weapon_id: String in party.inventory.weapon_stash:
			var stashed := ItemLoader.get_item(weapon_id) as Weapon
			if stashed == null:
				continue
			var can_equip := WeaponDatabase.can_class_equip(hero.hero_class, weapon_id)
			var row := HBoxContainer.new()
			var equip_btn := _button("Equip", party.equip_weapon.bind(hero, weapon_id), can_equip, ThemeManager.GREEN_BUTTON)
			if not can_equip:
				equip_btn.tooltip_text = "Cannot be equipped by a %s." % hero.get_class_name()
			_register_focus(equip_btn, "detail:equip:%s" % weapon_id)
			row.add_child(equip_btn)

			var color := _rarity_color(stashed.rarity)
			var lbl := _make_label("• %s  [%s]" % [stashed.name, Item.rarity_to_string(stashed.rarity)], color)
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			lbl.tooltip_text = stashed._to_string()
			row.add_child(lbl)
			detail_list.add_child(row)

func _make_label(txt: String, color: Color = COLOR_COMMON, font_size: int = 12) -> Label:
	var lbl := Label.new()
	lbl.text = txt
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return lbl

func _add_label(txt: String, color: Color = COLOR_COMMON, font_size: int = 12) -> Label:
	var lbl := _make_label(txt, color, font_size)
	detail_list.add_child(lbl)
	return lbl

func _button(text: String, action: Callable, enabled: bool = true, theme: Theme = null) -> Button:
	var button := Button.new()
	button.text = text
	button.disabled = not enabled
	if theme != null:
		button.theme = theme
	button.add_theme_font_size_override("font_size", 11)
	button.pressed.connect(_run.bind(action))
	return button

func _run(action: Callable) -> void:
	var result: Variant = action.call()
	if result == true:
		SaveManager.save_party()
	refresh()

func _select(hero_id: StringName) -> void:
	_selected_id = hero_id
	refresh()

func _register_focus(btn: Button, key: String) -> void:
	_focus_controls[key] = btn
	btn.focus_entered.connect(func() -> void:
		_last_focus_key = key
	)

func _restore_default_focus() -> void:
	var target := get_default_focus_target()
	if target != null:
		InputManager.focus_menu_control_deferred(target)

func _is_focusable(ctrl: Control) -> bool:
	if ctrl == null or not is_instance_valid(ctrl) or not ctrl.is_inside_tree():
		return false
	if ctrl is Button and (ctrl as Button).disabled:
		return false
	return ctrl.is_visible_in_tree()

func _rarity_color(rarity: Item.Rarity) -> Color:
	match rarity:
		Item.Rarity.RARE:      return COLOR_RARE
		Item.Rarity.LEGENDARY: return COLOR_LEGENDARY
		_:                     return COLOR_COMMON
