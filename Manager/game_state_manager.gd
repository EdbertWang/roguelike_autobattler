# MainGame.gd
extends Node

enum Total_State {
	MAIN_MENU,
	PLAYING,
	PAUSED,
	CLEANUP
}

@onready var campaign_controller = $CampaignController
@onready var map_generator = $MapGenerator
@onready var battle_manager = $BattleManager

func _ready():
	# Connect systems
	campaign_controller.map_generator = map_generator
	campaign_controller.battle_manager = battle_manager
	
	# Connect UI signals
	setup_ui_connections()
	
	# Start new campaign
	campaign_controller.start_new_campaign()
	
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
