extends Node

@onready var world: Node2D = $World
@onready var player: Player = $Player

func get_player() -> Player:
	return player

func get_world() -> Node:
	return world
