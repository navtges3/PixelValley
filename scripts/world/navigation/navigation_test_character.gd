extends CharacterBody2D


@export var target: Marker2D
@export var move_speed: float = 50.0

@onready var character_navigation: CharacterNavigation = $CharacterNavigation


func _ready() -> void:
	if target == null:
		push_error("Navigation test target is not assigned")
		return
	
	var path_found := character_navigation.set_destination(target.global_position)
	
	if not path_found:
		push_warning("Navigation test could not find a path.")


func _physics_process(_delta: float) -> void:
	velocity = character_navigation.get_desired_velocity(move_speed)
	move_and_slide()
