extends BaseLocation
class_name WeaponShopInterior

const ENTRANCE_ID := "weapon_shop"

@onready var shop_window: ShopWindow = $CanvasLayer/ShopWindow
@onready var interact_area: InteractArea = $FloorProps/Counter/InteractArea

func _get_screen_name() -> ScreenManager.ScreenName:
	return ScreenManager.ScreenName.WEAPON_SHOP

func _on_location_ready() -> void:
	interact_area.interacted.connect(_on_counter_interacted)
	shop_window.closed.connect(_on_window_closed)
	shop_window.hide()

func _on_counter_interacted() -> void:
	player.movement_blocked = true
	shop_window.open(ShopWindow.ShopType.WEAPON)

func _on_window_closed() -> void:
	player.movement_blocked = false

func _input(event: InputEvent) -> void:
	if shop_window.is_visible_in_tree():
		if event.is_action_pressed("open_hud") or event.is_action_pressed("ui_cancel"):
			shop_window.close()
	else:
		super._input(event)
