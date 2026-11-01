extends CanvasLayer

@onready var _label: Label = $Puntos


func _ready() -> void:
	util_func.puntos_cambiados.connect(_actualizar)
	util_func.reiniciar_puntos()
	_actualizar(util_func.puntos)


func _actualizar(total: int) -> void:
	_label.text = "PTS. %06d" % total
