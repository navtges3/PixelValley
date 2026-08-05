extends BaseLocation
class_name WeaponShopInterior

const ENTRANCE_ID := "weapon_shop"
const SERVICE_ID: StringName = &"weapon_shop"

@onready var shop_window: ShopWindow = $CanvasLayer/ShopWindow

func _get_screen_name() -> ScreenManager.ScreenName:
	return ScreenManager.ScreenName.WEAPON_SHOP

func _on_location_ready() -> void:
	shop_window.setup_shop(ShopWindow.ShopType.WEAPON)
	shop_window.closed.connect(_on_window_closed)
	shop_window.close()

func _handle_npc_service_request(npc_id: StringName, service_id: StringName) -> void:
	if service_id != SERVICE_ID:
		super._handle_npc_service_request(npc_id, service_id)
		return
	player.movement_blocked = true
	shop_window.open()

func _on_window_closed() -> void:
	player.movement_blocked = false

func _input(event: InputEvent) -> void:
	if _handle_window_input(event, shop_window):
		return
	else:
		super._input(event)
