extends CharacterVisual
## Dibujo cuadro a cuadro con AnimatedSprite2D (personaje de prueba de Matías).

## Si falta una animación, se usa esta en su lugar.
const FALLBACKS := {
	&"crouch": &"idle",
	&"crouch_punch": &"punch",
	&"crouch_kick": &"kick",
	&"air_punch": &"punch",
	&"air_kick": &"kick",
}

@onready var sprite: AnimatedSprite2D = $Sprite


func play_animation(anim: StringName, restart: bool = false) -> void:
	if not sprite.sprite_frames.has_animation(anim):
		anim = FALLBACKS.get(anim, &"idle")
	sprite.play(anim)
	if restart:
		sprite.frame = 0


func set_facing(facing: float) -> void:
	# Los dibujos miran a la derecha; hacia la izquierda los volteamos.
	sprite.flip_h = facing < 0.0
