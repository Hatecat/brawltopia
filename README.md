# Brawltopia

Juego de lucha 2D tipo *platform fighter*, inspirado en Super Smash Bros. y M.U.G.E.N., hecho con **Godot 4** y GDScript.

## Estado actual

- Escenario con suelo y dos plataformas que se atraviesan desde abajo.
- Jugador con movimiento horizontal, salto y gravedad. Si cae fuera del escenario, reaparece.
- **Agacharse** (hurtbox más baja) y **ataques en tres situaciones:** de pie, agachado (puñetazo bajo y barrida) y en el aire (puñetazo y patada voladora; se puede seguir moviendo y el ataque termina al aterrizar).
- **Personaje por piezas:** esqueleto de articulaciones con 7 imágenes intercambiables (una *skin*) y 11 animaciones. La skin actual es **gerald**, generada con Copilot e importada con `tools/import_parts_sheet.py`. Ver `docs/skin_spec.md`.
- **Skins asimétricas:** cada pieza puede tener una versión para mirar a la izquierda (`_left`) y otra para la extremidad de atrás (`_back`).
- **Skins de jugadores:** se cargan desde una carpeta (`user://skins/<nombre>/`). Solo se aceptan PNG de hasta 1024 px; las piezas que falten se toman de la skin por defecto.
- **Ataques definidos como datos** (`AttackData`), con tiempos en cuadros de juego (60 por segundo): preparación, cuadros activos de la caja de golpe (hitbox) y recuperación. Todavía no hay un rival que reciba el daño.
- Personaje de prueba cuadro a cuadro (Matías), disponible como alternativa: `scenes/characters/player_matias_temp.tscn`.

## Cómo abrirlo

1. Instala [Godot 4](https://godotengine.org/download) (versión 4.3 o superior, la estándar, no la de .NET).
2. En el Gestor de proyectos, pulsa **Importar** y elige `project.godot`.
3. Pulsa **F5** para jugar.

Para ver las cajas de colisión y de golpe mientras juegas: menú **Depurar → Formas de colisión visibles** (*Debug → Visible Collision Shapes*). La hitbox aparece en rojo solo durante los cuadros activos del golpe.

## Controles

| Acción    | Teclas                  |
|-----------|-------------------------|
| Moverse   | A / D o ← / →           |
| Saltar    | W, ↑ o Espacio          |
| Agacharse | S o ↓ (mantener)        |
| Puñetazo  | J                       |
| Patada    | K                       |

Puñetazo y patada cambian según la situación: de pie, agachado o en el aire.

## Estructura

```
project.godot                      configuración: ventana, controles, capas de física
scenes/
  main.tscn                        escena principal: escenario + jugador
  stages/test_stage.tscn           suelo y dos plataformas
  characters/
    player.tscn                    jugador: física, hurtbox, hitbox; usa el visual por piezas
    player_matias_temp.tscn        variante con el personaje de prueba cuadro a cuadro
    visuals/rig_visual.tscn        esqueleto por piezas + AnimationPlayer
    visuals/matias_sprite_visual.tscn
resources/attacks/                 datos de cada ataque (.tres)
assets/characters/
  skins/default/                   piezas provisorias (skin por defecto)
  skins/gerald/                    skin generada con Copilot (+ skin.json)
  rig/rig_animations.tres          animaciones del esqueleto (generadas)
  matias_temp/                     animaciones temporales de Matías
scripts/
  player.gd                        movimiento, salto, gravedad y ataques
  attack_data.gd                   definición de un ataque (AttackData)
  main.gd                          reaparición al caer del escenario
  visuals/character_visual.gd      interfaz común de los visuales
  visuals/rig_visual.gd            personaje por piezas y carga de skins
  visuals/sprite_visual.gd         personaje cuadro a cuadro
tools/                             scripts de Python que generan piezas, plantilla y animaciones
docs/
  skin_spec.md                     especificación de las piezas
  skin_template.png                plantilla visual de las piezas
  prompt_copilot.md                prompt para generar las piezas con IA
tmp_assets/                        imágenes de origen (hojas de referencia y de piezas)
```

## Cambiar de personaje o de skin

- **Personaje:** en `main.tscn`, el nodo `Player` es una instancia de `player.tscn`. Para probar a Matías, reemplázalo por `player_matias_temp.tscn`. En la práctica, el jugador solo cambia su `visual_scene` y sus ataques.
- **Skin:** en `main.tscn`, propiedad `skin_path` del nodo `Player` (ahora `res://assets/characters/skins/gerald`), o por código con `visual.load_skin("user://skins/mi_skin")`.

## Capas de física

| Capa | Nombre      | Uso                                             |
|------|-------------|-------------------------------------------------|
| 1    | world       | suelo y plataformas                             |
| 2    | players     | cuerpo físico de los personajes                 |
| 3    | hitboxes    | cajas de golpe de los ataques (buscan hurtboxes)|
| 4    | hurtboxes   | zona donde un personaje puede recibir golpes    |

## Ideas de diseño a futuro

- Cuatro tamaños de personaje predefinidos, cada uno con su caja de colisión y su especificación de piezas.
- Ataques, armas y poderes diseñados por el equipo para mantener el equilibrio.
- Cosméticos creados por los jugadores como skins de piezas.
