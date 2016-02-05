if SERVER then AddCSLuaFile() return end

hook.Add( "PopulateContent", "NebcorpHax", function( pnlContent, tree, node )
	PM_Content = pnlContent
	PM_Tree = tree
	PM_Node = node
end)

// Caching this up here just to speed up the loop down there
local function iconOpenMenu( icon )
	local menu = DermaMenu()
	menu:AddOption( "Copy to Clipboard", function() SetClipboardText( icon:GetModelName() ) end )
	menu:AddOption( "Spawn using Toolgun", function() RunConsoleCommand( "gmod_tool", "creator" ) RunConsoleCommand( "creator_type", "4" ) RunConsoleCommand( "creator_name", icon:GetModelName() ) end )

	local submenu = menu:AddSubMenu( "Re-Render", function() icon:RebuildSpawnIcon() end )
		submenu:AddOption( "This Icon", function() icon:RebuildSpawnIcon() end )
		submenu:AddOption( "All Icons", function() icon.ViewPanel:RebuildAll() end )

	menu:AddOption( "Edit Icon", function()
		
		local editor = vgui.Create( "IconEditor" )
		editor:SetIcon( icon )
		editor:Refresh()
		editor:MakePopup()
		editor:Center()
	
	end )

	local ChangeIconSize = function( w, h )
		
		icon:SetSize( w, h )
		icon:InvalidateLayout( true )
		icon.ViewPanel:OnModified()
		icon.ViewPanel:Layout()
		icon:SetModel( icon:GetModelName(), 0 )
	
	end

	local submenu = menu:AddSubMenu( "Resize", function() end )
		submenu:AddOption( "64 x 64 (default)", function() ChangeIconSize( 64, 64 ) end )
		submenu:AddOption( "64 x 128", function() ChangeIconSize( 64, 128 ) end )
		submenu:AddOption( "64 x 256", function() ChangeIconSize( 64, 256 ) end )
		submenu:AddOption( "64 x 512", function() ChangeIconSize( 64, 512 ) end )
		submenu:AddSpacer()
		submenu:AddOption( "128 x 64", function() ChangeIconSize( 128, 64 ) end )
		submenu:AddOption( "128 x 128", function() ChangeIconSize( 128, 128 ) end )
		submenu:AddOption( "128 x 256", function() ChangeIconSize( 128, 256 ) end )
		submenu:AddOption( "128 x 512", function() ChangeIconSize( 128, 512 ) end )
		submenu:AddSpacer()
		submenu:AddOption( "256 x 64", function() ChangeIconSize( 256, 64 ) end )
		submenu:AddOption( "256 x 128", function() ChangeIconSize( 256, 128 ) end )
		submenu:AddOption( "256 x 256", function() ChangeIconSize( 256, 256 ) end )
		submenu:AddOption( "256 x 512", function() ChangeIconSize( 256, 512 ) end )
		submenu:AddSpacer()
		submenu:AddOption( "512 x 64", function() ChangeIconSize( 512, 64 ) end )
		submenu:AddOption( "512 x 128", function() ChangeIconSize( 512, 128 ) end )
		submenu:AddOption( "512 x 256", function() ChangeIconSize( 512, 256 ) end )
		submenu:AddOption( "512 x 512", function() ChangeIconSize( 512, 512 ) end )

	menu:AddSpacer()
	menu:AddOption( "Delete", function() icon:Remove() hook.Run( "SpawnlistContentChanged" ) end )
	menu:Open()
	
end

hook.Add( "PopulateContent", "NCGameProps", function( pnlContent, tree, node )

	--
	-- Create a node in the `other` category on the tree
	--
	local MyNode = node:AddNode( "Games Full", "icon16/folder_database.png" )

	local ViewPanel = vgui.Create( "ContentContainer", pnlContent )
	ViewPanel:SetVisible( false )

	local games = engine.GetGames()
	/*table.insert( games, {
		title = "All",
		folder = "GAME",
		icon = "all",
		mounted = true
	} )*/
	table.insert( games, {
		title = "Garry's Mod",
		folder = "garrysmod",
		mounted = true
	} )
	
	--
	-- Create a list of mounted games, allowing us to browse them
	--
	for _, game in SortedPairsByMemberValue( games, "title" ) do
		
		if ( !game.mounted ) then continue end
		local gameNode = MyNode:AddNode(game.title)
		gameNode:SetIcon( "games/16/" .. ( game.icon or game.folder ) .. ".png" )
		gameNode.BrowseContentType = "models"
		gameNode.BrowseExtension = "*.mdl"
		gameNode.ContentType = "model"
		gameNode.ViewPanel = ViewPanel
		gameNode.title = game.title
		gameNode.image = "games/16/" .. ( game.icon or game.folder ) .. ".png"
		gameNode.folder = game.folder
		gameNode.ModelsIndex = 1
		//gameNode:CreateChildNodes()
		//gameNode:FilePopulateCallback( Models, {}, game.folder, "", bAndChildren ) 
		
		local function OnNodeSelected( slf, node )

			-- Already viewing this panel
			if ( ViewPanel && ViewPanel.CurrentNode && ViewPanel.CurrentNode == node ) then return end

			-- Clear the viewpanel in preperation for displaying it
			ViewPanel:Clear( true )
			ViewPanel.CurrentNode = node
			
			--
			-- Fill the viewpanel with models that are in this node's folder
			--
			if !node.Models then
				local path = "models"
				local Models = {}
				for _, model in pairs(file.Find( path .. "/*.mdl", node.folder )) do
					table.insert(Models, path .. "/" .. model)
				end
				local _, folders = file.Find( path .. "/*", node.folder )
				for _,v in pairs(folders) do
					if node.folder == "portal2" and (v == "container_ride" or v == "container_ride_360" or v == "a4_destruction" or v == "car_int_dest") then continue end
					local path = path .. "/" .. v
					for _, model in pairs(file.Find(path .. "/*.mdl", node.folder)) do
						table.insert(Models, path .. "/" .. model)
					end
					local _, folders = file.Find( path .. "/*", node.folder )
					for _, v in pairs(folders) do
						local path = path .. "/" .. v
						for _, model in pairs(file.Find(path .. "/*.mdl", node.folder)) do
							table.insert(Models, path .. "/" .. model)
						end
						local _, folders = file.Find( path .. "/*", node.folder )
						for _, v in pairs(folders) do
							local path = path .. "/" .. v
							for _, model in pairs(file.Find(path .. "/*.mdl", node.folder)) do
								table.insert(Models, path .. "/" .. model)
							end
							local _, folders = file.Find( path .. "/*", node.folder )
							for _, v in pairs(folders) do
								local path = path .. "/" .. v
								for _, model in pairs(file.Find(path .. "/*.mdl", node.folder)) do
									table.insert(Models, path .. "/" .. model)
								end
							end
						end
					end
				end
				print(node.folder .. " #" .. #Models)
				node.Models = Models
				
				for k=1001, #node.Models, 1000 do
					local subNode = node:AddNode(tostring(k-1).."+")
					subNode:SetIcon( node.image )
					subNode.BrowseContentType = "models"
					subNode.BrowseExtension = "*.mdl"
					subNode.ContentType = "model"
					subNode.ViewPanel = ViewPanel
					subNode.folder = node.folder
					subNode.Models = Models
					subNode.ModelsIndex = k
					subNode.OnNodeSelected = OnNodeSelected
				end
				node:SetExpanded(true)
			end
			
			local endpoint = math.Min(node.ModelsIndex + 1000, #node.Models)
			for k=node.ModelsIndex, endpoint do
				local model = node.Models[k]
				if !UTIL_IsUselessModel(model) then
					//local cp = spawnmenu.GetContentType( "model" )
					//cp( ViewPanel, { model = model } )
					
					local icon = vgui.Create( "SpawnIcon", ViewPanel )
					icon.ViewPanel = ViewPanel
					
					//if ( obj.body ) then obj.body = string.Trim( tostring(obj.body), "B" ) end
					//if ( obj.wide ) then icon:SetWide( obj.wide ) end
					//if ( obj.tall ) then icon:SetTall( obj.tall ) end
					
					icon:InvalidateLayout( true )
					icon:SetModel( model, 0 )
					icon:SetTooltip( string.Replace( string.GetFileFromFilename(model), ".mdl", "" ) )

					icon.DoClick = function( icon ) 
						surface.PlaySound( "ui/buttonclickrelease.wav") 
						RunConsoleCommand( "gm_spawn", icon:GetModelName(), icon:GetSkinID() or 0, icon:GetBodyGroup() or "" ) 
					end
					icon.OpenMenu = iconOpenMenu
					icon:InvalidateLayout( true )
					if ( IsValid( ViewPanel ) ) then
						ViewPanel:Add( icon )
					end
				end
			end

			--
			-- Switch to it
			--
			pnlContent:SwitchPanel( ViewPanel )
			ViewPanel.CurrentNode = node

		end
		
		gameNode.OnNodeSelected = OnNodeSelected

		//AddBrowseContent( ViewPanel, MyNode, game.title, "games/16/" .. ( game.icon or game.folder ) .. ".png", "", game.folder, pnlContent )
		
	end

end )

