extends CanvasLayer

@onready var dialogue_canvas = $"../DialogueCanvas"
@onready var character_select = $CharacterSelect
@onready var item_list = $CharacterSelect/ItemList

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

# track selected character when player is prompted
var selected_character
signal character_selected

var baton_passing:Character

signal your_turn(character_id:int)
signal sequence_ended(sequence_type:String)

# Called when the node enters the scene tree for the first time.
func _ready():
	# initialize combatants
	initialize_combatants()
	print("COMBATANTS!: ", combatants)
	
	# connect dialogue controlled combat signal
	dialogue_canvas.combat_start.connect(_start_combat)
	item_list.item_selected.connect(_on_player_character_selected)
	self.sequence_ended.connect(_on_sequence_ended)
	
	# connect all baton pass signals to _on_baton_pass
	for party in combatants:
		for i in len(combatants[party]):
			combatants[party][i]["Node"].baton_pass.connect(_on_baton_pass)
			combatants[party][i]["Node"].death.connect(_on_character_death)

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
		for turn in round:
			# every party gets 1 turn per loop, so with all loops all characters get to act
			for party in party_order:
				# each party designates a combatant to act
				var combatant = await choose_combatant(party)
				if combatant != null: # null if no combatant in party can act
					await combatant["Node"].take_turn() # combatant takes turn
					
					# after turn, if a character triggered a baton pass
					if baton_passing != null:
						baton_pass(baton_passing)
		
		# round over, while loop triggers
		sequence_ended.emit("Acted this round?")

# should return null if all of that party's members have acted
func choose_combatant(party_name:String, baton_pass=false):
	# determine if tracking baton pass or round
	var acted = "Acted this baton pass?" if baton_pass else "Acted this round?"
	
	if party_name == "PCs":
		# prompt player to pick which character they want to go
		# provide list of characters who haven't acted yet
		# selection determines who goes
		item_list.clear()
		for character in combatants["PCs"]:
			print(character["Name"], " ", character["Node"].downed)
			if not character[acted] and character["Node"].downed == 0:
				item_list.add_item(character["Name"],character["Sprite"])
		
		# return null if no characters to select
		if item_list.item_count == 0:
			return null
		
		character_select.visible = true
		print("awaiting character_selected")
		await character_selected
		character_select.visible = false
		for i in len(combatants["PCs"]):
			if combatants["PCs"][i]["Name"] == selected_character["Name"]:
				combatants["PCs"][i][acted] = true
		return selected_character
	
	else: # arbitrarily pick NPC
		for character in combatants[party_name]:
			if not character[acted]:
				character[acted] = true
				return character
	
	return null # if all characters in party have acted

# returns the length of the largest party in combatants
func get_biggest_party_size():
	var size = 0
	for party in combatants:
		print("party is ", combatants[party])
		size = max(num_active_characters(party), size)
	return size

# get the number of active characters in a party
func num_active_characters(party:String):
	var sum = 0
	for i in len(combatants[party]):
		if combatants[party][i]["Node"].downed == 0 and not combatants[party][i]["Acted this round?"]:
			sum += 1
	return sum

func _on_player_character_selected(index:int):
	var char_name = $CharacterSelect/ItemList.get_item_text(index)
	for character in combatants["PCs"]:
		if character["Name"] == char_name:
			selected_character = character
			print("emitting character_selected")
			character_selected.emit()
			return

# on round ended, reset everyone's acted this round
func _on_sequence_ended(acted:String):
	for party in combatants:
		for i in len(combatants[party]):
			combatants[party][i][acted] = false

# on baton pass initiated, wait until end of turn and then initiate baton pass sequence
func _on_baton_pass(character:Character):
	baton_passing = character

# start a baton pass
func baton_pass(character:Character):
	# set acted this baton pass to true
	set_combatant_attribute("Acted this baton pass?", true)
	
	# for every other combatant in PCs, prompt player for next and take their turn
	for i in len(combatants[character.party])-1:
		var combatant = await choose_combatant(character.party, true)
		if combatant != null: # null if no combatant in party can act
			await combatant.get("Node").take_turn() # combatant takes turn
	
	# all out attack?
	# end baton pass
	sequence_ended.emit("Acted this baton pass?")

# set attribute of a combatant
func set_combatant_attribute(attribute, value):
	for party in combatants:
		for i in len(combatants[party]):
			if combatants[party][i].has(attribute):
				combatants[party][i][attribute] = value

# called when a character dies
func _on_character_death(character:Character):
	# find character
	for party in combatants:
		for i in len(combatants[party]):
			if combatants[party][i]["Node"] == character:
				# remove and return
				combatants[party].remove_at(i)
				return
