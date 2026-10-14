# Brawltopia

Juego de lucha 2D tipo *platform fighter*, inspirado en Super Smash Bros. y M.U.G.E.N., hecho con **Godot 4** y GDScript.

## Estado actual — Etapa 1: movimiento y plataformas

- Escenario con suelo y dos plataformas que se atraviesan desde abajo.
- Un jugador con movimiento horizontal, salto y gravedad.
- Si el jugador cae fuera del escenario, reaparece.

## Cómo abrirlo

1. Instala [Godot 4](https://godotengine.org/download) (versión 4.3 o superior, la estándar, no la de .NET).
2. En el Gestor de proyectos, pulsa **Importar** y elige `project.godot`.
3. Pulsa **F5** para jugar.

## Controles

| Acción   | Teclas                  |
|----------|-------------------------|
| Moverse  | A / D o ← / →           |
| Saltar   | W, ↑ o Espacio          |

## Estructura

```
project.godot                  configuración: ventana, controles, capas de física
scenes/
  main.tscn                    escena principal: escenario + jugador
  stages/test_stage.tscn       suelo y dos plataformas
  characters/player.tscn       cuerpo, colisión y dibujo del jugador
scripts/
  player.gd                    movimiento, salto y gravedad
  main.gd                      reaparición al caer del escenario
```

## Ideas de diseño a futuro

- Cuatro tamaños de personaje predefinidos, cada uno con su caja de colisión fija.
- Ataques, armas y poderes diseñados por el equipo para mantener el equilibrio.
- Personajes por piezas (cabeza, torso, brazos, piernas, arma): los jugadores pueden crear y cargar sus propios cosméticos.
