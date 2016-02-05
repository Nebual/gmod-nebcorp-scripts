ENT.PrintName		= "Neapon Projectile"
ENT.Type 			= "anim"
ENT.Base 			= "base_gmodentity"
ENT.Author			= "Nebual"
ENT.Spawnable		= false

function ENT:Draw()
	self.Entity:DrawModel()
end
function ENT:Initialize()
	if self:GetModel() == "models/props_phx/amraam.mdl" then
		self.Think = function(self)
			local AngVec = self.Entity:GetAngles():Forward()
			local Offset = self.Entity:GetPos() + (self.Entity:GetAngles():Up() * 9) + (AngVec * -85)
			local rcolor = math.random(220, 235)
			
			local emitter = ParticleEmitter( Offset )
			for i=1, 10 do
				local particle = emitter:Add( "particle/smokestack", Offset + Vector(math.random(-5,5),math.random(-5,5),math.random(-5,5)) + (AngVec * math.random(-17,17)) )

				particle:SetVelocity( (AngVec + Vector(math.sin(math.random() * math.Rand(-0.3, 0.3)), math.sin(math.random() * math.Rand(-0.3, 0.3)), math.sin(math.random() * math.Rand(-0.3, 0.3)))) * -200)
				particle:SetDieTime( 10 )
				particle:SetStartAlpha( 240 )
				particle:SetEndAlpha( 0 )
				particle:SetStartSize( 8 )
				particle:SetEndSize( 160 )
				particle:SetRoll( math.Rand( -5, 5 ) )
				particle:SetRollDelta( 0 )
				particle:SetAirResistance(30)
				particle:SetColor( rcolor,rcolor,rcolor )
						
				emitter:Finish()
			end
			
			for i=1, 10 do
				local particle = emitter:Add( "effects/fire_cloud1", Offset + Vector(math.random(-5,5),math.random(-5,5),math.random(-5,5)) + (AngVec * math.random(-17,17)) )

				particle:SetVelocity( (AngVec + Vector(math.sin(math.random() * math.Rand(-0.4, 0.4)), math.sin(math.random() * math.Rand(-0.4, 0.4)), math.sin(math.random() * math.Rand(-0.4, 0.4)))) * -300)
				particle:SetDieTime( 0.5 )
				particle:SetStartAlpha( 255 )
				particle:SetEndAlpha( 0 )
				particle:SetStartSize( 14 )
				particle:SetEndSize( 16 )
				particle:SetRoll( math.Rand( -5, 5 ) )
				particle:SetRollDelta( 0 )
				particle:SetAirResistance(10)
				particle:SetColor( 255,255,255 )
				particle:SetLighting(1)
						
				emitter:Finish()
			end
			
			/*elseif self:IsOn() == 2 then
			
				local Ang = self.Entity:GetAngles()
				local Pos = self.Entity:GetPos() + (Ang:Up() * 9)
				local AngVec = self.Entity:GetAngles():Forward()
				local Offset = Pos + (AngVec * -85)
				local rcolor = math.random(160, 190)
				
				local emitter = ParticleEmitter( Offset )
				
					local particle = emitter:Add( "particle/smokestack", Offset + Vector(math.random(-5,5),math.random(-5,5),math.random(-5,5)))
					particle:SetVelocity( Vector(math.random(-5,5),math.random(-5,5),math.random(-5,5)+20) )
					particle:SetDieTime( 10 )
					particle:SetStartAlpha( 255 )
					particle:SetEndAlpha( 0 )
					particle:SetStartSize( 16 )
					particle:SetEndSize( 25 )
					particle:SetRoll( math.Rand( -2, 2 ) )
					particle:SetRollDelta( 0 )
					particle:SetAirResistance(0)
					particle:SetColor( rcolor,rcolor,rcolor )
							
					emitter:Finish()
			end*/
		end
	end
end