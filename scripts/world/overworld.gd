extends Node2D

func place_player_at_entrance(entrance_id: String) -> void:
	var entrance = get_node_or_null("Entrances/" + entrance_id)
	if entrance:
		$Player.place_at_entrance(entrance)
	else:
		push_warning("Entrance not found: ", entrance_id)
