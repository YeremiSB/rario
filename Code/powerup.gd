extends Area2D

@export var brillo := true
@export var emerge := false
@onready var _sprite: Sprite2D = $Sprite2D

var _tiempo := 0.0
var _recogido := false
var _activo := true


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if emerge:
		_emerger()


func _emerger() -> void:
	_activo = false
	monitoring = false
	var destino := position + Vector2(0, -32)
	position += Vector2(0, 16)

	var tween := create_tween()
	tween.tween_property(self, "position", destino, 0.35) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished

	_activo = true
	monitoring = true


func _physics_process(delta: float) -> void:
	if not _activo or _recogido:
		return
	_tiempo += delta
	var pulso := 1.0 + sin(_tiempo * 4.0) * 0.08
	_sprite.scale = Vector2(pulso, pulso)
	if brillo:
		_sprite.modulate = Color(1.0, 1.0, 1.0).lerp(Color(1.0, 0.95, 0.6), 0.5 + 0.5 * sin(_tiempo * 4.0))


func _on_body_entered(body: Node2D) -> void:
	if _recogido or not body.has_method("hacer_super"):
		return
	_recogido = true
	body.hacer_super()
	_desaparecer()


func _desaparecer() -> void:
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.6, 1.6), 0.15)
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.chain().tween_callback(queue_free)
