extends RefCounted
## Owns a route's visit state independently of its terrain or presentation.

signal changed
var total: int = 3
var visited: Array[int] = []

func visit(index: int) -> bool:
	if index < 0 or index >= total or visited.has(index):
		return false
	visited.append(index)
	changed.emit()
	return true

func reset() -> void:
	visited.clear()
	changed.emit()

func is_complete() -> bool:
	return visited.size() == total
