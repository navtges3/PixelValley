extends RefCounted
class_name RewardEntry

var display_text: String
var color: Color

const COLOR_GOLD       := Color(0.95, 0.80, 0.25)
const COLOR_XP         := Color(0.35, 0.55, 0.90)
const COLOR_POTION     := Color(0.25, 0.85, 0.35)
const COLOR_WEAPON     := Color(0.85, 0.45, 0.15)
const COLOR_WEAPON_SOLD := Color(0.65, 0.65, 0.65)

static func gold(amount: int) -> RewardEntry:
	var entry := RewardEntry.new()
	entry.display_text = "⬡ %d Gold" % amount
	entry.color = COLOR_GOLD
	return entry

static func experience(amount: int) -> RewardEntry:
	var entry := RewardEntry.new()
	entry.display_text = "✦ %d Experience" % amount
	entry.color = COLOR_XP
	return entry

static func potion(item_id: String, count: int) -> RewardEntry:
	var entry := RewardEntry.new()
	var item := ItemLoader.get_item(item_id)
	var name := item.name if item else item_id
	entry.display_text = "⬥ %dx %s" % [count, name]
	entry.color = COLOR_POTION
	return entry

static func weapon(item_id: String) -> RewardEntry:
	var entry := RewardEntry.new()
	var item := ItemLoader.get_item(item_id)
	var name := item.name if item else item_id
	entry.display_text = "⚔ %s" % name
	entry.color = COLOR_WEAPON
	return entry

static func weapon_sold(item_id: String, gold_amount: int) -> RewardEntry:
	var entry := RewardEntry.new()
	var item := ItemLoader.get_item(item_id)
	var name := item.name if item else item_id
	entry.display_text = "⚔ %s (duplicate — sold for %d gold)" % [name, gold_amount]
	entry.color = COLOR_WEAPON_SOLD
	return entry
