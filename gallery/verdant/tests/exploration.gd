extends SceneTree

func _initialize() -> void:
	var Progress = load("res://systems/exploration/visit_progress.gd")
	var Terrain = load("res://content/meadow/terrain.gd")
	var progress = Progress.new()
	assert(not progress.visit(-1))
	assert(not progress.visit(3))
	assert(progress.visit(1))
	assert(not progress.visit(1))
	assert(not progress.is_complete())
	assert(progress.visit(0))
	assert(progress.visit(2))
	assert(progress.is_complete())
	progress.reset()
	assert(progress.visited.is_empty())
	assert(not progress.is_complete())
	for point in Terrain.ROUTE:
		assert(Terrain.path_distance(point.x, point.y) < 0.001)
		assert(Terrain.coverage_at(point.x, point.y) == 0)
		assert(is_finite(Terrain.height_at(point.x, point.y)))
	print("EXPLORATION_CHECK_COMPLETE")
	quit()
