--- NormalMap.lua
--- Genera un mapa de normales (normal map) a partir del contorno alfa del
--- dibujo. Unifica en un solo panel todo, permitiendo elegir cualquier combinacion de
--- alcance (capas x fotogramas) y ajustar la intensidad del relieve
---
--- El resultado se escribe en una capa "<nombre>_NormalGenerated" por cada
--- capa de origen, reutilizandola si ya existe
---
--- Solo funciona en modo de color RGB
--- Originalmente este script era de alguien, pero no lo recuerdo y no lo encuentro en internet, así que lo he modificado y adaptado para mi uso personal

local SUFFIX = "_NormalGenerated"

-- Opciones del dialogo (cadenas visibles en castellano).
local LAYERS_ACTIVE = "Capa activa"
local LAYERS_RANGE = "Capas seleccionadas (rango)"
local LAYERS_ALL = "Todas las capas"

local FRAMES_CURRENT = "Fotograma actual"
local FRAMES_ALL = "Todos los fotogramas"

-- Algoritmo del mapa de normales

---Marca si una capa es una salida generada previamente (no se usa como origen).
local function isGeneratedLayer(layer)
    return layer.name:sub(-#SUFFIX) == SUFFIX
end

---Convierte una imagen RGB en su mapa de normales (mutando in situ el clon).
---Es correcto mutar mientras se leen vecinos: los pixeles opacos se reescriben
---manteniendo alfa 255 y los transparentes no se tocan, asi que la deteccion
---de borde por alfa sobre la misma imagen no se corrompe.
---@param img Image imagen clonada en modo RGB
---@param intensity integer factor de relieve (1..63)
local function processImage(img, intensity)
    local rgba = app.pixelColor.rgba
    local rgbaA = app.pixelColor.rgbaA

    for it in img:pixels() do
        local x = it.x
        local y = it.y
        local top = 2
        local bottom = 2
        local left = 2
        local right = 2

        if rgbaA(it()) < 255 then
            -- Pixel transparente: se ignora.
        else
            -- Arriba
            if y > 0 then
                local topPixel = img:getPixel(x, y - 1)
                if rgbaA(topPixel) < 255 then
                    top = 0
                elseif y > 1 then
                    topPixel = img:getPixel(x, y - 2)
                    if rgbaA(topPixel) < 255 then
                        top = 1
                    end
                else
                    top = 1
                end
            else
                top = 0
            end

            -- Abajo
            if y < img.height - 1 then
                local bottomPixel = img:getPixel(x, y + 1)
                if rgbaA(bottomPixel) < 255 then
                    bottom = 0
                elseif y < img.height - 2 then
                    bottomPixel = img:getPixel(x, y + 2)
                    if rgbaA(bottomPixel) < 255 then
                        bottom = 1
                    end
                else
                    bottom = 1
                end
            else
                bottom = 0
            end

            -- Izquierda
            if x > 0 then
                local leftPixel = img:getPixel(x - 1, y)
                if rgbaA(leftPixel) < 255 then
                    left = 0
                elseif x > 1 then
                    leftPixel = img:getPixel(x - 2, y)
                    if rgbaA(leftPixel) < 255 then
                        left = 1
                    end
                else
                    left = 1
                end
            else
                left = 0
            end

            -- Derecha
            if x < img.width - 1 then
                local rightPixel = img:getPixel(x + 1, y)
                if rgbaA(rightPixel) < 255 then
                    right = 0
                elseif x < img.width - 2 then
                    rightPixel = img:getPixel(x + 2, y)
                    if rgbaA(rightPixel) < 255 then
                        right = 1
                    end
                else
                    right = 1
                end
            else
                right = 0
            end

            -- Codificacion del normal en RGB.
            local x_digit = -right + left       -- -2 .. +2
            local y_digit = -top + bottom       -- -2 .. +2
            local z_digit = math.max(math.abs(x_digit), math.abs(y_digit))

            local nx = x_digit * intensity + 128
            local ny = y_digit * intensity + 128
            local nz = z_digit * -intensity + 255

            it(rgba(nx, ny, nz, 255))
        end
    end
end

-- Resolucion de capas y fotogramas segun el alcance elegido

---Aplana recursivamente las capas de imagen (salta grupos y salidas generadas)
local function collectImageLayers(layers, out)
    for _, layer in ipairs(layers) do
        if layer.isGroup then
            collectImageLayers(layer.layers, out)
        elseif not isGeneratedLayer(layer) then
            out[#out + 1] = layer
        end
    end
    return out
end

---Devuelve la lista de capas origen segun la opcion del dialogo
local function resolveLayers(spr, layersOption)
    if layersOption == LAYERS_ALL then
        return collectImageLayers(spr.layers, {})
    elseif layersOption == LAYERS_RANGE then
        local result = {}
        for _, layer in ipairs(app.range.layers) do
            if not layer.isGroup and not isGeneratedLayer(layer) then
                result[#result + 1] = layer
            end
        end
        if #result > 0 then
            return result
        end
        -- Sin seleccion de rango: caer a la capa activa
    end

    -- LAYERS_ACTIVE (o fallback del rango vacio)
    local active = app.activeLayer
    if active and not active.isGroup and not isGeneratedLayer(active) then
        return { active }
    end
    return {}
end

---Devuelve la lista de numeros de fotograma segun la opcion del dialogo
local function resolveFrames(spr, framesOption)
    if framesOption == FRAMES_ALL then
        local frames = {}
        for i = 1, #spr.frames do
            frames[i] = i
        end
        return frames
    end
    local active = app.activeFrame and app.activeFrame.frameNumber or 1
    return { active }
end

-- Generacion del mapa de normales

---Reutiliza o crea la capa de salida "<nombre>_NormalGenerated".
local function getOrCreateNormalLayer(spr, srcLayer)
    local name = srcLayer.name .. SUFFIX
    for _, layer in ipairs(spr.layers) do
        if layer.name == name then
            return layer
        end
    end
    local newLayer = spr:newLayer()
    newLayer.name = name
    return newLayer
end

-- Dialogo

local function handleDialogInput()
    local dlg = Dialog { title = "Generar mapa de normales" }

    dlg:separator { id = "sepScope", text = "Sobre que se aplica" }
    dlg:combobox {
        id = "layers",
        label = "Capas",
        option = LAYERS_ACTIVE,
        options = { LAYERS_ACTIVE, LAYERS_RANGE, LAYERS_ALL }
    }
    dlg:combobox {
        id = "frames",
        label = "Fotogramas",
        option = FRAMES_CURRENT,
        options = { FRAMES_CURRENT, FRAMES_ALL }
    }

    dlg:separator { id = "sepRelief", text = "Relieve" }
    dlg:slider { id = "intensity", label = "Intensidad del relieve", min = 1, max = 63, value = 32 }

    dlg:separator { id = "sepConfirm", text = "Confirmar" }
    dlg:button { id = "confirm", text = "Aceptar" }
    dlg:button { id = "cancel", text = "Cancelar" }

    dlg:show()
    return dlg.data
end

local function main()
    if app.apiVersion < 1 then
        return app.alert("Este script requiere Aseprite v1.2.10-beta3 o superior.")
    end

    local spr = app.activeSprite
    if not spr then
        return app.alert("No hay ningun sprite abierto.")
    end
    if spr.colorMode ~= ColorMode.RGB then
        return app.alert("Este script solo funciona en modo de color RGB.")
    end
    if not app.activeCel then
        return app.alert("No hay ninguna imagen activa.")
    end

    local data = handleDialogInput()
    if not data.confirm then
        return
    end

    local layers = resolveLayers(spr, data.layers)
    if #layers == 0 then
        return app.alert("No hay ninguna capa de imagen valida en el alcance elegido.")
    end

    local frames = resolveFrames(spr, data.frames)
    local intensity = data.intensity

    app.transaction(function()
        for _, srcLayer in ipairs(layers) do
            local normalLayer = getOrCreateNormalLayer(spr, srcLayer)
            for _, frameNumber in ipairs(frames) do
                local cel = srcLayer:cel(frameNumber)
                if cel then
                    local img = cel.image:clone()
                    processImage(img, intensity)
                    if normalLayer:cel(frameNumber) then
                        spr:deleteCel(normalLayer, frameNumber)
                    end
                    spr:newCel(normalLayer, frameNumber, img, cel.position)
                end
            end
        end
    end)

    app.refresh()
end

main()
