extends Sprite

const Constants = preload("res://scripts/Constants.gd")

func _ready():
	z_as_relative = false
	z_index = Constants.HUD_ZLAYER

func _unhandled_input(event):
	var world_map = get_parent().map_view
	if !world_map: return
	
	if event is InputEventMouseMotion:
		var mouse_pos = world_map.get_global_mouse_position()
		if world_map.point_on_map(mouse_pos):
			position = world_map.unit_grid.snap_to_grid(mouse_pos)

