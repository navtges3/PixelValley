extends RefCounted
class_name HudStyle
## Shared palette and control factories for HUD panels. Pure static helpers, so
## non-panel UI (hero_hud, reward entries, ...) can use them too.

const COLOR_HEADER    := Color(0.95, 0.92, 0.80)
const COLOR_SUBTEXT   := Color(0.72, 0.67, 0.57)
const COLOR_GOLD      := Color(0.95, 0.80, 0.25)
const COLOR_COMMON    := Color(0.85, 0.85, 0.85)
const COLOR_RARE      := Color(0.30, 0.65, 1.00)
const COLOR_LEGENDARY := Color(1.00, 0.75, 0.20)
const COLOR_EQUIPPED  := Color(0.30, 0.90, 0.45)
const COLOR_DOWNED    := Color(0.90, 0.35, 0.35)
const COLOR_SELECTED  := Color(0.95, 0.80, 0.25)

const DEFAULT_FONT_SIZE := 12
const BUTTON_FONT_SIZE := 11

# word_wrap defaults to false: an autowrap Label in a container with no minimum
# width collapses into a tall, thin column. Lists inside a full-width
# ScrollContainer (party, inventory) pass word_wrap = true.
static func label(text: String, color: Color = COLOR_COMMON,
		font_size: int = DEFAULT_FONT_SIZE, word_wrap: bool = false) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", font_size)
	if word_wrap:
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return lbl

static func button(text: String, enabled: bool = true, button_theme: Theme = null,
		font_size: int = BUTTON_FONT_SIZE) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.disabled = not enabled
	if button_theme != null:
		btn.theme = button_theme
	btn.add_theme_font_size_override("font_size", font_size)
	return btn

## Labels ignore the mouse by default, so a tooltip on one never shows.
## This sets the tooltip and lets the label receive hover events.
static func set_tooltip(control: Control, text: String) -> void:
	control.tooltip_text = text
	if control is Label:
		control.mouse_filter = Control.MOUSE_FILTER_PASS

static func rarity_color(rarity: Item.Rarity) -> Color:
	match rarity:
		Item.Rarity.RARE: return COLOR_RARE
		Item.Rarity.LEGENDARY: return COLOR_LEGENDARY
		_: return COLOR_COMMON
