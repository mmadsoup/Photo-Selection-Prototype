extends Node2D
@onready var animation_player := $AnimationPlayer

var camera : SpringArm3D

func _ready():
	animation_player.play('slide')

func _on_button_pressed():
	Globals.selected_a_photo = false
	get_tree().change_scene_to_file('res://game.tscn')
	

