extends Node2D

@onready var message: Label = $HUD/Label

var _terminado := false


func _on_final_body_entered(body: Node2D) -> void:
	await _terminar("YOU WIN", "res://Scenes/game.tscn")


func _on_void_body_entered(body: Node2D) -> void:
	await _terminar("GAME OVER", "res://Scenes/level_scene.tscn")


## La llama el player cuando lo mata un enemigo.
func game_over() -> void:
	await _terminar("GAME OVER", "res://Scenes/level_scene.tscn")


## Muestra el mensaje en el Label del HUD y cambia de escena.
func _terminar(texto: String, escena: String) -> void:
	if _terminado:
		return
	_terminado = true

	message.text = texto
	message.show()
	await get_tree().create_timer(2.0).timeout
	util_func.change_scene(escena)
