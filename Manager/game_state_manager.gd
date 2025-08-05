# MainGame.gd
extends Node

# This script will mainly work as a way to connect all the different component managers to each other
# Usage is close to a global signal bus
# Actual State control will be done by the campaign controller

@onready var campaign_controller = $CampaignController
@onready var map_generator = $MapManager
@onready var battle_manager = $BattleManager
@onready var gui = $Gui

func _ready():
	# Connect UI signals
	setup_ui_connections()
	
	#Sync all children to post ready state
	post_ready()

func setup_ui_connections():
	# Connect campaign controller signals to UI
	campaign_controller.state_changed.connect(_on_game_state_changed)
	campaign_controller.battle_started.connect(_on_battle_started)
	campaign_controller.campaign_completed.connect(_on_campaign_completed)

func _on_game_state_changed(new_state):
	print("Game state: " + str(new_state))
	# Update UI based on state

func _on_battle_started(node):
	print("Battle started at node: " + str(node.id))

func _on_campaign_completed():
	print("Campaign completed!")

func post_ready():
	
	for i in get_children():
		if i.has_method("post_ready"):
			i.post_ready()

	# wait till everything has called post_ready then
	# Start new campaign
	campaign_controller.start_new_campaign()
