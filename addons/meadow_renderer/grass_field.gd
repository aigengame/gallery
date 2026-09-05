class_name GrassField
extends Node3D
## Chunked geometric vegetation. Inject terrain and material from the caller.
## Samplers take (world_x: float, world_z: float); this node stays at identity.

const HALF_EXTENT := 64.0
const CHUNK_SIZE := 8.0
const CELLS_PER_CHUNK := 32
const FIELD_SEED := 741903
const VIEW_INTERVAL_MS := 150
const DETAIL_HYSTERESIS := 2.0
const PRESETS := {
	"low": {"density": 0.50, "near": 12.0, "mid": 27.0, "far": 48.0},
	"medium": {"density": 0.75, "near": 17.0, "mid": 35.0, "far": 59.0},
	"high": {"density": 1.0, "near": 23.0, "mid": 44.0, "far": 72.0},
}

var _height_sampler: Callable
var _coverage_sampler: Callable
var _material: ShaderMaterial
var _meshes: Array[ArrayMesh] = []
var _chunks: Array[Dictionary] = []
var _quality := "high"
var _wind_enabled := true
var _last_view_ms := -1000
var _camera_position := Vector3(0.0, 4.0, 22.0)
var _total_clumps := 0
var _visible_clumps := 0
var _visible_chunks := 0
var _visible_triangles := 0
var _build_time_ms := 0


func configure(height_sampler: Callable, coverage_sampler: Callable, shader: Shader) -> void:
	_height_sampler = height_sampler
	_coverage_sampler = coverage_sampler
	_material = ShaderMaterial.new()
	_material.shader = shader
	_material.set_shader_parameter("wind_enabled", _wind_enabled)
	_apply_material_quality()


func build() -> void:
	if not _height_sampler.is_valid() or not _coverage_sampler.is_valid() or _material == null:
		push_error("GrassField.configure() needs two valid samplers and a shader before build().")
		return
	var started := Time.get_ticks_msec()
	for chunk in _chunks:
		(chunk["node"] as MultiMeshInstance3D).free()
	_chunks.clear()
	_total_clumps = 0
	if _meshes.is_empty():
		_meshes.append(_make_clump(6, 4))
		_meshes.append(_make_clump(4, 2))
		_meshes.append(_make_clump(3, 2))
	var chunk_count := int(HALF_EXTENT * 2.0 / CHUNK_SIZE)
	for z_index in range(chunk_count):
		for x_index in range(chunk_count):
			_build_chunk(x_index, z_index)
	_build_time_ms = Time.get_ticks_msec() - started
	_last_view_ms = -1000
	update_view(_camera_position)


func update_view(camera_position: Vector3) -> void:
	_camera_position = camera_position
	var now := Time.get_ticks_msec()
	if now - _last_view_ms < VIEW_INTERVAL_MS:
		return
	_last_view_ms = now
	var preset: Dictionary = PRESETS[_quality]
	_visible_clumps = 0
	_visible_chunks = 0
	_visible_triangles = 0
	for chunk in _chunks:
		var center: Vector2 = chunk["center"]
		var distance := center.distance_to(Vector2(camera_position.x, camera_position.z))
		var node: MultiMeshInstance3D = chunk["node"]
		var shown := distance < float(preset["far"]) + CHUNK_SIZE * 0.71
		node.visible = shown
		if not shown:
			continue
		var near_distance := float(preset["near"])
		var mid_distance := float(preset["mid"])
		var detail := _detail_for_distance(distance, int(chunk["detail"]), near_distance, mid_distance)
		# Keep density continuous across geometry switches. Prefixes remain uniform.
		var density := float(preset["density"]) * lerpf(1.0, 0.64, smoothstep(near_distance - 5.0, mid_distance, distance))
		density *= lerpf(1.0, 0.45, smoothstep(mid_distance, float(preset["far"]), distance))
		var count := maxi(1, int(float(chunk["count"]) * density))
		if detail != int(chunk["detail"]):
			node.multimesh.mesh = _meshes[detail]
			node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if detail == 0 else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			chunk["detail"] = detail
		node.multimesh.visible_instance_count = count
		_visible_clumps += count
		_visible_chunks += 1
		_visible_triangles += count * [42, 12, 9][detail]


func _detail_for_distance(distance: float, previous: int, near_distance: float, mid_distance: float) -> int:
	var requested := 0 if distance < near_distance else (1 if distance < mid_distance else 2)
	if previous < 0 or previous == requested:
		return requested
	if requested > previous:
		var boundary := near_distance if previous == 0 else mid_distance
		return requested if distance > boundary + DETAIL_HYSTERESIS else previous
	var boundary := mid_distance if previous == 2 else near_distance
	return requested if distance < boundary - DETAIL_HYSTERESIS else previous


func set_quality(level: String) -> void:
	if not PRESETS.has(level):
		return
	_quality = level
	_apply_material_quality()
	_last_view_ms = -1000
	update_view(_camera_position)


func set_wind_enabled(enabled: bool) -> void:
	_wind_enabled = enabled
	if _material != null:
		_material.set_shader_parameter("wind_enabled", enabled)


func get_stats() -> Dictionary:
	return {
		"quality": _quality,
		"wind_enabled": _wind_enabled,
		"chunks": _chunks.size(),
		"total_clumps": _total_clumps,
		"visible_chunks": _visible_chunks,
		"visible_clumps": _visible_clumps,
		"visible_triangles": _visible_triangles,
		"build_time_ms": _build_time_ms,
	}


func _apply_material_quality() -> void:
	if _material != null:
		var far_distance := float(PRESETS[_quality]["far"])
		_material.set_shader_parameter("fade_start", far_distance - 10.0)
		_material.set_shader_parameter("fade_end", far_distance)
		_material.set_shader_parameter("near_distance", float(PRESETS[_quality]["near"]))
		_material.set_shader_parameter("mid_distance", float(PRESETS[_quality]["mid"]))


func _build_chunk(x_index: int, z_index: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = FIELD_SEED + x_index * 7919 + z_index * 104729
	var origin := Vector3(-HALF_EXTENT + x_index * CHUNK_SIZE, 0.0, -HALF_EXTENT + z_index * CHUNK_SIZE)
	var placements: Array[Transform3D] = []
	var custom: Array[Color] = []
	var min_height := INF
	var max_height := -INF
	var cell_size := CHUNK_SIZE / float(CELLS_PER_CHUNK)
	for z_cell in range(CELLS_PER_CHUNK):
		for x_cell in range(CELLS_PER_CHUNK):
			var x := origin.x + (x_cell + rng.randf()) * cell_size
			var z := origin.z + (z_cell + rng.randf()) * cell_size
			var coverage := clampf(float(_coverage_sampler.call(x, z)), 0.0, 1.0)
			if rng.randf() >= coverage:
				continue
			var y := float(_height_sampler.call(x, z)) - 0.025
			var height := rng.randf_range(0.64, 0.94)
			var width := rng.randf_range(0.80, 1.18)
			var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(width, height, width))
			placements.append(Transform3D(basis, Vector3(x - origin.x, y, z - origin.z)))
			custom.append(Color(rng.randf(), rng.randf(), rng.randf(), rng.randf()))
			min_height = minf(min_height, y)
			max_height = maxf(max_height, y + height)
	if placements.is_empty():
		return
	# Shuffle once so every visible-instance prefix covers the whole chunk.
	for index in range(placements.size() - 1, 0, -1):
		var swap := rng.randi_range(0, index)
		var old_transform := placements[index]
		placements[index] = placements[swap]
		placements[swap] = old_transform
		var old_custom := custom[index]
		custom[index] = custom[swap]
		custom[swap] = old_custom
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_custom_data = true
	multi.mesh = _meshes[0]
	multi.instance_count = placements.size()
	# Includes blade lean, width, wind, and optional local displacement.
	multi.custom_aabb = AABB(Vector3(-1.4, min_height - 0.2, -1.4), Vector3(CHUNK_SIZE + 2.8, max_height - min_height + 1.4, CHUNK_SIZE + 2.8))
	for index in range(placements.size()):
		multi.set_instance_transform(index, placements[index])
		multi.set_instance_custom_data(index, custom[index])
	var node := MultiMeshInstance3D.new()
	node.name = "Grass_%02d_%02d" % [x_index, z_index]
	node.position = origin
	node.multimesh = multi
	node.material_override = _material
	node.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	add_child(node)
	_chunks.append({"node": node, "center": Vector2(origin.x + CHUNK_SIZE * 0.5, origin.z + CHUNK_SIZE * 0.5), "count": placements.size(), "detail": -1})
	_total_clumps += placements.size()


func _make_clump(blade_count: int, segments: int) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var blade_ids := PackedVector2Array()
	var indices := PackedInt32Array()
	var rng := RandomNumberGenerator.new()
	rng.seed = FIELD_SEED
	for blade in range(blade_count):
		var angle := float(blade) * 2.399963 + rng.randf_range(-0.35, 0.35)
		var outward := Vector3(sin(angle), 0.0, cos(angle))
		var right := Vector3(cos(angle), 0.0, -sin(angle))
		var root := outward * rng.randf_range(0.025, 0.11)
		var height := rng.randf_range(0.55, 0.75)
		var lean := rng.randf_range(0.16, 0.34)
		var blade_width := rng.randf_range(0.025, 0.043)
		var curl := rng.randf_range(-0.08, 0.11)
		var first := vertices.size()
		for step in range(segments):
			var t := float(step) / float(segments)
			var center := root + Vector3.UP * height * t + outward * lean * t * t + right * curl * t * t * t
			var half_width := blade_width * (1.0 - t) * (0.66 + 0.65 * sin(t * PI)) * 0.5
			var tangent := Vector3.UP * height + outward * (2.0 * lean * t) + right * (3.0 * curl * t * t)
			var normal := right.cross(tangent).normalized()
			vertices.append(center - right * half_width)
			vertices.append(center + right * half_width)
			normals.append(normal)
			normals.append(normal)
			uvs.append(Vector2(0.0, t))
			uvs.append(Vector2(1.0, t))
			blade_ids.append(Vector2(float(blade), 0.0))
			blade_ids.append(Vector2(float(blade), 0.0))
			if step > 0:
				var lower := first + (step - 1) * 2
				# Godot front faces use clockwise winding, opposite the normal cross.
				indices.append_array(PackedInt32Array([lower, lower + 2, lower + 1, lower + 1, lower + 2, lower + 3]))
		var tip_index := vertices.size()
		vertices.append(root + Vector3.UP * height + outward * lean + right * curl)
		normals.append(right.cross(Vector3.UP * height + outward * 2.0 * lean + right * 3.0 * curl).normalized())
		uvs.append(Vector2(0.5, 1.0))
		blade_ids.append(Vector2(float(blade), 0.0))
		indices.append_array(PackedInt32Array([tip_index - 2, tip_index, tip_index - 1]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_TEX_UV2] = blade_ids
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
