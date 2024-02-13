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
@onready var dialogue_box = $DialogueBox
@onready var chat = $Text
@onready var voice = $Voice
@onready var sound = $Sound
@onready var timer = $Delay

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

func _ready():
	# set invisible by default
	print("DialogueCanvas ready")
	print("Timer, delay: ", timer.name, " (", timer, ")")
	visible = false

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
	
	# if index is out of bounds, end dialogue
	if current_dialogue >= len(dialogue) or current_dialogue < 0:
		end_dialogue()
		return
	# check index oob again just in case cause awaits make things a lil' wonky
	if (current_dialogue >= len(dialogue)):
		return
	
	# update text, works with bbcode
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
	
	finished = true
	
	# restore text_speed
	timer.set_wait_time(text_speed)
	
	# determine next line
	if dialogue[current_dialogue].has("Choices"):
		# display choices, and wait for selection
		# set current dialogue to index of selected choice's next
		pass
	elif dialogue[current_dialogue].has("Next"):
		# get index of next (the line with the label tag matching dialogue[current_dialogue]["Next"])
		current_dialogue = index_of_line(dialogue[current_dialogue]["Next"])
		pass
	else:
		# increment index
		current_dialogue += 1
	
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
