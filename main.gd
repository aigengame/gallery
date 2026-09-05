extends Node
## Composition root: content never depends on UI.

func _ready() -> void:
	var world := $World
	if ResourceLoader.exists("res://ui/overlay.gd"):
		var overlay = load("res://ui/overlay.gd").new()
		overlay.name = "Overlay"
		add_child(overlay)
		overlay.setup(world)
		world.pause_requested.connect(overlay.handle_escape)
