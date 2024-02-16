class_name PlayerCharacter

extends Character

# on player death, set player to downed indefinitely
func die():
	downed = -1
