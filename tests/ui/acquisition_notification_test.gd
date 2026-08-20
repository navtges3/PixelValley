extends TestCase

const ACQUISITION_NOTIFICATION_SCENE := preload(
	"res://scenes/ui/hud/acquisition_notification.tscn"
)

func run_tests() -> int:
	_begin_test_run()
	_test_notification_is_nonblocking_and_starts_hidden()
	_test_notification_queue_displays_and_advances()
	_test_clear_resets_active_and_queued_entries()
	return _finish_test_run("Acquisition notification tests")

func _test_notification_is_nonblocking_and_starts_hidden() -> void:
	var acquisition := _new_notification()

	_expect_true(not acquisition.panel.visible, "the notification starts hidden")
	_expect_equal(
		acquisition.mouse_filter,
		Control.MOUSE_FILTER_IGNORE,
		"the notification root ignores mouse input"
	)
	_expect_equal(
		acquisition.panel.mouse_filter,
		Control.MOUSE_FILTER_IGNORE,
		"the visible notification panel ignores mouse input"
	)
	_expect_equal(
		acquisition.focus_mode,
		Control.FOCUS_NONE,
		"the notification cannot take menu focus"
	)
	_expect_true(
		acquisition.display_timer.one_shot,
		"the notification timer stops after each displayed entry"
	)
	acquisition.free()

func _test_notification_queue_displays_and_advances() -> void:
	var acquisition := _new_notification()
	var potion := RewardEntry.potion("lesser_healing_potion", 2)
	var gold := RewardEntry.gold(10)
	var rewards: Array[RewardEntry] = [potion, gold]

	acquisition.enqueue(rewards)

	_expect_true(acquisition.panel.visible, "enqueue displays the first reward")
	_expect_equal(
		acquisition.label.text,
		potion.display_text,
		"the first notification displays item name and quantity"
	)
	_expect_equal(acquisition._queue.size(), 1, "later rewards remain queued")

	acquisition.display_timer.timeout.emit()
	_expect_true(acquisition.panel.visible, "the next queued reward is displayed")
	_expect_equal(
		acquisition.label.text,
		gold.display_text,
		"the notification advances in queue order"
	)
	_expect_true(acquisition._queue.is_empty(), "the queue drains in order")

	acquisition.display_timer.timeout.emit()
	_expect_true(
		not acquisition.panel.visible,
		"the final notification clears automatically on timeout"
	)
	_expect_true(
		acquisition._active_entry == null,
		"no reward remains active after the final timeout"
	)
	acquisition.free()

func _test_clear_resets_active_and_queued_entries() -> void:
	var acquisition := _new_notification()
	var rewards: Array[RewardEntry] = [
		RewardEntry.gold(5),
		RewardEntry.gold(10),
	]
	acquisition.enqueue(rewards)

	acquisition.clear()

	_expect_true(not acquisition.panel.visible, "clear hides the notification")
	_expect_true(acquisition._queue.is_empty(), "clear empties queued rewards")
	_expect_true(acquisition._active_entry == null, "clear removes the active reward")
	_expect_true(acquisition.display_timer.is_stopped(), "clear stops the timer")
	acquisition.free()

func _new_notification() -> AcquisitionNotification:
	var acquisition := (
		ACQUISITION_NOTIFICATION_SCENE.instantiate()
		as AcquisitionNotification
	)
	add_child(acquisition)
	return acquisition
