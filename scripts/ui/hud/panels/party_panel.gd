extends HudPanel
class_name PartyPanel

@onready var active_list: VBoxContainer = $ScrollContainer/VBox/ActiveList
@onready var reserve_list: VBoxContainer = $ScrollContainer/VBox/ReserveList

@onready var hero_name: Label = $ScrollContainer/VBox/HeroDetails/HeroStats/Name

@onready var hp_bar: ProgressBar = $ScrollContainer/VBox/HeroDetails/HeroStats/HPBar
@onready var hp_label: Label = $ScrollContainer/VBox/HeroDetails/HeroStats/HPBar/HPLabel
@onready var nrg_bar: ProgressBar = $ScrollContainer/VBox/HeroDetails/HeroStats/NRGBar
@onready var nrg_label: Label = $ScrollContainer/VBox/HeroDetails/HeroStats/NRGBar/NRGLabel
@onready var xp_bar: ProgressBar = $ScrollContainer/VBox/HeroDetails/HeroStats/XPBar
@onready var xp_label: Label = $ScrollContainer/VBox/HeroDetails/HeroStats/XPBar/XPLabel

@onready var attack_label: Label = $ScrollContainer/VBox/HeroDetails/HeroStats/StatsGrid/AttackLabel
@onready var magic_label: Label = $ScrollContainer/VBox/HeroDetails/HeroStats/StatsGrid/MagicLabel
@onready var defense_label: Label = $ScrollContainer/VBox/HeroDetails/HeroStats/StatsGrid/DefenseLabel
@onready var resist_label: Label = $ScrollContainer/VBox/HeroDetails/HeroStats/StatsGrid/ResistLabel

@onready var attack_up: Button = $ScrollContainer/VBox/HeroDetails/HeroStats/StatsGrid/AttackMod/AttackUp
@onready var attack_down: Button = $ScrollContainer/VBox/HeroDetails/HeroStats/StatsGrid/AttackMod/AttackDown
@onready var magic_up: Button = $ScrollContainer/VBox/HeroDetails/HeroStats/StatsGrid/MagicMod/MagicUp
@onready var magic_down: Button = $ScrollContainer/VBox/HeroDetails/HeroStats/StatsGrid/MagicMod/MagicDown
@onready var defense_up: Button = $ScrollContainer/VBox/HeroDetails/HeroStats/StatsGrid/DefenseMod/DefenseUp
@onready var defense_down: Button = $ScrollContainer/VBox/HeroDetails/HeroStats/StatsGrid/DefenseMod/DefenseDown
@onready var resist_up: Button = $ScrollContainer/VBox/HeroDetails/HeroStats/StatsGrid/ResistMod/ResistUp
@onready var resist_down: Button = $ScrollContainer/VBox/HeroDetails/HeroStats/StatsGrid/ResistMod/ResistDown

@onready var skill_label: Label = $ScrollContainer/VBox/HeroDetails/HeroStats/StatsGrid/SkillLabel
@onready var confirm_button: Button = $ScrollContainer/VBox/HeroDetails/HeroStats/StatsGrid/ConfirmButton

@onready var equipment: VBoxContainer = $ScrollContainer/VBox/HeroDetails/Equipment

var _selected_id: StringName = &""

var _stat_hero_id: StringName = &""
var _available_points := 0
var _temp_allocations := {
	"attack": 0,
	"magic": 0,
	"defense": 0,
	"resist": 0,
}

func _ready() -> void:
	attack_up.pressed.connect(_on_increase.bind("attack"))
	attack_down.pressed.connect(_on_decrease.bind("attack"))
	magic_up.pressed.connect(_on_increase.bind("magic"))
	magic_down.pressed.connect(_on_decrease.bind("magic"))
	defense_up.pressed.connect(_on_increase.bind("defense"))
	defense_down.pressed.connect(_on_decrease.bind("defense"))
	resist_up.pressed.connect(_on_increase.bind("resist"))
	resist_down.pressed.connect(_on_decrease.bind("resist"))

	confirm_button.pressed.connect(_run.bind(_confirm_selected_hero))

	_register_detail_focus()

func _register_detail_focus() -> void:
	_register_focus(attack_up, "detail:stats:attack:up")
	_register_focus(attack_down, "detail:stats:attack:down")
	_register_focus(magic_up, "detail:stats:magic:up")
	_register_focus(magic_down, "detail:stats:magic:down")
	_register_focus(defense_up, "detail:stats:defense:up")
	_register_focus(defense_down, "detail:stats:defense:down")
	_register_focus(resist_up, "detail:stats:resist:up")
	_register_focus(resist_down, "detail:stats:resist:down")
	_register_focus(confirm_button, "detail:stats:confirm")

# ---- HudPanel contract ----

func refresh() -> void:
	var party := GameState.party
	if party == null or party.members.is_empty():
		return
	if party.get_member_by_id(_selected_id) == null:
		_selected_id = party.members[0].hero_id
	_clear_focus_registry()
	_register_detail_focus()
	clear_children(active_list)
	clear_children(reserve_list)
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
	var selected_hero := party.get_member_by_id(_selected_id)
	if selected_hero != null:
		_refresh_hero_details(party, selected_hero)

func on_tab_opened() -> void:
	_reset_pending_allocations()
	refresh()

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

# --- Hero Details ---

func _refresh_hero_details(party: Party, hero: Hero) -> void:
	if _stat_hero_id != hero.hero_id:
		_stat_hero_id = hero.hero_id
		_reset_pending_allocations()
	if _pending_total() > hero.skill_points:
		_reset_pending_allocations()
	_available_points = hero.skill_points - _pending_total()
	_refresh_identity(hero)
	_refresh_bars(hero)
	_refresh_stats(hero)
	_refresh_equipment(party, hero)

func _refresh_identity(hero: Hero) -> void:
	hero_name.text = "%s  Lv: %d" % [hero.name, hero.level]
	hero_name.add_theme_color_override("font_color", HudStyle.COLOR_HEADER)

func _refresh_bars(hero: Hero) -> void:
	_refresh_bar(hp_bar, hp_label, hero.current_hp,
		hero.max_hp, "%d / %d HP", HudBarStyle.hp_color(hero.current_hp, hero.max_hp))
	_refresh_bar(nrg_bar, nrg_label, hero.current_nrg,
		hero.max_nrg, "%d / %d NRG", HudBarStyle.COLOR_NRG)
	_refresh_bar(xp_bar, xp_label, hero.experience,
		hero.level * Hero.LEVEL_UP_MULT, "%d / %d XP", HudBarStyle.COLOR_XP)

func _refresh_bar(bar: ProgressBar, label: Label, value: int,
	max_value: int, text_format: String, color: Color) -> void:
	bar.max_value = max(max_value, 1)
	bar.value = value
	label.text = text_format % [value, max_value]
	HudBarStyle.apply(bar, color)

func _refresh_stats(hero: Hero) -> void:
	_refresh_stat_label(attack_label, "Attack",
		hero.attack, _temp_allocations["attack"])
	_refresh_stat_label(magic_label, "Magic",
		hero.magic, _temp_allocations["magic"])
	_refresh_stat_label(defense_label, "Defense",
		hero.defense, _temp_allocations["defense"])
	_refresh_stat_label(resist_label, "Resist",
		hero.resist, _temp_allocations["resist"])
	skill_label.text = "Skill Points: %d" % _available_points
	attack_up.disabled = _available_points <= 0
	magic_up.disabled = _available_points <= 0
	defense_up.disabled = _available_points <= 0
	resist_up.disabled = _available_points <= 0
	attack_down.disabled = _temp_allocations["attack"] <= 0
	magic_down.disabled = _temp_allocations["magic"] <= 0
	defense_down.disabled = _temp_allocations["defense"] <= 0
	resist_down.disabled = _temp_allocations["resist"] <= 0
	confirm_button.visible = _pending_total() > 0

func _refresh_stat_label(label: Label, prefix: String,
	base_value: int, bonus: int) -> void:
	if bonus > 0:
		label.text = "%s: %d (+%d)" % [prefix, base_value, bonus]
		label.add_theme_color_override("font_color", Color(0.30, 0.90, 0.40))
	else:
		label.text = "%s: %d" % [prefix, base_value]
		label.remove_theme_color_override("font_color")

func _pending_total() -> int:
	var total := 0
	for stat: String in _temp_allocations:
		total += _temp_allocations[stat]
	return total

func _refresh_equipment(party: Party, hero: Hero) -> void:
	clear_children(equipment)
	equipment.add_theme_constant_override("separation", 6)
	# ---- Weapon ----
	equipment.add_child(HudStyle.label("Weapon", HudStyle.COLOR_HEADER, 14, true))
	var weapon := hero.equipped_weapon
	if weapon == null:
		equipment.add_child(HudStyle.label("None", HudStyle.COLOR_SUBTEXT,
				HudStyle.DEFAULT_FONT_SIZE, true))
	else:
		var weapon_label := HudStyle.label(weapon.name, HudStyle.COLOR_EQUIPPED,
			HudStyle.DEFAULT_FONT_SIZE, true)
		HudStyle.set_tooltip(weapon_label, weapon._to_string())
		equipment.add_child(weapon_label)
		# Active party members must keep their weapon equipped.
		if hero.hero_id not in party.active_member_ids:
			equipment.add_child(_action_button("Unequip",party.unequip_weapon.bind(hero),
					true, ThemeManager.RED_BUTTON, "detail:unequip"))
	# ---- Weapon Stash ----
	equipment.add_child(HSeparator.new())
	equipment.add_child(HudStyle.label("Weapon Stash", HudStyle.COLOR_HEADER, 12, true))
	var equipable_count := 0
	for weapon_id: String in party.inventory.weapon_stash:
		if not WeaponDatabase.can_class_equip(hero.hero_class, weapon_id):
			continue
		var stashed := ItemLoader.get_item(weapon_id) as Weapon
		if stashed == null:
			continue
		equipment.add_child(_stash_row(party, hero, weapon_id, stashed))
		equipable_count += 1
	if equipable_count == 0:
		var message := "No weapons in stash"
		if not party.inventory.weapon_stash.is_empty():
			message = "No equipable weapons"
		equipment.add_child(HudStyle.label(message, HudStyle.COLOR_SUBTEXT,
			HudStyle.DEFAULT_FONT_SIZE, true))
	# ---- Active Effects ----
	equipment.add_child(HSeparator.new())
	equipment.add_child(HudStyle.label("Active Effects",
			HudStyle.COLOR_HEADER, 12, true))
	var effects: Array[EffectView] = EffectManager.get_active_effects(hero)
	if effects.is_empty():
		equipment.add_child(HudStyle.label("No active effects",
				HudStyle.COLOR_SUBTEXT, HudStyle.DEFAULT_FONT_SIZE, true))
	else:
		for effect: EffectView in effects:
			var effect_label := HudStyle.label("• %s" % effect.tooltip_text,
				HudStyle.COLOR_SUBTEXT, HudStyle.DEFAULT_FONT_SIZE, true)
			HudStyle.set_tooltip(effect_label, effect.tooltip_text)
			equipment.add_child(effect_label)

func _on_increase(stat: String) -> void:
	if _available_points <= 0:
		return
	_temp_allocations[stat] += 1
	_available_points -= 1
	request_refresh()

func _on_decrease(stat: String) -> void:
	if _temp_allocations[stat] <= 0:
		return
	_temp_allocations[stat] -= 1
	_available_points += 1
	request_refresh()

func _confirm_stat_allocation(hero: Hero) -> bool:
	if _pending_total() <= 0:
		return false
	for stat: String in _temp_allocations:
		var increase: int = _temp_allocations[stat]
		if increase <= 0:
			continue
		match stat:
			"attack":
				hero.attack += increase
			"magic":
				hero.magic += increase
			"defense":
				hero.defense += increase
			"resist":
				hero.resist += increase
	hero.skill_points = _available_points
	_reset_pending_allocations()
	return true

func _stash_row(party: Party, hero: Hero, weapon_id: String, stashed: Weapon) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_child(_action_button("Equip", party.equip_weapon.bind(hero, weapon_id),
		true, ThemeManager.GREEN_BUTTON, "detail:equip:%s" % weapon_id))
	var lbl := HudStyle.label("• %s  [%s]" % [stashed.name, Item.rarity_to_string(stashed.rarity)],
		HudStyle.rarity_color(stashed.rarity), HudStyle.DEFAULT_FONT_SIZE, true)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	HudStyle.set_tooltip(lbl, stashed._to_string())
	row.add_child(lbl)
	return row

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

func _confirm_selected_hero() -> bool:
	var party := GameState.party
	if party == null:
		return false
	var hero := party.get_member_by_id(_selected_id)
	if hero == null:
		return false
	return _confirm_stat_allocation(hero)

func _reset_pending_allocations() -> void:
	for stat: String in _temp_allocations:
		_temp_allocations[stat] = 0
