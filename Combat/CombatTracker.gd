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

var selected_character
signal character_selected

signal your_turn(character_id:int)
signal round_ended

# Called when the node enters the scene tree for the first time.
func _ready():
	# initialize combatants
	initialize_combatants()
	print("COMBATANTS!: ", combatants)
	
	# connect dialogue controlled combat signal
	dialogue_canvas.combat_start.connect(_start_combat)
	$CharacterSelect/ItemList.item_selected.connect(_on_player_character_selected)
	self.round_ended.connect(_on_round_ended)

# Initialize array of combatants
func initialize_combatants():
	# get array of all characters in scene
	var character_nodes = get_characters()
	
	# add all participating characters to combatants
	combatants = {}
	for combatant in character_nodes:
		print("party: ", combatant.party)
		
		# initialize party
		if not combatants.has(combatant.party):
			combatants[combatant.party] = []
		
		# add combatant to party
		combatants[combatant.party].append({
				"Name": combatant.character_name, 
				"Node": combatant,
				"Sprite": combatant.battle_sprite,
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
	print("_start_combat called")
	
	# determine the order the parties act in
	var party_order = combatants.keys() # get all parties in an array
	party_order.erase(starting_party) # erase starting_party
	party_order.push_front(starting_party) # and push it to the front
	
	# while there are still enemies
	while combatants.has("Monsters") and len(combatants["Monsters"]) > 0:
		# loop through combatants
		var round = get_biggest_party_size()
		print("round = ", round)
		for turn in round:
			print("turn = ", round)
			# every party gets 1 turn per loop, so with all loops all characters get to act
			for party in party_order:
				print("party = ", party)
				# each party designates a combatant to act
				var combatant = await choose_combatant(party)
				print("Combatant chosen: ", combatant)
				if combatant != null: # null if no combatant in party can act
					print("take turn")
					await combatant["Node"].take_turn() # combatant takes turn
					print("awaiting")
					# await combatant["Node"].turn_ended # wait for their turn to end before progressing
		
		# round over, while loop triggers
		round_ended.emit()

# should return null if all of that party's members have acted
func choose_combatant(party_name:String):
	if party_name == "PCs":
		# prompt player to pick which character they want to go
		# provide list of characters who haven't acted yet
		# selection determines who goes
		$CharacterSelect/ItemList.clear()
		for character in combatants["PCs"]:
			if not character["Acted this round?"]:
				$CharacterSelect/ItemList.add_item(character["Name"],character["Sprite"],not character["Acted this round?"])
			
		$CharacterSelect.visible = true
		print("awaiting character_selected")
		await character_selected
		$CharacterSelect.visible = false
		for i in len(combatants["PCs"]):
			if combatants["PCs"][i]["Name"] == selected_character["Name"]:
				combatants["PCs"][i]["Acted this round?"] = true
		return selected_character
	
	else: # arbitrarily pick NPC
		for character in combatants[party_name]:
			if not character["Acted this round?"]:
				character["Acted this round?"] = true
				return character
	
	return null # if all characters in party have acted

# returns the length of the largest party in combatants
func get_biggest_party_size():
	var size = 0
	for party in combatants:
		print("party is ", combatants[party])
		size = max(len(combatants[party]), size)
	return size

func _on_player_character_selected(index:int):
	var char_name = $CharacterSelect/ItemList.get_item_text(index)
	for character in combatants["PCs"]:
		if character["Name"] == char_name:
			selected_character = character
			print("emitting character_selected")
			character_selected.emit()
			return

# on round ended, reset everyone's acted this round
func _on_round_ended():
	for party in combatants:
		for i in len(combatants[party]):
			combatants[party][i]["Acted this round?"] = false
