# Brawltopia

Juego de lucha 2D tipo *platform fighter*, inspirado en Super Smash Bros. y M.U.G.E.N., hecho con **Godot 4** y GDScript.

## Estado actual

- Escenario con suelo y dos plataformas que se atraviesan desde abajo.
- Un jugador con movimiento horizontal, salto y gravedad.
- Si el jugador cae fuera del escenario, reaparece.
- Personaje de prueba animado (quieto, caminar, salto, caída, puñetazo y patada) recortado de una hoja de presentación. Es temporal: ver `assets/characters/matias_temp/`.
- Ataques definidos como datos (`AttackData`): animación, daño, cuadros activos y caja de golpe (hitbox). Por ahora solo en el suelo y sin rival que reciba el daño.

## Cómo abrirlo

1. Instala [Godot 4](https://godotengine.org/download) (versión 4.3 o superior, la estándar, no la de .NET).
2. En el Gestor de proyectos, pulsa **Importar** y elige `project.godot`.
3. Pulsa **F5** para jugar.

Para ver las cajas de colisión y de golpe mientras juegas: menú **Depurar → Formas de colisión visibles** (*Debug → Visible Collision Shapes*). La hitbox del ataque aparece en rojo solo durante los cuadros en que el golpe está activo.

## Controles

| Acción    | Teclas                  |
|-----------|-------------------------|
| Moverse   | A / D o ← / →           |
| Saltar    | W, ↑ o Espacio          |
| Puñetazo  | J                       |
| Patada    | K                       |

## Estructura

```
project.godot                  configuración: ventana, controles, capas de física
scenes/
  main.tscn                    escena principal: escenario + jugador
  stages/test_stage.tscn       suelo y dos plataformas
  characters/player.tscn       cuerpo, colisión, hurtbox, hitbox y animaciones
resources/attacks/
  matias_punch.tres            datos del puñetazo
  matias_kick.tres             datos de la patada
assets/characters/
  matias_temp/                 animaciones temporales del personaje de prueba
scripts/
  player.gd                    movimiento, salto, gravedad, animaciones y ataques
  attack_data.gd               definición de un ataque (AttackData)
  main.gd                      reaparición al caer del escenario
```

## Capas de física

| Capa | Nombre      | Uso                                             |
|------|-------------|-------------------------------------------------|
| 1    | world       | suelo y plataformas                             |
| 2    | players     | cuerpo físico de los personajes                 |
| 3    | hitboxes    | cajas de golpe de los ataques (buscan hurtboxes)|
| 4    | hurtboxes   | zona donde un personaje puede recibir golpes    |

## Ideas de diseño a futuro

- Cuatro tamaños de personaje predefinidos, cada uno con su caja de colisión fija.
- Ataques, armas y poderes diseñados por el equipo para mantener el equilibrio.
- Personajes por piezas (cabeza, torso, brazos, piernas, arma): los jugadores pueden crear y cargar sus propios cosméticos.
