extends CharacterBody2D
@export var velocidad: float = 45.0
@export var gravedad: float = 900.0
@export var caida_maxima: float = 620.0
@export var puntos_al_pisarlo: int = 200
@export var balanceo: bool = true
@export var frecuencia_balanceo: float = 9.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _rayo_der: RayCast2D = $RayoDer
@onready var _rayo_izq: RayCast2D = $RayoIzq

var _direccion := -1.0
var _muerto := false
var _t := 0.0


func _ready() -> void:
	floor_snap_length = 4.0
	_sprite.flip_h = _direccion > 0.0
	_sprite.play("walk")


func _physics_process(delta: float) -> void:
	if _muerto:
		return

	velocity.y = minf(velocity.y + gravedad * delta, caida_maxima)
	velocity.x = _direccion * velocidad
	if is_on_wall() or (is_on_floor() and not _hay_suelo_delante()):
		_doblar()

	move_and_slide()
	_animar_paso(delta)

	if global_position.y > 900.0:
		queue_free()


## El sprite del enemigo es una sola pose, así que el "caminar" se finge
## con un balanceo: sube y baja, se aplasta un poco y se inclina.
func _animar_paso(delta: float) -> void:
	if not balanceo or not is_on_floor():
		_sprite.position.y = 0.0
		_sprite.rotation = 0.0
		_sprite.scale = Vector2.ONE
		return

	_t += delta * frecuencia_balanceo
	var paso := sin(_t)
	_sprite.position.y = -absf(paso) * 2.0
	_sprite.rotation = paso * 0.07
	_sprite.scale = Vector2(1.0 + paso * 0.06, 1.0 - paso * 0.06)

func _hay_suelo_delante() -> bool:
	var rayo := _rayo_der if _direccion > 0.0 else _rayo_izq
	return rayo.is_colliding()

func _doblar() -> void:
	_direccion = -_direccion
	_sprite.flip_h = _direccion > 0.0

func pisar() -> void:
	if _muerto:
		return
	_muerto = true
	set_collision_layer_value(1, false)
	velocity = Vector2.ZERO
	util_func.sumar_puntos(puntos_al_pisarlo)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_sprite, "scale", Vector2(1.25, 0.2), 0.1)
	tween.tween_property(_sprite, "modulate:a", 0.0, 0.25).set_delay(0.35)
	tween.chain().tween_callback(queue_free)
