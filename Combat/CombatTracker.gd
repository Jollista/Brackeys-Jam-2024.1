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
	"Monsters":[
		{
			"Name":"Goblin",
			"Acted this round?": false,
			"Acted this baton pass?": false
		}
	]}

signal your_turn(character_id:int)
signal round_ended

# Called when the node enters the scene tree for the first time.
func _ready():
	# initialize combatants
	initialize_combatants()
	print("COMBATANTS!: ", combatants)
	
	# connect dialogue controlled combat signal
	dialogue_canvas.combat_start.connect(_start_combat)

# Initialize array of combatants
func initialize_combatants():
	# get array of all characters in scene
	var character_nodes = get_characters()
	
	# add all participating characters to combatants
	combatants = {}
	for combatant in character_nodes:
		combatants[combatant.party].append({
				"Name": combatant.character_name, 
				"Node": combatant,
				"Acted this round?": false, 
				"Acted this baton pass?": false
			})

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

# start combat loop
func _start_combat(starting_party:String):
	# determine the order the parties act in
	var party_order = combatants.keys() # get all parties in an array
	party_order.erase(starting_party) # erase starting_party
	party_order.push_front(starting_party) # and push it to the front
	
	# while there are still enemies
	while combatants.has("Monsters") and len(combatants["Monsters"]) > 0:
		# loop through combatants
		var round = get_biggest_party_size()
		for turn in round:
			# every party gets 1 turn per loop, so with all loops all characters get to act
			for party in party_order:
				# each party designates a combatant to act
				var combatant = choose_combatant(party)
				if combatant != null: # null if no combatant in party can act
					combatant["Node"].take_turn() # combatant takes turn
					await combatant["Node"].turn_ended # wait for their turn to end before progressing
		
		# round over, while loop triggers
		round_ended.emit()

# should return null if all of that party's members have acted
func choose_combatant(party_name:String):
	if party_name == "PCs":
		# prompt player to pick which character they want to go
		# provide list of characters who haven't acted yet
		# selection determines who goes
		return
	
	else: # arbitrarily pick NPC
		for character in combatants[party_name]:
			if not character["Acted this round?"]:
				character["Acted this round?"] = true
				return character
	
	return null # if all characters in party have acted

# returns the length of the largest party in combatants
func get_biggest_party_size():
	pass
