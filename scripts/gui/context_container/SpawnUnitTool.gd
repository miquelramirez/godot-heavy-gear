extends "ContextBase.gd"

const Unit = preload("res://scripts/units/Unit.gd")
const Crew = preload("res://scripts/units/Crew.gd")

onready var player_button = $HBoxContainer/PlayerButton
onready var faction_button = $HBoxContainer/FactionButton
onready var unit_model_button = $HBoxContainer/UnitModelButton

var players = {}
var factions = {}
var faction_ids = {}
var unit_models = {}

func _ready():
	faction_button.clear()
	var all_faction_ids = GameData.all_faction_ids()
	for i in range(all_faction_ids.size()):
		var faction_id = all_faction_ids[i]
		var faction = GameData.get_faction(faction_id)
		faction_button.add_item(faction.name, i)
		factions[i] = faction
		faction_ids[faction_id] = i
		
		var models = {}
		for j in range(faction.unit_models.size()):
			var model_id = faction.unit_models[j]
			models[j] = GameData.get_unit_model(model_id)
		unit_models[i] = models
	
	_update_model_list(faction_button.get_selected_id())

func _setup():
	player_button.clear()
	var all_players = GameSession.all_players()
	for i in range(all_players.size()):
		var player = all_players[i]
		player_button.add_item(player.display_name, i)
		players[i] = player

	var active_player = GameState.current_game.get_active_player()
	if active_player:
		for i in players:
			if players[i] == active_player:
				player_button.select(i)
				_set_player_faction(i)

func _player_button_item_selected(i):
	_set_player_faction(i)

func _set_player_faction(i):
	var player = players[i]
	if GameState.current_game.has_player(player):
		var force_side = GameState.current_game.get_player_side(player)
		var faction_idx = faction_ids[force_side.default_faction.faction_id]
		faction_button.select(faction_idx)
		_faction_button_item_selected(faction_idx)

func _faction_button_item_selected(i):
	_update_model_list(i)

func _update_model_list(i):
	unit_model_button.clear()
	for j in unit_models[i]:
		var unit_info = unit_models[i][j]
		unit_model_button.add_item(unit_info.desc.name, j)

func cell_input(world_map, cell_pos, event):
	if event.is_action_pressed("click_select"):
		_spawn_unit(cell_pos)

func _spawn_unit(cell_pos):
	var current_game = GameState.current_game

	var spawn_unit = Unit.new()

	var player_idx = player_button.get_selected_id()
	var player = players[player_idx]

	var force_side = current_game.get_player_side(player)
	if !force_side: return
	
	var faction_idx = faction_button.get_selected_id()
	var faction = factions[faction_idx]
	
	var model_idx = unit_model_button.get_selected_id()
	var unit_model = unit_models[faction_idx][model_idx]

	spawn_unit.set_faction(faction)
	spawn_unit.set_unit_model(unit_model)
	if current_game.world_map.unit_can_place(spawn_unit, cell_pos):
		var crew = Crew.new(faction, unit_model.get_default_crew())
		spawn_unit.set_crew_info(crew)
		
		spawn_unit.set_side(force_side)
		
		spawn_unit.cell_position = cell_pos
		current_game.add_unit(spawn_unit)
		
		if spawn_unit.has_facing():
			var rotate_context = context_manager.activate("SelectFacing", { rotate_unit = spawn_unit })
			var rotate_info = yield(rotate_context, "context_return")
			if rotate_info:
				spawn_unit.set_facing(rotate_info.selected_dir)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		context_return()

func _done_button_pressed():
	context_return()
