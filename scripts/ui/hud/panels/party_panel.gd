extends HudPanel
class_name PartyPanel

const UP_BUTTON_THEME := preload("res://resources/themes/buttons/specialty/up_button.tres")
const DOWN_BUTTON_THEME := preload("res://resources/themes/buttons/specialty/down_button.tres")

@onready var active_list: VBoxContainer = $ScrollContainer/VBox/ActiveList
@onready var reserve_list: VBoxContainer = $ScrollContainer/VBox/ReserveList
@onready var detail_list: VBoxContainer = $ScrollContainer/VBox/DetailList

var _selected_id: StringName = &""

var _stat_hero_id: StringName = &""
var _available_points := 0
var _temp_allocations := {
	"attack": 0,
	"magic": 0,
	"defense": 0,
	"resist": 0,
}

# ---- HudPanel contract ----

func refresh() -> void:
	var party := GameState.party
	if party == null or party.members.is_empty():
		return
	if party.get_member_by_id(_selected_id) == null:
		_selected_id = party.members[0].hero_id
	_clear_focus_registry()
	for list: VBoxContainer in [active_list, reserve_list, detail_list]:
		clear_children(list)
	var active := party.get_active_members()
	for i: int in active.size():
		active_list.add_child(_active_row(party, active[i], i, active.size()))
	var reserve_count := 0
	for hero: Hero in party.members:
		if hero not in active:
			reserve_list.add_child(_reserve_row(party, hero))
			reserve_count += 1
	if reserve_count == 0:
		reserve_list.add_child(HudStyle.label("No reserve members", HudStyle.COLOR_SUBTEXT, 12, true))
	_build_detail(party, party.get_member_by_id(_selected_id))

# Add moves a hero from reserve to active (and Remove the reverse), so when the
# remembered control is gone, land on the same hero's select button.
func _get_focus_fallback(lost_key: String) -> Control:
	var parts := lost_key.split(":")
	if parts.size() < 3 or parts[0] not in ["active", "reserve"]:
		return null
	for list_name: String in ["active", "reserve"]:
		var select: Control = _focus_controls.get("%s:%s:select" % [list_name, parts[1]])
		if can_receive_focus(select):
			return select
	return null

# ---- Rows ----

func _active_row(party: Party, hero: Hero, index: int, count: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	var leader_tag := " (Leader)" if party.is_leader(hero) else ""
	var downed_tag := " (Downed)" if not hero.is_alive() else ""
	row.add_child(_hero_select_button(
		hero,
		"%d. %s Lv%d  %d/%d HP%s%s" % [
			index + 1, hero.name, hero.level, hero.current_hp, hero.max_hp, leader_tag, downed_tag
		],
		"active:%s:select" % hero.hero_id
	))
	row.add_child(_action_button(
		"▲", party.move_active_member.bind(hero, -1), index > 0,
		ThemeManager.GRAY_BUTTON, "active:%s:up" % hero.hero_id
	))
	row.add_child(_action_button(
		"▼", party.move_active_member.bind(hero, 1), index < count - 1,
		ThemeManager.GRAY_BUTTON, "active:%s:down" % hero.hero_id
	))
	row.add_child(_action_button(
		"Remove", party.remove_from_active_party.bind(hero),
		not party.is_leader(hero) and count > 1,
		ThemeManager.RED_BUTTON, "active:%s:remove" % hero.hero_id
	))
	# Leader control sits after formation buttons so ▲ ▼ Remove stay grouped.
	row.add_child(_action_button(
		"Make Leader", _promote_to_leader.bind(party, hero),
		not party.is_leader(hero),
		ThemeManager.GRAY_BUTTON, "active:%s:leader" % hero.hero_id
	))
	return row

func _reserve_row(party: Party, hero: Hero) -> HBoxContainer:
	var row := HBoxContainer.new()
	var downed_tag := " (Downed)" if not hero.is_alive() else ""
	row.add_child(_hero_select_button(
		hero,
		"%s Lv%d%s" % [hero.name, hero.level, downed_tag],
		"reserve:%s:select" % hero.hero_id
	))
	var has_room := party.active_member_ids.size() < Party.MAX_ACTIVE_MEMBERS
	row.add_child(_action_button(
		"Add", party.add_to_active_party.bind(hero),
		party.is_eligible(hero) and has_room,
		ThemeManager.GREEN_BUTTON, "reserve:%s:add" % hero.hero_id
	))
	return row

# ---- Detail ----

func _build_detail(party: Party, hero: Hero) -> void:
	if hero == null:
		return
	if _stat_hero_id != hero.hero_id:
		_stat_hero_id = hero.hero_id
		_reset_pending_allocations()
	if _pending_total() > hero.skill_points:
		_reset_pending_allocations()
	_available_points = hero.skill_points - _pending_total()
	_add_identity_row(hero)
	detail_list.add_child(_bar_row(hero.current_hp, hero.max_hp,
		"%d / %d HP", HudBarStyle.hp_color(hero.current_hp, hero.max_hp)))
	detail_list.add_child(_bar_row(hero.current_nrg, hero.max_nrg,
		"%d / %d NRG", HudBarStyle.COLOR_NRG))
	detail_list.add_child(_bar_row(	hero.experience, hero.level * Hero.LEVEL_UP_MULT,
		"%d / %d XP", HudBarStyle.COLOR_XP))
	_add_stat_section(hero)
	_add_effects_section(hero)
	_add_equipment_section(party, hero)

func _add_identity_row(hero: Hero) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var name_label := HudStyle.label(hero.name, HudStyle.COLOR_HEADER, 18, true)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var class_label := HudStyle.label(hero.get_class_name(), HudStyle.COLOR_SUBTEXT, 12, true)
	var level_label := HudStyle.label("Level %d" % hero.level, HudStyle.COLOR_HEADER, 13, true)
	row.add_child(name_label)
	row.add_child(class_label)
	row.add_child(level_label)
	detail_list.add_child(row)

func _add_stat_section(hero: Hero) -> void:
	var separator := HSeparator.new()
	detail_list.add_child(separator)
	var header := HudStyle.label("Stats", HudStyle.COLOR_HEADER, 14, true)
	detail_list.add_child(header)
	var stats_grid := GridContainer.new()
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("v_separation", 6)
	stats_grid.add_theme_constant_override("h_separation", 8)
	detail_list.add_child(stats_grid)
	var stat_data := [
		["attack", "Attack", hero.attack],
		["magic", "Magic", hero.magic],
		["defense", "Defense", hero.defense],
		["resist", "Resist", hero.resist],
	]
	for entry in stat_data:
		var stat: String = entry[0]
		var label_text: String = entry[1]
		var base_value: int = entry[2]
		stats_grid.add_child(_stat_value_label(stat, label_text, base_value))
		stats_grid.add_child(_stat_modifier_controls(stat))
	var skill_label := HudStyle.label("Skill Points: %d" % _available_points, HudStyle.COLOR_GOLD, 16, true)
	skill_label.name = "SkillLabel"
	stats_grid.add_child(skill_label)
	var confirm_button := HudStyle.button("Confirm", _pending_total() > 0, ThemeManager.GREEN_BUTTON)
	confirm_button.name = "ConfirmButton"
	confirm_button.pressed.connect(_run.bind(_confirm_stat_allocation.bind(hero)))
	_register_focus(confirm_button, "detail:stats:confirm")
	stats_grid.add_child(confirm_button)

func _stat_value_label(stat: String, prefix: String, base_value: int) -> Label:
	var bonus: int = _temp_allocations[stat]
	var label: Label
	if bonus > 0:
		label = HudStyle.label("%s: %d (+%d)" % [prefix, base_value, bonus], Color(0.30, 0.90, 0.40), 16, true)
	else:
		label = HudStyle.label("%s: %d" % [prefix, base_value], HudStyle.COLOR_COMMON, 16, true)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	return label

func _stat_modifier_controls(stat: String) -> VBoxContainer:
	var controls := VBoxContainer.new()
	controls.add_theme_constant_override("separation", 1)
	var increase_button := HudStyle.button("+", _available_points > 0, UP_BUTTON_THEME)
	increase_button.custom_minimum_size = Vector2(32, 16)
	increase_button.pressed.connect(_on_increase.bind(stat))
	_register_focus(increase_button, "detail:stats:%s:up" % stat)
	var decrease_button := HudStyle.button("−", _temp_allocations[stat] > 0, DOWN_BUTTON_THEME)
	decrease_button.custom_minimum_size = Vector2(32, 16)
	decrease_button.pressed.connect(_on_decrease.bind(stat))
	_register_focus(decrease_button, "detail:stats:%s:down" % stat)
	controls.add_child(increase_button)
	controls.add_child(decrease_button)
	return controls

func _add_effects_section(hero: Hero) -> void:
	detail_list.add_child(HSeparator.new())
	detail_list.add_child(
		HudStyle.label("Active Effects", HudStyle.COLOR_HEADER, 12, true))
	var effects: Array[EffectView] = EffectManager.get_active_effects(hero)
	if effects.is_empty():
		detail_list.add_child(
			HudStyle.label("No active effects", HudStyle.COLOR_SUBTEXT, 11, true))
		return
	for effect: EffectView in effects:
		detail_list.add_child(
			HudStyle.label("  • %s" % effect.tooltip_text, HudStyle.COLOR_SUBTEXT, 11, true))

func _add_equipment_section(party: Party, hero: Hero) -> void:
	detail_list.add_child(HSeparator.new())
	var weapon := hero.equipped_weapon
	_add_detail_label("Weapon: %s" % (weapon.name if weapon != null else "None"),
		HudStyle.COLOR_EQUIPPED if weapon != null else HudStyle.COLOR_SUBTEXT)
	# Abilities come from the equipped weapon, so an active hero must keep one.
	if weapon != null and hero.hero_id not in party.active_member_ids:
		detail_list.add_child(
			_action_button("Unequip", party.unequip_weapon.bind(hero),
				true, ThemeManager.RED_BUTTON, "detail:unequip"))
	if party.inventory.weapon_stash.is_empty():
		_add_detail_label("No weapons in stash", HudStyle.COLOR_SUBTEXT)
		return
	for weapon_id: String in party.inventory.weapon_stash:
		var stashed := ItemLoader.get_item(weapon_id) as Weapon
		if stashed == null:
			continue
		detail_list.add_child(_stash_row(party, hero, weapon_id, stashed))

func _stash_row(party: Party, hero: Hero, weapon_id: String, stashed: Weapon) -> HBoxContainer:
	var row := HBoxContainer.new()
	var can_equip := WeaponDatabase.can_class_equip(hero.hero_class, weapon_id)
	var equip_btn := _action_button("Equip", party.equip_weapon.bind(hero, weapon_id), can_equip,
		ThemeManager.GREEN_BUTTON, "detail:equip:%s" % weapon_id)
	if not can_equip:
		equip_btn.tooltip_text = "Cannot be equipped by a %s." % hero.get_class_name()
	row.add_child(equip_btn)
	var lbl := HudStyle.label("• %s  [%s]" % [stashed.name, Item.rarity_to_string(stashed.rarity)],
		HudStyle.rarity_color(stashed.rarity), HudStyle.DEFAULT_FONT_SIZE, true)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	HudStyle.set_tooltip(lbl, stashed._to_string())
	row.add_child(lbl)
	return row

func _add_detail_label(text: String, color: Color, font_size: int = HudStyle.DEFAULT_FONT_SIZE) -> void:
	detail_list.add_child(HudStyle.label(text, color, font_size, true))

func _bar_row(value: int, max_val: int, fmt: String, color: Color) -> Control:
	var bar := ProgressBar.new()
	bar.max_value = max(max_val, 1)
	bar.value = value
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 18)
	HudBarStyle.apply(bar, color)
	var lbl := HudStyle.label(fmt % [value, max_val], HudStyle.COLOR_HEADER, 11)
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bar.add_child(lbl)
	return bar

# ---- Controls ----

func _hero_select_button(hero: Hero, text: String, focus_key: String) -> Button:
	var is_selected := hero.hero_id == _selected_id
	var button := HudStyle.button(("▶ " if is_selected else "  ") + text)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if is_selected:
		button.add_theme_color_override("font_color", HudStyle.COLOR_SELECTED)
	elif not hero.is_alive():
		button.add_theme_color_override("font_color", HudStyle.COLOR_DOWNED)
	button.pressed.connect(_select.bind(hero.hero_id))
	_register_focus(button, focus_key)
	return button

func _action_button(text: String, action: Callable, enabled: bool,
		button_theme: Theme, focus_key: String) -> Button:
	var button := HudStyle.button(text, enabled, button_theme)
	button.pressed.connect(_run.bind(action))
	_register_focus(button, focus_key)
	return button

# ---- Actions ----

func _run(action: Callable) -> void:
	var result: Variant = action.call()
	if result == true:
		SaveManager.save_party()
	request_refresh()

func _promote_to_leader(party: Party, hero: Hero) -> bool:
	return party.set_leader(hero)

func _select(hero_id: StringName) -> void:
	_selected_id = hero_id
	request_refresh()

func _reset_pending_allocations() -> void:
	_temp_allocations["attack"] = 0
	_temp_allocations["magic"] = 0
	_temp_allocations["defense"] = 0
	_temp_allocations["resist"] = 0
