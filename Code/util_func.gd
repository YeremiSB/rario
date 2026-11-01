extends Node

signal puntos_cambiados(total: int)

const RUTA_AJUSTES := "user://settings.cfg"

var color_fade: Color = Color(0.0, 0.0, 0.0)
var duracion: float = 0.25
var fade_al_iniciar: bool = true

var volumen: float = 1.0

## Puntos de la partida.
var puntos: int = 0

var _capa: CanvasLayer
var _velo: ColorRect
var _ocupado := false


func _ready() -> void:
	_cargar_ajustes()
	_aplicar_volumen()

	_capa = CanvasLayer.new()
	_capa.layer = 128  
	add_child(_capa)

	_velo = ColorRect.new()
	_velo.color = Color(color_fade.r, color_fade.g, color_fade.b, 0.0)
	_velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_capa.add_child(_velo)
	_velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	if fade_al_iniciar:
		_velo.color = Color(color_fade.r, color_fade.g, color_fade.b, 1.0)
		await get_tree().process_frame
		await _fundir(0.0)


func change_scene(scene: String) -> void:
	if _ocupado:
		return
	_ocupado = true
	_velo.mouse_filter = Control.MOUSE_FILTER_STOP  # bloquea clics durante el cambio

	await _fundir(1.0)

	var error := get_tree().change_scene_to_file(scene)
	if error != OK:
		push_error("No se pudo cargar la escena: %s (error %d)" % [scene, error])

	await get_tree().process_frame
	await _fundir(0.0)

	_velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ocupado = false


# ── Audio ─────────────────────────────────────────────────────────────

## Cambia el volumen (0..1). guardar=true lo escribe en disco al momento.
func set_volumen(valor: float, guardar: bool = false) -> void:
	volumen = clampf(valor, 0.0, 1.0)
	_aplicar_volumen()
	if guardar:
		guardar_ajustes()


func _aplicar_volumen() -> void:
	# El bus 0 de Godot siempre es "Master": afecta a todo el sonido del juego.
	AudioServer.set_bus_mute(0, volumen <= 0.001)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volumen, 0.001)))


# ── Puntos ────────────────────────────────────────────────────────────

func sumar_puntos(cantidad: int) -> void:
	puntos += cantidad
	puntos_cambiados.emit(puntos)


func reiniciar_puntos() -> void:
	puntos = 0
	puntos_cambiados.emit(puntos)


# ── Ajustes en disco ──────────────────────────────────────────────────

func guardar_ajustes() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "volumen", volumen)
	var error := cfg.save(RUTA_AJUSTES)
	if error != OK:
		push_warning("No se pudo guardar %s (error %d)" % [RUTA_AJUSTES, error])


func _cargar_ajustes() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(RUTA_AJUSTES) != OK:
		return  # primera vez: se queda el volumen por defecto
	volumen = clampf(float(cfg.get_value("audio", "volumen", 1.0)), 0.0, 1.0)


# ── Fundido ───────────────────────────────────────────────────────────

func _fundir(alfa: float) -> void:
	var tween := create_tween()
	tween.tween_property(_velo, "color:a", alfa, duracion)
	await tween.finished
