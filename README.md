# 🚀 Aseprite 2.5D Animation Pipeline

Tres scripts de **Lua puro para Aseprite** (sin dependencias, sin compilar nada) para animar sprites y prepararlos para iluminación dinámica en motores como Godot, Unity o Defold.

- 🧬 **Skeleton2Animation** — anima por huesos (esqueleto jerárquico).
- 🔄 **Tween** — interpola movimiento, giro, escala y color entre poses.
- 💡 **NormalMap** — genera mapas de normales para luces 2.5D.

> 💡 **Nota:** no pretenden reemplazar a las extensiones de pago. Son gratuitos y funcionan; la interfaz es funcional, no bonita.

---

## ✅ Requisitos

- **Aseprite** con soporte de scripts (menú `Archivo > Scripts`).
- **Tween** y **NormalMap** trabajan **solo en modo de color RGB** (`Sprite > Modo de color > RGB`).
- Los `.lua` deben guardarse en **UTF-8 sin BOM** (Aseprite no ejecuta scripts con BOM).

---

## ⚙️ Instalación

1. Descarga los `.lua` de la carpeta [`scripts/`](scripts/).
2. En Aseprite: **Archivo > Scripts > Abrir carpeta de scripts**.
3. Copia los archivos en esa carpeta.
4. Vuelve a **Archivo > Scripts** y pulsa **Recargar scripts** (o `F5`). Ejecuta cada uno desde ese mismo menú.

---

## 🧬 1. Skeleton2Animation.lua — Animación por huesos

Monta un esqueleto de huesos padre-hijo sobre tu sprite, vincula cada capa (una extremidad) a un hueso y anima moviendo/rotando huesos. Guarda una **pose base** para volver a ella y exporta las poses a **JSON**.

<!-- 🎬 GIF de demostración -->
> _(GIF pendiente)_

**Cómo se usa:**

1. Abre tu sprite con cada parte del personaje en **una capa distinta** (p. ej. `Cabeza`, `Cuerpo`, `PataFD`…) y ejecuta el script. Al abrirlo **no** modifica el sprite hasta que hagas algo.
2. Crea los huesos:
   - **Autodetectar huesos**: crea un hueso por cada capa de imagen, colgando todos de la raíz.
   - O manualmente con el nombre + botón **`+`** / **`-`**.
3. Define la jerarquía con **Reparentar** (elige qué hueso cuelga de cuál).
4. Vincula la piel al hueso (el match es por **nombre de capa = nombre de hueso**):
   - **Vincular capa**: asocia la capa activa entera al hueso seleccionado.
   - **Vincular piel**: recorta la selección activa y crea la piel del hueso.
   - (Autodetectar ya deja todo vinculado).
5. Anima:
   - **Mover nodo**: mueve el hueso y su piel. **Mover solo hueso**: solo el pivote.
   - Slider de **rotación** (con / sin hijos). Al rotar, el esqueleto se oculta para ver bien la piel; reaparece al soltar o cambiar de modo.
6. **Crear fotograma**: copia la pose actual a un fotograma nuevo y devuelve el fotograma 1 a la **pose base** para componer el siguiente.
7. **Restaurar pose base**: devuelve todo al reposo (útil si el deshacer se lía).
8. **Guardar** / **Cargar**: exporta o importa la pose en JSON. Al cargar, revincula automáticamente cada hueso con su capa homónima.

**Datos:** la pose se guarda en un `.json` con la jerarquía, posiciones y la pose base. La imagen no se guarda ahí: se recupera de las capas por nombre al cargar.

**Origen:** basado en el [Skeleton2Animation de **aimarzhang**](https://aimarzhang.itch.io/skeleton2animation-in-aseprite/devlog/943953/skeleton2animation-in-aseprite), muy modificado y adaptado (corrigiendo bastantes bugs por el camino).

---

## 🔄 2. Tween.lua — Interpolación entre poses

Genera los fotogramas intermedios entre dos poses, o crea el movimiento a partir de una sola. Interpola posición, giro, escala y color, con curvas de recorrido y easing.

<!-- 🎬 GIF de demostración -->
> _(GIF pendiente)_

**Cómo se usa:**

1. Selecciona la capa a animar (modo RGB) y ejecuta el script.
2. Elige el **método**:
   - **Rellenar entre dos poses que ya he dibujado**: indica el fotograma inicial (pose A) y final (pose B); el script calcula el hueco.
   - **Crear el movimiento desde una sola pose**: partes de una pose y defines los cambios con valores relativos (posición, giro, escala, pivote).
   - **Actualizar un tween ya generado**: recalcula usando los parámetros guardados en la capa.
3. Elige la **acción**: mover, fundir (fade) o ambas.
4. Ajusta **cadencia** (nº de fotogramas, duración, easing) y, si quieres, el **recorrido** (recta / arco / onda / rebote), el **squash & stretch** y el **cambio de color** (interpolado en HSL).
5. **Aceptar**: genera los fotogramas.

**Recálculo en caliente:** los parámetros se guardan en los metadatos de la capa (`layer.properties.tween`), así que puedes reejecutar con **Actualizar** sin volver a configurarlo todo.

**Origen:** desarrollo propio, inspirado en **The Tween Machine** (CarbsCode) y **Tweencel** (devkidd).

---

## 💡 3. NormalMap.lua — Mapas de normales

Genera un mapa de normales a partir del contorno alfa del dibujo, para que tus sprites reaccionen a luces dinámicas 2.5D en el motor.

<!-- 🎬 GIF de demostración -->
> _(GIF pendiente)_

**Cómo se usa:**

1. Con el sprite en modo RGB, ejecuta el script.
2. Elige el **alcance**:
   - **Capas**: activa / seleccionadas (rango) / todas.
   - **Fotogramas**: actual / todos.
3. Ajusta la **intensidad del relieve** (1–63; 32 por defecto).
4. **Aceptar**: por cada capa de origen crea/reutiliza una capa **`<nombre>_NormalGenerated`** con el mapa de normales.

**Origen:** basado en el [gist de **ruccho**](https://gist.github.com/ruccho/2d1eb4aea3dfa55690c2ddc4419172ff), modificado y adaptado.

---

## 🗺️ Flujo recomendado (pipeline 2.5D)

1. **Estructura y anima** con `Skeleton2Animation` (o dibuja poses a mano).
2. **Rellena/automatiza** los fotogramas intermedios con `Tween`.
3. **Ilumina**: pasa `NormalMap` sobre los fotogramas para generar sus normales.
4. **Exporta** la hoja de color y la de normales a tu motor y activa las luces 2D dinámicas.

---

## 📄 Licencia

Proyecto bajo **Licencia MIT** ([LICENSE](LICENSE)): úsalo, modifícalo y distribúyelo gratis, en proyectos personales o comerciales.
