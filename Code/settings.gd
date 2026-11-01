extends Control

@onready var _slider: HSlider = $VBoxContainer/HSlider
@onready var _titulo: Label = $VBoxContainer/Label

const ESCENA_MENU := "res://Scenes/game.tscn"


func _ready() -> void:
	_slider.min_value = 0.0
	_slider.max_value = 1.0
	_slider.step = 0.01
	_slider.value = util_func.volumen
	_slider.value_changed.connect(_on_volumen_cambiado)
	_mostrar_valor(_slider.value)


func _on_volumen_cambiado(valor: float) -> void:
	util_func.set_volumen(valor)
	_mostrar_valor(valor)


func _mostrar_valor(valor: float) -> void:
	_titulo.text = "VOLUME %d%%" % roundi(valor * 100.0)


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_cancel"):
		_on_back_pressed()


func _exit_tree() -> void:
	util_func.guardar_ajustes()


func _on_back_pressed() -> void:
	util_func.change_scene(ESCENA_MENU)
