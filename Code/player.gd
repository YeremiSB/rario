extends CharacterBody2D

signal cambio_de_tamano(es_super: bool)

@export_group("Movimiento")
@export var velocidad_caminar: float = 110.0
@export var velocidad_correr: float = 175.0
@export var aceleracion: float = 900.0
@export var desaceleracion: float = 1400.0
@export var aceleracion_aerea: float = 600.0
@export var friccion_aerea: float = 300.0

@export_group("Salto")
@export var fuerza_salto: float = 460.0
@export var corte_salto: float = 0.45
@export var gravedad_subida: float = 1000.0
@export var gravedad_bajada: float = 1400.0
@export var caida_maxima: float = 520.0
@export var coyote_time: float = 0.1
@export var buffer_salto: float = 0.12

@export_group("Estado")
@export var es_super: bool = false

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _colision: CollisionShape2D = $CollisionShape2D

var _escala_base: Vector2
var _tween_escala: Tween
var _coyote := 0.0
var _buffer := 0.0
var _corriendo := false


func _ready() -> void:
	floor_snap_length = 6.0
	_escala_base = _sprite.scale
	_configurar_animaciones()
	_aplicar_tamano()
	call_deferred("_ajustar_limites_camara")



func _ajustar_limites_camara() -> void:
	var cam := get_node_or_null("Camera2D") as Camera2D
	var escena := get_tree().current_scene
	if cam == null or escena == null:
		return
	var mapa := escena.get_node_or_null("TileMapLayer") as TileMapLayer
	if mapa == null or mapa.tile_set == null:
		return
	var usados := mapa.get_used_rect()
	var tam := Vector2(mapa.tile_set.tile_size) * mapa.scale
	cam.limit_left = int(usados.position.x * tam.x)
	cam.limit_top = int(usados.position.y * tam.y) - 320
	cam.limit_right = int(usados.end.x * tam.x)
	cam.limit_bottom = int(usados.end.y * tam.y)


func _physics_process(delta: float) -> void:
	var direccion := Input.get_axis("move_left", "move_right")
	_corriendo = Input.is_action_pressed("correr")

	_mover_horizontal(direccion, delta)
	_procesar_salto(delta)
	_aplicar_gravedad(delta)

	var estaba_en_suelo := is_on_floor()
	var subiendo := velocity.y < 0.0
	move_and_slide()
	if not estaba_en_suelo and is_on_floor():
		_aterrizar()
	if subiendo:
		_golpear_bloques()

	_animar(direccion)


## Si el player choca con la cara de abajo de un bloque "?", lo activa.
func _golpear_bloques() -> void:
	for i in get_slide_collision_count():
		var colision := get_slide_collision(i)
		if colision.get_normal().y > 0.7:
			var cuerpo := colision.get_collider()
			if cuerpo and cuerpo.has_method("golpear_desde_abajo"):
				cuerpo.golpear_desde_abajo()


# ── Movimiento ────────────────────────────────────────────────────────

func _mover_horizontal(direccion: float, delta: float) -> void:
	var objetivo := direccion * (velocidad_correr if _corriendo else velocidad_caminar)
	var cambio: float
	if is_zero_approx(direccion):
		cambio = (desaceleracion if is_on_floor() else friccion_aerea) * delta
	else:
		cambio = (aceleracion if is_on_floor() else aceleracion_aerea) * delta
	velocity.x = move_toward(velocity.x, objetivo, cambio)


func _procesar_salto(delta: float) -> void:
	_coyote = coyote_time if is_on_floor() else maxf(_coyote - delta, 0.0)
	_buffer = buffer_salto if Input.is_action_just_pressed("jump") else maxf(_buffer - delta, 0.0)
	if _buffer > 0.0 and _coyote > 0.0:
		velocity.y = -fuerza_salto
		_buffer = 0.0
		_coyote = 0.0
		_estirar(Vector2(0.8, 1.2), 0.08)
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= corte_salto


func _aplicar_gravedad(delta: float) -> void:
	if is_on_floor():
		return
	var gravedad := gravedad_subida if velocity.y < 0.0 else gravedad_bajada
	velocity.y = minf(velocity.y + gravedad * delta, caida_maxima)


func _aterrizar() -> void:
	_estirar(Vector2(1.15, 0.85), 0.1)


# ── Animación ─────────────────────────────────────────────────────────

func _animar(direccion: float) -> void:
	var sufijo := "super" if es_super else "small"
	var anim: String
	if not is_on_floor():
		anim = "jump_" + sufijo
	elif absf(velocity.x) > 8.0:
		anim = "walk_" + sufijo
	else:
		anim = "idle_" + sufijo

	if _sprite.animation != anim:
		_sprite.play(anim)

	if not is_on_floor():
		var total := _sprite.sprite_frames.get_frame_count(anim)
		_sprite.frame = 0 if velocity.y < -60.0 else total - 1

	_sprite.speed_scale = 1.5 if (_corriendo and is_on_floor()) else 1.0

	if direccion > 0.05:
		_sprite.flip_h = false
	elif direccion < -0.05:
		_sprite.flip_h = true


func _configurar_animaciones() -> void:
	var frames := _sprite.sprite_frames
	for nombre in ["jump_small", "jump_super"]:
		if frames.has_animation(nombre):
			frames.set_animation_loop(nombre, false)
			frames.set_animation_speed(nombre, 10.0)
	for nombre in ["walk_small", "walk_super"]:
		if frames.has_animation(nombre):
			frames.set_animation_speed(nombre, 8.0)


func _estirar(escala: Vector2, tiempo: float) -> void:
	if _tween_escala and _tween_escala.is_valid():
		_tween_escala.kill()
	_sprite.scale = _escala_base * escala
	_tween_escala = create_tween()
	_tween_escala.tween_property(_sprite, "scale", _escala_base, tiempo * 2.0)


# ── Power-up: small <-> super ─────────────────────────────────────────

func hacer_super() -> void:
	if es_super:
		return
	es_super = true
	_aplicar_tamano()
	_estirar(Vector2(0.7, 1.35), 0.12)
	cambio_de_tamano.emit(true)


func perder_super() -> void:
	if not es_super:
		return
	es_super = false
	_aplicar_tamano()
	cambio_de_tamano.emit(false)


func _aplicar_tamano() -> void:
	var capsula := _colision.shape as CapsuleShape2D
	if capsula:
		if es_super:
			capsula.height = 58.0
			_colision.position = Vector2(0, -29)
		else:
			capsula.height = 26.0
			_colision.position = Vector2(0, -13)
	_sprite.offset = Vector2(0, -128) if es_super else Vector2(0, -64)
