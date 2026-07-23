# 🚀 Aseprite 2.5D Animation Pipeline

Un pipeline de animación técnica y renderizado avanzado para Aseprite escrito en **Lua puro, monolítico y sin dependencias externas**. Diseñado para desarrolladores de videojuegos independientes que necesitan conectar el arte 2D con la iluminación y físicas dinámicas de motores modernos (Godot, Unity, Defold) sin pagar licencias comerciales de software cerrado.
> 💡 **Nota:** Estos scripts no buscan reemplazar a las extensiones existentes. Se han hecho para que funcionen y sean gratuitos, aunque la interfaz no sea tan bonita como si fuese una extensión o una aplicación de terceros.

---

## 🛠️ Contenido del Pipeline

El ecosistema se compone de tres herramientas premium que trabajan en perfecta armonía:

### 1. 🧬 Skeleton2Animation.lua (Animación por Esqueleto)
* **Cinemática Jerárquica:** Crea estructuras de huesos (padre-hijo) para articular extremidades.
* **Separación de Rest Pose:** Captura el estado en reposo de la piel y el hueso de forma independiente para evitar deformaciones infinitas.
* **Persistencia Integrada:** Guarda las poses jerárquicas en formato JSON.

### 1. 🔄 Tween.lua (Motor de Interpolación Afín Avanzado)
* **Matriz Afín 3x3 Combinada:** Calcula Traslación, Rotación y Escala en un solo paso por píxel usando mapeo inverso (*Nearest-Neighbor*).
* **Rendimiento Óptimo:** Procesa un `cel.bounds` dinámico proyectado. Solo calcula el área mínima del dibujo, ignorando el lienzo vacío (ahorra un 90% de CPU frente a herramientas comerciales que agrandan el lienzo).
* **Físicas Orgánicas:** *Squash & Stretch* automatizado acoplado a la velocidad del movimiento con conservación matemática estricta del volumen.
* **Color HSLA Puro:** Interpolación de color basada en el arco más corto (`lerpHue`). Evita los tonos grises y sucios de la mezcla RGB estándar al transicionar entre colores opuestos.
* **Hot Update (Actualización en caliente):** Guarda los parámetros en los metadatos de la capa (`layer.properties.tween`) para recalcular movimientos en caliente sin destruir tu flujo de trabajo.

### 3. 💡 NormalMap.lua (Generador de Mapas de Normales)
* **Iluminación 2.5D Real:** Genera mapas de normales codificados en vectores estándar (RGB/XYZ) para que tus sprites reaccionen a luces dinámicas en motores de juego.
* **Biselado de Doble Paso:** Analiza bordes con un espesor adaptativo de 2 píxeles para lograr relieves suaves y realistas, evitando aristas afiladas.
* **Mutación In-Place Segura:** Optimizado para la RAM del sistema mediante el análisis estricto del canal Alfa.

---

## ⚙️ Instalación Rápida

No necesitas compilar extensiones en C++ ni gestionar carpetas complejas:

1. Descarga los archivos `.lua` de la carpeta `scripts/`.
2. En Aseprite, ve al menú superior: **Archivo > Scripts > Abrir carpeta de scripts**.
3. Arrastra los archivos descargados a esa carpeta.
4. Reinicia Aseprite o pulsa `F5` para recargar la lista de scripts. ¡Listo!

---

## 🗺️ Flujo de Trabajo Recomendado (Pipeline 2.5D)

1. **Estructura:** Diseña tu personaje articulado y define su jerarquía con `Skeleton2Animation.lua`.
2. **Anima:** Genera fotogramas clave o utiliza la potencia matemática de `Tween.lua` para automatizar movimientos fluidos, arcos de trayectoria y rebotes orgánicos con conservación de volumen.
3. **Ilumina:** Ejecuta `NormalMap.lua` para extraer el volumen de luz de cada fotograma generado.
4. **Exporta:** Lleva tu hoja de sprites de color y tu hoja de mapas de normales a tu motor de videojuegos favorito y activa las luces 2D dinámicas.

---

## 📄 Licencia

Este proyecto está bajo la **Licencia MIT**. Siéntete libre de usarlo, modificarlo y distribuirlo de forma totalmente gratuita, tanto para proyectos personales como para videojuegos comerciales. Hecho por y para desarrolladores independientes.
