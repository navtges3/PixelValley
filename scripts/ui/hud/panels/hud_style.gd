extends RefCounted
class_name HudStyle

const COLOR_HEADER    := Color(0.95, 0.92, 0.80)
const COLOR_SUBTEXT   := Color(0.72, 0.67, 0.57)
const COLOR_GOLD      := Color(0.95, 0.80, 0.25)
const COLOR_COMMON    := Color(0.85, 0.85, 0.85)
const COLOR_RARE      := Color(0.30, 0.65, 1.00)
const COLOR_LEGENDARY := Color(1.00, 0.75, 0.20)
const COLOR_EQUIPPED  := Color(0.30, 0.90, 0.45)
const COLOR_DOWNED    := Color(0.90, 0.35, 0.35)
const COLOR_SELECTED  := Color(0.95, 0.80, 0.25)

# wrap defaults to false: an autowrap Label in a container with no minimum
# width collapses into a tall, thin column. Party/inventory pass wrap = true.
static func label(text: String, color: Color = COLOR_COMMON, font_size: int = 12, word_wrap: bool = false) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", font_size)
	if word_wrap:
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return lbl

static func rarity_color(rarity: Item.Rarity) -> Color:
	match rarity:
		Item.Rarity.RARE: return COLOR_RARE
		Item.Rarity.LEGENDARY: return COLOR_LEGENDARY
		_: return COLOR_COMMON
