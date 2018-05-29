extends "ContextBase.gd"

const Unit = preload("res://scripts/units/Unit.tscn")
const Crew = preload("res://scripts/units/Crew.gd")

onready var player_button = $HBoxContainer/PlayerButton
onready var faction_button = $HBoxContainer/FactionButton
onready var unit_model_button = $HBoxContainer/UnitModelButton

var players = {}
var factions = {}
var faction_ids = {}
var unit_models = {}

func _ready():
	EventDispatch.autoconnect(self)
	
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

## refresh player lists whenever a new game is started
func _game_start(game_state):
	player_button.clear()
	var all_players = game_state.players
	for i in range(all_players.size()):
		var player = all_players[i]
		player_button.add_item(player.display_name, i)
		players[i] = player

func _player_button_item_selected(i):
	var sel_faction = players[i].default_faction
	var faction_idx = faction_ids[sel_faction.faction_id]
	faction_button.select(faction_idx)
	_update_model_list(faction_idx)

func _faction_button_item_selected(i):
	_update_model_list(i)

func _update_model_list(i):
	unit_model_button.clear()
	for j in unit_models[i]:
		var unit_info = unit_models[i][j]
		unit_model_button.add_item(unit_info.desc.name, j)

func cell_input(world_map, cell_pos, event):
	if event.is_action_pressed("click_select"):
		var spawn_unit = Unit.instance()
		
		var player_idx = player_button.get_selected_id()
		var player = players[player_idx]
		
		var faction_idx = faction_button.get_selected_id()
		var faction = factions[faction_idx]
		
		var model_idx = unit_model_button.get_selected_id()
		var unit_info = unit_models[faction_idx][model_idx]

		spawn_unit.set_player_owner(player)
		spawn_unit.set_faction(faction)
		spawn_unit.set_unit_info(unit_info)
		
		if world_map.unit_can_place(spawn_unit, cell_pos):
			var crew = Crew.new(faction, unit_info.get_default_crew())
			spawn_unit.set_crew_info(crew)
			
			spawn_unit.cell_position = cell_pos
			world_map.add_unit(spawn_unit)
			
			if spawn_unit.has_facing():
				context_manager.activate("select_facing", { unit = spawn_unit, forced = true })
			
		else:
			spawn_unit.queue_free()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		context_manager.deactivate()

func _done_button_pressed():
	context_manager.deactivate()
