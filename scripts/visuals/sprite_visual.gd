extends CharacterVisual
## Dibujo cuadro a cuadro con AnimatedSprite2D (personaje de prueba de Matías).

@onready var sprite: AnimatedSprite2D = $Sprite


func play_animation(anim: StringName, restart: bool = false) -> void:
	sprite.play(anim)
	if restart:
		sprite.frame = 0


func set_facing(facing: float) -> void:
	# Los dibujos miran a la derecha; hacia la izquierda los volteamos.
	sprite.flip_h = facing < 0.0
