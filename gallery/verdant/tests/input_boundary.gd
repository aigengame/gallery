extends SceneTree
## Discriminates viewport-delivered key events from global polled input state.

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_W
	event.physical_keycode = KEY_W
	event.pressed = true
	root.push_input(event)
	await process_frame
	var viewport_state := Input.is_physical_key_pressed(KEY_W)
	Input.parse_input_event(event)
	await process_frame
	var singleton_state := Input.is_physical_key_pressed(KEY_W)
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame
	print(JSON.stringify({"viewport_push_polled_w": viewport_state, "parse_input_polled_w": singleton_state}))
	assert(not viewport_state)
	assert(singleton_state)
	print("INPUT_BOUNDARY_COMPLETE")
	quit()
