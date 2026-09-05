extends RefCounted
## The authored landscape and its single shared height/coverage contract.

const ROUTE: Array[Vector2] = [Vector2(0, 26), Vector2(-18, 5), Vector2(10, -22), Vector2(34, 8)]

static func height_at(x: float, z: float) -> float:
	var broad := sin(x * 0.046 + 0.5) * cos(z * 0.039) * 3.1
	var roll := sin(z * 0.09 + x * 0.038) * 1.25 + cos(x * 0.113 - z * 0.035) * 0.55
	var rim := smoothstep(49.0, 115.0, Vector2(x, z).length()) * (8.0 + 4.0 * sin(x * 0.039 + z * 0.024))
	return broad + roll + rim

static func path_distance(x: float, z: float) -> float:
	var point := Vector2(x, z)
	var result := 1000.0
	for i in range(ROUTE.size() - 1):
		var a := ROUTE[i]
		var b := ROUTE[i + 1]
		var t := clampf((point - a).dot(b - a) / (b - a).length_squared(), 0.0, 1.0)
		result = minf(result, point.distance_to(a.lerp(b, t)))
	return result

static func coverage_at(x: float, z: float) -> float:
	var path := smoothstep(0.75, 1.7, path_distance(x, z))
	var variation := 0.79 + 0.14 * sin(x * 0.33 + sin(z * 0.21)) * cos(z * 0.29)
	return path * variation

static func create_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	const STEPS := 160
	const EXTENT := 120.0
	for z in range(STEPS + 1):
		for x in range(STEPS + 1):
			var px := -EXTENT + float(x) / STEPS * EXTENT * 2.0
			var pz := -EXTENT + float(z) / STEPS * EXTENT * 2.0
			var dx := height_at(px + 0.1, pz) - height_at(px - 0.1, pz)
			var dz := height_at(px, pz + 0.1) - height_at(px, pz - 0.1)
			surface.set_normal(Vector3(-dx, 0.2, -dz).normalized())
			surface.set_uv(Vector2(px, pz) * 0.08)
			var path := smoothstep(0.4, 1.65, path_distance(px, pz))
			surface.set_color(Color(path, 0, 0, 1))
			surface.add_vertex(Vector3(px, height_at(px, pz), pz))
	for z in range(STEPS):
		for x in range(STEPS):
			var a := z * (STEPS + 1) + x
			for index in [a, a + 1, a + STEPS + 1, a + 1, a + STEPS + 2, a + STEPS + 1]:
				surface.add_index(index)
	return surface.commit()

