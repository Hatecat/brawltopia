class_name AttackData
extends Resource
## Datos de un ataque. Cada ataque es un archivo .tres que se edita en el Inspector.
##
## El código del jugador no sabe nada de "puñetazo" o "patada": solo lee
## estos datos. Para crear un ataque nuevo basta con crear otro .tres.
##
## Los tiempos se cuentan en CUADROS DE JUEGO (60 por segundo), como en los
## juegos de pelea. La animación solo es el dibujo: dura total_frames / 60
## segundos, pero quien decide cuándo golpea es este contador.

## Animación del personaje que se reproduce (debe existir en su visual).
@export var animation: StringName

## Daño que hará al conectar (se usará cuando exista el sistema de daño).
@export var damage: float = 5.0

## Duración total del ataque, en cuadros de juego (60 = 1 segundo).
@export var total_frames: int = 20

## Cuadros en que el golpe está activo (puede dañar), contados desde 0.
## Antes = preparación (startup); después = recuperación (recovery).
@export var active_start_frame: int = 6
@export var active_end_frame: int = 11

## Caja de golpe (hitbox), mirando a la derecha. Se voltea sola al mirar a la izquierda.
## La posición es relativa a los pies del personaje (Y negativa = hacia arriba).
@export var hitbox_offset: Vector2 = Vector2(30, -55)
@export var hitbox_size: Vector2 = Vector2(24, 16)

## Ataque hecho agachado: el personaje sigue agachado (hurtbox baja) mientras dura.
@export var crouching: bool = false

## Ataque aéreo: se puede seguir moviendo en el aire y termina al aterrizar.
@export var aerial: bool = false

## Golpe con los brazos: la hitbox sube junto con el torso cuando la skin tiene piernas
## que empiezan más abajo (ver CharacterVisual.torso_lift). Las patadas no lo necesitan.
@export var follows_torso: bool = false

@export_group("Al conectar")
## Empujón que recibe quien es golpeado, en px/s: x = alejándose del atacante, y negativa = hacia arriba.
@export var knockback: Vector2 = Vector2(220, -150)
## Cuadros de juego que el golpeado queda aturdido (sin poder moverse ni atacar).
@export var hitstun_frames: int = 14
## Pequeño retroceso de quien golpea, en px/s (hacia atrás).
@export var self_recoil: float = 200.0


func is_active_frame(frame: int) -> bool:
	return frame >= active_start_frame and frame <= active_end_frame
