extends Node
## Rendered regression fixture: the real meadow, with wind and camera fixed.
## Start with gda daemon start --windowed --scene res://tests/shadow_regression.tscn.

@export_enum("low", "medium", "high") var quality: String = "high":
	set(value):
		quality = value
		if is_node_ready():
			$World.set_quality(value)


func _ready() -> void:
	$World.begin_exploration()
	$World.set_wind_enabled(false)
	$World.set_volume(0.0)
	$World.set_quality(quality)
	$World.explorer.reset_to(Vector3(8.0, 0.0, 26.0))
	$World.explorer.yaw = 0.0
	$World.explorer.pitch = -0.22
	$World.explorer.enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
