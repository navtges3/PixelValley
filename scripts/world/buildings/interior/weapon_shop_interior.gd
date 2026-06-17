extends BaseLocation
class_name WeaponShopInterior

const SCREEN_NAME := ScreenManager.ScreenName.WEAPON_SHOP
const ENTRANCE_ID := "weapon_shop"

@onready var shop_window: ShopWindow = $CanvasLayer/ShopWindow
@onready var interact_area: InteractArea = $FloorProps/Counter/InteractArea

func _get_screen_name() -> ScreenManager.ScreenName:
	return SCREEN_NAME

func _on_location_ready() -> void:
	interact_area.interacted.connect(_on_counter_interacted)
	shop_window.closed.connect(_on_window_closed)
	shop_window.hide()

func _on_counter_interacted() -> void:
	player.movement_blocked = true
	shop_window.open(ShopWindow.ShopType.WEAPON)

func _on_window_closed() -> void:
	player.movement_blocked = false
