class_name Character

extends CharacterBody3D

@export var max_health = 10
@export var armor = 0

signal baton_pass(character:Character)
signal end_turn(character:Character)
