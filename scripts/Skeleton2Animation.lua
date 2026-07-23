--- Skeleton2Animation.lua
--- animaciones de huesos 2d para Aseprite
--- Originalmente este script era de aimarzhang, pero lo he modificado y adaptado para mi uso personal
--- MIT license (http://opensource.org/licenses/MIT)

local dlg 
local cmdDlg
local max_child = 8  
local radius = 2
local row_space = 6
local colum_space = 8
local max_depth = 4
local bone_sprite = nil
local bone_layer = nil
local sk_layer_name = "BoneTree"
local frame_index = 1

-- Diccionario de traducciones integradas (en = idioma fuente / fallback).
local LOCALIZATION = {
    en = {
        state_add = "Add bone / skin",
        state_pose = "Set pose",
        state_offset = "Move bone only",
        state_rotate = "Rotate",
        err_no_sprite = "Skeleton sprite not found",
        err_src_region = "Select a region from a sprite as the source",
        err_src_image = "Select a region from the source image",
        err_src_select = "Select a region to bind",
        err_bone_name = "Enter a name for the bone",
        err_dup_name = "Duplicate name",
        err_sel_parent = "Select a bone as the parent",
        err_max_child = "Maximum %d sibling bones",
        err_max_depth = "Maximum %d depth levels",
        err_sel_bone = "Select a bone",
        err_no_root_delete = "The root bone cannot be deleted",
        err_no_bound_image = "No image is bound to this bone",
        err_no_sprite2 = "Error: skeleton sprite not found",
        err_sel_file = "Select a file",
        err_json_type = "The pose file must be of json type",
        err_read_pose = "Could not read the pose data",
        saved_pose = "Pose saved to: %s",
        err_save_pose = "Could not save the skeleton data",
        delete_title = "Delete '%s'?",
        yes = "Yes",
        no = "No",
        modify_title = "Modify: %s",
        add = "Add",
        rotate = "Rotate",
        scale = "Scale",
        delete = "Delete",
        close = "Close",
        addchild_title = "Add bone to %s",
        bone_name = "Bone name",
        ok = "OK",
        open_dlg_title = "Open file",
        open_label = "Open",
        open_file_title = "Open pose file",
        cancel = "Cancel",
        save_dlg_title = "Save file",
        save_label = "Save as",
        save_file_title = "Save pose as",
        main_title = "Skeleton",
        state_lbl = "State:",
        point_none = "None",
        bind_skin = "Bind skin",
        bind_layer = "Bind layer",
        autodetect = "Auto-detect bones",
        reparent = "Reparent",
        reparent_title = "New parent for '%s'",
        parent_label = "Parent",
        err_no_layers = "No image layers to detect",
        move_node = "Move node",
        move_bone_only = "Move bone only",
        pos_xy = "Position X:Y",
        rotation = "Rotation",
        options = "Options:",
        with_children = "With children",
        no_children = "Without children",
        algorithm = "Algorithm:",
        nearest = "Nearest neighbor",
        bilinear = "Bilinear",
        load = "Load",
        create_frame = "Create frame",
        save = "Save",
        askpoint_move = "Moving bone... press Esc to quit",
        askpoint_edit = "Edit pose"
    },
    es = {
        state_add = "Añadir hueso / piel",
        state_pose = "Colocar pose",
        state_offset = "Mover solo el hueso",
        state_rotate = "Rotar",
        err_no_sprite = "No se encuentra el sprite del esqueleto",
        err_src_region = "Selecciona una región de un sprite como origen",
        err_src_image = "Selecciona una región de la imagen de origen",
        err_src_select = "Selecciona una región para vincular",
        err_bone_name = "Escribe un nombre para el hueso",
        err_dup_name = "Nombre duplicado",
        err_sel_parent = "Selecciona un hueso como padre",
        err_max_child = "Máximo %d huesos hermanos",
        err_max_depth = "Máximo %d niveles de profundidad",
        err_sel_bone = "Selecciona un hueso",
        err_no_root_delete = "No se puede borrar el hueso raíz",
        err_no_bound_image = "No hay ninguna imagen vinculada a este hueso",
        err_no_sprite2 = "Error: no se encuentra el sprite del esqueleto",
        err_sel_file = "Selecciona un archivo",
        err_json_type = "El archivo de pose debe ser de tipo json",
        err_read_pose = "No se pudieron leer los datos de pose",
        saved_pose = "Pose guardada en: %s",
        err_save_pose = "No se pudieron guardar los datos del esqueleto",
        delete_title = "¿Borrar '%s'?",
        yes = "Sí",
        no = "No",
        modify_title = "Modificar: %s",
        add = "Añadir",
        rotate = "Rotar",
        scale = "Escalar",
        delete = "Borrar",
        close = "Cerrar",
        addchild_title = "Añadir hueso a %s",
        bone_name = "Nombre del hueso",
        ok = "OK",
        open_dlg_title = "Abrir archivo",
        open_label = "Abrir",
        open_file_title = "Abrir archivo de pose",
        cancel = "Cancelar",
        save_dlg_title = "Guardar archivo",
        save_label = "Guardar como",
        save_file_title = "Guardar pose como",
        main_title = "Esqueleto",
        state_lbl = "Estado:",
        point_none = "Ninguno",
        bind_skin = "Vincular piel",
        bind_layer = "Vincular capa",
        autodetect = "Autodetectar huesos",
        reparent = "Reparentar",
        reparent_title = "Nuevo padre de '%s'",
        parent_label = "Padre",
        err_no_layers = "No hay capas de imagen que detectar",
        move_node = "Mover nodo",
        move_bone_only = "Mover solo hueso",
        pos_xy = "Posición X:Y",
        rotation = "Rotación",
        options = "Opciones:",
        with_children = "Con hijos",
        no_children = "Sin hijos",
        algorithm = "Algoritmo:",
        nearest = "Vecino más cercano",
        bilinear = "Bilineal",
        load = "Cargar",
        create_frame = "Crear fotograma",
        save = "Guardar",
        askpoint_move = "Moviendo hueso... pulsa Esc para salir",
        askpoint_edit = "Editar pose"
    }
}

-- Detección del idioma de Aseprite (best-effort; fallback a inglés).
local userLang = "en"
local okLang, prefLang = pcall(function() return app.preferences.general.language end)
if okLang and type(prefLang) == "string" and prefLang ~= "" then
    userLang = prefLang:lower():gsub("[_-].*$", "")
end
if not LOCALIZATION[userLang] then userLang = "en" end
local L = LOCALIZATION[userLang]

local state_Add_bone_skin = L.state_add
local state_pose = L.state_pose
local state_offset = L.state_offset
local state_rotate = L.state_rotate
local cur_state = state_Add_bone_skin
local label_pose_256 = "256x256 (ejemplo)"
local label_pose_128 = "128x128 (ejemplo)"
local label_pose_64 = "64x64 (ejemplo)"
---select size at first
local icon_size = 12
local sizes = {
  { label = "64x64", width = 64, height = 64 },
  { label = "128x128", width = 128, height = 128 },
  { label = "256x256", width = 256, height = 256 },
  { label = label_pose_128, width = 128, height = 128 },
  { label = label_pose_256 , width = 256, height = 256 },
}
local selected_size = sizes[1]

local bone_pixels =  {
  {0,0,0,0,0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,1,1,0,0,0},
  {0,0,0,0,0,0,0,1,1,1,0,0},
  {0,0,0,0,0,0,0,0,1,1,1,1},
  {0,0,0,0,0,0,0,1,1,0,1,1},
  {0,0,0,0,0,0,1,1,0,0,0,0},
  {0,0,0,0,0,1,1,0,0,0,0,0},
  {0,0,1,0,1,1,0,0,0,0,0,0},
  {0,1,1,1,1,0,0,0,0,0,0,0},
  {0,0,0,1,1,0,0,0,0,0,0,0},
  {0,0,0,0,1,1,0,0,0,0,0,0},
  {0,0,0,0,1,0,0,0,0,0,0,0},


}
local button_state  = {
        normal = {part = "sunken_normal", color = "button_normal_text"},
        selected = {part = "sunken_focused", color = "button_normal_text"},
        focused = {part = "sunken_focused", color = "button_normal_text"}
    }
local bone_label_ids = {}
local canvas_size = { width = 20, height = 20 }
local custom_icon = nil
local dragging_index = nil
local target_point =  nil
local withSkin = false
local node_radius = 10  
local selected_node = skeleton_tree 
local selected_layer_image = nil
local last_rotate_value = 0
local skeleton_tree = {name="root",x=64,y=64,bx=64,by=64,bcx=0,bcy=0,children={},index = 1,parent=nil,depth=1,image=nil,rotate = 0,offset_x=0,offset_y=0}
local node_positions = {}
local customButton = {
    bounds = Rectangle(5, 5, 20, 20),
    state = {
        normal = {part = "button_normal", color = "button_normal_text"},
        hot = {part = "button_hot", color = "button_hot_text"},
        selected = {part = "button_selected", color = "button_selected_text"},
        focused = {part = "button_focused", color = "button_normal_text"}
    },
    text = "Custom Button",
    onclick = function() print("Clicked <Custom Button>") end
}
local function indent(level)
	return string.rep("  ",level)
end

-- Busca una capa por su nombre. La API de Aseprite NO permite indexar
-- sprite.layers por nombre (solo por índice numérico), así que hay que
-- recorrerlas. Devuelve nil si no existe.
function findLayerByName(spr, name)
	if not spr then return nil end
	for _, layer in ipairs(spr.layers) do
		if layer.name == name then
			return layer
		end
	end
	return nil
end

local function read_json_file(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end
  local content = file:read("*a")
  file:close()
  return json.decode(content)
end


---create pose sample 128 , 256
local function pose_sample_256()
  local root =  {name="root",x=139,y=91,bx=70,by=70,bcx=0,bcy=0,children={},index = 5,parent=nil,depth=1,image=nil,rotate = 0,offset_x=0,offset_y=0}
  local head = {name="head",x=139,y=60,bx=0,by=0,bcx=0,bcy=0,children={},index = 1,parent=root,depth=2,image=nil,rotate = 0,offset_x=0,offset_y=0}
  local hip = {name="hip",x=139,y=128,bx=0,by=0,bcx=0,bcy=0,children={},index = 3,parent=root,depth=2,image=nil,rotate = 0,offset_x=0,offset_y=0}
  local r_leg = {name="r_leg",x=122,y=156,bx=0,by=0,bcx=0,bcy=0,children={},index = 2,parent=hip,depth=3,image=nil,rotate = 0,offset_x=0,offset_y=0}
  local l_leg = {name="l_leg",x=162,y=157,bx=0,by=0,bcx=0,bcy=0,children={},index = 2,parent=hip,depth=3,image=nil,rotate = 0,offset_x=0,offset_y=0}
  local r_knee = {name="r_knee",x=119,y=194,bx=0,by=0,bcx=0,bcy=0,children={},index = 1,parent=r_leg,depth=4,image=nil,rotate = 0,offset_x=0,offset_y=0}
  local l_knee = {name="l_knee",x=164,y=193,bx=0,by=0,bcx=0,bcy=0,children={},index = 1,parent=l_leg,depth=4,image=nil,rotate = 0,offset_x=0,offset_y=0}
  local r_arm = {name="r_arm",x=113,y=106,bx=0,by=0,bcx=0,bcy=0,children={},index = 2,parent=root,depth=2,image=nil,rotate = 0,offset_x=0,offset_y=0}
  local l_arm = {name="l_arm",x=166,y=103,bx=0,by=0,bcx=0,bcy=0,children={},index = 2,parent=root,depth=2,image=nil,rotate = 0,offset_x=0,offset_y=0}
  local r_hand = {name="r_hand",x=109,y=132,bx=0,by=0,bcx=0,bcy=0,children={},index = 1,parent=r_arm,depth=3,image=nil,rotate = 0,offset_x=0,offset_y=0}
  local l_hand = {name="l_hand",x=170,y=132,bx=0,by=0,bcx=0,bcy=0,children={},index = 1,parent=l_arm,depth=3,image=nil,rotate = 0,offset_x=0,offset_y=0}
  
  table.insert(r_arm.children,r_hand)
  table.insert(l_arm.children,l_hand)
  table.insert(root.children,r_arm)
  table.insert(root.children,l_arm)
  
  table.insert(r_leg.children,r_knee)
  table.insert(l_leg.children,l_knee)
  table.insert(hip.children,l_leg)
  table.insert(hip.children,r_leg)
  table.insert(root.children,hip)
  table.insert(root.children,head)
  return root
end

local function pose_sample_128()
  local root =  {name="root",x=66,y=41,bx=70,by=70,bcx=0,bcy=0,children={},index = 5,parent=nil,depth=1,image=nil,rotate = 0,offset_x=0,offset_y=0}
  local head = {name="head",x=66,y=30,bx=0,by=0,bcx=0,bcy=0,children={},index = 1,parent=root,depth=2,image=nil,rotate = 0,offset_x=0,offset_y=0}
  local hip = {name="hip",x=66,y=61,bx=0,by=0,bcx=0,bcy=0,children={},index = 3,parent=root,depth=2,image=nil,rotate = 0,offset_x=0,offset_y=0}
  local r_leg = {name="r_leg",x=58,y=78,bx=0,by=0,bcx=0,bcy=0,children={},index = 2,parent=hip,depth=3,image=nil,rotate = 0,offset_x=0,offset_y=0}
  local l_leg = {name="l_leg",x=76,y=77,bx=0,by=0,bcx=0,bcy=0,children={},index = 2,parent=hip,depth=3,image=nil,rotate = 0,offset_x=0,offset_y=0}
  local r_knee = {name="r_knee",x=57,y=94,bx=0,by=0,bcx=0,bcy=0,children={},index = 1,parent=r_leg,depth=4,image=nil,rotate = 0,offset_x=0,offset_y=0}
  local l_knee = {name="l_knee",x=78,y=97,bx=0,by=0,bcx=0,bcy=0,children={},index = 1,parent=l_leg,depth=4,image=nil,rotate = 0,offset_x=0,offset_y=0}
  local r_arm = {name="r_arm",x=54,y=50,bx=0,by=0,bcx=0,bcy=0,children={},index = 2,parent=root,depth=2,image=nil,rotate = 0,offset_x=0,offset_y=0}
  local l_arm = {name="l_arm",x=80,y=48,bx=0,by=0,bcx=0,bcy=0,children={},index = 2,parent=root,depth=2,image=nil,rotate = 0,offset_x=0,offset_y=0}
  local r_hand = {name="r_hand",x=52,y=61,bx=0,by=0,bcx=0,bcy=0,children={},index = 1,parent=r_arm,depth=3,image=nil,rotate = 0,offset_x=0,offset_y=0}
  local l_hand = {name="l_hand",x=84,y=61,bx=0,by=0,bcx=0,bcy=0,children={},index = 1,parent=l_arm,depth=3,image=nil,rotate = 0,offset_x=0,offset_y=0}
  
  table.insert(r_arm.children,r_hand)
  table.insert(l_arm.children,l_hand)
  table.insert(root.children,r_arm)
  table.insert(root.children,l_arm)
  
  table.insert(r_leg.children,r_knee)
  table.insert(l_leg.children,l_knee)
  table.insert(hip.children,l_leg)
  table.insert(hip.children,r_leg)
  table.insert(root.children,hip)
  table.insert(root.children,head)
  return root
end
--local skeleton_tree = {name="root",x=64,y=64,bx=64,by=64,bcx=0,bcy=0,children={},index = 1,parent=nil,depth=1,image=nil,rotate = 0,offset_x=0,offset_y=0}

local function process_node(node,sk_node)
  if node.children then
    for _, child in ipairs(node.children) do
       local depth = sk_node.depth + 1
       local newSknode = { name=child.name,x=child.x,y=child.y,bx=child.bx,by=child.by,bcx=0,bcy=0,children = {},index=1 ,parent=sk_node, depth=depth,image=nil,rotate = 0,offset_x = 0,offset_y = 0}
       table.insert(sk_node.children, newSknode)
	   sk_node.index = sk_node.index+1
	   process_node(child,newSknode)
	end
  end
end


function node_to_json_pretty(node, level)
  level = level or 0
  local lines = {}

  
  table.insert(lines, indent(level) .. "{")
  if level == 0 then
	  table.insert(lines, indent(level + 1) .. '"sprite_width": '..selected_size.width..',')
	  table.insert(lines, indent(level + 1) .. '"sprite_height": '..selected_size.height..',')
  end
  table.insert(lines, indent(level + 1) .. '"name": "'.. node.name..'",')
  table.insert(lines, indent(level + 1) .. '"x": '..node.x..',')
  table.insert(lines, indent(level + 1) .. '"y": '..node.y..',')
  table.insert(lines, indent(level + 1) .. '"bx": '.. node.bx..',')
  table.insert(lines, indent(level + 1) .. '"by": '..node.by..',')
  table.insert(lines, indent(level + 1) .. '"bcx": '..node.bcx..',')
  table.insert(lines, indent(level + 1) .. '"bcy": '..node.bcy..',')
  table.insert(lines, indent(level + 1) .. '"index": '..node.index..',')
  table.insert(lines, indent(level + 1) .. '"depth": '..node.depth..',')
  table.insert(lines, indent(level + 1) .. '"rotate": '.. node.rotate..',')
  table.insert(lines, indent(level + 1) .. '"offset_x": '..node.offset_x..',')
  table.insert(lines, indent(level + 1) .. '"offset_y": '..node.offset_y..',')
  table.insert(lines, indent(level + 1) .. '"children": [')

  for i, child in ipairs(node.children) do
    table.insert(lines, node_to_json_pretty(child, level + 2))
    if i < #node.children then
      lines[#lines] = lines[#lines] .. ","  -- añadir coma
    end
  end

  table.insert(lines, indent(level + 1) .. "]")
  table.insert(lines, indent(level) .. "}")

  return table.concat(lines, "\n")
end




local function ValidNodeName(name,node)
	local value = false
	if name == node.name then
		return false
	end

	for i, child in ipairs(node.children) do
     	value = ValidNodeName(name,child)
		if value == false then
			return false
		end
    end
	return true
end



local function create_skeleton_sprite()
	-- Preferir el sprite ya abierto; solo crear uno nuevo (64x64) si no hay ninguno.
	bone_sprite = app.activeSprite
	if bone_sprite == nil then
		bone_sprite = Sprite(selected_size.width, selected_size.height, ColorMode.RGB)
		bone_sprite.filename = "skeleton_sprite"
	end

	-- Reutilizar la capa del esqueleto si ya existe (evita duplicar documentos
	-- al reabrir la ventana); si no, crearla en el sprite.
	bone_layer = findLayerByName(bone_sprite, sk_layer_name)
	if bone_layer == nil then
		bone_layer = bone_sprite:newLayer()
		bone_layer.name = sk_layer_name
	end

	-- Asegurar un cel en el frame 1 para poder dibujar el arbol de huesos.
	if bone_layer:cel(1) == nil then
		bone_sprite:newCel(bone_layer, 1)
	end
end

-- Crea la capa/cel del esqueleto bajo demanda (una sola vez) y en una
-- transacción, para que abrir la ventana no modifique el sprite hasta que el
-- usuario ejecute una acción real.
local function ensureSkeleton()
	if bone_layer ~= nil then return end
	if app.activeSprite == nil then
		-- No hay sprite: hay que crearlo fuera de transacción.
		create_skeleton_sprite()
	else
		-- Sobre un sprite existente, agrupar la creación de capa/cel en un solo
		-- paso deshacible.
		app.transaction(function() create_skeleton_sprite() end)
	end
end
local function moveSkLayer2Top()
	if bone_sprite == nil then
	   app.alert(L.err_no_sprite)
	   return
	end
	if bone_layer then
		local newSkLayer = bone_sprite:newLayer()
		--newSkLayer.name = sk_layer_name
		for _,cel in ipairs(bone_layer.cels) do
			local newImage = cel.image:clone()
			bone_sprite:newCel(newSkLayer,cel.frameNumber,newImage,cel.position)

		end
		bone_sprite:deleteLayer(bone_layer)
		bone_layer = newSkLayer
		bone_layer.name = sk_layer_name
	end
end

local function updateOffset(node, pos_x,pos_y)
	if node.image then	
		local newOffsetX = pos_x - node.x												 
		local newOffsetY = pos_y - node.y
		node.x = pos_x
		node.y = pos_y  
	end
	if dlg.data.rotator1 then
		for _,child in pairs(node.children) do
		    local newPos_x = child.x + newOffsetX
			local newPos_y = child.y + newOffsetY
			local vaildPos = GetValidPoint(newPos_x,newPos_y)
			updateOffset(child, vaildPos.x,vaildPos.y)
		end
	end
end

local function findBondLayer()
	for _,layer in ipairs(bone_sprite.layers) do
	   if layer.name == sk_layer_name then
	      bone_layer = layer
		  break
	   end
	end
end


-- Obtiene la jerarquía del esqueleto como texto (para mostrar en un label)
local function getSkeletonHierarchy()
    return table.concat(generateIndentedList(skeleton_tree, ""), "\n")
end

local function add_skin_layer(skinLayer_name)
	ensureSkeleton()
	local src_spr = app.activeSprite
	local src_cel = app.cel
	-- La capa activa debe ser una capa de imagen válida como origen (no un
	-- grupo, ni la capa del esqueleto, ni una capa de piel ya generada).
	local src_layer = app.activeLayer
	if not src_layer or not src_layer.isImage
	   or src_layer.name == sk_layer_name
	   or src_layer.name == skinLayer_name then
		app.alert(L.err_src_region)
		return
	end

	if not src_cel then
	   app.alert(L.err_src_image)
	   return
	end
	local selection = app.sprite.selection
	if  selection.isEmpty then
	   app.alert(L.err_src_select)
	   return
	end

	local src_img = src_cel.image:clone()
	local srcPos = src_cel.position
	local bounds = selection.bounds
	local w,h = bounds.width, bounds.height
	local selectionPixels = {}

-- Pre-extrae los píxeles de la selección (al perder el foco deja de ser válida)
	for y = bounds.y, bounds.y + bounds.height - 1 do
		for x = bounds.x, bounds.x + bounds.width - 1 do
		 if selection:contains(x, y) then
		    local sx = x - srcPos.x
			local sy = y - srcPos.y
			local color
			if sx >=0 and sx < src_img.width and sy >=0 and sy < src_img.height then
			   color = src_img:getPixel(sx, sy)
			else
			   color = Color(0,0,0,0)
			end
			table.insert(selectionPixels, {x=x, y=y, color=color})
		 end
	    end
	end

	
	
	local croppedImg = Image(w,h,bone_sprite.colorMode)
	--for y = bounds.y, bounds.y+bounds.height - 1 do
	 --   for x = bounds.x, bounds.x + bounds.width - 1 do
	--	  if selection:contains(x,y) then
	--			local color = src_img:getPixel(x,y)
	--			croppedImg:putPixel(x-bounds.x,y-bounds.y,color)
	--		end
	--	end
	--end
	-- Rellena la imagen destino con los píxeles guardados
	for _, pix in ipairs(selectionPixels) do
			croppedImg:putPixel(pix.x - bounds.x, pix.y - bounds.y, pix.color)
	end
	
	local skin_layer = findLayerByName(bone_sprite, skinLayer_name)
	if skin_layer == nil then
	   skin_layer = bone_sprite:newLayer()
	   skin_layer.name = skinLayer_name
	   --skin_layer.stackIndex = 1
	end
	local skin_cel = skin_layer:cel(1)
	if not skin_cel then
		skin_cel= bone_sprite:newCel(skin_layer,1)
	end
	selected_node.image = croppedImg
	skin_cel.image:clear()
	--skin_cel.image = selected_node.image:clone()
	skin_cel.image:drawImage(croppedImg,0,0)
	--skin_cel.position= Point(selected_node.x + selected_node.offset_x , selected_node.y + selected_node.offset_y )
	skin_cel.position= Point(bounds.x, bounds.y)
	selected_node.bcx =  selected_node.x
	selected_node.bcy =  selected_node.y
	moveSkLayer2Top()
	app.refresh()
end


-- Recalcula la profundidad de un nodo y su subárbol tras un reparentado.
local function updateDepth(node)
	node.depth = node.parent and (node.parent.depth + 1) or 1
	for _, c in ipairs(node.children) do updateDepth(c) end
end

-- ¿'maybe' está dentro del subárbol de 'node' (incluido el propio 'node')?
local function isInSubtree(node, maybe)
	if node == maybe then return true end
	for _, c in ipairs(node.children) do
		if isInSubtree(c, maybe) then return true end
	end
	return false
end

-- Cambia el padre de 'node' a 'newParent' (evita raíz y ciclos).
local function reparentNode(node, newParent)
	if node.parent == nil then return end            -- la raíz no se mueve
	if isInSubtree(node, newParent) then return end  -- evita ciclos
	for i, c in ipairs(node.parent.children) do
		if c == node then table.remove(node.parent.children, i); break end
	end
	node.parent = newParent
	table.insert(newParent.children, node)
	updateDepth(node)
end

-- Reúne los nombres de nodos que pueden ser padre de 'exclude'
-- (todos menos 'exclude' y sus descendientes).
local function collectParentCandidates(node, exclude, out)
	if not isInSubtree(exclude, node) then
		table.insert(out, node.name)
	end
	for _, child in ipairs(node.children) do
		collectParentCandidates(child, exclude, out)
	end
end

-- Busca un nodo por nombre en el árbol (primero que coincida).
local function findNodeByName(node, name)
	if node.name == name then return node end
	for _, child in ipairs(node.children) do
		local found = findNodeByName(child, name)
		if found then return found end
	end
	return nil
end

-- Vincula la capa activa (completa) al hueso seleccionado, renombrando el hueso
-- con el nombre de la capa (el vínculo hueso<->capa es por nombre).
local function bind_existing_layer()
	if selected_node == nil then
		app.alert(L.err_sel_bone)
		return
	end
	local layer = app.activeLayer
	if not layer or not layer.isImage or layer.name == sk_layer_name then
		app.alert(L.err_src_region)
		return
	end
	local cel = layer:cel(1)
	if not cel or not cel.image then
		app.alert(L.err_src_image)
		return
	end
	-- Renombrar el hueso al nombre de la capa (unicidad, salvo que ya coincida).
	if layer.name ~= selected_node.name and not ValidNodeName(layer.name, skeleton_tree) then
		app.alert(L.err_dup_name)
		return
	end
	ensureSkeleton()
	selected_node.name = layer.name
	selected_node.image = cel.image:clone()
	selected_node.bcx = cel.position.x
	selected_node.bcy = cel.position.y
	moveSkLayer2Top()
	local image = bone_layer:cel(1).image
	image:clear()
	drawNodeTree(skeleton_tree)
	dlg:repaint()
	app.refresh()
end

-- Crea un hueso por cada capa de imagen del sprite (excepto BoneTree y grupos),
-- colgando de la raíz. La jerarquía se ajusta luego con "Reparentar".
local function autodetect_bones()
	ensureSkeleton()
	local created = 0
	for _, layer in ipairs(bone_sprite.layers) do
		if layer.isImage and not layer.isGroup and layer.name ~= sk_layer_name then
			-- Saltar si ya existe un hueso con ese nombre.
			if ValidNodeName(layer.name, skeleton_tree) then
				local node = add_skeleton_node(skeleton_tree, layer.name)
				local cel = layer:cel(1)
				if cel and cel.image then
					local cx = cel.position.x + math.floor(cel.image.width / 2)
					local cy = cel.position.y + math.floor(cel.image.height / 2)
					local pos = GetValidPoint(cx, cy)
					node.x, node.y = pos.x, pos.y
					node.bx, node.by = pos.x, pos.y
					node.image = cel.image:clone()
					node.bcx = cel.position.x
					node.bcy = cel.position.y
				end
				created = created + 1
			end
		end
	end
	if created == 0 then
		app.alert(L.err_no_layers)
		return
	end
	local image = bone_layer:cel(1).image
	image:clear()
	drawNodeTree(skeleton_tree)
	dlg:repaint()
	app.refresh()
end



-- Función recursiva: añade un nodo al árbol de huesos
function add_skeleton_node(parent, name)
    local x = math.min(selected_size.width, parent.x + row_space)   -- * parent.depth
	local y = math.min(selected_size.height,parent.y + colum_space * parent.index)
	local depth = parent.depth + 1
    local node = { name = name, x=x,y=y,bx=x,by=y,bcx=0,bcy=0,children = {},index=1 ,parent=parent, depth=depth,image=nil,rotate = 0,offset_x = 0,offset_y = 0}
    table.insert(parent.children, node)
	parent.index = parent.index+1

    return node -- Devuelve el nodo creado para poder seguir añadiendo hijos
end

-- Añade un nodo de hueso
local function addBoneNode()
    local boneName = dlg.data.BoneName
	if boneName == "" then
		app.alert(L.err_bone_name)
		return
	end
	if not ValidNodeName(boneName,skeleton_tree) then
		app.alert(L.err_dup_name)
		return
	end
	if selected_node == nil then
		app.alert(L.err_sel_parent)
		return
	end
	if selected_node.index >= max_child then
		app.alert(string.format(L.err_max_child, max_child))
		return
	end
	if selected_node.depth > max_depth then
		app.alert(string.format(L.err_max_depth, max_depth))
		return
	end
	local newnode = add_skeleton_node(selected_node,boneName)
	ensureSkeleton()
	dlg:repaint()
	dlg:repaint()
	local image = bone_layer:cel(1).image
	image:clear()
    drawNodeTree(skeleton_tree)
	app.refresh()
end


-- Añade un hueso hijo
local function addBoneChildNode(node,boneName)
	if boneName == "" then
        app.alert(L.err_bone_name)
        return
    end

 
    -- Establece el hueso padre
    add_skeleton_node(node,boneName)
	dlg:repaint()
	dlg:repaint()
end

function drawLine(layer,cel, x0, y0, x1, y1, color)
	local img = cel.image
  local dx = math.abs(x1 - x0)
  local dy = math.abs(y1 - y0)
  local sx = (x0 < x1) and 1 or -1
  local sy = (y0 < y1) and 1 or -1
  local err = dx - dy

  while true do
    if x0 >= 0 and y0 >= 0 and x0 < img.width and y0 < img.height then
      img:putPixel(x0, y0, color)
    end
    if x0 == x1 and y0 == y1 then break end
    local e2 = 2 * err
    if e2 > -dy then err = err - dy; x0 = x0 + sx end
    if e2 < dx  then err = err + dx; y0 = y0 + sy end
  end
end



local function drawLine2(layer,cel,p1x,p1y, p2x,p2y, color)
    local line_color = Color { r = 255, g = 255, b = 255, a = 255 }

    local brush = Brush(1)
    app.useTool {
        tool = "line",
        color = line_color,
        points = { Point(p1x,p1y), Point(p2x,p2y) },
        brush = brush,
        layer = layer,
        cel = cel
    }
end


function drawCircle(lay,cel, cx, cy, r, color)
	local img = cel.image
  for y = -r, r do
    for x = -r, r do
      if x*x + y*y <= r*r then
        local px, py = cx + x, cy + y
        if px >= 0 and py >= 0 and px < img.width and py < img.height then
          img:putPixel(px, py, color)
        end
      end
    end
  end
end


function moveLayerPos(node)
	local layerName = node.name
	local skin_layer = findLayerByName(bone_sprite, layerName)
	if skin_layer ~= nil then
		local skin_cel = skin_layer:cel(1)
		if skin_cel then
			skin_cel.position= Point(node.x,node.y)
		end
	end
	if dlg.data.rotator1 then
		for _,child in pairs(node.children) do
			moveLayerPos(child)

		end
	end
end

function GetValidPoint(pos_x,pos_y)
	local newPos_x = pos_x
	local newPos_y = pos_y
	if pos_x < 0 then 
	   newPos_x = 0
	end
    if pos_x >= selected_size.width then
	   newPos_x = selected_size.width -1
	end
	if newPos_y < 0 then
	   newPos_y = 0
    end
	if newPos_y >= selected_size.height then
	   newPos_y = selected_size.height -1
	end
	return Point(newPos_x,newPos_y)
end



function drawNodeTree(node)
  local color = Color { r = 255, g = 255, b = 255, a = 255 }

  if bone_layer == nil then
     return
  end
  local cel = bone_layer:cel(1)
  drawCircle(bone_layer,cel,node.x ,node.y,radius,color)
  if node.parent ~= nil then
	drawLine(bone_layer,cel,node.x,node.y, node.parent.x, node.parent.y, Color(255, 0, 0))  -- línea roja
  end
  --if withSkin then
--	      local skin = findLayerByName(bone_sprite, node.name)
--	      if skin and node.image ~= nil then
--		    local skin_cel = skin:cel(1)
--			local newPos =  GetValidPoint(node.x+node.offset_x,node.y+node.offset_y)
--			skin_cel.position = Point(newPos.x,newPos.y)
--			skin_cel.position = Point(node.x + node.offset_x ,node.y + node.offset_y)
--		  end
 -- end
  for i, child in ipairs(node.children) do
      drawNodeTree(child)
  end
 
end

-- Dibuja recursivamente el árbol de huesos en el sprite
function drawBoneTree(spr, node)
  local color = Color { r = 255, g = 255, b = 255, a = 255 }

  if bone_layer == nil then
     return

  end
  local cel = bone_layer:cel(1)
  --local pos_y = node.y + colum_space * index
  --local pos_x = node.x + row_space * node.depth
  --drawCircle(layer,cel,node.x + 10 * node.depth ,node.y + 10* node.index,5,color)
  drawCircle(bone_layer,cel,node.x ,node.y,radius,color)
  if node.parent ~= nil then
  -- Dibuja la línea de conexión (si tiene padre)
	drawLine(bone_layer,cel,node.x,node.y, node.parent.x, node.parent.y, Color(255, 0, 0))  -- línea roja
  end



  for i, child in ipairs(node.children) do
     drawBoneTree(spr, child)
  end
end

local function removeLayer(node)
	local layerName = node.name
	local layer = findLayerByName(bone_sprite, layerName)
	if layer then
		bone_sprite:deleteLayer(layer)
	end
	for _,child in pairs(node.children) do
		removeLayer(child)
	end

end


local function rmBoneChildNode()
	if selected_node == nil then
	  app.alert(L.err_sel_bone)
	  return
	end
	if selected_node.parent == nil then
	  app.alert(L.err_no_root_delete)
		return
	end

	ensureSkeleton()
	local clickButton = nil

	local comfirmDlg = Dialog(string.format(L.delete_title, selected_node.name))
	comfirmDlg:button{"Button_Yes",text=L.yes, onclick = function()
		clickButton = "Button_Yes"
		local parenNode = selected_node.parent
			for i,node in ipairs(parenNode.children) do
				if node == selected_node then
				  table.remove(parenNode.children,i)
				  removeLayer(selected_node)
				  parenNode.index = parenNode.index - 1
				  local image = bone_layer:cel(1).image
	              image:clear()
                  drawNodeTree(skeleton_tree)
	              app.refresh()
				break
			end
		end
		selected_node = nil
		dlg:repaint()
		dlg:repaint()
		comfirmDlg:close()
		end
		}
	comfirmDlg:button{"Button_No",text=L.no, onclick = function() clickButton="Button_No" comfirmDlg:close() end}

	comfirmDlg:show()


end

function on_canvas_click(ev)
    local click_x, click_y = ev.x, ev.y
    for _, entry in ipairs(node_positions) do
        if click_x >= entry.x and click_x <= (entry.x + entry.width) and
           click_y >= entry.y and click_y <= (entry.y + entry.height) then
            print("Clicked on node:", entry.node.name)
            break
        end
    end
end


function showCommandDialog(node)
    if cmdDlg then
		cmdDlg:close{}
	end
    cmdDlg = Dialog(string.format(L.modify_title, node.name))
	cmdDlg:canvas{id="cmdDlg_canva",width=80,height=1}
	--cmdDlg:entry{id="childBone", label="Nombre del hueso"}
    cmdDlg:button{ id="cmd1", text=L.add, onclick=function()
											local addChildDlg = Dialog{title=string.format(L.addchild_title, node.name),parent=cmdDlg}

											local chilebone_name = ""
											addChildDlg:entry{id="childBone", label=L.bone_name}
											addChildDlg:button{ id="ok", text=L.ok, onclick=function()
														chilebone_name = addChildDlg.data.childBone
														addChildDlg:close() end }
											addChildDlg:show{}

											addBoneChildNode(node,chilebone_name)

											end
				}

	cmdDlg:newrow()
    cmdDlg:button{ id="cmd2", text=L.rotate, onclick=function() print(node.name .. " Rotar") end }
	cmdDlg:newrow()
    cmdDlg:button{ id="cmd3", text=L.scale, onclick=function() print(node.name .. " Escalar") end }
	cmdDlg:newrow()
    cmdDlg:button{ id="cmd4", text=L.delete, onclick=function()
											if selected_node.parent == nil then
												print(L.err_no_root_delete)
												return
											end

											rmBoneChildNode(); cmdDlg:close() end }
	cmdDlg:newrow()
    cmdDlg:button{ id="close", text=L.close, onclick=function() cmdDlg:close() end }
    cmdDlg:show{wait = false}
end



function draw_skeleton(ev, node, x, y, depth)
    local spacing = 3    
    local indent = depth * 10 

    table.insert(node_positions, {
        node = node,
        x = x + indent,
        y = y,
        width = icon_size + spacing + 50, -- icon + text length
        height = icon_size
    })

    ev.context:fillText(node.name,x + indent + spacing, y)
	local textSize= ev.context:measureText(node.name)
	ev.context:drawImage(custom_icon,x + indent + textSize.width + spacing,y-4)
	if node == selected_node then
		local origialColor = ev.context.color
		ev.context.color = Color(50,200,50)
		ev.context:strokeRect(x+indent+spacing-2,y-2,textSize.width+4,textSize.height+2)
		ev.context.color = origialColor
	end

    local new_y = y + icon_size + spacing
    for _, child in ipairs(node.children) do
        new_y = draw_skeleton(ev, child, x, new_y, depth + 1)
    end

    return new_y
end


local function edit_stop()
    app.editor:cancel()
	withSkin = false
end

function get_bone_at_pos(bone,px, py, size)
	--for i, bone in ipairs(skeleton_tree) do
	local dx = px - bone.x
	local dy = py - bone.y
	if (dx ^ 2 + dy ^ 2) <= size ^ 2 then
      return bone
	else
		local bone_child = nil
		for i, child in ipairs(bone.children) do
			bone_child = get_bone_at_pos(child,px, py, size)
			if bone_child ~= nil then
			   return bone_child
			end
		end
    end
	return nil
end



local function get_bone(mx, my, size)
  for i, bone in ipairs(skeleton_tree) do
    local dx = mx - bone.x
    local dy = my - bone.y
    if (dx ^ 2 + dy ^ 2) <= size ^ 2 then
      return bone
    end
  end
  return nil
end

local function move_child(node,offset_x,offset_y)
	
    for _,child in ipairs(node.children) do
	   child.x = math.max(0, math.min(app.activeSprite.width - 1, child.x + offset_x))
	   child.y = math.max(0, math.min(app.activeSprite.height - 1, child.y + offset_y))
	   if withSkin then
	     local skin = findLayerByName(bone_sprite, child.name)
	     if skin and child.image ~= nil then
		   local skin_cel = skin:cel(1)
		   local newPos =  GetValidPoint(skin_cel.position.x +offset_x,skin_cel.position.y+offset_y)
		   skin_cel.position = Point(newPos.x,newPos.y)
		   child.bcx = newPos.x
		   child.bcy = newPos.y
		 end
	   end
	   move_child(child,offset_x,offset_y)
	end
end
local function move_point(ev)
    if target_point == nil then
	   target_point = get_bone_at_pos(skeleton_tree,ev.point.x, ev.point.y, 3)
    end
	if target_point ~= nil then
	   local ori_x = target_point.x
	   local ori_y = target_point.y
	   target_point.x = math.max(0, math.min(app.activeSprite.width - 1, ev.point.x))
	   target_point.y = math.max(0, math.min(app.activeSprite.height - 1, ev.point.y))
	   local offset_x = target_point.x - ori_x
	   local offset_y = target_point.y - ori_y
	   if withSkin then
	      local skin = findLayerByName(bone_sprite, target_point.name)
	      if skin and target_point.image ~= nil then
		    local skin_cel = skin:cel(1)
			local newPos =  GetValidPoint(skin_cel.position.x +offset_x,skin_cel.position.y+offset_y)
			skin_cel.position = Point(newPos.x,newPos.y)
			target_point.bcx = newPos.x
		    target_point.bcy = newPos.y
		  end
	   end
	   
       if  dlg.data.rotator1 then
			 move_child(target_point,offset_x,offset_y)
       end
	   local image = bone_layer:cel(1).image
		image:clear()
		drawNodeTree(skeleton_tree)
		app.refresh()
    end

end


---Editar pose: al soltar el clic se libera el hueso actual para que el
---siguiente arrastre seleccione uno nuevo (el movimiento real lo hace
---move_point en el onchange del askPoint).
local function edit_skeletion_pose(ev)
	target_point = nil
end


local function delayed_restart()
        target_point = nil
        if app.activeSprite.selection.isEmpty == false then
            app.command.Cancel()
            app.activeSprite.selection:deselect()
        end
        local timer
        timer = Timer {
            interval = 0.01,
            ontick = function()
                app.editor:askPoint {
                    title = L.askpoint_move,
                    onclick = function(ev)
                        edit_skeletion_pose(ev)
                        delayed_restart()
                       -- (código antiguo eliminado)
                    end,
                    onchange = function(ev)
                        move_point(ev)
                    end,
                    oncancel = function(ev)
                        edit_stop()
                    end,
                }
                timer:stop()
            end }
        timer:start()
    end



local function edit_start()
	ensureSkeleton()
	if bone_sprite == nil then
	   app.alert(L.err_no_sprite)
	   return
	end
	app.activeSprite = bone_sprite
    if app.editor ~= nil then
        app.editor:askPoint {
            title = L.askpoint_edit,
            onclick = function(ev)
                delayed_restart()
            end,
            onchange = function(ev) move_point(ev) end,
            oncancel = function(ev)
                edit_stop()
            end,
        }
    end
end

function nearestNeighborSample(image, fx, fy)
  local x = math.floor(fx + 0.5)
  local y = math.floor(fy + 0.5)

  if x >= 0 and x < image.width and y >= 0 and y < image.height then
    return Color(image:getPixel(x, y))
  else
    return Color(0, 0, 0, 0) 
  end
end

function get_bilinear_sample(img, x, y)
  local x_int = math.floor(x + 0.5)
  local y_int = math.floor(y+ 0.5)
  local w,h = img.width ,img.height
  if math.abs(x - x_int) < 1e-4 and math.abs(y - y_int) < 1e-4 then
    if x_int >= 0 and x_int < w and y_int >= 0 and y_int < h then
      return Color(img:getPixel(x_int, y_int))
    else
      return Color(0, 0, 0, 0)
    end
  end

  local x0, y0 = math.floor(x), math.floor(y)
  local x1, y1 = x0 + 1, y0 + 1
  local dx, dy = x - x0, y - y0

  if x0 < 0 or y0 < 0 or x1 >= img.width or y1 >= img.height then
    return app.pixelColor.rgba(0, 0, 0, 0)
  end
  local c00 = img:getPixel(x0, y0)
  local c10 = img:getPixel(x1, y0)
  local c01 = img:getPixel(x0, y1)
  local c11 = img:getPixel(x1, y1)

  local function lerp(a, b, t) return a + (b - a) * t end
  local function lerpColor(c1, c2, t)
    local r = lerp(app.pixelColor.rgbaR(c1), app.pixelColor.rgbaR(c2), t)
    local g = lerp(app.pixelColor.rgbaG(c1), app.pixelColor.rgbaG(c2), t)
    local b = lerp(app.pixelColor.rgbaB(c1), app.pixelColor.rgbaB(c2), t)
    local a = lerp(app.pixelColor.rgbaA(c1), app.pixelColor.rgbaA(c2), t)
    return app.pixelColor.rgba(r, g, b, a)
  end

  local c0 = lerpColor(c00, c10, dx)
  local c1 = lerpColor(c01, c11, dx)
  return lerpColor(c0, c1, dy)
end

local function rotate_image_any_angle(img, angle_deg)
  local angle_rad = math.rad(angle_deg)
  local cos_theta = math.cos(-angle_rad)  
  local sin_theta = math.sin(-angle_rad)

  local w, h = img.width, img.height
  local cx, cy = w / 2, h / 2

  local diag = math.ceil(math.sqrt(w * w + h * h))
  local new_img = Image(diag, diag, img.colorMode)
  local ncx, ncy = diag / 2, diag / 2

  for y = 0, diag - 1 do
    for x = 0, diag - 1 do
      local dx = x - ncx
      local dy = y - ncy
      local src_x = cos_theta * dx - sin_theta * dy + cx
      local src_y = sin_theta * dx + cos_theta * dy + cy

      local color = nearestNeighborSample(img, src_x, src_y)
      new_img:putPixel(x, y, color)
    end
  end

  return new_img, diag, diag
end

function get_rotated_cel_position(cx, cy, sx, sy, angle_deg, w, h)
  local angle_rad = math.rad(angle_deg)
  local cos_theta = math.cos(angle_rad)
  local sin_theta = math.sin(angle_rad)

  local ox = w / 2
  local oy = h / 2

  local img_cx = sx + ox
  local img_cy = sy + oy

  local dx = img_cx - cx
  local dy = img_cy - cy

  local rdx = dx * cos_theta - dy * sin_theta
  local rdy = dx * sin_theta + dy * cos_theta

  local new_img_cx = cx + rdx
  local new_img_cy = cy + rdy

  local new_w = (angle_deg % 180 == 0) and w or h
  local new_h = (angle_deg % 180 == 0) and h or w

  local new_sx = new_img_cx - new_w / 2
  local new_sy = new_img_cy - new_h / 2

  return math.floor(new_sx + 0.5), math.floor(new_sy + 0.5)
end


function rotate_point(px, py, cx, cy, angle)
  local angle_rad = math.rad(angle)
  local dx = px - cx
  local dy = py - cy
  local rx = dx * math.cos(angle_rad) - dy * math.sin(angle_rad)
  local ry = dx * math.sin(angle_rad) + dy * math.cos(angle_rad)
  return {x= math.floor(cx + rx + 0.5),y= math.floor(cy + ry + 0.5)}
end



function rotatePoint(x, y, center, cos_a, sin_a)
  local dx = x - center.x
  local dy = y - center.y
  local rx = cos_a * dx - sin_a * dy + center.x
  local ry = sin_a * dx + cos_a * dy + center.y
  return {x=math.floor(rx+0.5), y=math.floor(ry+0.5)}
end

function rotateChild(node,angle)
    local newNodePos = rotate_point(node.bx,node.by,selected_node.x,selected_node.y,angle)
    node.x = newNodePos.x
    node.y = newNodePos.y
	local skin_layer = findLayerByName(bone_sprite, node.name)
	if skin_layer == nil then
		return
	end
	local skin_cel = skin_layer:cel(1)
	if not skin_cel or not skin_cel.image then
	 return
	end
	local offsetx= node.x - node.bx
	local offsety= node.y - node.by
	skin_cel.position = Point(node.bcx +offsetx, node.bcy +offsety )
	if dlg.data.rotator1 then
		for i,child in ipairs(node.children) do
		 rotateChild(child,angle)
		end
	end
			
end

function rotateTree(node,angle,withSkeleton)
	if node.image then
		rotateSelectLayerImage(node,angle,withSkeleton)
		--CreateTempImage(node,angle)
	end
	if dlg.data.rotator1 then
		for i,child in ipairs(node.children) do
		  rotateChild(child,angle)
		end
	end

end


function rotateSelectLayerImage(node,angle,withSkeleton)
---if withclid ,node ~= selected_node
	local srcImage = node.image
	--local cx, cy = selected_node.x , selected_node.y
	local cx, cy = node.x , node.y
	if not srcImage then
	  return
	end
	local skin_layer = findLayerByName(bone_sprite, node.name)
	if skin_layer == nil then
	  return
	end
	local skin_cel = skin_layer:cel(1)
	if not skin_cel or not skin_cel.image then
		return
	end
	if angle >= 360 then
	   angle = 0
	end
	local src_bounds = srcImage.bounds
	--local src_x, src_y = node.x  ,node.y 
	local src_x, src_y = node.bcx ,node.bcy
	local angle_rad = math.rad(angle)
	local cos_theta = math.cos(angle_rad)
	local sin_theta = math.sin(angle_rad)
	local maxSize = math.floor(srcImage.width * 1.416)
  	if math.floor(srcImage.height * 1.416) > maxSize then
    	maxSize = math.floor(srcImage.height * 1.416)
  	end
  	if maxSize%2 == 1 then
    	maxSize = maxSize + 1
  	end
	maxSize = math.min(selected_size.width,maxSize)
	local bone_local = Point(cx - src_x, cy - src_y)
    local corners = {
    rotatePoint(0, 0, bone_local, cos_theta, sin_theta),
    rotatePoint(srcImage.width, 0, bone_local, cos_theta,sin_theta),
    rotatePoint(0, srcImage.height, bone_local, cos_theta, sin_theta),
    rotatePoint(srcImage.width, srcImage.height, bone_local, cos_theta, sin_theta),
   }
    
  local min_x, max_x = 0, selected_size.width
  local min_y, max_y = 0, selected_size.height
  for _, pt in ipairs(corners) do
    min_x = math.min(min_x, pt.x)
    max_x = math.max(max_x, pt.x)
    min_y = math.min(min_y, pt.y)
    max_y = math.max(max_y, pt.y)
  end
  local new_w = math.ceil(max_x - min_x)
  local new_h = math.ceil(max_y - min_y)
  local new_image = Image(new_w,new_h,srcImage.colorMode)
  new_image:clear()
  local new_cel_pos = Point( math.floor(src_x + min_x),math.floor(src_y + min_y))
	for y = 0, new_h - 1 do
		for x = 0, new_w - 1 do
			local tx = x + min_x
			local ty = y + min_y
			local dx = tx - bone_local.x
			local dy = ty - bone_local.y
			local src_xf =  math.floor(cos_theta * dx + sin_theta * dy + bone_local.x)
			local src_yf = math.floor(-sin_theta * dx + cos_theta * dy + bone_local.y)
			--local color = get_bilinear_sample(srcImage, src_xf, src_yf)
			local color = Color(0,0,0,0)
			if dlg.data.nearestNeighbor then
			   color = nearestNeighborSample(srcImage, src_xf, src_yf)
			else 
			   color = get_bilinear_sample(srcImage, src_xf, src_yf)
			end
			new_image:putPixel(x, y, color)
		end
	end
	skin_cel.image = new_image

	skin_cel.position = new_cel_pos
	new_image:clear()
	--if withSkeleton then
	   --local newNodePos = rotate_point(node.bx,node.by,cx,cy,angle)
      -- node.x = newNodePos.x
       --node.y = newNodePos.y
	  -- local newNodePos = GetValidPoint(node.x+celOffsetx,node.y+celOffsety)
	  -- node.x = newNodePos.x
	  -- node.y = newNodePos.y
	--end 
end




function Rotar(image2Rot, angle)
  local maskColor = image2Rot.spec.transparentColor
  local maxSize = math.floor(image2Rot.width * 1.416)
  if math.floor(image2Rot.height * 1.416) > maxSize then
    maxSize = math.floor(image2Rot.height * 1.416)
  end
  if maxSize%2 == 1 then
    maxSize = maxSize + 1
  end
  -- maxSize is a even number
  local centeredImage = Image(maxSize, maxSize, image2Rot.colorMode)
  -- center image2Rot in the new image 'centeredImage'
  local image2RotPosition = Point((centeredImage.width - image2Rot.width) / 2, (centeredImage.height - image2Rot.height) / 2)
  for y=image2RotPosition.y, image2RotPosition.y + image2Rot.height - 1, 1 do
    for x=image2RotPosition.x, image2RotPosition.x + image2Rot.width - 1, 1 do
      centeredImage:drawPixel(x, y, image2Rot:getPixel(x - image2RotPosition.x, y - image2RotPosition.y))
    end
  end

  local pivot = Point(centeredImage.width / 2 - 0.5 + (image2Rot.width % 2) * 0.5, centeredImage.height / 2 - 0.5 + (image2Rot.height % 2) * 0.5)
  local outputImg = Image(centeredImage.width, centeredImage.height, image2Rot.colorMode)

  if angle == 0 then
    for y = 0 , centeredImage.height-1, 1 do
      for x = 0, centeredImage.width-1, 1 do
        local px = centeredImage:getPixel(x, y)
        outputImg:drawPixel(x, y, px)
      end
    end
  elseif angle == math.pi / 2 then
    for y = 0 , centeredImage.height-1, 1 do
      for x = 0, centeredImage.width-1, 1 do
        local px = centeredImage:getPixel(centeredImage.width - 1 - y, x)
        outputImg:drawPixel(x, y, px)
      end
    end
  elseif angle == math.pi * 3 / 2 then
    for y = 0 , centeredImage.height-1, 1 do
      for x = 0, centeredImage.width-1, 1 do
        local px = centeredImage:getPixel(y, centeredImage.height - 1 - x)
        outputImg:drawPixel(x, y, px)
      end
    end
  elseif angle == math.pi then
    for y = 0 , centeredImage.height-1, 1 do
      for x = 0, centeredImage.width-1, 1 do
        local px = centeredImage:getPixel(centeredImage.width - 1 - x, centeredImage.height - 1 - y)
        outputImg:drawPixel(x, y, px)
      end
    end
  else
    for y = 0 , centeredImage.height-1, 1 do
      for x = 0, centeredImage.width-1, 1 do
        local oposite = pivot.x - x
        local adyacent = pivot.y - y
        local hypo = math.sqrt(oposite^2 + adyacent^2)
        if hypo == 0.0 then
          local px = centeredImage:getPixel(x, y)
          outputImg:drawPixel(x, y, px)
        else
          local currentAngle = math.asin(oposite / hypo)
          local resultAngle
          local u
          local v
          if adyacent < 0 then
            resultAngle = currentAngle + angle
            v = - hypo * math.cos(resultAngle)
          else
            resultAngle = currentAngle - angle
            v = hypo * math.cos(resultAngle)
          end
          u = hypo * math.sin(resultAngle)
          if centeredImage.width / 2 - u >= 0 and
            centeredImage.height / 2 - v >= 0 and
            centeredImage.height / 2 - v < centeredImage.height and
            centeredImage.width / 2 - u < centeredImage.width then
            local px = centeredImage:getPixel(centeredImage.width / 2 - u, centeredImage.height / 2 - v)
            if px ~= maskColor then
              outputImg:drawPixel(x, y, px)
            end
          end
        end
      end
    end
  end
  return outputImg
end

function UpdateBoneTree(node)
    node.offset_x = node.x - node.bx
	node.offset_y = node.y - node.by
	node.bk_x = node.x
	node.bk_y = node.y
    for _,child in pairs(node.children) do
		UpdateBoneTree(child)
	end
end

function UpdateState(stateName)
    if cur_state ~= stateName then
		UpdateData(skeleton_tree)
		if (cur_state == state_pose) or (cur_state == state_offset) then
		   edit_stop()
		end
		cur_state = stateName
		if dlg then dlg:repaint() end
	end
end
function UpdateData(node,skin2Node)
	local layer = findLayerByName(bone_sprite, node.name)
	if layer and layer:cel(1) and layer:cel(1).image then
			--node.image = layer:cel(1).image:clone()
			--node.offset_x = layer:cel(1).position.x - node.bx
			--node.offset_y = layer:cel(1).position.y - node.by
			node.bcx = layer:cel(1).position.x
			node.bcy = layer:cel(1).position.y
			node.bx = node.x
			node.by = node.y
			--app.alert(layer:cel(1).position.x)
	end
	
    for _,child in pairs(node.children) do
		UpdateData(child,skin2Node)
	end
end


local function print_tree(node)
  local indent = string.rep("  ", node.depth)
  print(string.format("%s- %s (depth=%d)", indent,  node.name, node.depth))
  for i, child in ipairs(node.children) do
    print_tree(node.children[i])
  end
end


local function createFrame()
    ensureSkeleton()
    if not bone_sprite then
	   app.alert(L.err_no_sprite2)
	return
	end
    app.activeSprite = bone_sprite
	app.transaction(function()
	   local current_frame = bone_sprite.frames[1]
		if bone_sprite.frames[frame_index+1] == nil then
		   frame_index = frame_index + 1
           bone_sprite:newEmptyFrame(frame_index)
          end

	   for _, layer in ipairs(bone_sprite.layers) do
    -- Ignora la capa llamada sk_layer_name
		  if not layer.isGroup and layer.name ~= sk_layer_name then
		     local cel = layer:cel(current_frame)
		     if cel and cel.image then
			   local img_copy = cel.image:clone()
			   bone_sprite:newCel(layer, bone_sprite.frames[frame_index], img_copy, cel.position)
		  end
	    end
	    end
    end)
    app.refresh()

end



local function open_file_dialog()
  local open_file_dlg = Dialog(L.open_dlg_title)
  open_file_dlg:file{
    id = "open_path",
    label = L.open_label,
    title = L.open_file_title,
	filename = "load_pose_file",
    open = true,
    filetypes = {"json"},
  }
   open_file_dlg:button {
        id = "ok",
        text = L.ok,
        onclick = function()
            local filepath = open_file_dlg.data.open_path
            if filepath == "" then
                app.alert(L.err_sel_file)
                return
            end
            if not filepath:match("%.json$") then
                app.alert(L.err_json_type)
				return
            end
            local root = read_json_file(filepath)
		    if root then
				   skeleton_tree = {name=root.name,x=root.x,y=root.y,bx=root.bx,by=root.by,bcx=0,bcy=0,children={},index = 1,parent=nil,depth=1,image=nil,rotate = 0,offset_x=0,offset_y=0}
	               process_node(root,skeleton_tree)
		           dlg:repaint()
		           dlg:repaint()
		           bone_sprite = nil
		           bone_layer = nil
		           selected_size.width = math.floor(root.sprite_width)
		           selected_size.height = math.floor(root.sprite_height)
				   selected_size.label = selected_size.width .. "x" .. selected_size.height
		           ensureSkeleton()
	               local image = bone_layer:cel(1).image
	               image:clear()
                   drawNodeTree(skeleton_tree)
	               app.refresh()
				   open_file_dlg:close()
			else
				   app.alert(L.err_read_pose)
	        end
		end
		}
  open_file_dlg:button{ text = L.cancel, onclick = function() open_file_dlg:close() end }
  open_file_dlg:show{ wait = false }
end


local function save_file_dialog()
  local save_file_dlg = Dialog(L.save_dlg_title)
  save_file_dlg:file{
    id = "save_file",
    label = L.save_label,
    title = L.save_file_title,
	filename = "save_pose_data.json",
    save = true,
    filetypes = {"json"},
  }
  save_file_dlg:button {
        id = "ok",
        text = L.ok,
        onclick = function()
            local filepath = save_file_dlg.data.save_file
            if filepath == "" then
                app.alert(L.err_sel_file)
                return
            end

            -- Add .json extension if not present
            if not filepath:match("%.json$") then
                filepath = filepath .. ".json"				
            end
			-- Save to file
			local json_str = node_to_json_pretty(skeleton_tree) 
            local file = io.open(filepath, "w")
            if file then
                file:write(json_str)
                file:close()
                app.alert(string.format(L.saved_pose, filepath))
                save_file_dlg:close()
            else
                app.alert(L.err_save_pose)
            end
		end
		}
  save_file_dlg:button{ text = L.cancel, onclick = function() save_file_dlg:close() end }
  save_file_dlg:show{ wait = false }
 end

function createDiaglog()
	if dlg then
		dlg:close()
	end

	dlg = Dialog(L.main_title)
	-- El estado (modo actual, tamaño, nodo seleccionado) se dibuja dentro del
	-- canvas, no en labels: cambiar el texto de un label reajustaba el ancho del
	-- diálogo y hacía que Aseprite lo redimensionara y recolocara.
	dlg:entry{id="BoneName",label=L.bone_name}
	dlg:button{id="label", text=" + ", onclick=function()
	                                        addBoneNode()
											UpdateState(state_Add_bone_skin)
											end}
	dlg:button{id="delete_done", text=" - ", onclick=function() rmBoneChildNode()
	                                        UpdateState(state_Add_bone_skin)
	                                        end}
	dlg:button{id="bind", text=L.bind_skin, onclick=function()
	                             add_skin_layer(selected_node.name)
								 UpdateState(state_Add_bone_skin)
								 --moveSkLayer2Top()
								 end }
	dlg:button{id="bindLayer", text=L.bind_layer, onclick=function()
	                             bind_existing_layer()
								 UpdateState(state_Add_bone_skin)
								 end }
	dlg:button{id="autodetect", text=L.autodetect, onclick=function()
	                             autodetect_bones()
								 UpdateState(state_Add_bone_skin)
								 end }
	dlg:button{id="reparent", text=L.reparent, onclick=function()
			if selected_node == nil then
				app.alert(L.err_sel_bone)
				return
			end
			if selected_node.parent == nil then
				app.alert(L.err_no_root_delete)
				return
			end
			local candidates = {}
			collectParentCandidates(skeleton_tree, selected_node, candidates)
			if #candidates == 0 then return end
			local reDlg = Dialog{title=string.format(L.reparent_title, selected_node.name), parent=dlg}
			reDlg:combobox{id="newParent", label=L.parent_label, option=selected_node.parent.name, options=candidates}
			reDlg:button{id="ok", text=L.ok, onclick=function()
				local target = findNodeByName(skeleton_tree, reDlg.data.newParent)
				if target then
					reparentNode(selected_node, target)
					ensureSkeleton()
					local image = bone_layer:cel(1).image
					image:clear()
					drawNodeTree(skeleton_tree)
					dlg:repaint()
					app.refresh()
				end
				reDlg:close()
			end}
			reDlg:button{id="cancel", text=L.cancel, onclick=function() reDlg:close() end}
			reDlg:show()
			end }
	dlg:button{id="editPose", text=L.move_node, onclick=function()
	            withSkin = true
	            UpdateState(state_pose)
				edit_start()
				end}
	dlg:button{id="editOffset", text=L.move_bone_only, onclick=function()
	            withSkin = false
	            UpdateState(state_offset)
				edit_start()
				end}

	dlg:slider { id = "pos_x",
            label = L.pos_xy,
			text = "x",
			visible = false,
            min = 0,
            max = selected_size.width,
            value = 0,
			onchange=function()
				if not selected_node.image then
					app.alert(L.err_no_bound_image)
					return
				end
				updateOffset(selected_node,dlg.data.pos_x,dlg.data.pos_y)
				moveLayerPos(selected_node)
				app.refresh()
			 end
			}
    dlg:slider { id = "pos_y",
	        text ="y",
            min = 0,
            max = selected_size.height,
			visible = false,
            value = 0 ,
			onchange= function()

				if not selected_node.image then
					app.alert(L.err_no_bound_image)
					return
				end
				updateOffset(selected_node,dlg.data.pos_x,dlg.data.pos_y)
				moveLayerPos(selected_node)
				app.refresh()
			end
			}
	dlg:slider { id = "rotator",
            label = L.rotation,
            min = -180,
            max = 180,
            value = 0 ,
			onchange = function()
			local value = dlg.data.rotator
            local rounded_value = math.floor(value / 18 + 0.5) * 18
			dlg:modify{id = "rotator", value = rounded_value}
			 if rounded_value ~= last_rotate_value then
				 last_rotate_value = rounded_value
				if not selected_node.image then
					app.alert(L.err_no_bound_image)
					return
				end
				if rounded_value >= 180 then
					rounded_value = 0
				elseif rounded_value <= -180 then
					rounded_value = 0
				end

				selected_node.rotate = rounded_value
				UpdateState(state_rotate)
				if dlg.data.rotator1 or dlg.data.rotator2 then
					 rotateTree(selected_node,rounded_value)
					 if dlg.data.rotator1 then
					    local image = bone_layer:cel(1).image
	                    image:clear()
                        drawNodeTree(skeleton_tree)
	                    app.refresh()
					 end
				else
					 rotateTree(selected_node,rounded_value)
				end --rotateSelectLayerImage(selected_node.image,rounded_value)
				app.refresh()
			 end
			end

			}
	dlg:radio{ label=L.options, id = "rotator1",selected = true, text=L.with_children }
	   :radio{ id = "rotator2",  text=L.no_children }
dlg:separator()  
	dlg_canvas = dlg:canvas{
		id = "skeleton_canvas",
		width = 300,
		height = 400,
		autoScaling = true,
		onpaint = function(ev)
			node_positions = {}
			local ctx = ev.context
			-- Barra de estado dibujada en el canvas (no redimensiona la ventana).
			ctx:fillText(L.state_lbl .. " " .. cur_state, 2, 2)
			ctx:fillText(selected_size.label .. "  |  " .. (selected_node and selected_node.name or L.point_none), 2, 16)
			draw_skeleton(ev, skeleton_tree, 1, 34, 0)
		end,

		onmousedown = function(ev)
			local click_x, click_y = ev.x, ev.y
				for _, entry in ipairs(node_positions) do
					if click_x >= entry.x and click_x <= (entry.x + entry.width) and
						click_y >= entry.y and click_y <= (entry.y + entry.height) then
						--showCommandDialog(entry.node)
						UpdateState(state_Add_bone_skin)
						selected_node = entry.node
						dlg:modify { id = "pos_x", value = selected_node.x }
						dlg:modify { id = "pos_y", value = selected_node.y }
						dlg:modify{id = "rotator", value = selected_node.rotate}
						dlg:repaint()

						return
					end
				end
				selected_node = nil
		end
	}

	dlg:radio{ label=L.algorithm, id = "nearestNeighbor",selected = true,text=L.nearest }
	   :radio{ id = "bilinear",  text=L.bilinear }
	dlg:separator()
	
	dlg:button{id="load", text=L.load ,onclick=function()
	   open_file_dialog()
	   end}
	dlg:button{id="CreateKey", text=L.create_frame, onclick=function()
	createFrame()
	end}
	dlg:button{id="Save", text=L.save,onclick=function()
	 save_file_dialog()
	 end}
	dlg:button{id="close", text=L.close, onclick=function() dlg:close() end}

	dlg:show{wait = false}
end



-- Tamaño de trabajo: si hay un sprite abierto se usa su tamaño y el esqueleto
-- se monta sobre el; si no, se crea uno nuevo de 64x64 por defecto.
local activeSpr = app.activeSprite
if activeSpr then
  selected_size = { label = activeSpr.width .. "x" .. activeSpr.height, width = activeSpr.width, height = activeSpr.height }
else
  selected_size = { label = "64x64", width = 64, height = 64 }
end

custom_icon = Image(12,12)
custom_icon:clear()
local white = Color{r=255,g=255,b=255,a=255}
for y=1,icon_size do
  for x=1,icon_size do
    if bone_pixels[y][x] == 1 then
      custom_icon:drawPixel(x-1, y-1, white)
    end
  end
end

-- Raiz del esqueleto en el centro del lienzo.
skeleton_tree.x = math.floor(selected_size.width / 2)
skeleton_tree.y = math.floor(selected_size.height / 2)
skeleton_tree.bx = skeleton_tree.x
skeleton_tree.by = skeleton_tree.y
selected_node = skeleton_tree
-- Creación diferida: no tocamos el sprite al abrir. La capa BoneTree y el dibujo
-- del árbol se generan con ensureSkeleton() en la primera acción del usuario. El
-- árbol se ve igualmente en el canvas del diálogo (draw_skeleton), independiente
-- del sprite.
createDiaglog()