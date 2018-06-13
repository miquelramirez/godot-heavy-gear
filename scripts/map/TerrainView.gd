extends Node2D

const Constants = preload("res://scripts/Constants.gd")
const HexUtils = preload("res://scripts/helpers/HexUtils.gd")
const ElevationOverlay = preload("res://scripts/terrain/ElevationOverlay.tscn")

var world_coords setget set_coordinate_system

onready var terrain_tilemap = $TileMap

func _ready():
	terrain_tilemap.z_as_relative = false
	terrain_tilemap.z_index = Constants.TERRAIN_ZLAYER
	terrain_tilemap.cell_half_offset = TileMap.HALF_OFFSET_X

func set_coordinate_system(coords):
	world_coords = coords

	var terrain_grid = world_coords.terrain_grid
	terrain_tilemap.cell_size = terrain_grid.cell_spacing
	terrain_tilemap.position = terrain_grid.position - terrain_grid.cell_spacing/2 #center tiles on grid points

func load_terrain(map_loader):
	modulate = map_loader.global_lighting

	## setup terran tiles
	terrain_tilemap.tile_set = map_loader.terrain_tileset
	for offset_cell in map_loader.terrain_data:
		var terrain_data = map_loader.terrain_data[offset_cell]
		terrain_tilemap.set_cellv(offset_cell, terrain_data.tile_idx)

	## setup roads
	for road in map_loader.roads:
		add_child(road)

	## setup clouds overlay
	var clouds_data = map_loader.clouds_overlay

	var clouds = clouds_data.type.new()
	clouds.texture = clouds_data.texture
	clouds.transform = clouds_data.transform
	clouds.drift_velocity = clouds_data.drift_velocity
	clouds.set_display_rect(map_loader.display_rect)
	add_child(clouds)

func load_elevation(map_loader):
	var terrain_grid = world_coords.terrain_grid
	var unit_grid = world_coords.unit_grid

	var display_rect = map_loader.display_rect
	var elevation = map_loader.terrain_elevation

	var ul = unit_grid.get_offset_cell(display_rect.position)
	var lr = unit_grid.get_offset_cell(display_rect.end + unit_grid.cell_size)
	var elevation_overlay_cells = HexUtils.get_rect(Rect2(ul, lr - ul))
	for offset_grid_cell in elevation_overlay_cells:
		var grid_cell = unit_grid.offset_to_axial(offset_grid_cell)
		var elevation_info = elevation.get_info(grid_cell)
		
		var terrain_cell = world_coords.get_terrain_cell(grid_cell)
		var offset_cell = terrain_grid.axial_to_offset(terrain_cell)

		var overlay_color = (
			map_loader.terrain_data[offset_cell].overlay_color
			if map_loader.terrain_data.has(offset_cell)
			else null
		)

		var overlay = ElevationOverlay.instance()
		overlay.set_color(overlay_color)
		overlay.setup(elevation_info)
		add_child(overlay)