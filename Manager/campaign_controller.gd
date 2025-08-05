extends Node

# Campaign Controller
# Manages the flow between map exploration and battle execution

var map_generator: Node2D
var battle_manager: Node2D  
var gui : Control

enum GameState {
	MAP_EXPLORATION,
	BATTLE_PREPARATION,
	BATTLE_ACTIVE,
	BATTLE_COMPLETE,
	CAMPAIGN_COMPLETE
}

var current_state: GameState = GameState.MAP_EXPLORATION
var current_battle_node: MapNode

signal state_changed(new_state: GameState)
signal battle_started(node: MapNode)
signal battle_completed(node: MapNode, victory: bool)
signal campaign_completed()

func post_ready():
	map_generator = get_parent().map_generator
	battle_manager = get_parent().battle_manager
	gui = get_parent().gui
	
	connect_systems()
	
	for i in self.get_children():
		if i.has_method("post_ready"):
			i.post_ready()

func connect_systems():
	"""Connect all system signals and references"""

	# Connect battle manager signals if available
	if battle_manager:
		if battle_manager.has_signal("preperation_ended"):
			battle_manager.preperation_ended.connect(_end_prep_phase)
		if battle_manager.has_signal("battle_ended"):
			battle_manager.battle_ended.connect(_on_battle_ended)
		
	
	print("Campaign controller systems connected")

func change_state(new_state: GameState):
	"""Change the current game state"""
	var old_state = current_state
	current_state = new_state
	
	print("State changed: %s -> %s" % [GameState.keys()[old_state], GameState.keys()[new_state]])
	state_changed.emit(new_state)
	
	# Handle state-specific logic
	match new_state:
		GameState.MAP_EXPLORATION:
			enable_map_interaction()
		GameState.BATTLE_PREPARATION:
			prepare_battle()
		GameState.BATTLE_ACTIVE:
			start_battle_sequence()
		GameState.BATTLE_COMPLETE:
			handle_battle_completion()
		GameState.CAMPAIGN_COMPLETE:
			handle_campaign_completion()

# =============================================================================
# MAP EXPLORATION STATE
# =============================================================================

func enable_map_interaction():
	"""Enable map interaction and disable battle systems"""
	if map_generator:
		map_generator.set_process_input(true)
		map_generator.show()
	
	if battle_manager:
		battle_manager.set_process(false)
		battle_manager.hide()
	
	#print("Map exploration enabled. Available nodes: %d" % map_generator.get_available_nodes().size())

func _on_map_node_selected(node: MapNode):
	"""Handle when player selects a map node"""
	if current_state != GameState.MAP_EXPLORATION:
		return
	
	if not node.available or node.completed:
		print("Node %d is not available" % node.id)
		return
	
	current_battle_node = node
	change_state(GameState.BATTLE_PREPARATION)

# =============================================================================
# BATTLE PREPARATION STATE
# =============================================================================

func prepare_battle():
	"""Prepare for battle at the selected node"""
	if not current_battle_node:
		push_error("No battle node selected")
		return
	
	print("Preparing battle at node %d (Stage: %d, Difficulty: %s)" % 
		  [current_battle_node.id, current_battle_node.stage, current_battle_node.difficulty])
	
	# Setup battle environment
	setup_battle_environment()
	

func setup_battle_environment():
	"""Setup the battle environment for the current node"""
	battle_manager.show()
	battle_manager.set_process(true)
	
	# Clear any existing units
	battle_manager.clear_battlefield()
	
	# Setup battle-specific parameters based on node
	battle_manager.setup_battle({
		"stage": current_battle_node.stage,
		"difficulty": current_battle_node.difficulty,
		"node_type": current_battle_node.node_type
	})
	
	gui.deployment_mode = false

	# Hide map during battle
	map_generator.hide()
	map_generator.set_process_input(false)

func _end_prep_phase():
	# Create breif countdown to 
	await get_tree().create_timer(1.0).timeout
	change_state(GameState.BATTLE_ACTIVE)
	
	# TODO: Talk to GUI to disable inventory,
	gui.deployment_mode = false

# =============================================================================
# BATTLE ACTIVE STATE
# =============================================================================

func start_battle_sequence():
	"""Start the actual battle"""
	print("Battle started at node %d" % current_battle_node.id)
	battle_started.emit(current_battle_node)
	
	# Start battle systems
	if battle_manager and battle_manager.has_method("start_battle"):
		battle_manager.start_battle()
	
	# The battle will run until _on_battle_ended is called

func _on_battle_ended(victory: bool):
	"""Handle battle completion from battle manager"""
	print("Battle ended. Victory: %s" % victory)
	
	# Store battle result
	current_battle_node.completed = victory
	
	if victory:
		change_state(GameState.BATTLE_COMPLETE)
	else:
		# Handle defeat - could retry, return to map, etc.
		handle_battle_defeat()

func handle_battle_defeat():
	"""Handle what happens when player loses a battle"""
	print("Battle defeat - implementing retry logic")
	
	# For now, allow retry
	change_state(GameState.BATTLE_PREPARATION)
	
	# Alternative: return to map
	# change_state(GameState.MAP_EXPLORATION)

# =============================================================================
# BATTLE COMPLETE STATE
# =============================================================================

func handle_battle_completion():
	"""Handle successful battle completion"""
	if not current_battle_node:
		return
	
	print("Battle completed successfully at node %d" % current_battle_node.id)
	
	# Mark node as completed
	map_generator.complete_current_battle()
	
	# Give rewards, show victory screen, etc.
	award_battle_rewards()
	
	# Check if campaign is complete
	if current_battle_node.node_type == "end":
		change_state(GameState.CAMPAIGN_COMPLETE)
	else:
		# Brief pause then return to map
		await get_tree().create_timer(2.0).timeout
		change_state(GameState.MAP_EXPLORATION)
	
	battle_completed.emit(current_battle_node, true)
	current_battle_node = null

func award_battle_rewards():
	"""Award rewards based on battle performance"""
	var rewards = calculate_battle_rewards()
	print("Battle rewards: %s" % str(rewards))
	
	# Implement your reward system here
	# e.g., add gold, experience, new units, etc.

func calculate_battle_rewards() -> Dictionary:
	"""Calculate rewards based on node difficulty and performance"""
	var base_rewards = {
		"gold": 100,
		"experience": 50
	}
	
	# Scale by difficulty
	match current_battle_node.difficulty:
		"easy":
			base_rewards.gold *= 1
		"medium":
			base_rewards.gold *= 1.5
		"hard":
			base_rewards.gold *= 2
	
	# Scale by stage
	base_rewards.gold += current_battle_node.stage * 10
	base_rewards.experience += current_battle_node.stage * 5
	
	return base_rewards

# =============================================================================
# CAMPAIGN COMPLETE STATE
# =============================================================================

func handle_campaign_completion():
	"""Handle campaign completion"""
	print("=== CAMPAIGN COMPLETED ===")
	campaign_completed.emit()
	
	# Show victory screen, unlock new campaigns, etc.
	show_campaign_victory()

func show_campaign_victory():
	"""Show campaign victory screen"""
	print("Showing campaign victory screen")
	# Implement your victory screen UI here

# =============================================================================
# PUBLIC INTERFACE
# =============================================================================

func start_new_campaign():
	"""Start a new campaign"""
	print("Starting new campaign")
	
	# Reset systems
	current_battle_node = null
	
	# Generate new map
	if map_generator:
		map_generator.regenerate_map()
	
	change_state(GameState.MAP_EXPLORATION)

func save_campaign_progress() -> Dictionary:
	"""Save current campaign progress"""
	var save_data = {
		"current_state": current_state,
		"current_battle_node_id": current_battle_node.id if current_battle_node else -1
	}
	
	# Add map state
	if map_generator:
		save_data.map_state = map_generator.save_map_state()
	
	return save_data

func load_campaign_progress(save_data: Dictionary):
	"""Load campaign progress from save data"""
	# Load map state first
	if map_generator and save_data.has("map_state"):
		map_generator.load_map_state(save_data.map_state)
	
	# Restore current state
	var saved_state = save_data.get("current_state", GameState.MAP_EXPLORATION)
	change_state(saved_state)
	
	# Restore current battle node if applicable
	var battle_node_id = save_data.get("current_battle_node_id", -1)
	if battle_node_id >= 0:
		for node in map_generator.nodes:
			if node.id == battle_node_id:
				current_battle_node = node
				break

func get_campaign_progress() -> Dictionary:
	"""Get current campaign progress for UI display"""
	var progress = {
		"state": GameState.keys()[current_state],
		"current_node": current_battle_node.id if current_battle_node else -1
	}
	
	if map_generator:
		progress.merge(map_generator.get_map_progress())
	
	return progress

# =============================================================================
# DEBUG INTERFACE
# =============================================================================

func force_battle_victory():
	"""Debug: Force current battle to end in victory"""
	if current_state == GameState.BATTLE_ACTIVE:
		_on_battle_ended(true)

func force_battle_defeat():
	"""Debug: Force current battle to end in defeat"""
	if current_state == GameState.BATTLE_ACTIVE:
		_on_battle_ended(false)

func skip_to_end():
	"""Debug: Skip to campaign end"""
	if map_generator and map_generator.end_node:
		current_battle_node = map_generator.end_node
		change_state(GameState.CAMPAIGN_COMPLETE)
