TOOL.Category		= "Render"
TOOL.Name			= "#tool.sortedmaterial.name"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.ClientConVar[ "override" ] = "debug/env_cubemap_model"

if CLIENT then
	language.Add( "tool.sortedmaterial.name", "Material - Sorted" )
	language.Add( "tool.sortedmaterial.choose", "Material to apply:" )
	language.Add( "tool.sortedmaterial.desc", "A better way to Change an object's material" )
	language.Add( "tool.sortedmaterial.0", "Left click to apply material, Right click to remove, Reload to copy" )
else
	resource.AddFile("data/nebcorp/material_surfaceprops_default.txt")
	//include("autotextures.lua")
end

local function SetMaterial( Player, Entity, Data )
	Entity:SetMaterial( Data.MaterialOverride )
	if ( SERVER ) then duplicator.StoreEntityModifier( Entity, "material", Data ) end
	return true
end
duplicator.RegisterEntityModifier( "material", SetMaterial )

function TOOL:LeftClick( trace )
	if !IsValid(trace.Entity) || trace.Entity:EntIndex() == 0 then return end

	SetMaterial( self:GetOwner(), trace.Entity, { MaterialOverride = self:GetClientInfo( "override" ) } )
	return true

end



function TOOL:RightClick( trace )
	if !IsValid(trace.Entity) || trace.Entity:EntIndex() == 0 then return end

	SetMaterial( self:GetOwner(), trace.Entity, { MaterialOverride = "" } )
	return true
end

function TOOL:Reload( trace )
	if trace.Entity:IsWorld() then return false end
	if CLIENT then 
		timer.Create("SortedMaterialClipboard",0.5,1,function() SetClipboardText( GetConVarString("sortedmaterial_override")) end) 
		return true 
	end
	
	self:GetOwner():ConCommand("sortedmaterial_override "..trace.Entity:GetMaterial())
	return true
end

list.Add( "OverrideMaterials", "models/wireframe" )
list.Add( "OverrideMaterials", "debug/env_cubemap_model" )
list.Add( "OverrideMaterials", "models/shadertest/shader3" )
list.Add( "OverrideMaterials", "models/shadertest/shader4" )
list.Add( "OverrideMaterials", "models/shadertest/shader5" )
list.Add( "OverrideMaterials", "models/shiny" )
list.Add( "OverrideMaterials", "models/debug/debugwhite" )
list.Add( "OverrideMaterials", "Models/effects/comball_sphere" )
list.Add( "OverrideMaterials", "Models/effects/comball_tape" )
list.Add( "OverrideMaterials", "Models/effects/splodearc_sheet" )
list.Add( "OverrideMaterials", "Models/effects/vol_light001" )
list.Add( "OverrideMaterials", "models/props_combine/stasisshield_sheet" )
list.Add( "OverrideMaterials", "models/props_combine/portalball001_sheet" )
list.Add( "OverrideMaterials", "models/props_combine/com_shield001a" )
list.Add( "OverrideMaterials", "models/props_c17/frostedglass_01a" )
list.Add( "OverrideMaterials", "models/props_lab/Tank_Glass001" )
list.Add( "OverrideMaterials", "models/props_combine/tprings_globe" )
list.Add( "OverrideMaterials", "models/rendertarget" )
list.Add( "OverrideMaterials", "models/screenspace" )
list.Add( "OverrideMaterials", "brick/brick_model" )
list.Add( "OverrideMaterials", "models/props_pipes/GutterMetal01a" )
list.Add( "OverrideMaterials", "models/props_pipes/Pipesystem01a_skin3" )
list.Add( "OverrideMaterials", "models/props_wasteland/wood_fence01a" )
list.Add( "OverrideMaterials", "models/props_foliage/tree_deciduous_01a_trunk" )
list.Add( "OverrideMaterials", "models/props_c17/FurnitureFabric003a" )
list.Add( "OverrideMaterials", "models/props_c17/FurnitureMetal001a" )
list.Add( "OverrideMaterials", "models/props_c17/paper01" )
list.Add( "OverrideMaterials", "models/flesh" )

if SERVER then
	local SurfaceProps = util.JSONToTable(file.Read("nebcorp/material_surfaceprops_sv.txt","DATA") or "{}")
	util.AddNetworkString("sortedmaterial_refresh")
	local function RefreshTags(ply,cmd,args)
		if IsValid(ply) then
			net.Start("sortedmaterial_refresh") net.WriteTable(SurfaceProps) net.Send(ply)
		else
			net.Start("sortedmaterial_refresh") net.WriteTable(SurfaceProps) net.Broadcast()
		end
	end
	concommand.Add("sortedmaterial_refresh", RefreshTags)
	
	local function AddTag(ply,cmd,args)
		if !args[1] || !args[2] then return end
		SurfaceProps[args[1]] = args[2]
		timer.Create("SaveSurfaceProps", 10, 1, function() file.Write("nebcorp/material_surfaceprops_sv.txt", util.TableToJSON(SurfaceProps)) RefreshTags() end)
	end
	concommand.Add("sortedmaterial_tag", AddTag)
end

if CLIENT then 
	local sortedMaterialCPanel, filter
	local tags = {"wood","metal","wall","floor","glass","plastic",""}
	function TOOL.BuildCPanel( panel )
		sortedMaterialCPanel = panel
		NebcorpMaterialCPanel(panel)
	end
	function TOOL:Deploy()
		if sortedMaterialCPanel then NebcorpMaterialCPanel(sortedMaterialCPanel) end
	end


	concommand.Add("sortedmaterial_filter", function(ply,cmd,args)
		if args[1] != "" then filter = args[1] else filter = nil end
		NebcorpMaterialCPanel(sortedMaterialCPanel)
	end)

	local SurfaceProps = util.JSONToTable(file.Read("nebcorp/material_surfaceprops.txt","DATA") or file.Read("nebcorp/material_surfaceprops_default.txt","DATA") or "{}")
	local metatable = {
		__index = function(object, key)
			local mat = Material(key):GetString("$surfaceprop") or ""
			object[key] = mat
			timer.Create("SaveSurfaceProps", 10, 1, function() file.Write("nebcorp/material_surfaceprops.txt", util.TableToJSON(SurfaceProps)) end) -- To prevent lots of writes in a short time, its a timer
			return mat
		end,
	}
	SurfaceProps = setmetatable(SurfaceProps, metatable) 
	
	net.Receive("sortedmaterial_refresh", function(len)
		for k,v in pairs(net.ReadTable()) do SurfaceProps[k] = v end
		NebcorpMaterialCPanel(sortedMaterialCPanel)
	end)
	RunConsoleCommand("sortedmaterial_refresh")
	
	function NebcorpMaterialCPanel(CPanel)
		if !CPanel then return end
		CPanel:ClearControls()
		CPanel:SetTooltip( "#tool.sortedmaterial.desc" )
		local searchbox = CPanel:AddControl( "TextBox", {
				Label = "Filter:",
				Command = "sortedmaterial_filter",
			})
			
		local read = {}
		local tab = {}
		for k,v in ipairs(list.Get("OverrideMaterials")) do
			if !read[v] then
				read[v] = true
				if !filter || string.find(v, filter) || string.find(SurfaceProps[v] or "", filter) then
					table.insert(tab,v)
				end
			end
		end
		table.sort(tab)
		local MatSelect = CPanel:MatSelect( "sortedmaterial_override", tab, true, 0.33, 0.33 )
		
		local function MatMenu( icon ) 
			local menu = DermaMenu()
				menu:AddOption( "Copy to Clipboard", function() SetClipboardText( icon.Value ) end )
				menu:AddSpacer()
				local submenu = menu:AddSubMenu( "Add Tag", function() local b end )
					for _,tag in pairs(tags) do
						submenu:AddOption(tag, function()
							local tag = SurfaceProps[icon.Value] .. " " .. tag
							SurfaceProps[icon.Value] = tag
							icon:SetTooltip(icon.Value .. " ["..tag.."]")
							RunConsoleCommand("sortedmaterial_tag", icon.Value, tag)
							timer.Create("SaveSurfaceProps", 10, 1, function() file.Write("nebcorp/material_surfaceprops.txt", util.TableToJSON(SurfaceProps)) end)
						end)
					end
				local submenu = menu:AddSubMenu( "Set Tag", function() local b end )
					for _,tag in pairs(tags) do
						submenu:AddOption(tag, function()
							SurfaceProps[icon.Value] = tag
							icon:SetTooltip(icon.Value .. " ["..tag.."]")
							RunConsoleCommand("sortedmaterial_tag", icon.Value, tag)
							timer.Create("SaveSurfaceProps", 10, 1, function() file.Write("nebcorp/material_surfaceprops.txt", util.TableToJSON(SurfaceProps)) end)
						end)
					end
				menu:AddOption( "Create Custom Tag", function() 
					g_SpawnMenu:HangOpen( true ) 
					Derma_StringRequest("Create Custom Tag","What should the tag be called?","",function( strTextOut ) table.insert(tags, strTextOut ) NebcorpMaterialCPanel(_, CPanel) end)
				end )
			menu:Open()
		end
		for k, v in pairs( MatSelect.List:GetItems() ) do
			//v.DoRightClick = function() SetClipboardText(v.Value) end
			v.DoRightClick = MatMenu
			v:SetTooltip(v.Value .. " ["..SurfaceProps[v.Value].."]")
		end
		CPanel.MatSelecter = MatSelect
	end
end

