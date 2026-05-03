extends Control
class_name InventoryPanel

@onready var potions_list: VBoxContainer = $ScrollContainer/VBox/PotionsSection/PotionsList
@onready var equipped_label: Label = $ScrollContainer/VBox/WeaponsSection/EquippedLabel
@onready var weapons_list: VBoxContainer = $ScrollContainer/VBox/WeaponsSection/WeaponsList

const COLOR_HEADER    := Color(0.95, 0.92, 0.80)
const COLOR_SUBTEXT   := Color(0.72, 0.67, 0.57)
const COLOR_GOLD      := Color(0.95, 0.80, 0.25)
const COLOR_COMMON    := Color(0.85, 0.85, 0.85)
const COLOR_RARE      := Color(0.30, 0.65, 1.00)
const COLOR_LEGENDARY := Color(1.00, 0.75, 0.20)
const COLOR_EQUIPPED  := Color(0.30, 0.90, 0.45)

func refresh() -> void:
	if GameState.hero == null:
		return
	var hero := GameState.hero
	_refresh_potions(hero)
	_refresh_weapons(hero)

func _refresh_potions(hero: Hero) -> void:
	for child in potions_list.get_children():
		child.queue_free()
	
	if hero.inventory.potions.is_empty():
		potions_list.add_child(_make_label("No potions", COLOR_SUBTEXT))
		return
	
	for item_id in hero.inventory.potions:
		var count: int = hero.inventory.potions[item_id]
		var item := ItemLoader.get_item(item_id) as Potion
		if item == null:
			continue
		var row := HBoxContainer.new()
		var name_lbl := _make_label("• %dx %s" % [count, item.name], COLOR_COMMON)
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_lbl)
		if item.effects.size() > 0:
			var tip_parts: Array = []
			for eff in item.effects:
				tip_parts.append(eff._to_string())
			name_lbl.tooltip_text = "\n".join(tip_parts)
		potions_list.add_child(row)

func _refresh_weapons(hero: Hero) -> void:
	for child in weapons_list.get_children():
		child.queue_free()
	
	var equipped := hero.inventory.equipped_weapon
	if equipped:
		equipped_label.text = "Equipped: %s" % equipped.name
		equipped_label.add_theme_color_override("font_color", COLOR_EQUIPPED)
		var tip := equipped._to_string()
		equipped_label.tooltip_text = tip
	else:
		equipped_label.text = "Equipped: None"
		equipped_label.add_theme_color_override("font_color", COLOR_SUBTEXT)
	
	if hero.inventory.weapon_stash.is_empty():
		weapons_list.add_child(_make_label("No weapons in stash", COLOR_SUBTEXT))
		return
	
	for weapon_id in hero.inventory.weapon_stash:
		var weapon := ItemLoader.get_item(weapon_id) as Weapon
		if weapon == null:
			continue
		var color := _rarity_color(weapon.rarity)
		var lbl := _make_label("• %s  [%s]" % [weapon.name, Item.rarity_to_string(weapon.rarity)], color)
		lbl.tooltip_text = weapon._to_string()
		weapons_list.add_child(lbl)

func _rarity_color(rarity: Item.Rarity) -> Color:
	match rarity:
		Item.Rarity.RARE:      return COLOR_RARE
		Item.Rarity.LEGENDARY: return COLOR_LEGENDARY
		_:                     return COLOR_COMMON

func _make_label(txt: String, color: Color, font_size: int = 12) -> Label:
	var lbl := Label.new()
	lbl.text = txt
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return lbl
