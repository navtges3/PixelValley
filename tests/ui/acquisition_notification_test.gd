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
	var notification := _new_notification()

	_expect_true(not notification.panel.visible, "the notification starts hidden")
	_expect_equal(
		notification.mouse_filter,
		Control.MOUSE_FILTER_IGNORE,
		"the notification root ignores mouse input"
	)
	_expect_equal(
		notification.panel.mouse_filter,
		Control.MOUSE_FILTER_IGNORE,
		"the visible notification panel ignores mouse input"
	)
	_expect_equal(
		notification.focus_mode,
		Control.FOCUS_NONE,
		"the notification cannot take menu focus"
	)
	_expect_true(
		notification.display_timer.one_shot,
		"the notification timer stops after each displayed entry"
	)
	notification.free()

func _test_notification_queue_displays_and_advances() -> void:
	var notification := _new_notification()
	var potion := RewardEntry.potion("lesser_healing_potion", 2)
	var gold := RewardEntry.gold(10)
	var rewards: Array[RewardEntry] = [potion, gold]

	notification.enqueue(rewards)

	_expect_true(notification.panel.visible, "enqueue displays the first reward")
	_expect_equal(
		notification.label.text,
		potion.display_text,
		"the first notification displays item name and quantity"
	)
	_expect_equal(notification._queue.size(), 1, "later rewards remain queued")

	notification.display_timer.timeout.emit()
	_expect_true(notification.panel.visible, "the next queued reward is displayed")
	_expect_equal(
		notification.label.text,
		gold.display_text,
		"the notification advances in queue order"
	)
	_expect_true(notification._queue.is_empty(), "the queue drains in order")

	notification.display_timer.timeout.emit()
	_expect_true(
		not notification.panel.visible,
		"the final notification clears automatically on timeout"
	)
	_expect_true(
		notification._active_entry == null,
		"no reward remains active after the final timeout"
	)
	notification.free()

func _test_clear_resets_active_and_queued_entries() -> void:
	var notification := _new_notification()
	var rewards: Array[RewardEntry] = [
		RewardEntry.gold(5),
		RewardEntry.gold(10),
	]
	notification.enqueue(rewards)

	notification.clear()

	_expect_true(not notification.panel.visible, "clear hides the notification")
	_expect_true(notification._queue.is_empty(), "clear empties queued rewards")
	_expect_true(notification._active_entry == null, "clear removes the active reward")
	_expect_true(notification.display_timer.is_stopped(), "clear stops the timer")
	notification.free()

func _new_notification() -> AcquisitionNotification:
	var notification := (
		ACQUISITION_NOTIFICATION_SCENE.instantiate()
		as AcquisitionNotification
	)
	add_child(notification)
	return notification
