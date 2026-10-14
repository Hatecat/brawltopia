class_name CharacterVisual
extends Node2D
## Base para "cómo se ve" un personaje. El jugador solo habla con esta interfaz,
## así puede usar distintos tipos de dibujo sin cambiar su código:
##   - RigVisual: personaje por piezas (el sistema definitivo).
##   - SpriteVisual: animación cuadro a cuadro (el personaje de prueba de Matías).
##
## Nombres de animación que el jugador pide: idle, walk, jump, fall,
## y el nombre definido en cada AttackData (por ejemplo punch, kick).


## Cuánto más arriba queda el torso porque la skin une las piernas más abajo de lo normal
## (px de juego). El jugador lo usa para subir su zona golpeable y la hitbox de los puñetazos.
var torso_lift: float = 0.0


## Reproduce una animación. Con restart = true vuelve a empezar aunque ya se esté reproduciendo.
func play_animation(_anim: StringName, _restart: bool = false) -> void:
	pass


## 1 = mira a la derecha, -1 = mira a la izquierda.
func set_facing(_facing: float) -> void:
	pass
