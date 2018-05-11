extends Node2D

const Constants = preload("res://scripts/Constants.gd")

## dimensions of terrain hexes
## it is important that these are both multiples of 4
const TERRAIN_WIDTH  = 64*4 #256
const TERRAIN_HEIGHT = 74*4 #296

const UNITGRID_WIDTH = 16*4
const UNITGRID_HEIGHT = 18*4
const UNITGRID_OFFSET = Vector2(0,-18*2) #so that grid cells are centered in terrain hexes

onready var terrain = $TerrainTiles
onready var unit_grid = $UnitGrid

func _ready():
	terrain.cell_size = Vector2(TERRAIN_WIDTH, TERRAIN_HEIGHT*3/4)
	unit_grid.cell_size = Vector2(UNITGRID_WIDTH, UNITGRID_HEIGHT*3/4)
	
	terrain.z_as_relative = false
	terrain.z_index = Constants.TERRAIN_ZLAYER

## returns the bounding rectangle in world coords
func get_bounding_rect():
	var cell_bounds = terrain.get_used_rect()
	var cell_size = terrain.cell_size
	var cell_to_pixel = Transform2D(Vector2(cell_size.x, 0), Vector2(0, cell_size.y), Vector2())
	return Rect2(cell_to_pixel * cell_bounds.position, cell_to_pixel * cell_bounds.size)

func get_terrain_at(world_pos):
	var cell_pos = terrain.world_to_map(world_pos)
	return get_terrain_at_cell(cell_pos)

func get_terrain_at_cell(cell_pos):
	var tile_id = terrain.get_cellv(cell_pos)
	return TerrainTypes.get_tile_terrain_info(tile_id)

func point_on_map(world_pos):
	var cell_pos = terrain.world_to_map(world_pos)
	var tile_id = terrain.get_cellv(cell_pos)
	return tile_id >= 0

func get_grid_cell(world_pos):
	var cell_pos = unit_grid.world_to_map(world_pos - UNITGRID_OFFSET)
	return cell_pos

func get_grid_pos(cell_pos):
	## grid cells have their origin at their upper-left corner.
	## but we want to produce a position at the cell center
	return unit_grid.map_to_world(cell_pos) + unit_grid.cell_size/2 + UNITGRID_OFFSET

func add_object(object):
	assert point_on_map(object.position)
	
	#snap to grid
	var cell_pos = get_grid_cell(object.position)
	object.position = get_grid_pos(cell_pos)
	
	add_child(object)