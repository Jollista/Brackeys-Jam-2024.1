extends Node

# vars for check results
const SUCCESS_THRESHOLD = 5 # minimum value for a check to be considered successful
const MIXED_SUCCESS_THRESHOLD = 3 # minimum value for a check to be considered a mixed success
enum {SUCCESS, MIXED_SUCCESS, FAILURE}

# tracks the last few ability checks for karmic rolls
var check_queue_length = 3
var check_queue = []

# tracks the last few rolls from the PCs for karmic rolls
# each PC should have an array at character_queues[character_name]
var character_queue_length = 2
var character_queues = {}

# simulate rolling x dice with d sides
func roll(x:int, d:int):
	var rolls = []
	for i in x:
		rolls.append(randi_range(1,d))
	return rolls

# roll a die with sides sides
func d(sides:int):
	return randi_range(1,sides)

# simulate a check with a skill of level rank
func skill_check(rank:int):
	# roll rank + karma d6s
	var num_dice = rank + get_check_karma()
	var rolls = roll(num_dice, 6)
	rolls = trim_rolls(rolls, rank)
	var result = interpret_result(rolls, MIXED_SUCCESS_THRESHOLD, SUCCESS_THRESHOLD)
	
	# check die rolls
	return {"Result":result, "Rolls":rolls}

# returns the number of failed rolls in the queue
func get_check_karma():
	# count failures in check_queue
	var failures = 0
	for i in check_queue:
		if i == FAILURE:
			failures += 1
	
	# return karma
	return failures

# update the check_karma queue with last result
func update_karma(last_result:int, character_name=""):
	var queue
	var queue_len
	
	# if no character_name given, update karma for check_queue
	if character_name != "":
		queue = check_queue
		queue_len = check_queue_length
	
	# else if character given and initialized, update karma for that character
	elif character_queues.has(character_name):
		queue = character_queues[character_name]
		queue_len = character_queue_length
	
	else: # if character_name not emptystring, but not initialized, don't update karma
		return
	
	# update karma queue
	queue.push_front(last_result)
	if len(queue) > queue_len:
		queue.pop_back()

# trim the lowest roll from an array of rolls until len(rolls) == max_rolls
func trim_rolls(rolls:Array, max_rolls:int):
	while len(rolls) > max_rolls:
		rolls.erase(rolls.min())

# determine the result of a check given an array of rolls
func interpret_result(rolls:Array, mixed_threshold:int, success_threshold:int):
	var result = FAILURE
	
	var i = 0
	while result != SUCCESS:
		if rolls[i] >= mixed_threshold:
			result = MIXED_SUCCESS
		if rolls[i] >= success_threshold:
			result = SUCCESS
	
	return result

# simulate a character roll (typically for actions) of XdD
func character_roll(character_name:String, x:int, d:int):
	# initialize for character if not already in character queues
	if not character_queues.has(character_name):
		character_queues[character_name] = []
	
	var rolls = []
	var avg = d/2+1 # high average of a single die roll of type d
	
	# for each roll
	for i in x:
		var dice = 1 + get_character_karma(character_name) # dice rolled is the sum of 1 (base) + karma
		var roll = trim_rolls(roll(dice, d), 1) # get roll with karma applied
		var result = interpret_result(roll, avg/2, avg) # interpret result
		rolls.append(roll[0]) # append roll to rolls
		update_karma(result, character_name) # update karma
	
	return rolls

# get karma for a given character's karma queue
func get_character_karma(character_name:String):
	# catch uninitialized character
	if not character_queues.has(character_name):
		return
	
	# count failures in character_queue
	var failures = 0
	for i in character_queues[character_name]:
		if i == FAILURE:
			failures += 1
	
	# return karma
	return failures
