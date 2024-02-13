extends CanvasLayer

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
	# add all participating characters to combatants
	# set each character's id to their index in combatants
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
