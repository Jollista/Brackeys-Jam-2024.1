extends CanvasLayer

signal flag(flag_name:String)

# path to default dialogue file json (should never play)
@export var dialogue_file = ""

const FAST = 0.010
const NORM = 0.025
const SLOW = 0.1

# text speed
@export var text_speed = NORM

# reference to components
@onready var dialogue_box = $ScrollContainer/DialogueBox
@onready var text_container = $ScrollContainer/GridContainer
@onready var voice = $Voice
@onready var sound = $Sound
@onready var timer = $Delay
@onready var scrollbar = $ScrollContainer.get_v_scroll_bar()
var chat

signal dialogue_ended

# array of lines
var dialogue = []
# index of current line
var current_dialogue = 0
# is dialogue active
var active = false
# is current line finished displaying
var finished = true
# skip line if blackout_screen()
var skipping = false

var selection
var choice_items = []
var choices_list

@onready var combat_tracker = $"../CombatTracker"

signal choice_selected
signal combat_start(starting_party:String)

func _ready():
	# set invisible by default
	print("DialogueCanvas ready")
	print("Timer, delay: ", timer.name, " (", timer, ")")
	visible = false
	
	# set up automatic scrolling
	scrollbar.changed.connect(autoscroll)

# automatically scroll on scrollbar changed
func autoscroll():
	scrollbar.value = scrollbar.max_value

func _process(_delta):
	# allows player to skip dialogue animation
	if skipping or active and (Input.is_action_just_pressed("interact")):
		if finished: # go to next line
			next_line()
			skipping = false
		else: # skip dialogue animation and stop sounds
			chat.visible_characters = len(chat.text)
			voice.stop()

func start_dialogue(filepath:String=""):
	print("dialogue filepath : ", filepath)
	# if given filepath, load that instead of default
	if filepath != "" and filepath != null:
		dialogue_file = filepath
		print("dialogue_file : ", dialogue_file)
	
	# load dialogue
	dialogue = load_dialogue()
	
	# initial yield before it matters bc that one messes with 
	# chat.visible_characters for some reason
	print("initial timer check")
	timer.set_wait_time(text_speed)
	timer.start()
	await timer.timeout
	print("initial timer check works")
	
	# reset index and set visible/active true
	current_dialogue = 0
	active = true
	set_visible(active)
	
	# update text
	next_line()

# load and parse dialogue from JSON file
func load_dialogue():
	print("\nLOADING DIALOGUE")
	if FileAccess.file_exists(dialogue_file):
		print("DIALOGUE EXISTS, OPENING")
		var file = FileAccess.open(dialogue_file, FileAccess.READ)
		var json = JSON.new()
		if OK == json.parse(file.get_as_text()): 
			print("AS TEXT:\n", file.get_as_text())
			print(json, " : ", json.get_data())
			return json.get_data()
		else:
			print("ERROR PARSING JSON : ", json.parse(file.get_as_text()))

func next_line():
	# update vars
	finished = false
	
	# if dialogue starts combat, start combat
	if dialogue[current_dialogue].has("Combat"):
		print("emitting start combat signal")
		print(dialogue[current_dialogue])
		combat_start.emit(dialogue[current_dialogue]["Combat"])
		end_dialogue()
	
	# if index is out of bounds, end dialogue
	if current_dialogue >= len(dialogue) or current_dialogue < 0 or not dialogue[current_dialogue].has("Text"):
		end_dialogue()
		return
	
	# update text, works with bbcode
	print("current line:" , dialogue[current_dialogue]["Text"])
	var newtext = RichTextLabel.new()
	newtext.bbcode_enabled = true
	newtext.fit_content = true
	newtext.custom_minimum_size = Vector2(300,50)
	text_container.add_child(newtext)
	chat = newtext
	chat.text = dialogue[current_dialogue]["Text"]
	
	# change speed of text progression if needed
	if dialogue[current_dialogue].has("Speed"):
		match dialogue[current_dialogue]["Speed"]:
			"slow":
				timer.set_wait_time(SLOW)
			"fast":
				timer.set_wait_time(FAST)
			_:
				timer.set_wait_time(NORM)
	
	# update resources if any updates were requested
	if dialogue[current_dialogue].has("Stress"):
		ResourceTracker.increment_stress(dialogue[current_dialogue]["Stress"])
	if dialogue[current_dialogue].has("Resource"):
		print("incrementing resource by ", dialogue[current_dialogue]["Resource"])
		ResourceTracker.increment_resource_points(dialogue[current_dialogue]["Resource"])
	
	# clear textbox
	chat.visible_characters = 0
	
	# write phrase
	print("chat.text = ", chat.text)
	while chat.visible_characters < len(chat.text):
		chat.visible_characters += 1 # make next char visible
		
		# pause for punctuation
		if !has_trailing_punctuation() and chat.text.substr(chat.visible_characters-1, 1) in [".", "!", "?", ","]:
			timer.start(text_speed*6)
			await timer.timeout
		
		#print("resetting timer speed")
		timer.set_wait_time(text_speed)
		
		# delay between characters made visible
		#print("text-speed")
		timer.start(text_speed)
		await timer.timeout # delay while loop until timeout
		#print("finished waiting, next character\n")
	
	# restore text_speed
	timer.set_wait_time(text_speed)
	
	# determine next line
	if dialogue[current_dialogue].has("Choices"):
		# display choices, and wait for selection
		# set current dialogue to index of selected choice's next
		display_choices(dialogue[current_dialogue]["Choices"])
		await choice_selected
		var choice = selection
		remove_choice(choice)
		
		print("current_dialogue: ", current_dialogue)
		if choice.has("Next"):
			current_dialogue = index_of_line(choice["Next"])
			print("Selected choice: \"", choice["Text"],"\"")
			print("Next label: ", choice["Next"])
			print("updated with label: ", current_dialogue)
		else:
			current_dialogue += 1
		
	elif dialogue[current_dialogue].has("Next"):
		# get index of next (the line with the label tag matching dialogue[current_dialogue]["Next"])
		current_dialogue = index_of_line(dialogue[current_dialogue]["Next"])
	else:
		# increment index
		current_dialogue += 1
	
	if dialogue[current_dialogue].has("Check"):
		var rank # rank of the skill check
		var result # result of the skill check
		var next_labels = [] # labels for the next dialogue to be played
		next_labels.append(dialogue[current_dialogue]["Check"]["Success"]) # 0
		next_labels.append(dialogue[current_dialogue]["Check"]["Mixed"]) # 1
		next_labels.append(dialogue[current_dialogue]["Check"]["Failure"]) # 2
		
		# determine who makes the check
		if dialogue[current_dialogue]["Check"]["Character"] == "Party":
			# find the party member with the highest rank in dialogue[current_dialogue]["Check"]
			rank = get_party_highest_skill(dialogue[current_dialogue]["Check"]["Skill"])
		else:
			# have the character whose name is listed in check at character make the check with their skill rank
			var character = get_character(dialogue[current_dialogue]["Check"]["Character"])
			rank = character.get_skill(dialogue[current_dialogue]["Check"]["Skill"])
		
		# make the check
		result = Dice.skill_check(rank)
		output_check_result(result)
		
		var stress_boost = 0
		# if it's a mixed success or failure, prompt if the player wants to spend stress
		if ResourceTracker.stress > 0 and (result["Result"] == Dice.MIXED_SUCCESS or result["Result"] == Dice.FAILURE):
			stress_boost = await prompt_stress_boost()
			ResourceTracker.set_stress(ResourceTracker.get_stress()-stress_boost)
			if stress_boost > 0:
				output_check_result({"Stress Boost":true, "Result":result["Result"]-stress_boost})
		
		# continue to next dialogue based on result
		var next = next_labels[result["Result"]-stress_boost] # next label = result - stress_boost
		# get index of next (the line with the label tag matching dialogue[current_dialogue]["Next"])
		current_dialogue = index_of_line(next)
	
	finished = true
	return

# end current dialogue
func end_dialogue():
	# print for debug
	print("ending dialogue")
	
	# reset variables
	active = false
	set_visible(active)
	current_dialogue = 0
	
	# unpause game
	#unpause()
	# emit signal
	dialogue_ended.emit()

# returns true if the last visible character has punctuation following it
func has_trailing_punctuation():
	# if last visible character isn't the last character and the next character is punctuation
	return chat.visible_characters != len(chat.text) and chat.text.substr(chat.visible_characters, 1) in [".", "!", "?", ","]

func unpause():
	# unpause game
	get_tree().set_deferred("paused", false)

func pause():
	# pause game
	get_tree().set_deferred("paused", true)

# Find the index of a dialogue line where line["Label"] = label
func index_of_line(label:String):
	for i in len(dialogue):
		if dialogue[i].has("Label") and dialogue[i]["Label"] == label:
			return i
	# if label does not exist
	return -1

# display selectable choices
func display_choices(choices):
	print("Choices : ", choices)
	choices_list = ItemList.new()
	choices_list.deselect_all()
	choices_list.auto_height = true
	choices_list.custom_minimum_size = Vector2(300, 0)
	choices_list.max_text_lines = 10
	choices_list.text_overrun_behavior = TextServer.OVERRUN_TRIM_WORD_ELLIPSIS
	choices_list.item_selected.connect(_on_choice_selected)
	text_container.add_child(choices_list)
	
	choice_items = []
	for choice in choices:
		choices_list.add_item(choice["Text"])
		choice_items.append(choice)

# on choice selected, update variables and disable all current dialogue options
func _on_choice_selected(index:int):
	selection = choice_items[index]
	
	# display selection
	print("itemlist queuefree")
	choices_list.queue_free() # remove ItemList
	chat.text += "\n\n[color=gray][i]" + selection["Text"] + "[/i]" # append selection to text
	chat.visible_characters = -1 # make visible
	
	choice_selected.emit()

# Remove a choice from the list of selectable options
func remove_choice(choice):
	dialogue[current_dialogue]["Choices"].erase(choice)

# return the node of the player character with the name character_name
func get_character(character_name:String, party="PCs"):
	# if party doesn't exist, return null
	if not combat_tracker.combatants.has(party):
		return null
	
	# steal characters list from combat_tracker's list of combatants
	for i in len(combat_tracker.combatants[party]):
		if combat_tracker.combatants[party][i]["Name"] == character_name:
			return combat_tracker.combatants[party][i]["Node"]
	
	# return null if no character found of that name
	return null

# return an array of every character node in a given party
func get_party_characters(party:String):
	# if party doesn't exist, return null
	if not combat_tracker.combatants.has(party):
		return null
	
	# populate and return array
	var characters = []
	for i in len(combat_tracker.combatants[party]):
		characters.append(combat_tracker.combatants[party][i]["Node"])
	return characters

# get the highest rank of the party's skill ranks for a particular skill
func get_party_highest_skill(skill:String, party_name="PCs"):
	# get party
	var party = get_party_characters(party_name)
	
	# iterate through party to find the highest rank of a certain skill
	var max_rank = 0
	for character in party:
		max_rank = max(max_rank, character.get_skill(skill))
	
	return max_rank

# output a given result to the player
func output_check_result(result):
	if not result.has("Stress Boost"):
		chat.text += "\n\n[color=gray][i]" + str(len(result["Rolls"])) + "d6 ("
		
		for i in len(result["Rolls"]):
			chat.text += str(result["Rolls"][i]) # add roll to text
			# add comma if not last roll
			if i < len(result["Rolls"])-1:
				chat.text += ", "
		
		chat.text += ") : "
	else:
		chat.text += "\n\n[color=gray][i] Stress Boost : "
	
	var success_message
	match result["Result"]:
		Dice.SUCCESS:
			success_message = "Success"
		Dice.MIXED_SUCCESS:
			success_message = "Mixed Success"
		Dice.FAILURE:
			success_message = "Failure"
	
	chat.text += success_message
	
	chat.visible_characters = -1

# prompt the player to spend stress or not to boost their result by one step
# from a failure to a mixed success; mixed success, success
func prompt_stress_boost():
	var choices = [
		{"Text":"[Accept.]"},
		{"Text":"[Spend stress for better result.]"}
	]
	
	display_choices(choices)
	await choice_selected
	return 0 if selection["Text"] == "[Accept.]" else 1
