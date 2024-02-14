class_name Character

extends CharacterBody3D

@export var character_name:String

# track the character's health
@export var max_health:int
@onready var current_health = max_health

# track the character's armor
@export var armor:int

# track how much the character can move on their turns
@export var max_movement:float
@onready var remaining_movement = max_movement

# tracks which party the character belongs to
@export var party:String

@onready var combat_tracker = $"../../CombatTracker"

# track own id, managed by combat_tracker
var id:float

signal baton_pass(character:Character)
signal turn_ended

# onready, connect signals from combat_tracker to self, disable process by default
# also add self to relevant groups based on party affiliation
func _ready():
	set_process(false) # process should only be enabled when it is the character's turn
	
	combat_tracker.your_turn.connect(_on_turn_start)
	
	add_to_group("Combatants")
	add_to_group(party)

func _on_turn_start(character_id:int):
	# ignore if not self
	if character_id != id:
		return
	
	# else, take turn
	take_turn()

# take turn
# player control and enemy ai goes here depending on implementation
func take_turn():
	# take turn
	turn_ended.emit()
	return

# Take damage
func take_damage(damage:int):
	if damage < armor:
		return
	else:
		current_health -= damage - armor
	
	if current_health <= 0:
		die()

# Die function to be implemented by inherited classes
func die():
	pass
