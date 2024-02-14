extends Node2D

func _ready():
	var total = []
	var rolls = 1000
	for rank in range(1,5):
		total = skill_check(rolls, rank)
		print("average result of ", rolls, " rolls at rank ", rank, ": ", average_result(total))

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
