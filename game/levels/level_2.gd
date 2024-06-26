extends Level

@export var card_resources: Array[CardData]

var spawn_location: Vector2
var current_deck_length: int = 2
var current_cards: Array[Node]

@onready var engineer: Engineer = %Engineer
@onready var decision_tree: ConstructedDecisionTree = %ConstructedDecisionTree
@onready var card_spawn_location: Marker2D = %CardSpawnLocation
@onready var submit_button: Button = %SubmitButton
@onready var base_card_object = preload("res://game/objects/object_card.tscn")


func _ready():
	super._ready()
	spawn_location = card_spawn_location.position

	await LevelTransition.fade_from_black()
	await get_tree().create_timer(0.5).timeout
	await engineer.show_normal_dialogue(level_dialogue, "rensselaer_opening_lines")
	engineer.engineer_coming_in()

func _process(_delta):
	if Input.is_action_just_released("skip_level"):
		_end_level()

#region Game logic
func _connect_signals():
	engineer.tree_created.connect(_create_first_decision_tree)
	engineer.deck_introduced.connect(_show_first_deck)
	engineer.new_tree_construction.connect(_reconstruction)
	engineer.level_finished.connect(_end_level)
	decision_tree.tree_not_filled.connect(_missing_rectangles)
	decision_tree.tree_filled_correctly.connect(_tree_fill_success)
	decision_tree.tree_filled_incorrectly.connect(_tree_fill_failure)

func _show_deck():
	if decision_tree.current_root >= decision_tree.tree_roots.size():
		_final_dialogue()
		return
	await get_tree().create_timer(1.0).timeout
	for i in current_deck_length:
		var current_card: BaseCard = base_card_object.instantiate()
		current_card.card_properties = card_resources[i]
		current_cards.push_back(current_card)
		current_card.name = "ObjectCard%s" %i
		add_child(current_card)
		current_card.global_position = Vector2(spawn_location.x + (i * 40), spawn_location.y)
		current_card.initialPos = current_card.global_position
	for card: Node2D in current_cards:
		card.visible = true
		await get_tree().create_timer(1.0).timeout
	submit_button.visible = true

func _clean_deck():
	for card in current_cards:
		card.queue_free()
		await get_tree().create_timer(1.0).timeout
	current_cards.clear()

func _on_submit_button_pressed():
	decision_tree.check_correctness()

func _missing_rectangles():
	engineer.show_normal_dialogue(level_dialogue, "tree_not_filled")

func _tree_fill_failure():
	engineer.show_normal_dialogue(level_dialogue, "tree_filled_incorrectly")

func _tree_fill_success():
	if current_deck_length == 2:
		engineer.show_normal_dialogue(level_dialogue, "tree_filled_correctly_first_time")
	else:
		engineer.show_normal_dialogue(level_dialogue, "tree_filled_correctly")

func _reconstruction():
	submit_button.visible = false
	await decision_tree.remove_current_tree()
	await _clean_deck()
	_change_deck_length(true)
	await decision_tree.expose_new_tree()
	await _show_deck()

func _change_deck_length(increase: bool):
	if increase:
		current_deck_length += 1
	else:
		current_deck_length -= 1

#endregion

#region Level story
func _show_first_deck():
	await _show_deck()
	await get_tree().create_timer(0.5).timeout
	engineer.show_normal_dialogue(level_dialogue, "cards_introduced")

func _create_first_decision_tree():
	decision_tree.expose_new_tree()
	if (decision_tree.current_root == 1):
		await engineer.show_normal_dialogue(level_dialogue, "introduction_to_decision_trees")

func _final_dialogue():
	await engineer.engineer_coming_in()
	await engineer.show_normal_dialogue(level_dialogue, "all_trees_finished")

#endregion
