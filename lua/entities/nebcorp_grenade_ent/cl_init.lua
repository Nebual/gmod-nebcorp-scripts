ENT.PrintName		= "Multipurpose Grenade"
ENT.Type = "anim"
ENT.Base 		= "base_gmodentity"
ENT.Author			= "Nebual"

/*---------------------------------------------------------
Draw
---------------------------------------------------------*/
function ENT:Draw()
	self.Entity:DrawModel()
end


/*---------------------------------------------------------
IsTranslucent
---------------------------------------------------------*/
function ENT:IsTranslucent()
	return true
end


