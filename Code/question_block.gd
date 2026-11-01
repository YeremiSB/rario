extends StaticBody2D
## Bloque "?" del nivel: al golpearlo desde abajo suelta un powerup o puntos
## y queda convertido en bloque usado.

enum Tipo { PUNTOS, POWERUP }

@export var tipo: Tipo = Tipo.PUNTOS
@export var puntos: int = 100

const REGION_SIGNO := Rect2(32, 64, 32, 32)
const REGION_USADO := Rect2(0, 64, 32, 32)
const ESCENA_POWERUP := preload("res://Scenes/powerup.tscn")

@onready var _sprite: Sprite2D = $Sprite2D

var _golpeado := false


func golpear_desde_abajo() -> void:
	if _golpeado:
		return
	_golpeado = true

	_sprite.region_rect = REGION_USADO
	_bump()
	util_func.sumar_puntos(puntos)

	if tipo == Tipo.POWERUP:
		_soltar_powerup()
	else:
		_soltar_texto()


func _bump() -> void:
	var y := position.y
	var tween := create_tween()
	tween.tween_property(self, "position:y", y - 6.0, 0.06)
	tween.tween_property(self, "position:y", y, 0.1)


func _soltar_powerup() -> void:
	var nuevo := ESCENA_POWERUP.instantiate()
	nuevo.emerge = true
	nuevo.position = position
	get_parent().add_child(nuevo)


func _soltar_texto() -> void:
	var texto := Label.new()
	texto.text = "+%d" % puntos
	texto.add_theme_font_size_override("font_size", 10)
	texto.add_theme_color_override("font_color", Color(1.0, 0.95, 0.45))
	texto.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	texto.add_theme_constant_override("outline_size", 4)
	texto.position = Vector2(-12, -44)
	add_child(texto)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(texto, "position:y", -72.0, 0.55)
	tween.tween_property(texto, "modulate:a", 0.0, 0.4).set_delay(0.15)
	tween.chain().tween_callback(texto.queue_free)
