extends Node2D

func _ready():
	get_character_stats(10000)
	get_check_stats(10000, 4)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("interact"):
		print("rolling skill at rank 2")
		print("result is: ", Dice.skill_check(2), "\n\n")

func skill_check(num_checks:int, rank:int):
	var results = []
	for i in num_checks:
		results.append(Dice.skill_check(rank)["Result"])
	return results

func average_result(results:Array):
	var sum = 0.0
	for result in results:
		sum += result
	return sum/len(results)

func get_check_stats(num_rolls:int, check_rank:int):
	var total = []
	var rolls = num_rolls
	for rank in check_rank:
		total = skill_check(rolls, rank+1)
		print("average result of ", rolls, " rolls at rank ", rank+1, ": ", average_result(total))

func character_roll(char_name:String, num_checks:int, dice_per_check:int, die_type:int):
	var results = []
	for i in num_checks:
		var result = Dice.character_roll(char_name, dice_per_check, die_type)
		for j in len(result):
			results.append(result[j])
	return results

func get_character_stats(iterations:int):
	print("Warrior ", average_result(character_roll("Warrior", iterations, 2, 6)))
	print("Thief ", average_result(character_roll("Thief", iterations, 1, 10)))
	print("Thief (sneak) ", average_result(character_roll("Thief (sneak)", iterations, 2, 10)))
	print("Mage ", average_result(character_roll("Mage", iterations, 1, 6)))
