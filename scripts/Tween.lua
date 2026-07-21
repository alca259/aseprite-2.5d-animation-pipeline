--- Tween.lua
--- Motor unificado de interpolacion (tween) para Aseprite.
---
--- Combina dos filosofias de trabajo:
---   * Fotogramas clave: dibujas la pose A y la
---     pose B a mano y el script deduce el movimiento/escala y rellena el hueco.
---   * Parametrico: partes de una sola pose y defines los
---     cambios con valores relativos, con trayectorias avanzadas y recalculo
---     en caliente guardando los parametros en los metadatos de la capa.
---
--- Los 5 pilares tecnicos:
---   1. Transformacion afin combinada (Traslacion x Rotacion x Escala) por
---      mapeo inverso, en una sola operacion matricial por pixel.
---   2. Aislamiento sobre cel.bounds (solo se procesa la caja del dibujo, no
---      el lienzo completo).
---   3. Squash & stretch: la escala reacciona a la velocidad conservando el
---      volumen.
---   4. Interpolacion de color en espacio HSL/HSLA (transiciones limpias).
---   5. Trayectorias no lineales (arco, onda, rebote) desacopladas del tiempo.
---
--- Codificacion: UTF-8 SIN BOM (Aseprite no ejecuta scripts con BOM).
--- MIT license (http://opensource.org/licenses/MIT)

-- Diccionario de traducciones integradas (en = idioma fuente / fallback).
local LOCALIZATION = {
    en = {
        title = "Tween between poses",
        sep_workflow = "How to create the animation",
        method = "Method",
        wf_keyframe = "Fill between two poses I already drew",
        wf_param = "Create the motion from a single pose",
        wf_update = "Update an existing tween",
        update_yes = "It will be recalculated with the saved values.",
        update_no = "This layer has no saved tween.",
        sep_mode = "What to do between the two poses",
        action = "Action",
        mode_move = "Move (slide / rotate / scale)",
        mode_fade = "Fade one drawing into another",
        mode_both = "Move and fade at once",
        manual_angle = "Extra rotation in degrees",
        sep_smooth = "Timing and smoothing",
        smooth = "Smoothing",
        ease_linear = "Constant",
        ease_smooth = "Smooth",
        ease_in = "Slow start",
        ease_out = "Smooth stop",
        ease_inout = "Slow at start and end",
        frames_create = "Frames to create",
        duration = "Duration of each one (ms)",
        sep_frames = "Reference frames",
        frame_a = "Start frame (pose A)",
        frame_b = "End frame (pose B)",
        sep_transform = "Move, rotate and scale",
        pos_x = "Position X (from / to)",
        pos_y = "Position Y (from / to)",
        angle = "Rotation in degrees (from / to)",
        scale_x = "Size X % (from / to)",
        scale_y = "Size Y % (from / to)",
        pivot = "Rotation center X / Y",
        sep_path = "Path shape",
        path = "Path",
        path_straight = "Straight",
        path_arc = "Arc (jump)",
        path_wave = "Wave",
        path_bounce = "Bounce",
        amplitude = "Curve height (px)",
        frequency = "Number of waves",
        sep_squash = "Stretch and squash while moving",
        squash = "Intensity (0 = off)",
        sep_color = "Color change",
        tint = "Apply color change",
        tint_from = "Start color",
        tint_to = "End color",
        sep_confirm = "Confirm",
        accept = "OK",
        cancel = "Cancel",
        err_no_sprite = "There is no active sprite.",
        err_rgb = "This script only works with RGB color mode.",
        err_layer = "Select a normal layer (not a group).",
        err_no_meta = "The active layer has no saved tween to update.",
        err_len = "'Frames to create' must be at least 1.",
        err_duration = "'Duration of each one' must be at least 1 ms.",
        err_frame_range = "Frame numbers are out of range (1..%d).",
        err_same_frame = "Pose A and pose B must be different frames.",
        err_both_cels = "The active layer must have an image on both frames (A and B).",
        err_from_range = "The start frame is out of range (1..%d).",
        err_from_cel = "The active layer has no image on frame %d.",
        err_src_layer = "Source layer '%s' not found.",
        err_src_cel = "The source layer has no image on frame %d."
    },
    es = {
        title = "Animar entre poses (Tween)",
        sep_workflow = "Cómo quieres crear la animación",
        method = "Método",
        wf_keyframe = "Rellenar entre dos poses que ya he dibujado",
        wf_param = "Crear el movimiento desde una sola pose",
        wf_update = "Actualizar un tween ya generado",
        update_yes = "Se recalculará con los valores guardados.",
        update_no = "Esta capa no tiene un tween guardado.",
        sep_mode = "Qué quieres hacer entre las dos poses",
        action = "Acción",
        mode_move = "Mover (deslizar / girar / escalar)",
        mode_fade = "Fundir un dibujo en otro",
        mode_both = "Mover y fundir a la vez",
        manual_angle = "Giro extra en grados",
        sep_smooth = "Cadencia y suavizado",
        smooth = "Suavizado",
        ease_linear = "Constante",
        ease_smooth = "Suave",
        ease_in = "Arranque lento",
        ease_out = "Frenada suave",
        ease_inout = "Lento al inicio y al final",
        frames_create = "Fotogramas a crear",
        duration = "Duración de cada uno (ms)",
        sep_frames = "Fotogramas de referencia",
        frame_a = "Fotograma inicial (pose A)",
        frame_b = "Fotograma final (pose B)",
        sep_transform = "Movimiento, giro y tamaño",
        pos_x = "Posición X (desde / hasta)",
        pos_y = "Posición Y (desde / hasta)",
        angle = "Giro en grados (desde / hasta)",
        scale_x = "Tamaño X % (desde / hasta)",
        scale_y = "Tamaño Y % (desde / hasta)",
        pivot = "Centro de giro X / Y",
        sep_path = "Forma del recorrido",
        path = "Recorrido",
        path_straight = "Recta",
        path_arc = "Arco (salto)",
        path_wave = "Onda",
        path_bounce = "Rebote",
        amplitude = "Altura de la curva (px)",
        frequency = "Número de ondas",
        sep_squash = "Estirar y encoger al moverse",
        squash = "Intensidad (0 = desactivado)",
        sep_color = "Cambio de color",
        tint = "Aplicar cambio de color",
        tint_from = "Color inicial",
        tint_to = "Color final",
        sep_confirm = "Confirmar",
        accept = "Aceptar",
        cancel = "Cancelar",
        err_no_sprite = "No hay ningún sprite abierto.",
        err_rgb = "Este script solo funciona en modo de color RGB.",
        err_layer = "Selecciona una capa normal (no un grupo).",
        err_no_meta = "La capa activa no tiene un tween guardado que actualizar.",
        err_len = "'Fotogramas a crear' debe ser al menos 1.",
        err_duration = "'Duración de cada uno' debe ser al menos 1 ms.",
        err_frame_range = "Los números de fotograma están fuera de rango (1..%d).",
        err_same_frame = "La pose A y la pose B deben ser fotogramas distintos.",
        err_both_cels = "La capa activa debe tener dibujo en ambos fotogramas (A y B).",
        err_from_range = "El fotograma inicial está fuera de rango (1..%d).",
        err_from_cel = "La capa activa no tiene dibujo en el fotograma %d.",
        err_src_layer = "No encuentro la capa origen '%s'.",
        err_src_cel = "La capa origen no tiene dibujo en el fotograma %d."
    }
}

-- Detección del idioma de Aseprite (best-effort; fallback a inglés).
-- Normaliza "es-ES"/"es_ES" -> "es".
local userLang = "en"
local ok, pref = pcall(function() return app.preferences.general.language end)
if ok and type(pref) == "string" and pref ~= "" then
    userLang = pref:lower():gsub("[_-].*$", "")
end
if not LOCALIZATION[userLang] then userLang = "en" end
local L = LOCALIZATION[userLang]

-- Nucleo matematico compartido

local function round(num)
    if num >= 0 then
        return math.floor(num + .5)
    else
        return math.ceil(num - .5)
    end
end

---@param from number
---@param to number
---@param t number
---@return number
local function lerp(from, to, t)
    return (to - from) * t + from
end

local function lerpPoint(fx, fy, tx, ty, t)
    return lerp(fx, tx, t), lerp(fy, ty, t)
end

local function cubicBezier(x1, y1, x2, y2, t)
    local p1x, p1y = lerpPoint(0, 0, x1, y1, t)
    local p2x, p2y = lerpPoint(x1, y1, x2, y2, t)
    local p3x, p3y = lerpPoint(x2, y2, 1, 1, t)

    local a1x, a1y = lerpPoint(p1x, p1y, p2x, p2y, t)
    local a2x, a2y = lerpPoint(p2x, p2y, p3x, p3y, t)

    return lerpPoint(a1x, a1y, a2x, a2y, t)
end

local function cubicInterpolate(x1, y1, x2, y2, t)
    local _, interpolate = cubicBezier(x1, y1, x2, y2, t)
    return interpolate
end

-- Suavizado: clave interna estable (se guarda en metadatos) + etiqueta
-- traducida (solo para mostrar). El combobox muestra la etiqueta; la logica y
-- los metadatos usan la clave, asi que sobreviven a un cambio de idioma.
local EASING = {
    { key = "linear", label = L.ease_linear, func = function(t) return t end },
    { key = "smooth", label = L.ease_smooth, func = function(t) return cubicInterpolate(0.25, 0.1, 0.25, 1.0, t) end },
    { key = "in",     label = L.ease_in,     func = function(t) return cubicInterpolate(0.42, 0.0, 1.0, 1.0, t) end },
    { key = "out",    label = L.ease_out,    func = function(t) return cubicInterpolate(0.0, 0.0, 0.58, 1.0, t) end },
    { key = "inout",  label = L.ease_inout,  func = function(t) return cubicInterpolate(0.42, 0.0, 0.58, 1.0, t) end }
}
local EASING_OPTIONS = {}
local EASING_LABEL2KEY = {}
local EASING_FUNC = {}
for _, e in ipairs(EASING) do
    EASING_OPTIONS[#EASING_OPTIONS + 1] = e.label
    EASING_LABEL2KEY[e.label] = e.key
    EASING_FUNC[e.key] = e.func
end
local EASING_DEFAULT_LABEL = EASING[1].label

---Devuelve la funcion de suavizado por su clave interna (fallback: lineal).
local function easingByKey(key)
    return EASING_FUNC[key] or function(t) return t end
end

-- Matrices afines 2x3  (fila implicita [0 0 1])
-- m = { a, b, c, d, e, f }  ->  x' = a*x + b*y + c ; y' = d*x + e*y + f

local function matMul(m1, m2)
    return {
        m1[1] * m2[1] + m1[2] * m2[4],
        m1[1] * m2[2] + m1[2] * m2[5],
        m1[1] * m2[3] + m1[2] * m2[6] + m1[3],
        m1[4] * m2[1] + m1[5] * m2[4],
        m1[4] * m2[2] + m1[5] * m2[5],
        m1[4] * m2[3] + m1[5] * m2[6] + m1[6]
    }
end

local function matTranslate(tx, ty)
    return { 1, 0, tx, 0, 1, ty }
end

local function matRotate(rad)
    local c = math.cos(rad)
    local s = math.sin(rad)
    return { c, -s, 0, s, c, 0 }
end

local function matScale(sx, sy)
    return { sx, 0, 0, 0, sy, 0 }
end

local function matApply(m, x, y)
    return m[1] * x + m[2] * y + m[3],
           m[4] * x + m[5] * y + m[6]
end

local function matInvert(m)
    local det = m[1] * m[5] - m[2] * m[4]
    if det == 0 then det = 1e-9 end
    local ia = m[5] / det
    local ib = -m[2] / det
    local id = -m[4] / det
    local ie = m[1] / det
    local ic = -(ia * m[3] + ib * m[6])
    local iff = -(id * m[3] + ie * m[6])
    return { ia, ib, ic, id, ie, iff }
end

---Matriz afin completa alrededor de un pivote (coords del sprite):
---M = T(pivot+trans) * R(angulo) * S(escala) * T(-pivot)
local function buildMatrix(px, py, tx, ty, angleDeg, scaleX, scaleY)
    if math.abs(scaleX) < 0.001 then scaleX = 0.001 end
    if math.abs(scaleY) < 0.001 then scaleY = 0.001 end
    local rad = angleDeg * math.pi / 180
    local m = matTranslate(px + tx, py + ty)
    m = matMul(m, matRotate(rad))
    m = matMul(m, matScale(scaleX, scaleY))
    m = matMul(m, matTranslate(-px, -py))
    return m
end

-- Color: RGB <-> HSL y mezcla por tono mas corto

local function rgbToHsl(r, g, b)
    r, g, b = r / 255, g / 255, b / 255
    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local h, s = 0, 0
    local l = (max + min) / 2
    if max ~= min then
        local d = max - min
        s = l > 0.5 and d / (2 - max - min) or d / (max + min)
        if max == r then
            h = (g - b) / d + (g < b and 6 or 0)
        elseif max == g then
            h = (b - r) / d + 2
        else
            h = (r - g) / d + 4
        end
        h = h / 6
    end
    return h, s, l
end

local function hue2rgb(p, q, t)
    if t < 0 then t = t + 1 end
    if t > 1 then t = t - 1 end
    if t < 1 / 6 then return p + (q - p) * 6 * t end
    if t < 1 / 2 then return q end
    if t < 2 / 3 then return p + (q - p) * (2 / 3 - t) * 6 end
    return p
end

local function hslToRgb(h, s, l)
    local r, g, b
    if s == 0 then
        r, g, b = l, l, l
    else
        local q = l < 0.5 and l * (1 + s) or l + s - l * s
        local p = 2 * l - q
        r = hue2rgb(p, q, h + 1 / 3)
        g = hue2rgb(p, q, h)
        b = hue2rgb(p, q, h - 1 / 3)
    end
    return round(r * 255), round(g * 255), round(b * 255)
end

---Interpola el tono (0..1) por el arco mas corto de la rueda de color.
local function lerpHue(h1, h2, t)
    local d = h2 - h1
    if d > 0.5 then
        d = d - 1
    elseif d < -0.5 then
        d = d + 1
    end
    local h = h1 + d * t
    if h < 0 then h = h + 1 elseif h > 1 then h = h - 1 end
    return h
end

-- Trayectorias no lineales

-- Trayectoria: clave interna estable (metadatos) + etiqueta traducida.
local PATH = {
    { key = "straight", label = L.path_straight },
    { key = "arc",      label = L.path_arc },
    { key = "wave",     label = L.path_wave },
    { key = "bounce",   label = L.path_bounce }
}
local PATH_OPTIONS = {}
local PATH_LABEL2KEY = {}
for _, p in ipairs(PATH) do
    PATH_OPTIONS[#PATH_OPTIONS + 1] = p.label
    PATH_LABEL2KEY[p.label] = p.key
end
local PATH_DEFAULT_LABEL = PATH[1].label

---Desplazamiento normalizado (-1..1) del recorrido en funcion de t (0..1).
local function pathOffset(pathType, t, freq)
    if pathType == "arc" then
        return math.sin(t * math.pi)
    elseif pathType == "wave" then
        return math.sin(t * 2 * math.pi * freq)
    elseif pathType == "bounce" then
        return math.abs(math.sin(t * math.pi * freq)) * (1 - t)
    end
    return 0
end

-- Aislamiento y rasterizado por cel.bounds

local pc = app.pixelColor

---Lee un pixel de una imagen devolviendo 0 (transparente) si esta fuera.
local function safeGetPixel(img, x, y, w, h)
    if x >= 0 and x < w and y >= 0 and y < h then
        return img:getPixel(x, y)
    end
    return 0
end

---Rasteriza una imagen origen a traves de una matriz afin usando mapeo
---inverso nearest-neighbor. Solo procesa la caja transformada (no el lienzo).
---@return Image outImg, integer outX, integer outY
local function rasterizeAffine(srcImg, srcX, srcY, m, tintR, tintG, tintB)
    local w, h = srcImg.width, srcImg.height

    -- Caja destino: transformar las 4 esquinas (en coords del sprite).
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    local corners = { { 0, 0 }, { w, 0 }, { 0, h }, { w, h } }
    for _, corner in ipairs(corners) do
        local wx, wy = matApply(m, srcX + corner[1], srcY + corner[2])
        if wx < minX then minX = wx end
        if wy < minY then minY = wy end
        if wx > maxX then maxX = wx end
        if wy > maxY then maxY = wy end
    end

    -- +1 para incluir la ultima fila/columna: con nearest-neighbor el borde
    -- puede caer justo sobre un entero (o rozarlo por precision flotante) y
    -- perderse un pixel periferico. El margen extra queda transparente.
    local outX = math.floor(minX)
    local outY = math.floor(minY)
    local outW = math.max(1, math.ceil(maxX) - outX + 1)
    local outH = math.max(1, math.ceil(maxY) - outY + 1)

    local out = Image(outW, outH, ColorMode.RGB)
    out:clear()

    local minv = matInvert(m)
    local doTint = tintR ~= nil

    for oy = 0, outH - 1 do
        for ox = 0, outW - 1 do
            local sxw, syw = matApply(minv, outX + ox, outY + oy)
            -- Muestreo estandar de rejilla: el espacio local de origen es
            -- positivo, asi que floor(n + 0.5) es consistente en todo el rango.
            local lx = math.floor(sxw - srcX + 0.5)
            local ly = math.floor(syw - srcY + 0.5)
            if lx >= 0 and lx < w and ly >= 0 and ly < h then
                local p = srcImg:getPixel(lx, ly)
                if pc.rgbaA(p) > 0 then
                    if doTint then
                        local r = round(pc.rgbaR(p) * tintR / 255)
                        local g = round(pc.rgbaG(p) * tintG / 255)
                        local b = round(pc.rgbaB(p) * tintB / 255)
                        p = pc.rgba(r, g, b, pc.rgbaA(p))
                    end
                    out:drawPixel(ox, oy, p)
                end
            end
        end
    end

    return out, outX, outY
end

---Mezcla (crossfade) dos imagenes posicionadas en espacio HSL, sobre la union
---de sus cajas. t = 0 => A, t = 1 => B.
---@return Image outImg, integer outX, integer outY
local function blendPositioned(imgA, ax, ay, imgB, bx, by, t)
    local aw, ah = imgA.width, imgA.height
    local bw, bh = imgB.width, imgB.height

    local minX = math.min(ax, bx)
    local minY = math.min(ay, by)
    local maxX = math.max(ax + aw, bx + bw)
    local maxY = math.max(ay + ah, by + bh)
    local outW = math.max(1, maxX - minX)
    local outH = math.max(1, maxY - minY)

    local out = Image(outW, outH, ColorMode.RGB)
    out:clear()

    for oy = 0, outH - 1 do
        for ox = 0, outW - 1 do
            local wx = minX + ox
            local wy = minY + oy
            local pa = safeGetPixel(imgA, wx - ax, wy - ay, aw, ah)
            local pb = safeGetPixel(imgB, wx - bx, wy - by, bw, bh)

            local aA = pc.rgbaA(pa)
            local aB = pc.rgbaA(pb)
            local outA = round(aA * (1 - t) + aB * t)

            if outA > 0 then
                local wa = aA * (1 - t)
                local wb = aB * t
                local wsum = wa + wb
                local eff = wsum > 0 and (wb / wsum) or t

                local hA, sA, lA = rgbToHsl(pc.rgbaR(pa), pc.rgbaG(pa), pc.rgbaB(pa))
                local hB, sB, lB = rgbToHsl(pc.rgbaR(pb), pc.rgbaG(pb), pc.rgbaB(pb))
                -- Si un lado no aporta color, usa el tono del otro (evita gris/negro).
                if aA == 0 then hA, sA, lA = hB, sB, lB end
                if aB == 0 then hB, sB, lB = hA, sA, lA end

                local h = lerpHue(hA, hB, eff)
                local s = lerp(sA, sB, eff)
                local l = lerp(lA, lB, eff)
                local r, g, b = hslToRgb(h, s, l)
                out:drawPixel(ox, oy, pc.rgba(r, g, b, outA))
            end
        end
    end

    return out, minX, minY
end

--Generacion de fotogramas (usa cfg + imagenes)

-- Accion/modo: clave interna estable (metadatos) + etiqueta traducida.
local MODE = {
    { key = "move", label = L.mode_move },
    { key = "fade", label = L.mode_fade },
    { key = "both", label = L.mode_both }
}
local MODE_OPTIONS = {}
local MODE_LABEL2KEY = {}
for _, m in ipairs(MODE) do
    MODE_OPTIONS[#MODE_OPTIONS + 1] = m.label
    MODE_LABEL2KEY[m.label] = m.key
end
local MODE_DEFAULT_LABEL = MODE[3].label

---Precalcula, para cada fotograma i (1..len), la posicion (con trayectoria) y
---los factores de estirado/encogido (squash & stretch, conservando volumen).
---@return table posiciones, table estirados, function easing
local function precompute(cfg)
    local easing = easingByKey(cfg.funcName)

    -- Direccion perpendicular al desplazamiento para el offset de trayectoria.
    local dirX = cfg.toTX - cfg.fromTX
    local dirY = cfg.toTY - cfg.fromTY
    local dlen = math.sqrt(dirX * dirX + dirY * dirY)
    local perpX, perpY
    if dlen > 0.0001 then
        perpX, perpY = -dirY / dlen, dirX / dlen
    else
        perpX, perpY = 0, -1 -- sin movimiento: la trayectoria actua hacia arriba
    end

    local positions = {}
    for i = 1, cfg.len do
        local t = easing(i / (cfg.len + 1))
        local off = cfg.amplitude * pathOffset(cfg.pathType, t, cfg.frequency)
        local tx = lerp(cfg.fromTX, cfg.toTX, t) + perpX * off
        local ty = lerp(cfg.fromTY, cfg.toTY, t) + perpY * off
        positions[i] = { x = tx, y = ty }
    end

    -- Velocidad (diferencia central) y factor normalizado por la velocidad max.
    local stretch = {}
    for i = 1, cfg.len do
        stretch[i] = { x = 1, y = 1 }
    end

    if cfg.squashIntensity > 0 and cfg.len >= 2 then
        local vx, vy, speed = {}, {}, {}
        local maxSpeed = 0
        for i = 1, cfg.len do
            local prev = positions[math.max(1, i - 1)]
            local next = positions[math.min(cfg.len, i + 1)]
            vx[i] = next.x - prev.x
            vy[i] = next.y - prev.y
            speed[i] = math.sqrt(vx[i] * vx[i] + vy[i] * vy[i])
            if speed[i] > maxSpeed then maxSpeed = speed[i] end
        end
        if maxSpeed > 0 then
            for i = 1, cfg.len do
                local d = cfg.squashIntensity * (speed[i] / maxSpeed)
                local factor = 1 + d
                if math.abs(vy[i]) >= math.abs(vx[i]) then
                    stretch[i] = { x = 1 / factor, y = factor }
                else
                    stretch[i] = { x = factor, y = 1 / factor }
                end
            end
        end
    end

    return positions, stretch, easing
end

---Calcula la imagen de un fotograma intermedio.
---@return Image img, integer x, integer y
local function computeFrameImage(cfg, i, t, positions, stretch, srcImg, srcX, srcY, tgtImg, tgtX, tgtY)
    local doTransform = cfg.mode ~= "fade"
    local doBlend = (cfg.mode == "fade" or cfg.mode == "both") and tgtImg ~= nil

    local img, ox, oy = srcImg, srcX, srcY

    if doTransform then
        local pos = positions[i]
        local angle = lerp(cfg.fromAng, cfg.toAng, t)
        local scaleX = lerp(cfg.fromSX, cfg.toSX, t) * stretch[i].x
        local scaleY = lerp(cfg.fromSY, cfg.toSY, t) * stretch[i].y
        local m = buildMatrix(cfg.px, cfg.py, pos.x, pos.y, angle, scaleX, scaleY)

        local tr, tg, tb
        if cfg.enableTint then
            local hf, sf, lf = rgbToHsl(cfg.tintFR, cfg.tintFG, cfg.tintFB)
            local ht, st, lt = rgbToHsl(cfg.tintTR, cfg.tintTG, cfg.tintTB)
            tr, tg, tb = hslToRgb(lerpHue(hf, ht, t), lerp(sf, st, t), lerp(lf, lt, t))
        end

        img, ox, oy = rasterizeAffine(srcImg, srcX, srcY, m, tr, tg, tb)
    end

    if doBlend then
        img, ox, oy = blendPositioned(img, ox, oy, tgtImg, tgtX, tgtY, t)
    end

    return img, ox, oy
end

-- Metadatos (recalculo en caliente)

---Serializa cfg + origen a las propiedades persistentes de la capa tween.
local function saveMetadata(layer, cfg)
    layer.properties.tween = {
        version = 1,
        mode = cfg.mode,
        fromFrame = cfg.fromFrame,
        len = cfg.len,
        funcName = cfg.funcName,
        px = cfg.px, py = cfg.py,
        fromTX = cfg.fromTX, toTX = cfg.toTX,
        fromTY = cfg.fromTY, toTY = cfg.toTY,
        fromAng = cfg.fromAng, toAng = cfg.toAng,
        fromSX = cfg.fromSX, toSX = cfg.toSX,
        fromSY = cfg.fromSY, toSY = cfg.toSY,
        pathType = cfg.pathType,
        amplitude = cfg.amplitude,
        frequency = cfg.frequency,
        squashIntensity = cfg.squashIntensity,
        enableTint = cfg.enableTint,
        tintFR = cfg.tintFR, tintFG = cfg.tintFG, tintFB = cfg.tintFB,
        tintTR = cfg.tintTR, tintTG = cfg.tintTG, tintTB = cfg.tintTB,
        sourceLayerName = cfg.sourceLayerName
    }
end

---Reconstruye cfg desde las propiedades de una capa (o nil si no hay tween)
local function loadMetadata(layer)
    local t = layer.properties.tween
    if not t or t.version ~= 1 then return nil end
    local cfg = {}
    for k, v in pairs(t) do cfg[k] = v end
    return cfg
end

-- Dialogo

-- Flujo de trabajo: etiquetas traducidas (no se persisten, solo se comparan
-- dentro de la misma ejecucion, asi que basta con la etiqueta).
local WF_KEYFRAME = L.wf_keyframe
local WF_PARAM = L.wf_param
local WF_UPDATE = L.wf_update

---Muestra u oculta secciones segun el flujo de trabajo elegido.
local function updateVisibility(dlg, wf)
    local isKf = wf == WF_KEYFRAME
    local isParam = wf == WF_PARAM
    local isUpd = wf == WF_UPDATE
    local common = not isUpd

    -- Comunes a keyframe y parametrico (no en actualizar).
    for _, id in ipairs({ "func", "len", "duration", "pathType", "amplitude",
                          "frequency", "squashIntensity", "enableTint",
                          "tintFrom", "tintTo" }) do
        dlg:modify { id = id, visible = common }
    end

    -- Solo keyframe (poses A y B ya dibujadas).
    dlg:modify { id = "fromFrame", visible = isKf or isParam }
    dlg:modify { id = "toFrame", visible = isKf }
    dlg:modify { id = "mode", visible = isKf }
    dlg:modify { id = "manualAngle", visible = isKf }

    -- Solo parametrico (valores relativos + pivote).
    for _, id in ipairs({ "xFrom", "xTo", "yFrom", "yTo", "angleFrom", "angleTo",
                          "scaleFromX", "scaleToX", "scaleFromY", "scaleToY",
                          "pivotX", "pivotY" }) do
        dlg:modify { id = id, visible = isParam }
    end

    dlg:modify { id = "updateInfo", visible = isUpd }
end

---@param spr Sprite
---@param layer Layer
---@return table
local function handleDialogInput(spr, layer)
    local activeFrame = app.activeFrame and app.activeFrame.frameNumber or 1
    local lastFrame = #spr.frames

    -- Pivote por defecto: centro de la seleccion, del cel activo o del sprite.
    local px, py = spr.width / 2, spr.height / 2
    local sel = spr.selection
    if sel and not sel.isEmpty then
        px = sel.bounds.x + sel.bounds.width / 2
        py = sel.bounds.y + sel.bounds.height / 2
    else
        local cel = layer:cel(activeFrame)
        if cel then
            px = cel.bounds.x + cel.bounds.width / 2
            py = cel.bounds.y + cel.bounds.height / 2
        end
    end

    local hasMeta = loadMetadata(layer) ~= nil

    local dlg = Dialog { title = L.title }

    dlg:separator { id = "sepWorkflow", text = L.sep_workflow }
    dlg:combobox {
        id = "workflow",
        label = L.method,
        option = WF_PARAM,
        options = { WF_KEYFRAME, WF_PARAM, WF_UPDATE },
        onchange = function()
            updateVisibility(dlg, dlg.data.workflow)
        end
    }
    dlg:label {
        id = "updateInfo",
        label = "",
        text = hasMeta and L.update_yes or L.update_no
    }

    dlg:separator { id = "sepMode", text = L.sep_mode }
    dlg:combobox {
        id = "mode",
        label = L.action,
        option = MODE_DEFAULT_LABEL,
        options = MODE_OPTIONS
    }
    dlg:number { id = "manualAngle", label = L.manual_angle, text = "0" }

    dlg:separator { id = "sepSmooth", text = L.sep_smooth }
    dlg:combobox {
        id = "func",
        label = L.smooth,
        option = EASING_DEFAULT_LABEL,
        options = EASING_OPTIONS
    }
    dlg:number { id = "len", label = L.frames_create, text = "5" }
    dlg:number { id = "duration", label = L.duration, text = "100" }

    dlg:separator { id = "sepFrames", text = L.sep_frames }
    dlg:number { id = "fromFrame", label = L.frame_a, text = tostring(activeFrame) }
    dlg:number { id = "toFrame", label = L.frame_b, text = tostring(math.min(activeFrame + 1, lastFrame)) }

    dlg:separator { id = "sepTransform", text = L.sep_transform }
    dlg:number { id = "xFrom", label = L.pos_x, text = "0" }
    dlg:number { id = "xTo", text = "0" }
    dlg:number { id = "yFrom", label = L.pos_y, text = "0" }
    dlg:number { id = "yTo", text = "0" }
    dlg:number { id = "angleFrom", label = L.angle, text = "0" }
    dlg:number { id = "angleTo", text = "0" }
    dlg:number { id = "scaleFromX", label = L.scale_x, text = "100" }
    dlg:number { id = "scaleToX", text = "100" }
    dlg:number { id = "scaleFromY", label = L.scale_y, text = "100" }
    dlg:number { id = "scaleToY", text = "100" }
    dlg:number { id = "pivotX", label = L.pivot, text = tostring(round(px)) }
    dlg:number { id = "pivotY", text = tostring(round(py)) }

    dlg:separator { id = "sepPath", text = L.sep_path }
    dlg:combobox { id = "pathType", label = L.path, option = PATH_DEFAULT_LABEL, options = PATH_OPTIONS }
    dlg:number { id = "amplitude", label = L.amplitude, text = "0" }
    dlg:number { id = "frequency", label = L.frequency, text = "1" }

    dlg:separator { id = "sepSquash", text = L.sep_squash }
    dlg:number { id = "squashIntensity", label = L.squash, text = "0" }

    dlg:separator { id = "sepColor", text = L.sep_color }
    dlg:check { id = "enableTint", label = L.tint, selected = false }
    dlg:color { id = "tintFrom", label = L.tint_from, color = Color(255, 255, 255) }
    dlg:color { id = "tintTo", label = L.tint_to, color = Color(255, 255, 255) }

    dlg:separator { id = "sepConfirm", text = L.sep_confirm }
    dlg:button { id = "confirm", text = L.accept }
    dlg:button { id = "cancel", text = L.cancel }

    updateVisibility(dlg, WF_PARAM)
    dlg:show()
    return dlg.data
end

-- Construccion de cfg y ejecucion

---Centro de la caja de un cel (coords del sprite).
local function celCenter(cel)
    return cel.bounds.x + cel.bounds.width / 2,
           cel.bounds.y + cel.bounds.height / 2
end

---Construye cfg para el flujo parametrico (una sola pose).
local function cfgFromParametric(data, layer)
    return {
        mode = "move",
        fromFrame = round(data.fromFrame),
        len = round(data.len),
        durationMs = round(data.duration),
        funcName = EASING_LABEL2KEY[data.func] or "linear",
        px = data.pivotX, py = data.pivotY,
        fromTX = data.xFrom, toTX = data.xTo,
        fromTY = data.yFrom, toTY = data.yTo,
        fromAng = data.angleFrom, toAng = data.angleTo,
        fromSX = data.scaleFromX / 100, toSX = data.scaleToX / 100,
        fromSY = data.scaleFromY / 100, toSY = data.scaleToY / 100,
        pathType = PATH_LABEL2KEY[data.pathType] or "straight",
        amplitude = data.amplitude,
        frequency = data.frequency,
        squashIntensity = data.squashIntensity,
        enableTint = data.enableTint,
        tintFR = data.tintFrom.red, tintFG = data.tintFrom.green, tintFB = data.tintFrom.blue,
        tintTR = data.tintTo.red, tintTG = data.tintTo.green, tintTB = data.tintTo.blue,
        sourceLayerName = layer.name
    }
end

---Construye cfg para el flujo de fotogramas clave (deduce A -> B).
local function cfgFromKeyframe(data, layer, celA, celB)
    local cxA, cyA = celCenter(celA)
    local cxB, cyB = celCenter(celB)
    local bA, bB = celA.bounds, celB.bounds
    local scaleToX = bA.width > 0 and (bB.width / bA.width) or 1
    local scaleToY = bA.height > 0 and (bB.height / bA.height) or 1

    return {
        mode = MODE_LABEL2KEY[data.mode] or "both",
        fromFrame = round(data.fromFrame),
        len = round(data.len),
        durationMs = round(data.duration),
        funcName = EASING_LABEL2KEY[data.func] or "linear",
        px = cxA, py = cyA,
        fromTX = 0, toTX = cxB - cxA,
        fromTY = 0, toTY = cyB - cyA,
        fromAng = 0, toAng = data.manualAngle,
        fromSX = 1, toSX = scaleToX,
        fromSY = 1, toSY = scaleToY,
        pathType = PATH_LABEL2KEY[data.pathType] or "straight",
        amplitude = data.amplitude,
        frequency = data.frequency,
        squashIntensity = data.squashIntensity,
        enableTint = data.enableTint,
        tintFR = data.tintFrom.red, tintFG = data.tintFrom.green, tintFB = data.tintFrom.blue,
        tintTR = data.tintTo.red, tintTG = data.tintTo.green, tintTB = data.tintTo.blue,
        sourceLayerName = layer.name
    }
end

---Genera los fotogramas nuevos en una capa nueva (flujos keyframe/parametrico).
local function generateNew(spr, cfg, srcImg, srcX, srcY, tgtImg, tgtX, tgtY, layerName)
    local positions, stretch, easing = precompute(cfg)

    local animLayer = spr:newLayer()
    animLayer.name = layerName .. " - Tween"

    -- Se crean en orden secuencial: cada fotograma nuevo se inserta tras el
    -- anterior (insertAfter avanza), de modo que fromFrame+i recibe el valor t
    -- de i, sin depender del apilado inverso de newFrame.
    local insertAfter = cfg.fromFrame
    for i = 1, cfg.len do
        local t = easing(i / (cfg.len + 1))
        local img, ox, oy = computeFrameImage(cfg, i, t, positions, stretch,
            srcImg, srcX, srcY, tgtImg, tgtX, tgtY)

        local frame = spr:newFrame(spr.frames[insertAfter])
        frame.duration = cfg.durationMs / 1000
        local fn = frame.frameNumber
        if animLayer:cel(fn) then
            spr:deleteCel(animLayer, fn)
        end
        spr:newCel(animLayer, fn, img, Point(ox, oy))
        insertAfter = fn
    end

    return animLayer
end

---Recalcula in situ los fotogramas de un tween ya generado (Tweencel update).
local function regenerate(spr, cfg, animLayer)
    local srcLayer
    for _, l in ipairs(spr.layers) do
        if l.name == cfg.sourceLayerName then
            srcLayer = l
            break
        end
    end
    if not srcLayer then
        return app.alert(string.format(L.err_src_layer, tostring(cfg.sourceLayerName)))
    end

    local srcCel = srcLayer:cel(cfg.fromFrame)
    if not srcCel then
        return app.alert(string.format(L.err_src_cel, cfg.fromFrame))
    end

    local srcImg = srcCel.image
    local srcX, srcY = srcCel.position.x, srcCel.position.y
    local positions, stretch, easing = precompute(cfg)

    -- Los intermedios ocupan fromFrame+1 .. fromFrame+len (i = k).
    for k = 1, cfg.len do
        local fn = cfg.fromFrame + k
        if spr.frames[fn] then
            local t = easing(k / (cfg.len + 1))
            local img, ox, oy = computeFrameImage(cfg, k, t, positions, stretch,
                srcImg, srcX, srcY, nil, nil, nil)
            if animLayer:cel(fn) then
                spr:deleteCel(animLayer, fn)
            end
            spr:newCel(animLayer, fn, img, Point(ox, oy))
        end
    end
end

local function main()
    local spr = app.activeSprite
    if not spr then
        return app.alert(L.err_no_sprite)
    end
    if spr.colorMode ~= ColorMode.RGB then
        return app.alert(L.err_rgb)
    end

    local layer = app.activeLayer
    if not layer or layer.isGroup then
        return app.alert(L.err_layer)
    end

    local data = handleDialogInput(spr, layer)
    if not data.confirm then
        return
    end

    local lastFrame = #spr.frames

    -- Flujo: actualizar un tween ya generado (lee metadatos de la capa activa).
    if data.workflow == WF_UPDATE then
        local cfg = loadMetadata(layer)
        if not cfg then
            return app.alert(L.err_no_meta)
        end
        app.transaction(function()
            regenerate(spr, cfg, layer)
        end)
        app.refresh()
        return
    end

    -- Validaciones comunes
    local len = round(data.len)
    local durationMs = round(data.duration)
    if len < 1 then
        return app.alert(L.err_len)
    end
    if durationMs < 1 then
        return app.alert(L.err_duration)
    end

    if data.workflow == WF_KEYFRAME then
        local fromFrame = round(data.fromFrame)
        local toFrame = round(data.toFrame)
        if fromFrame < 1 or fromFrame > lastFrame or toFrame < 1 or toFrame > lastFrame then
            return app.alert(string.format(L.err_frame_range, lastFrame))
        end
        if fromFrame == toFrame then
            return app.alert(L.err_same_frame)
        end
        local celA = layer:cel(fromFrame)
        local celB = layer:cel(toFrame)
        if not celA or not celB then
            return app.alert(L.err_both_cels)
        end

        local cfg = cfgFromKeyframe(data, layer, celA, celB)
        app.transaction(function()
            generateNew(spr, cfg,
                celA.image, celA.position.x, celA.position.y,
                celB.image, celB.position.x, celB.position.y,
                layer.name)
        end)
        app.refresh()
        return
    end

    -- Flujo parametrico (una sola pose)
    local fromFrame = round(data.fromFrame)
    if fromFrame < 1 or fromFrame > lastFrame then
        return app.alert(string.format(L.err_from_range, lastFrame))
    end
    local cel = layer:cel(fromFrame)
    if not cel then
        return app.alert(string.format(L.err_from_cel, fromFrame))
    end


    local cfg = cfgFromParametric(data, layer)
    app.transaction(function()
        local animLayer = generateNew(spr, cfg,
            cel.image, cel.position.x, cel.position.y,
            nil, nil, nil, layer.name)
        saveMetadata(animLayer, cfg)
    end)
    app.refresh()
end

main()
