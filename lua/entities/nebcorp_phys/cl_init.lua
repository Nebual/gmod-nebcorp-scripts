ENT.Type 		= "anim"
ENT.Base 		= "base_anim"
ENT.PrintName 	= "Nebcorp Physics"
ENT.Category	= "Nebcorp"
ENT.Author		= "Nebual"
ENT.Purpose		= ";D"
ENT.Instructions	= ""

ENT.Spawnable		= true
ENT.AdminSpawnable	= false

ENT.RenderGroup = RENDERGROUP_OPAQUE

/*
Interestingly, two consecutive DrawModels of the same ent require a SetModelScale in between (does that gen a new model?)
*/

local NewCube = ClientsideModel( 'models/props/smallcubetrt.mdl', RENDERGROUP_BOTH )
NewCube:SetNoDraw( true ) NewCube:DrawShadow( false )

local mDisc = ClientsideModel( 'models/props_phx/construct/metal_angle360.mdl', RENDERGROUP_BOTH )
mDisc:SetNoDraw( true ) mDisc:DrawShadow( false )
local mSphereDual = ClientsideModel( 'models/hunter/misc/shell2x2.mdl', RENDERGROUP_BOTH )
mSphereDual:SetNoDraw( true ) mSphereDual:DrawShadow( false )
local mSphere = ClientsideModel( 'models/props_phx/ball.mdl', RENDERGROUP_BOTH )
mSphere:SetNoDraw( true ) mSphere:DrawShadow( false )

local function Draw( self )
	NewCube:SetMaterial(self:GetMaterial())
	NewCube:SetRenderOrigin(self:GetPos()) //NewCube:SetRenderOrigin( self:LocalToWorld( self:OBBCenter() ) )
	//NewCube:SetRenderAngles( self:GetAngles() )
	SetScale(NewCube,self.size)
	NewCube:DrawModel()
	NewCube:SetRenderOrigin(self:GetPos()+Vector(0,20,50)) //NewCube:SetRenderOrigin( self:LocalToWorld( self:OBBCenter() ) )
	SetScale(NewCube,self.size)
	NewCube:DrawModel()
end
local function DrawPlanet(self)
	mDisc:SetMaterial(self.mDiscMat)
	mDisc:SetRenderOrigin(self:GetPos())
	SetScale(mDisc,self.mDiscScale)
	mDisc:DrawModel()
	self.mSphereDualYaw= self.mSphereDualYaw + self.rotationSpeed
	mSphere:SetMaterial(self.mSphereMat)
	mSphere:SetRenderOrigin(self:GetPos()-Vector(0,0,self.radius))
	mSphere:SetRenderAngles(Angle(0,self.mSphereDualYaw,0))
	SetScale(mSphere,self.mSphereScale)
	mSphere:DrawModel()
	render.SetBlend(self.mSphere2Alpha)
	mSphere:SetMaterial(self.mSphere2Mat)
	mSphere:SetRenderOrigin(self:GetPos()-Vector(0,0,self.mSphere2Radius))
	mSphere:SetRenderAngles(Angle(0,self.mSphereDualYaw*2,0))
	SetScale(mSphere,self.mSphere2Scale)
	mSphere:DrawModel()
	render.SetBlend(self.mSphereDualAlpha)
	mSphereDual:SetMaterial(self.mSphereDualMat)
	mSphereDual:SetRenderOrigin(self:GetPos())
	//self.mSphereDualYaw= self.mSphereDualYaw + 0.05
	mSphereDual:SetRenderAngles(Angle(0,self.mSphereDualYaw,0))
	SetScale(mSphereDual,self.mSphereDualScale)
	mSphereDual:DrawModel()
	//render.SetBlend(0.8)
	render.SetBlend(1)
end

local function DrawBenchmark( self )
	local time = SysTime()
	local stuffs = {'models/props/smallcubetrt.mdl','models/props_phx/construct/metal_angle360.mdl'}
	for k=1,5000 do
		for k,v in pairs(stuffs) do
			local ent = cubs[v]
			if !ent then
				timer.Simple(0,function()
					ent = ClientsideModel(v,RENDERGROUP_BOTH)
					ent:SetNoDraw(true)
					ent:DrawShadow(false)
					cubs[v]=ent
				end)
				return
			end
			ent:SetRenderOrigin( self:GetPos())
			//ent:SetModelScale(Vector(self.ErrorCleanseOBB[1]/cubssize[v][1],self.ErrorCleanseOBB[2]/cubssize[v][2],self.ErrorCleanseOBB[3]/cubssize[v][3]))
			ent:DrawModel()
		end
	end
	//if !KeepTexture:GetBool() then render.MaterialOverride( 0 ) end
	//if !KeepColor:GetBool() then render.SetBlend( 1 ); render.SetColorModulation( 1, 1, 1 ) end
	print(SysTime()-time)
end
function ENT:Initialize()
	self.Entity:DrawShadow( false )
	self.Entity.size = (self.Entity:OBBMaxs() - self.Entity:OBBMins())/2
	self.mSphere2Alpha = 0.6
	self.mSphereDualAlpha = 0.4
	self.rotationSpeed = 0.025
	self.radius = self.Entity.size[1]
	self.Entity:SetRenderBounds( Vector(2000,2000,2000), Vector(-2000,-2000,-2000) )
	
	timer.Create("NCPhys_"..self:EntIndex(),0.8,1,function()
		if not IsValid(self.Entity) then return end
		if(self.Entity:GetNWBool("planet")) then
			self.radius = self.Entity.size[1]
			self.mSphere2Radius = self.radius
			self.mSphereDualYaw = 0
			self.mDiscScale = Vector(2*self.radius/95.3,2*self.radius/95.3,1)
			//self.mSphereDualScale = Vector(2*self.radius/95.3,2*self.radius/95.3,2*self.radius/95.3)
			//self.mSphereScale = Vector(2*self.radius/42.5,2*self.radius/42.5,2*self.radius/42.5)
			self.mSphereDualScale = Vector(2*self.radius/95.3,2*self.radius/95.3,2*self.radius/96)
			self.mSphereScale = Vector(2*self.radius/42.5,2*self.radius/42.5,2*self.radius/42.5)
			self.mSphere2Scale = Vector(2*self.radius/42,2*self.radius/42,2*self.radius/42)
			if !self.mDiscMat then self.mDiscMat = self.Entity:GetNWString("mDiscMat","") end
			if !self.mSphereDualMat then self.mSphereDualMat = self.Entity:GetNWString("mSphereDualMat","spacebuild/Hazard2") end
			if !self.mSphereMat then self.mSphereMat = self.Entity:GetNWString("mSphereMat","Cmats/genfield") end
			if !self.mSphere2Mat then self.mSphere2Mat = self.Entity:GetNWString("mSphere2Mat","models/props/de_tides/clouds") end
			//self.mDiscMat = self.Entity:GetNWString("mDisc","Cmats/genfield")
			//self.Entity:SetRenderBounds( self.Entity:OBBMaxs(), self.Entity:OBBMins() )
			print("Setting up planet of radius: "..self.radius)
			self.Entity:SetRenderBounds( Vector(self.radius,self.radius,self.radius), Vector(-self.radius,-self.radius,-self.radius) )
			self.Entity:SetRenderBounds( Vector(self.radius,self.radius,self.radius), Vector(-self.radius,-self.radius,-self.radius) )
			self.Entity.RenderOverride = DrawPlanet
			self.Entity.Draw = DrawPlanet
		else
			self.radius = nil
			self.Entity.RenderOverride = Draw
			self.Entity.Draw = Draw
			self.Entity:SetRenderBounds( self.Entity:OBBMaxs(), self.Entity:OBBMins() )
			self.Entity:SetRenderBounds( self.Entity:OBBMaxs(), self.Entity:OBBMins() )
			//self.Entity:SetRenderBounds( self.Entity:OBBMaxs(), self.Entity:OBBMins() )
		end
	end)
	
//	self.size = Vector(self.Entity.ErrorCleanseOBB[1],self.Entity.ErrorCleanseOBB[2],1)
//	self.Entity:SetCollisionBounds(-self.size,self.size)
    /*self.Entity:PhysicsInit(SOLID_VPHYSICS)
	self.Entity:PhysicsInitBox(Vector( -300, -300, 0 ), Vector( 300, 300, 8 ))
	self.Entity:GetPhysicsObject():EnableMotion(false)
	self.Entity:SetCollisionBounds(Vector( -300, -300, 0 ), Vector( 300, 300, 8 ))
	//self.Entity:SetCollisionGroup(0)
	self.Entity:SetMoveType( MOVETYPE_NONE )
	self.Entity:SetSolid( SOLID_VPHYSICS )*/
end


net.Receive( "NCPhys_Vars", function(len)
	local ent, tab = net.ReadEntity(), net.ReadTable()
	if tab.mSphereMat then ent.mSphereMat = tab.mSphereMat end
	if tab.mSphere2Mat then ent.mSphere2Mat = tab.mSphere2Mat end
	if tab.mSphereDualMat then ent.mSphereDualMat = tab.mSphereDualMat end
	if tab.mDiscMat then ent.mDiscMat = tab.mDiscMat end
	if tab.mSphere2Alpha then ent.mSphere2Alpha = tab.mSphere2Alpha/255 end
	if tab.mSphereDualAlpha then ent.mSphereDualAlpha = tab.mSphereDualAlpha/255 end
	if tab.rotationSpeed then ent.rotationSpeed = tab.rotationSpeed end
	if tab.mSphere2Scale then 
		if !ent.radius then
			timer.Create("NCPhys_sphere2scale"..ent:EntIndex(),2,1,function()
				ent.mSphere2Radius = ent.radius*tab.mSphere2Scale
				ent.mSphere2Scale = Vector(2*ent.mSphere2Radius/42,2*ent.mSphere2Radius/42,2*ent.mSphere2Radius/42)
			end)
		else 
			ent.mSphere2Radius = ent.radius*tab.mSphere2Scale
			ent.mSphere2Scale = Vector(2*ent.mSphere2Radius/42,2*ent.mSphere2Radius/42,2*ent.mSphere2Radius/42)
			
		end
	end
end)
