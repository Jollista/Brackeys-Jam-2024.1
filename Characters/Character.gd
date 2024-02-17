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

@export var battle_sprite:Texture2D

@onready var combat_tracker = $"../../CombatTracker"

# track skill proficiencies in a dictionary
@export var skills = {}

# true if in baton pass sequence, used to prevent single character baton pass initiation while already in a baton pass
var baton_passing = false

signal baton_pass(character:Character)
signal turn_ended
signal death(character:Character)

# CONDITIONS
# At the top of each round, each condition should tick down until it gets to 0 at which point the condition ends.
# if the condition is at -1, it only ends if ended manually (such as by the help action)
# DOWNED - typically happens when a PC is reduced to 0 hp. Can be roused by an ally taking the help action 
# at which point it ends immediately. otherwise, a downed creature passes its turn. Ends at start of round 
# when no longer at 0 hp.
var downed = 0
# SLOWED - creature moves at half speed and rolls damage at disadvantage
var slowed = 0
# INVISIBLE - creature cannot be seen or targeted by enemies
var invisible = 0

# onready, connect signals from combat_tracker to self, disable process by default
# also add self to relevant groups based on party affiliation
func _ready():
	#set_process(false) # process should only be enabled when it is the character's turn
	
	combat_tracker.sequence_ended.connect(_on_round_end)

# take turn
# player control and enemy ai goes here depending on implementation
func take_turn():
	# take turn
	print("emitting turn_ended signal")
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
	death.emit(self)
	queue_free()

# return the rank of a given skill tracked in skills
func get_skill(skill_name:String):
	# if not proficient with skill, default it to 1
	if not skills.has(skill_name):
		skills[skill_name] = 1
	
	# return skill proficiency rank
	return skills[skill_name]

# logic for end of the round
func _on_round_end(tag:String):
	# ignore if not round end
	if tag != "Acted this round?":
		return
	
	print("round over")
	
	# reset movement
	remaining_movement = max_movement
	# count down conditions
	condition_tick()

# tick down condition timers, and end conditions if satisfied
func condition_tick():
	if downed > 0:
		downed -= 1
	if slowed > 0:
		slowed -= 1
	if invisible > 0:
		invisible -= 1
