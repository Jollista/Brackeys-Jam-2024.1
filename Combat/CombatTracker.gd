extends CanvasLayer

# this is an example of the format, this is not actually used
# combatants are added dynamically at the start of each combat
var combatants = [
	{
		"Name":"Warrior",
		"Affiliation":"Party",
		"Acted this round?":false,
		"Acted this baton pass?": false
	}
]
var initiative = 0

signal your_turn(character_id:int)
signal round_ended

# Called when the node enters the scene tree for the first time.
func _ready():
	var character_nodes = get_characters()
	# add all participating characters to combatants
	# set each character's id to their index in combatants
	pass

# Get an array of all the characters in the scene
func get_characters():
	var characters = []
	var child_nodes = get_parent().get_children()
	for child in child_nodes:
		if child is Character:
			characters.append(child)
	
	return characters

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
