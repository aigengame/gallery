extends Node3D
## Terrain-following free look; input is disabled while application menus are open.

signal interaction_requested
var enabled: bool = false
var height_sampler: Callable
var camera: Camera3D
var yaw: float = 0.0
var pitch: float = -0.08
var eye_height: float = 1.72
var distance_walked: float = 0.0
var _jump_height: float = 0.0
var _jump_velocity: float = 0.0
var _step_clock: float = 0.0
var _steps: AudioStreamPlayer

func _ready() -> void:
	camera = Camera3D.new()
	camera.name = "Camera"
	camera.fov = 72
	camera.near = 0.04
	camera.far = 320
	add_child(camera)
	camera.current = true
	_steps = AudioStreamPlayer.new()
	_steps.volume_db = -20
	if ResourceLoader.exists("res://content/audio/grass_footstep.wav"):
		_steps.stream = load("res://content/audio/grass_footstep.wav")
	add_child(_steps)

func reset_to(point: Vector3) -> void:
	position = point
	yaw = 0.32
	pitch = -0.08
	_jump_height = 0.0
	_jump_velocity = 0.0
	distance_walked = 0.0
	_update_camera()

func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * 0.0022
		pitch = clampf(pitch - event.relative.y * 0.0022, -1.4, 1.3)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_E:
			interaction_requested.emit()
		elif event.physical_keycode == KEY_SPACE and _jump_height <= 0.001:
			_jump_velocity = 4.2

func _physics_process(delta: float) -> void:
	if enabled:
		var move := Input.get_vector("walk_left", "walk_right", "walk_forward", "walk_back")
		var crouch := Input.is_action_pressed("crouch")
		var speed := 2.0 if crouch else (7.0 if Input.is_action_pressed("sprint") else 3.8)
		var velocity := Vector3(move.normalized().x, 0, move.normalized().y).rotated(Vector3.UP, yaw) * speed
		var old := position
		position += velocity * delta
		position.x = clampf(position.x, -55, 55)
		position.z = clampf(position.z, -55, 55)
		distance_walked += Vector2(position.x - old.x, position.z - old.z).length()
		eye_height = lerpf(eye_height, 0.48 if crouch else 1.72, minf(delta*10.0, 1.0))
		if _jump_velocity != 0.0 or _jump_height > 0:
			_jump_velocity -= 11.0 * delta
			_jump_height = maxf(0, _jump_height + _jump_velocity * delta)
			if _jump_height == 0:
				_jump_velocity = 0
		if move.length() > 0.1 and _jump_height == 0:
			_step_clock += delta * speed
			if _step_clock > 2.3:
				_step_clock = 0
				if _steps.stream:
					_steps.pitch_scale = randf_range(0.91, 1.07)
					_steps.play()
	if height_sampler.is_valid():
		position.y = float(height_sampler.call(position.x, position.z))
	_update_camera()

func _update_camera() -> void:
	rotation.y = yaw
	if camera:
		camera.position.y = eye_height + _jump_height
		camera.rotation.x = pitch
