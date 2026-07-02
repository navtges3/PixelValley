extends BaseLocation
class_name PotionShopInterior

const ENTRANCE_ID := "potion_shop"

@onready var shop_window: ShopWindow = $CanvasLayer/ShopWindow
@onready var interact_area: InteractArea = $FloorProps/Counter/InteractArea

func _get_screen_name() -> ScreenManager.ScreenName:
	return ScreenManager.ScreenName.POTION_SHOP

func _on_location_ready() -> void:
	interact_area.interacted.connect(_on_counter_interacted)
	shop_window.closed.connect(_on_window_closed)
	shop_window.hide()

func _on_counter_interacted() -> void:
	player.movement_blocked = true
	shop_window.open(ShopWindow.ShopType.POTION)

func _on_window_closed() -> void:
	player.movement_blocked = false
