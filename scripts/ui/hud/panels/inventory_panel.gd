extends HudPanel
class_name InventoryPanel

@onready var gold_label: Label = $ScrollContainer/VBox/GoldLabel
@onready var potions_list: VBoxContainer = $ScrollContainer/VBox/PotionsSection/PotionsList
@onready var quest_items_list: VBoxContainer = $ScrollContainer/VBox/QuestItemsSection/QuestItemsList
@onready var equipped_label: Label = $ScrollContainer/VBox/WeaponsSection/EquippedLabel
@onready var weapons_list: VBoxContainer = $ScrollContainer/VBox/WeaponsSection/WeaponsList

# Read-only view of the shared inventory: equipping happens on the Party tab,
# so there is nothing to focus here (GameHUD falls back to the tab button).
func get_default_focus_target() -> Control:
	return null

func refresh() -> void:
	var party := GameState.party
	if party == null:
		return
	_refresh_gold(party.inventory)
	_refresh_potions(party.inventory)
	_refresh_quest_items(party.inventory)
	_refresh_weapons(party)

func _refresh_gold(inventory: Inventory) -> void:
	if gold_label != null:
		gold_label.text = "⬡ Gold: %d" % inventory.gold
		gold_label.add_theme_color_override("font_color", HudStyle.COLOR_GOLD)

func _refresh_potions(inventory: Inventory) -> void:
	clear_children(potions_list)
	if inventory.potions.is_empty():
		potions_list.add_child(_wrapped_label("No potions", HudStyle.COLOR_SUBTEXT))
		return
	for item_id in inventory.potions:
		var count: int = inventory.potions[item_id]
		var item := ItemLoader.get_item(item_id) as Potion
		if item == null:
			continue
		var name_lbl := _wrapped_label("• %dx %s" % [count, item.name], HudStyle.COLOR_COMMON)
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if item.effects.size() > 0:
			var tip_parts: Array = []
			for eff in item.effects:
				tip_parts.append(eff._to_string())
			HudStyle.set_tooltip(name_lbl, "\n".join(tip_parts))
		potions_list.add_child(name_lbl)

func _refresh_quest_items(inventory: Inventory) -> void:
	clear_children(quest_items_list)
	if inventory.quest_items.is_empty():
		quest_items_list.add_child(_wrapped_label("No quest items", HudStyle.COLOR_SUBTEXT))
		return
	for item_id: String in inventory.quest_items:
		var count := inventory.get_quest_item_count(item_id)
		var item := ItemLoader.get_item(item_id) as QuestItem
		if item == null:
			continue
		var label := _wrapped_label(
			"◆ %dx %s" % [count, item.name],
			RewardEntry.COLOR_QUEST_ITEM
		)
		HudStyle.set_tooltip(label, item.description)
		quest_items_list.add_child(label)

func _refresh_weapons(party: Party) -> void:
	clear_children(weapons_list)
	var equipped_lines: Array[String] = []
	for hero: Hero in party.members:
		var weapon := hero.equipped_weapon
		var weapon_name := weapon.name if weapon != null else "None"
		equipped_lines.append("%s: %s" % [hero.name, weapon_name])
	if equipped_lines.is_empty():
		equipped_label.text = "No party members"
		equipped_label.add_theme_color_override("font_color", HudStyle.COLOR_SUBTEXT)
	else:
		equipped_label.text = "\n".join(equipped_lines)
		equipped_label.add_theme_color_override("font_color", HudStyle.COLOR_EQUIPPED)

	if party.inventory.weapon_stash.is_empty():
		weapons_list.add_child(_wrapped_label("No weapons in stash", HudStyle.COLOR_SUBTEXT))
		return
	for weapon_id in party.inventory.weapon_stash:
		var weapon := ItemLoader.get_item(weapon_id) as Weapon
		if weapon == null:
			continue
		var lbl := _wrapped_label(
			"• %s  [%s]" % [weapon.name, Item.rarity_to_string(weapon.rarity)],
			HudStyle.rarity_color(weapon.rarity)
		)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		HudStyle.set_tooltip(lbl, weapon._to_string())
		weapons_list.add_child(lbl)

# Lists sit in a full-width ScrollContainer, so these labels wrap.
func _wrapped_label(text: String, color: Color) -> Label:
	return HudStyle.label(text, color, HudStyle.DEFAULT_FONT_SIZE, true)
