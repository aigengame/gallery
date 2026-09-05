extends SceneTree


func _initialize() -> void:
	call_deferred("_verify")


func _verify() -> void:
	var field_script := load("res://addons/meadow_renderer/grass_field.gd")
	var field: Node3D = field_script.new()
	root.add_child(field)
	var material_shader := Shader.new()
	material_shader.code = "shader_type spatial; void fragment() { ALBEDO = vec3(0.2, 0.4, 0.1); }"
	field.configure(_height, _coverage, material_shader)
	field.build()
	var high: Dictionary = field.get_stats()
	assert(high["chunks"] == 256)
	assert(high["total_clumps"] > 200000)
	var meshes: Array = field.get("_meshes")
	var mesh_triangles: Array[int] = []
	for mesh: ArrayMesh in meshes:
		var arrays := mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		mesh_triangles.append(indices.size() / 3)
		for index in range(vertices.size()):
			assert(is_equal_approx(normals[index].length(), 1.0))
			assert(uvs[index].y >= 0.0 and uvs[index].y <= 1.0)
			if uvs[index].y == 0.0:
				assert(vertices[index].y == 0.0)
		for index in range(0, indices.size(), 3):
			var a := vertices[indices[index]]
			var b := vertices[indices[index + 1]]
			var c := vertices[indices[index + 2]]
			var face := (b - a).cross(c - a)
			assert(face.length_squared() > 0.00000001)
			assert(face.dot(normals[indices[index]]) < 0.0)
	assert(mesh_triangles == [42, 12, 9])
	# Mesh detail retains the same seeded blades; only intermediate rows differ.
	var near_vertices: PackedVector3Array = meshes[0].surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var mid_vertices: PackedVector3Array = meshes[1].surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var far_vertices: PackedVector3Array = meshes[2].surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	for blade in range(4):
		assert(near_vertices[blade * 9] == mid_vertices[blade * 5])
		assert(near_vertices[blade * 9 + 4] == mid_vertices[blade * 5 + 2])
		assert(near_vertices[blade * 9 + 8] == mid_vertices[blade * 5 + 4])
	for index in range(far_vertices.size()):
		assert(far_vertices[index] == mid_vertices[index])
	assert(field._detail_for_distance(24.0, 0, 23.0, 44.0) == 0)
	assert(field._detail_for_distance(26.0, 0, 23.0, 44.0) == 1)
	assert(field._detail_for_distance(22.0, 1, 23.0, 44.0) == 1)
	assert(field._detail_for_distance(20.0, 1, 23.0, 44.0) == 0)
	assert(field._detail_for_distance(45.0, 1, 23.0, 44.0) == 1)
	assert(field._detail_for_distance(47.0, 1, 23.0, 44.0) == 2)
	assert(field._detail_for_distance(43.0, 2, 23.0, 44.0) == 2)
	assert(field._detail_for_distance(41.0, 2, 23.0, 44.0) == 1)
	field.set_quality("medium")
	var medium: Dictionary = field.get_stats()
	field.set_quality("low")
	var low: Dictionary = field.get_stats()
	assert(high["visible_triangles"] > medium["visible_triangles"])
	assert(medium["visible_triangles"] > low["visible_triangles"])
	field.set_wind_enabled(false)
	assert(field.get_stats()["wind_enabled"] == false)
	field.set_quality("high")
	field.build()
	assert(field.get_stats()["total_clumps"] == high["total_clumps"])
	assert(field.get_stats()["visible_triangles"] == high["visible_triangles"])
	field.update_view(Vector3(1000, 3, 1000))
	field.set_quality("medium")
	assert(field.get_stats()["visible_clumps"] == 0)
	print(JSON.stringify({"high": high, "medium": medium, "low": low, "mesh_triangles": mesh_triangles, "geometry_winding_roots": "pass", "lod_shared_blades": "pass", "lod_hysteresis": "pass", "deterministic_counts": "pass", "instance_transform_readback": "requires_rendered_backend", "quality_and_culling": "pass"}))
	field.free()
	print("GRASS_VERIFICATION_COMPLETE")
	quit(0)


func _height(x: float, z: float) -> float:
	return sin(x * 0.06) * 2.0 + cos(z * 0.08)


func _coverage(x: float, _z: float) -> float:
	return 0.0 if absf(x) < 1.25 else 1.0
