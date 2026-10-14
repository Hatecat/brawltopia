extends Camera2D
## Cámara de pelea, como en Smash: encuadra a todos los luchadores.
##
## Busca los nodos del grupo "fighters", calcula el rectángulo que los contiene
## (más un margen) y se mueve y hace zoom suavemente para que entren todos.
## Con un solo luchador se acerca al máximo; cuando se separan, se aleja.

## Zoom más cercano (con un luchador o cuando están juntos). 2 = el doble de grande.
@export var max_zoom: float = 3.0
## Zoom más lejano (luchadores muy separados).
@export var min_zoom: float = 1.4
## Espacio que se deja alrededor de los luchadores, en px del mundo.
@export var margin: Vector2 = Vector2(220, 140)
## Qué tan rápido sigue a los luchadores y ajusta el zoom (más = más rígido).
@export var follow_speed: float = 6.0
@export var zoom_speed: float = 3.0
## Centrar un poco más arriba de los pies, para ver el cuerpo entero.
@export var height_offset: float = -40.0
## Zona del mundo que la cámara puede mostrar (no se sale de aquí).
@export var bounds: Rect2 = Rect2(-100, -300, 1480, 1060)


func _ready() -> void:
	limit_left = int(bounds.position.x)
	limit_top = int(bounds.position.y)
	limit_right = int(bounds.end.x)
	limit_bottom = int(bounds.end.y)
	_update(1.0)  # empezar ya encuadrado


func _process(delta: float) -> void:
	_update(delta)


func _update(delta: float) -> void:
	var area := _fighters_rect()
	if area.size == Vector2.ZERO and area.position == Vector2.ZERO:
		return
	area = area.grow_individual(margin.x, margin.y, margin.x, margin.y)
	var view := get_viewport_rect().size
	var target_zoom := clampf(minf(view.x / area.size.x, view.y / area.size.y), min_zoom, max_zoom)
	var target_pos := area.get_center()
	# Movimiento suave: acercarse una fracción del camino cada frame.
	var follow := clampf(follow_speed * delta, 0.0, 1.0)
	var zooming := clampf(zoom_speed * delta, 0.0, 1.0)
	global_position = global_position.lerp(target_pos, follow)
	zoom = zoom.lerp(Vector2.ONE * target_zoom, zooming)


## Rectángulo que contiene a los luchadores que están dentro de la zona visible.
func _fighters_rect() -> Rect2:
	var rect := Rect2()
	var first := true
	for f in get_tree().get_nodes_in_group("fighters"):
		var p: Vector2 = (f as Node2D).global_position + Vector2(0, height_offset)
		if not bounds.has_point(p):
			continue  # cayendo fuera del escenario: no arrastrar la cámara
		if first:
			rect = Rect2(p, Vector2.ZERO)
			first = false
		else:
			rect = rect.expand(p)
	return rect
