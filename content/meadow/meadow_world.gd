extends Node3D

const Terrain = preload("res://content/meadow/terrain.gd")
const Explorer = preload("res://content/explorer/explorer.gd")
const Progress = preload("res://systems/exploration/visit_progress.gd")
const GDA_CALLABLE = ["get_snapshot", "get_viewpoints", "get_frame_metrics"]

signal state_changed
signal pause_requested
var started: bool = false
var paused: bool = false
var visited_count: int = 0
var nearest_viewpoint: int = -1
var visit_distance: float = 1000.0
var quality: String = "high"
var wind_enabled: bool = true
var explorer: Node3D
var grass: Node3D
var _progress = Progress.new()
var _ambience: AudioStreamPlayer
var _markers: Array[MeshInstance3D] = []
var _metric_frames: Array[float] = []
var _gpu_frames: Array[float] = []
var _ui_tick: float = 0.0
var _last_frame_us: int = 0
var _viewpoints: Array = [
	{"name_en":"Whispering Hollow", "name_zh":"听风谷", "description_en":"Crouch among the blades. Watch their roots hold as the wind passes.", "description_zh":"俯身看草叶，风吹过时，草根依然稳稳扎在土地里。", "position":Vector2(-18,5)},
	{"name_en":"Sunlit Ridge", "name_zh":"晴光岭", "description_en":"Look back across the meadow. Notice how detail becomes color in the distance.", "description_zh":"回望整片草地，近处的草叶渐渐融成远方的绿色。", "position":Vector2(10,-22)},
	{"name_en":"The Quiet Stone", "name_zh":"静石坡", "description_en":"Stay a while. There is no hurry here.", "description_zh":"在这里停留片刻，不必急着出发。", "position":Vector2(34,8)}
]

func _ready() -> void:
	_create_environment()
	var ground := MeshInstance3D.new()
	ground.name = "Terrain"
	ground.mesh = Terrain.create_mesh()
	var ground_material := ShaderMaterial.new()
	ground_material.shader = load("res://content/meadow/ground.gdshader")
	ground.material_override = ground_material
	add_child(ground)
	_create_landmarks()
	explorer = Explorer.new()
	explorer.name = "Explorer"
	explorer.height_sampler = Terrain.height_at
	add_child(explorer)
	explorer.reset_to(Vector3(0,0,26))
	explorer.interaction_requested.connect(visit_nearest)
	_progress.changed.connect(_on_progress_changed)
	if ResourceLoader.exists("res://addons/meadow_renderer/grass_field.gd"):
		grass = load("res://addons/meadow_renderer/grass_field.gd").new()
		grass.name = "Grass"
		add_child(grass)
		grass.configure(Terrain.height_at, Terrain.coverage_at, load("res://content/meadow/grass.gdshader"))
		grass.build()
	_ambience = AudioStreamPlayer.new()
	_ambience.name = "Ambience"
	add_child(_ambience)
	if ResourceLoader.exists("res://content/audio/meadow_ambience.wav"):
		_ambience.stream = load("res://content/audio/meadow_ambience.wav")
		_ambience.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		_ambience.volume_db = -9
		_ambience.play()
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)

func _create_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("548aba")
	sky_material.sky_horizon_color = Color("c8dcdf")
	sky_material.ground_bottom_color = Color("465538")
	sky_material.ground_horizon_color = Color("b4c8c1")
	sky_material.sky_curve = 0.18
	sky.sky_material = sky_material
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("bbd3d1")
	environment.ambient_light_energy = 0.48
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_light_color = Color("c5d9c4")
	environment.fog_density = 0.0018
	environment.fog_sky_affect = 0.16
	world_environment.environment = environment
	add_child(world_environment)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-32, -35, 0)
	sun.light_color = Color("fff1cb")
	sun.light_energy = 1.5
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 36
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	# Give nearby blades more room before the coarser cascade, and blend its edge.
	sun.directional_shadow_split_1 = 0.2
	sun.directional_shadow_blend_splits = true
	add_child(sun)

func _create_landmarks() -> void:
	var stone_material := StandardMaterial3D.new()
	stone_material.albedo_color = Color("778071")
	stone_material.roughness = 0.92
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color("776044")
	wood.roughness = 0.95
	for i in range(_viewpoints.size()):
		var p: Vector2 = _viewpoints[i].position
		var marker := MeshInstance3D.new()
		marker.name = "Viewpoint%d" % i
		var post := CylinderMesh.new()
		post.top_radius = 0.065
		post.bottom_radius = 0.075
		post.height = 1.2
		post.radial_segments = 7
		marker.mesh = post
		marker.material_override = wood
		marker.position = Vector3(p.x, Terrain.height_at(p.x,p.y)+0.6,p.y)
		add_child(marker)
		_markers.append(marker)
		var plaque := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.62,0.24,0.09)
		plaque.mesh = box
		plaque.material_override = wood
		plaque.position = marker.position + Vector3(0,0.43,0)
		add_child(plaque)
		var number := Label3D.new()
		number.text = "0%d" % (i+1)
		number.font_size = 48
		number.pixel_size = 0.003
		number.modulate = Color("eee5be")
		number.position = plaque.position + Vector3(0,0,0.05)
		add_child(number)
	var rng := RandomNumberGenerator.new()
	rng.seed = 8104
	for i in range(38):
		var x := rng.randf_range(-58,58)
		var z := rng.randf_range(-58,40)
		if Terrain.path_distance(x,z) < 2.8:
			continue
		var rock := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 1.0
		sphere.height = 2.0
		sphere.radial_segments = 7
		sphere.rings = 3
		rock.mesh = sphere
		rock.material_override = stone_material
		rock.position = Vector3(x,Terrain.height_at(x,z)-0.1,z)
		rock.scale = Vector3(rng.randf_range(0.3,1.4),rng.randf_range(0.22,0.75),rng.randf_range(0.4,1.1))
		rock.rotation.y = rng.randf()*TAU
		add_child(rock)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		pause_requested.emit()

func _process(delta: float) -> void:
	if grass and explorer:
		grass.update_view(explorer.global_position)
	var now := Time.get_ticks_usec()
	_metric_frames.append(float(now - _last_frame_us) / 1000.0 if _last_frame_us > 0 else delta * 1000.0)
	_last_frame_us = now
	_gpu_frames.append(RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid()))
	if _metric_frames.size() > 600:
		_metric_frames.pop_front()
		_gpu_frames.pop_front()
	_ui_tick += delta
	if _ui_tick > 0.15 and explorer:
		_ui_tick = 0
		var closest := -1
		var distance := 1000.0
		for i in range(_viewpoints.size()):
			var p: Vector2 = _viewpoints[i].position
			var d := Vector2(explorer.position.x, explorer.position.z).distance_to(p)
			if d < distance:
				distance = d
				closest = i
		nearest_viewpoint = closest
		visit_distance = distance
		state_changed.emit()

func begin_exploration() -> void:
	started = true
	set_paused(false)

func set_paused(value: bool) -> void:
	paused = value
	if explorer:
		explorer.enabled = started and not paused
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if started and not paused else Input.MOUSE_MODE_VISIBLE
	state_changed.emit()

func restart_exploration() -> void:
	_progress.reset()
	explorer.reset_to(Vector3(0,0,26))
	begin_exploration()

func visit_nearest() -> void:
	if started and not paused and visit_distance <= 3.0:
		_progress.visit(nearest_viewpoint)

func _on_progress_changed() -> void:
	visited_count = _progress.visited.size()
	state_changed.emit()

func set_quality(level: String) -> void:
	if level not in ["low","medium","high"]:
		return
	quality = level
	if grass:
		grass.set_quality(level)
	state_changed.emit()

func set_wind_enabled(value: bool) -> void:
	wind_enabled = value
	if grass:
		grass.set_wind_enabled(value)
	state_changed.emit()

func set_volume(value: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(clampf(value, 0.0, 1.0)))

func get_viewpoints() -> Array:
	var result: Array = []
	for item in _viewpoints:
		var copy: Dictionary = item.duplicate()
		copy.erase("position")
		result.append(copy)
	return result

func get_snapshot() -> Dictionary:
	return {"started":started,"paused":paused,"visited_count":visited_count,"visited":_progress.visited,"nearest_viewpoint":nearest_viewpoint,"visit_distance":visit_distance,"quality":quality,"wind_enabled":wind_enabled,"position":explorer.position,"distance_walked":explorer.distance_walked,"grass":grass.get_stats() if grass else {},"window_size":get_window().size,"render_size":get_viewport().get_texture().get_size()}

func get_frame_metrics() -> Dictionary:
	var frames := _metric_frames.duplicate()
	var gpu := _gpu_frames.duplicate()
	frames.sort()
	gpu.sort()
	if frames.is_empty():
		return {}
	return {"samples":frames.size(),"frame_p50_ms":frames[int((frames.size()-1)*0.5)],"frame_p95_ms":frames[int((frames.size()-1)*0.95)],"gpu_p50_ms":gpu[int((gpu.size()-1)*0.5)],"gpu_p95_ms":gpu[int((gpu.size()-1)*0.95)],"gpu_timer_available":gpu.back()>0.0}
