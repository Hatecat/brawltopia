class_name DeformMesh
extends Polygon2D
## Imagen que se DOBLA en una articulación (codo, rodilla o cintura).
##
## La imagen se cubre con una malla de vértices (una tira de filas). Cada vértice
## tiene un "peso": 0 = sigue a esta pieza, 1 = sigue a la articulación que se dobla.
## Cerca de la articulación los pesos van de 0 a 1 de forma suave, así que al girar
## la articulación la imagen se curva en vez de partirse en dos (como un brazo real).
##
## Técnica: "linear blend skinning" (la misma idea que usan Spine o Skeleton2D),
## hecha a mano para que sea fácil de leer.

## Nodo cuya rotación dobla la parte lejana de la imagen (el codo, la rodilla, el torso).
## Debe ser hermano de esta malla (mismo nodo padre).
@export var bend_node: Node2D
## Dirección (en el sistema de esta malla) hacia la parte que gira con bend_node.
@export var bend_axis: Vector2 = Vector2.DOWN
## Ancho de la zona de transición a cada lado de la articulación, en px de juego.
## Más grande = curva más suave; más chico = dobla más "en seco".
@export var blend: float = 3.5

var _rest := PackedVector2Array()   # posición de cada vértice sin doblar
var _weights := PackedFloat32Array()
var _last_angle := INF


## Arma la malla para una imagen.
## pivot: punto de unión en px de la imagen. px_scale: px de juego por px de imagen (x, y).
func setup(tex: Texture2D, pivot: Vector2, px_scale: Vector2) -> void:
	texture = tex
	_rest.clear()
	_weights.clear()
	if tex == null:
		polygon = PackedVector2Array()
		return
	var size := Vector2(tex.get_size())
	var bend_point := _bend_point()

	# Filas de la malla (en px de imagen): espaciadas, y más juntas cerca de la articulación.
	var rows := [0.0, size.y]
	var step := 4.0 / px_scale.y                       # una fila cada ~4 px de juego
	var y := step
	while y < size.y:
		rows.append(y)
		y += step
	if bend_axis.y != 0.0:
		var bend_row := pivot.y + bend_point.y / px_scale.y
		for i in range(-6, 7):                          # filas extra en la zona que se dobla
			rows.append(bend_row + i * (blend / 3.0) / px_scale.y)
	rows = rows.filter(func(r): return r >= 0.0 and r <= size.y)
	rows.sort()

	# Dos vértices por fila (izquierda y derecha): como el peso solo depende de la altura,
	# el doblez de cada fila es exacto con dos puntos.
	var uvs := PackedVector2Array()
	var prev := -1.0
	for r in rows:
		if r - prev < 0.25:
			continue                                    # filas casi repetidas
		prev = r
		for x in [0.0, size.x]:
			var uv := Vector2(x, r)
			var p := (uv - pivot) * px_scale             # posición en px de juego, unión en (0, 0)
			uvs.append(uv)
			_rest.append(p)
			var d := (p - bend_point).dot(bend_axis)
			_weights.append(smoothstep(-blend, blend, d))

	var quads: Array = []
	for i in range(0, uvs.size() - 2, 2):
		quads.append(PackedInt32Array([i, i + 1, i + 3, i + 2]))
	uv = uvs
	polygons = quads
	polygon = _rest
	_last_angle = INF
	_update_shape()


func _ready() -> void:
	# Actualizar después del AnimationPlayer (prioridad más alta = se procesa después).
	process_priority = 10


func _process(_delta: float) -> void:
	_update_shape()


## Recalcula los vértices según el ángulo actual de la articulación.
func _update_shape() -> void:
	if _rest.is_empty() or bend_node == null:
		return
	var angle := bend_node.rotation
	if angle == _last_angle:
		return
	_last_angle = angle
	var pivot := _bend_point()
	var turn := Transform2D(angle, Vector2.ZERO)
	var pts := PackedVector2Array()
	pts.resize(_rest.size())
	for i in _rest.size():
		var p := _rest[i]
		var bent := turn * (p - pivot) + pivot          # el vértice si siguiera 100% a la articulación
		pts[i] = p.lerp(bent, _weights[i])
	polygon = pts


## Dónde está la articulación, en el sistema de esta malla.
func _bend_point() -> Vector2:
	if bend_node == null:
		return Vector2.ZERO
	return bend_node.position - position
