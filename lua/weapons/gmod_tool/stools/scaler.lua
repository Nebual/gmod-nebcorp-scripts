TOOL.Category		= "Construction"
TOOL.Name			= "#tool.scaler.name"

TOOL.ClientConVar[ "scalex" ] = "2"
TOOL.ClientConVar[ "scaley" ] = "2"
TOOL.ClientConVar[ "scalez" ] = "2"
TOOL.ClientConVar[ "lock" ] = "1"
TOOL.ClientConVar[ "units" ] = "0"

if CLIENT then
	language.Add( "tool.scaler.name", "Scaler (Visual)" )
	language.Add( "tool.scaler.desc", "Holographically enlarges props" )
	language.Add( "tool.scaler.0", "Left click to scale, right click to reset, R to copy scale" )
end

function TOOL:LeftClick( trace )
	if !IsValid(trace.Entity) || trace.Entity:EntIndex() == 0 then return end
	if CLIENT then return true end
	if self:GetClientInfo("units") == "0" then
		SetScale(trace.Entity, Vector(tonumber(self:GetClientInfo("scalex")),tonumber(self:GetClientInfo("scaley")),tonumber(self:GetClientInfo("scalez"))), 1)
	else
		local propsize = trace.Entity:OBBMaxs() - trace.Entity:OBBMins()
		SetScale(trace.Entity, Vector(math.Max(tonumber(self:GetClientInfo("scalex")) / propsize.x, 0.01), math.Max(tonumber(self:GetClientInfo("scaley")) / propsize.y, 0.01), math.Max(tonumber(self:GetClientInfo("scalez")) / propsize.z, 0.01)), 1)
	end
end

function TOOL:RightClick( trace )
	if !IsValid(trace.Entity) || trace.Entity:EntIndex() == 0 then return end
	if CLIENT then return true end
	SetScale(trace.Entity, Vector(1,1,1), 1)
end

function TOOL:Reload( trace )
	if !IsValid(trace.Entity) || trace.Entity:EntIndex() == 0 then return end
	if CLIENT then
		local scale = trace.Entity.OldScale or Vector(1,1,1)
		RunConsoleCommand("scaler_scalex",scale[1])
		RunConsoleCommand("scaler_scaley",scale[2])
		RunConsoleCommand("scaler_scalez",scale[3])
		RunConsoleCommand("scaler_units","0")
	end
end

function TOOL.BuildCPanel( panel )
	local lock, changing
	local old = {2,2,2}
	local scalesliders = {
		panel:NumSlider("X:", "scaler_scalex", 0.01, 10, 2),
		panel:NumSlider("Y:", "scaler_scaley", 0.01, 10, 2),
		panel:NumSlider("Z:", "scaler_scalez", 0.01, 10, 2),
	}
	for k=1,3 do
		scalesliders[k].OnValueChanged = function(wang, value)
			if changing then return end
			local diff = value - old[k]
			old[k] = value
			for k2=1,3 do 
				if k != k2 then 
					old[k2]=old[k2]+diff 
					if lock:GetChecked() then
						changing = true
						scalesliders[k2]:SetValue(old[k2])
						changing = false
					end
				end
			end
		end
	end
	lock = panel:CheckBox( "Lock XYZ", "scaler_lock")
	local units = panel:CheckBox( "Set size in Garries rather than Multiplier", "scaler_units")
	//lock = panel:AddControl( "CheckBox", { Label = "Lock XYZ", Description = "", Command = "scaler_lock" }  )
	//local units = panel:AddControl( "CheckBox", { Label = "Set size in Garries rather than Multiplier", Description = "", Command = "scaler_units" }  )
	//units.OnChange = function(self) if self:GetChecked()lock:SetValue(self:GetChecked() and 0 or 1) end
end