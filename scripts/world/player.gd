extends CharacterBody2D

const SPEED := 120.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var _last_location_id: String = ""
var last_direction := Vector2.DOWN

func _physics_process(_delta: float) -> void:
	var input := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	).normalized()
	
	velocity = input * SPEED
	move_and_slide()
	_update_animation(input)
	_check_tile()

func _update_animation(input: Vector2) -> void:
	if input == Vector2.ZERO:
		anim.stop()
		return
	
	last_direction = input
	
	if abs(input.x) > abs(input.y):
		anim.play("walk_right" if input.x > 0 else "walk_left")
	else:
		anim.play("walk_down" if input.y > 0 else "walk_up")

func _check_tile() -> void:
	var tile_map_layer: TileMapLayer = get_parent().get_node("TileMapLayer")
	var tile_pos := tile_map_layer.local_to_map(global_position)
	var tile_data := tile_map_layer.get_cell_tile_data(tile_pos)
	if tile_data:
		var loc: String = tile_data.get_custom_data("location_id")
		if loc != _last_location_id:
			_last_location_id = loc
			var danger: bool = tile_data.get_custom_data("danger")
			match loc:
				"village":
					ScreenManager.go_to_screen(ScreenManager.ScreenName.VILLAGE, loc)
				"cave", "forest", "war_camp":
					print("location: ", loc)
			if danger:
				print("danger zone!")

func place_at_entrance(entrance_node: Node2D) -> void:
	global_position = entrance_node.global_position
