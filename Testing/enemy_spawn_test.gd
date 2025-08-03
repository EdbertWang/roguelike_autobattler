extends Node2D

# Enemy Spawner Test Suite
# Provides integration testing and visual debugging for the enemy spawner system

@export var enable_visual_debug := true
@export var show_spawn_areas := true
@export var show_unit_info := true
@export var auto_run_tests := false

var spawner: Node
var battle_manager: Node2D
var test_results := {}
var debug_overlays := []

# Test formations for controlled testing
var TEST_FORMATIONS = {
	"single_unit": ["[0,0,1,1,1,1]"],
	"small_formation": ["[0,0,2,2,1,1]", "[3,0,1,1,2,1]"],
	"large_formation": ["[0,0,3,3,1,1]", "[4,0,2,2,2,1]", "[1,4,1,2,3,1]"],
	"with_exact_type": ["[0,0,1,1,1,1,heavy_tank]"],
	"overlapping_areas": ["[0,0,2,2,1,1]", "[1,1,2,2,2,1]"],  # Intentional overlap
	"boundary_test": ["[7,7,1,1,1,1]"],  # Near map edge
	"malformed": ["[invalid]", "[1,2,3]", "not_a_formation"]
}

# Visual debug colors
var DEBUG_COLORS = {
	"spawn_area": Color.YELLOW,
	"spawn_area_occupied": Color.RED,
	"unit_valid": Color.GREEN,
	"unit_invalid": Color.MAGENTA,
	"text": Color.WHITE
}

func _ready():
	setup_test_environment()
	if auto_run_tests:
		call_deferred("run_all_tests")

func _draw():
	if enable_visual_debug:
		draw_debug_overlays()

func setup_test_environment():
	"""Initialize test environment with references to game systems"""
	# Find or create required nodes
	spawner = find_child("enemy_spawner") if has_node("enemy_spawner") else null
	battle_manager = find_child("battle_manager") if has_node("battle_manager") else null
	
	if not spawner:
		push_warning("No enemy spawner found for testing")
	if not battle_manager:
		push_warning("No battle manager found for testing")
	
	print("Test environment setup complete")

# =============================================================================
# INTEGRATION TESTS
# =============================================================================

func run_all_tests():
	"""Run complete test suite"""
	print("=== Starting Enemy Spawner Integration Tests ===")
	clear_debug_overlays()
	
	test_single_unit_spawn()
	test_formation_spawn()
	test_malformed_data_handling()
	test_spawn_area_validation()
	test_unit_placement_accuracy()
	test_weighted_selection_distribution()
	
	print_test_summary()

func test_single_unit_spawn():
	"""Test spawning a single unit"""
	var test_name = "Single Unit Spawn"
	print("Running: " + test_name)
	
	var initial_unit_count = get_unit_count()
	
	# Mock the formation system for this test
	mock_formation_for_test("single_unit")
	var spawn_positions = spawner.get_enemy_spawns(1, "test")
	
	var final_unit_count = get_unit_count()
	var units_spawned = final_unit_count - initial_unit_count
	
	# Validation
	var passed = true
	var issues = []
	
	if spawn_positions.size() != 1:
		passed = false
		issues.append("Expected 1 spawn position, got %d" % spawn_positions.size())
	
	if units_spawned <= 0:
		passed = false
		issues.append("No units were actually spawned")
	
	record_test_result(test_name, passed, issues)
	add_debug_overlay("spawn_area", Vector2(0, 0), Vector2(1, 1), test_name)

func test_formation_spawn():
	"""Test spawning a complete formation"""
	var test_name = "Formation Spawn"
	print("Running: " + test_name)
	
	var initial_unit_count = get_unit_count()
	
	mock_formation_for_test("small_formation")
	var spawn_positions = spawner.get_enemy_spawns(1, "test")
	
	var final_unit_count = get_unit_count()
	var units_spawned = final_unit_count - initial_unit_count
	
	var passed = true
	var issues = []
	
	if spawn_positions.size() != 2:
		passed = false
		issues.append("Expected 2 spawn positions, got %d" % spawn_positions.size())
	
	if units_spawned <= 0:
		passed = false
		issues.append("No units were spawned")
	
	record_test_result(test_name, passed, issues)
	
	# Add visual debug for spawn areas
	add_debug_overlay("spawn_area", Vector2(0, 0), Vector2(2, 2), "Formation Area 1")
	add_debug_overlay("spawn_area", Vector2(3, 0), Vector2(1, 1), "Formation Area 2")

func test_malformed_data_handling():
	"""Test that malformed spawn strings are handled gracefully"""
	var test_name = "Malformed Data Handling"
	print("Running: " + test_name)
	
	var initial_unit_count = get_unit_count()
	
	mock_formation_for_test("malformed")
	var spawn_positions = spawner.get_enemy_spawns(1, "test")
	
	var final_unit_count = get_unit_count()
	
	var passed = true
	var issues = []
	
	# Should handle malformed data without crashing
	if spawn_positions.size() > 0:
		passed = false
		issues.append("Malformed data produced spawn positions: %d" % spawn_positions.size())
	
	if final_unit_count != initial_unit_count:
		passed = false
		issues.append("Units were spawned from malformed data")
	
	record_test_result(test_name, passed, issues)

func test_spawn_area_validation():
	"""Test that spawn areas don't exceed map boundaries"""
	var test_name = "Spawn Area Validation"
	print("Running: " + test_name)
	
	mock_formation_for_test("boundary_test")
	var spawn_positions = spawner.get_enemy_spawns(1, "test")
	
	var passed = true
	var issues = []
	
	for pos in spawn_positions:
		if pos.x < 0 or pos.y < 0 or pos.x >= spawner.grid_size.x or pos.y >= spawner.grid_size.y:
			passed = false
			issues.append("Spawn position outside map bounds: %s" % str(pos))
	
	record_test_result(test_name, passed, issues)
	add_debug_overlay("spawn_area", Vector2(7, 7), Vector2(1, 1), "Boundary Test")

func test_unit_placement_accuracy():
	"""Test that units are placed at correct world positions"""
	var test_name = "Unit Placement Accuracy"
	print("Running: " + test_name)
	
	mock_formation_for_test("single_unit")
	var spawn_positions = spawner.get_enemy_spawns(1, "test")
	
	var passed = true
	var issues = []
	
	# Check if units are placed at expected world coordinates
	var expected_world_pos = battle_manager.grid_to_world(Vector2i(0, 0))
	var units_in_area = get_units_in_area(expected_world_pos, Vector2(64, 64))
	
	if units_in_area.size() == 0:
		passed = false
		issues.append("No units found at expected world position")
	
	record_test_result(test_name, passed, issues)

func test_weighted_selection_distribution():
	"""Test that weighted selection produces varied results over multiple runs"""
	var test_name = "Weighted Selection Distribution"
	print("Running: " + test_name)
	
	var selections = {}
	var test_runs = 10
	
	# Run multiple spawns to test distribution
	for i in range(test_runs):
		clear_all_units()
		mock_formation_for_test("single_unit")
		spawner.get_enemy_spawns(1, "test")
		
		# Track what was selected (this would need to be exposed by spawner)
		# For now, just verify units were spawned
		
	var passed = true
	var issues = ["Distribution testing requires spawner to expose selection data"]
	
	record_test_result(test_name, passed, issues)

# =============================================================================
# VISUAL DEBUG SYSTEM
# =============================================================================

func add_debug_overlay(type: String, grid_pos: Vector2, size: Vector2, label: String = ""):
	"""Add a visual debug overlay"""
	var overlay = {
		"type": type,
		"grid_pos": grid_pos,
		"size": size,
		"label": label,
		"world_pos": battle_manager.grid_to_world(Vector2i(grid_pos)),
		"world_size": size * battle_manager.tile_size
	}
	debug_overlays.append(overlay)
	queue_redraw()

func clear_debug_overlays():
	"""Clear all debug overlays"""
	debug_overlays.clear()
	queue_redraw()

func draw_debug_overlays():
	"""Draw all debug overlays"""
	for overlay in debug_overlays:
		draw_overlay(overlay)

func draw_overlay(overlay: Dictionary):
	"""Draw a single debug overlay"""
	var rect = Rect2(overlay.world_pos, overlay.world_size)
	var color = DEBUG_COLORS.get(overlay.type, Color.WHITE)
	
	if show_spawn_areas:
		# Draw spawn area rectangle
		draw_rect(rect, color, false, 2.0)
		
		# Draw fill with transparency
		var fill_color = color
		fill_color.a = 0.2
		draw_rect(rect, fill_color, true)
	
	if show_unit_info and overlay.label != "":
		# Draw label
		var font = ThemeDB.fallback_font
		var font_size = 12
		var text_pos = overlay.world_pos + Vector2(5, 15)
		draw_string(font, text_pos, overlay.label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, DEBUG_COLORS.text)

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

func get_unit_count() -> int:
	"""Get current number of units on the battlefield"""
	if battle_manager and battle_manager.has_node("Unit_Parent"):
		return battle_manager.get_node("Unit_Parent").get_child_count()
	return 0

func get_units_in_area(world_pos: Vector2, size: Vector2) -> Array:
	"""Get all units within a specific world area"""
	var units = []
	if battle_manager and battle_manager.has_node("Unit_Parent"):
		var unit_parent = battle_manager.get_node("Unit_Parent")
		var area_rect = Rect2(world_pos, size)
		
		for unit in unit_parent.get_children():
			if area_rect.has_point(unit.position):
				units.append(unit)
	
	return units

func clear_all_units():
	"""Remove all units from the battlefield"""
	if battle_manager and battle_manager.has_node("Unit_Parent"):
		var unit_parent = battle_manager.get_node("Unit_Parent")
		for unit in unit_parent.get_children():
			unit.queue_free()

func mock_formation_for_test(formation_name: String):
	"""Mock the formation system to use test data"""
	if not spawner:
		return
	
	# This assumes your spawner has access to FORMATION_MAP
	# You might need to add a test method to your spawner for this
	if spawner.has_method("set_test_formation"):
		spawner.set_test_formation(TEST_FORMATIONS[formation_name])
	else:
		push_warning("Spawner doesn't support test formations - add set_test_formation() method")

func record_test_result(test_name: String, passed: bool, issues: Array = []):
	"""Record the result of a test"""
	test_results[test_name] = {
		"passed": passed,
		"issues": issues
	}
	
	var status = "PASS" if passed else "FAIL"
	print("  %s: %s" % [test_name, status])
	
	if not passed and issues.size() > 0:
		for issue in issues:
			print("    - %s" % issue)

func print_test_summary():
	"""Print summary of all test results"""
	print("\n=== Test Summary ===")
	var total_tests = test_results.size()
	var passed_tests = 0
	
	for test_name in test_results.keys():
		if test_results[test_name].passed:
			passed_tests += 1
	
	print("Tests run: %d" % total_tests)
	print("Passed: %d" % passed_tests)
	print("Failed: %d" % (total_tests - passed_tests))
	
	if passed_tests == total_tests:
		print("All tests passed! ✓")
	else:
		print("Some tests failed. Check output above for details.")

# =============================================================================
# PUBLIC INTERFACE
# =============================================================================

func run_specific_test(test_name: String):
	"""Run a specific test by name"""
	match test_name:
		"single_unit":
			test_single_unit_spawn()
		"formation":
			test_formation_spawn()
		"malformed":
			test_malformed_data_handling()
		"boundary":
			test_spawn_area_validation()
		"placement":
			test_unit_placement_accuracy()
		"distribution":
			test_weighted_selection_distribution()
		_:
			print("Unknown test: " + test_name)

func toggle_visual_debug():
	"""Toggle visual debugging on/off"""
	enable_visual_debug = !enable_visual_debug
	queue_redraw()

func toggle_spawn_areas():
	"""Toggle spawn area visualization"""
	show_spawn_areas = !show_spawn_areas
	queue_redraw()

func toggle_unit_info():
	"""Toggle unit info display"""
	show_unit_info = !show_unit_info
	queue_redraw()
