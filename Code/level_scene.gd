extends Node2D
@onready var message = $HUD/Label

func _on_final_body_entered(body):
	message.text = "YOU WIN"
	message.show()
	await get_tree().create_timer(2.0).timeout
	util_func.change_scene("res://Scenes/game.tscn")


func _on_void_body_entered(body):
	message.text = "GAME OVER"
	message.show()
	await get_tree().create_timer(2.0).timeout
	util_func.change_scene("res://Scenes/level_scene.tscn")
