AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.Type = "anim"
ENT.PrintName       = "Wire Overlay Ent"
ENT.RenderGroup		= RENDERGROUP_OPAQUE
ENT.Spawnable = false
ENT.AdminOnly = false
ENT.IsWire = false

if CLIENT then 
	function ENT:Draw()
		self:DoNormalDraw()
		Wire_Render(self)
	end
	
	local edgesize = 18
	
	 -- makes sure the overlay doesn't go out of the screen & provides several useful sizes and positions for the DrawBody function
	function ENT:GetWorldTipPositions( w, h, w_body, h_body, w_footer, h_footer )
		local pos = LocalPlayer():GetEyeTrace().HitPos
		local spos = LocalPlayer():GetShootPos()
		if pos == spos then -- if the position is right in your face, get a better position
			pos = spos + LocalPlayer():GetAimVector() * 5
		end
		pos = pos:ToScreen()
		
		pos.x = math.Round(pos.x)
		pos.y = math.Round(pos.y)
		
		w = math.min( w, ScrW() - 64 )
		h = math.min( h, ScrH() - 64 )
		
		local maxx = pos.x - 32
		local maxy = pos.y - 32
		
		local minx = maxx - w
		local miny = maxy - h
		
		if minx < 32 then
			maxx = 32 + w
			minx = 32
		end
		
		if miny < 32 then
			maxy = 32 + h
			miny = 32
		end
		
		local centerx = (maxx+minx)/2
		local centery = (maxy+miny)/2
		
		return {	min = {x = minx,y = miny},
					max = {x = maxx,y = maxy}, 
					center = {x = centerx, y = centery},
					size = {w = w, h = h},
					bodysize = {w = w_body, h = h_body },
					footersize = {w = 0, h = 0},
					//footersize = {w = w_footer, h = h_footer},
					edgesize = edgesize
				}
	end

	-- This is overridable by other wire entities which want to customize the overlay, but generally you shouldn't override it
	function ENT:DrawWorldTipOutline( pos )
		draw.NoTexture()
		surface.SetDrawColor(Color(25,25,25,200))
		
		local poly = {
						{x = pos.min.x + edgesize, 	y = pos.min.y,				u = 0, v = 0 },
						{x = pos.max.x, 			y = pos.min.y,				u = 0, v = 0 },
						{x = pos.max.x, 			y = pos.max.y - edgesize,	u = 0, v = 0 },
						{x = pos.max.x - edgesize, 	y = pos.max.y,				u = 0, v = 0 },
						{x = pos.min.x, 			y = pos.max.y,				u = 0, v = 0 },
						{x = pos.min.x, 			y = pos.min.y + edgesize,	u = 0, v = 0 },
					}
		
		render.CullMode(MATERIAL_CULLMODE_CCW)
		surface.DrawPoly( poly )
		
		surface.SetDrawColor(Color(0,0,0,255))
		
		for i=1,#poly-1 do
			surface.DrawLine( poly[i].x, poly[i].y, poly[i+1].x, poly[i+1].y )
		end
		surface.DrawLine( poly[#poly].x, poly[#poly].y, poly[1].x, poly[1].y )
	end
	
	-- This is overridable by other wire entities which want to customize the overlay
	function ENT:GetWorldTipBodySize()
		local txt = self:GetOverlayData().txt
		if txt == "" then return 0,0 end
		return surface.GetTextSize( txt )
	end
	
	-- This is overridable by other wire entities which want to customize the overlay
	function ENT:DrawWorldTipBody( pos )
		local data = self:GetOverlayData()
		draw.DrawText( data.txt, "GModWorldtip", pos.center.x, pos.min.y + edgesize/2, Color(255,255,255,255), TEXT_ALIGN_CENTER )
	end
	
	-- This is overridable by other wire entities which want to customize the overlay
	function ENT:DrawWorldTip()
		local data = self:GetOverlayData()
		if not data then return end
		
		surface.SetFont( "GModWorldtip" )
		
		-- if data and data.txt then -- the entity has some text, draw it
		local txt = data.txt
	
		local w_body, 	h_body = self:GetWorldTipBodySize()
		
		local w_total = txt ~= "" and w_body or 0
		local h_total = txt ~= "" and h_body or 0
		
		if h_body == 0 then h_total = h_total - h_body - edgesize end
		
		local pos = self:GetWorldTipPositions( w_total + edgesize*2,h_total + edgesize,
												w_body,h_body,
												0,0 )

		self:DrawWorldTipOutline( pos )
		
		if h_body > 0 then
			self:DrawWorldTipBody( pos )
		end
	end
end

if CLIENT then return end -- no more client
