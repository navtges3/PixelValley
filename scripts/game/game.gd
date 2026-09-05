class_name Game
extends Node

static var instance: Game = null

@onready var world: Node2D = $World
@onready var player: Player = $Player
@onready var screens: CanvasLayer = $Screens

var current_location: BaseLocation = null
var current_ui: Control = null

func _enter_tree() -> void:
	instance = self

func _exit_tree() -> void:
	if instance == self:
		instance = null

func _ready() -> void:
	if ScreenManager.get_current_screen_name() == ScreenManager.ScreenName.NONE:
		ScreenManager.go_to_screen(ScreenManager.ScreenName.MAIN_MENU)

static func get_instance() -> Game:
	return instance

static func get_player() -> Player:
	return instance.player if instance != null else null

static func get_world() -> Node2D:
	return instance.world if instance != null else null

static func get_current_location() -> BaseLocation:
	return instance.current_location if instance != null else null

static func set_current_location(location: BaseLocation) -> void:
	if instance != null:
		instance.current_location = location

static func get_screens_container() -> CanvasLayer:
	return instance.screens if instance != null else null

static func get_current_ui() -> Control:
	return instance.current_ui if instance != null else null

static func set_current_ui(ui: Control) -> void:
	if instance != null:
		instance.current_ui = ui
