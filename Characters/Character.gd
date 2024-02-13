class_name Character

extends CharacterBody3D

@export var character_name:String

# track the character's health
@export var max_health:int
@onready var current_health = max_health

# track the character's armor
@export var armor:int

# track how much the character can move on their turns
@export var max_movement:int
@onready var remaining_movement = max_movement

var id:int

signal baton_pass(character:Character)
signal end_turn(character:Character)

# onready, connect signals from combat_tracker to self, disable process by default
func _ready():
	set_process(false) # process should only be enabled when it is the character's turn
	# combat_tracker.your_turn.connect(_on_turn_start)
	pass

func _on_turn_start(character_id:int):
	# ignore if not self
	if character_id != id:
		return
	
	# else, take turn
	

# 
func take_turn():
	pass

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
