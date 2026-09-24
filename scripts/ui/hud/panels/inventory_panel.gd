extends Control
class_name InventoryPanel

@onready var gold_label: Label = $ScrollContainer/VBox/GoldLabel
@onready var potions_list: VBoxContainer = $ScrollContainer/VBox/PotionsSection/PotionsList
@onready var quest_items_list: VBoxContainer = $ScrollContainer/VBox/QuestItemsSection/QuestItemsList
@onready var equipped_label: Label = $ScrollContainer/VBox/WeaponsSection/EquippedLabel
@onready var weapons_list: VBoxContainer = $ScrollContainer/VBox/WeaponsSection/WeaponsList

const COLOR_HEADER    := Color(0.95, 0.92, 0.80)
const COLOR_SUBTEXT   := Color(0.72, 0.67, 0.57)
const COLOR_GOLD      := Color(0.95, 0.80, 0.25)
const COLOR_COMMON    := Color(0.85, 0.85, 0.85)
const COLOR_RARE      := Color(0.30, 0.65, 1.00)
const COLOR_LEGENDARY := Color(1.00, 0.75, 0.20)
const COLOR_EQUIPPED  := Color(0.30, 0.90, 0.45)

func get_default_focus_target() -> Control:
	return null

func refresh() -> void:
	if GameState.party == null:
		return
	var party := GameState.party
	_refresh_gold(party.inventory)
	_refresh_potions(party.inventory)
	_refresh_quest_items(party.inventory)
	_refresh_weapons(party)

func _make_label(txt: String, color: Color, font_size: int = 12) -> Label:
	var lbl := Label.new()
	lbl.text = txt
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return lbl

func _rarity_color(rarity: Item.Rarity) -> Color:
	match rarity:
		Item.Rarity.RARE:      return COLOR_RARE
		Item.Rarity.LEGENDARY: return COLOR_LEGENDARY
		_:                     return COLOR_COMMON

func _refresh_gold(inventory: Inventory) -> void:
	if gold_label != null:
		gold_label.text = "⬡ Gold: %d" % inventory.gold
		gold_label.add_theme_color_override("font_color", COLOR_GOLD)

func _refresh_potions(inventory: Inventory) -> void:
	for child in potions_list.get_children():
		child.queue_free()
	if inventory.potions.is_empty():
		potions_list.add_child(_make_label("No potions", COLOR_SUBTEXT))
		return
	for item_id in inventory.potions:
		var count: int = inventory.potions[item_id]
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

func _refresh_quest_items(inventory: Inventory) -> void:
	for child in quest_items_list.get_children():
		child.queue_free()
	if inventory.quest_items.is_empty():
		quest_items_list.add_child(_make_label("No quest items", COLOR_SUBTEXT))
		return
	for item_id: String in inventory.quest_items:
		var count := inventory.get_quest_item_count(item_id)
		var item := ItemLoader.get_item(item_id) as QuestItem
		if item == null:
			continue
		var label := _make_label(
			"◆ %dx %s" % [count, item.name],
			RewardEntry.COLOR_QUEST_ITEM
		)
		label.tooltip_text = item.description
		quest_items_list.add_child(label)

func _refresh_weapons(party: Party) -> void:
	for child in weapons_list.get_children():
		child.queue_free()
	var equipped_lines: Array[String] = []
	for hero: Hero in party.members:
		var weapon := hero.equipped_weapon
		var weapon_name := weapon.name if weapon != null else "None"
		equipped_lines.append("%s: %s" % [hero.name, weapon_name])
	if equipped_lines.is_empty():
		equipped_label.text = "No party members"
		equipped_label.add_theme_color_override("font_color", COLOR_SUBTEXT)
	else:
		equipped_label.text = "\n".join(equipped_lines)
		equipped_label.add_theme_color_override("font_color", COLOR_EQUIPPED)

	if party.inventory.weapon_stash.is_empty():
		weapons_list.add_child(_make_label("No weapons in stash", COLOR_SUBTEXT))
		return
	for weapon_id in party.inventory.weapon_stash:
		var weapon := ItemLoader.get_item(weapon_id) as Weapon
		if weapon == null:
			continue
		var color := _rarity_color(weapon.rarity)
		var row := HBoxContainer.new()
		var lbl := _make_label("• %s  [%s]" % [weapon.name, Item.rarity_to_string(weapon.rarity)], color)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.tooltip_text = weapon._to_string()
		row.add_child(lbl)
		weapons_list.add_child(row)
