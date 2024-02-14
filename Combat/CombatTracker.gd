extends CanvasLayer

@onready var dialogue_canvas = $"../DialogueCanvas"

# this is an example of the format, this is not actually used
# combatants are added dynamically at the start of each combat
var combatants = {
	"PCs":[
		{
			"Name":"Warrior",
			"Acted this round?": false,
			"Acted this baton pass?": false
		},
		{
			"Name":"Thief",
			"Acted this round?": false,
			"Acted this baton pass?": false
		},
	],
	"Goblins":[
		{
			"Name":"Goblin",
			"Acted this round?": false,
			"Acted this baton pass?": false
		}
	]}

var initiative = 0

signal your_turn(character_id:int)
signal round_ended

# Called when the node enters the scene tree for the first time.
func _ready():
	
	initialize_combatants()
	print("COMBATANTS!: ", combatants)

# Initialize array of combatants
func initialize_combatants():
	# get array of all characters in scene
	var character_nodes = get_characters()
	
	# add all participating characters to combatants
	var id = 0
	combatants = []
	for combatant in character_nodes:
		combatants[combatant.party].append({
				"Name":combatant.character_name, 
				"Acted this round?": false, 
				"Acted this baton pass?": false
			})
		
		# set each character's id to their index in combatants
		combatant.id = id
		id += 1

# Get an array of all the characters in the scene
# only checks nodes that are children of sibling nodes with "Party" in the name
# it's scuffed but it works
func get_characters():
	var characters = []
	var child_nodes = get_parent().get_children()
	for child in child_nodes:
		if "Party" in child.name:
			for character in child.get_children():
				if character is Character:
					characters.append(character)
	
	return characters

func _on_combat_start():
	pass
