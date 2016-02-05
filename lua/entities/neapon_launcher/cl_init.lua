ENT.PrintName		= "Neapon Launcher"
ENT.Type 			= "anim"
ENT.Base 			= "base_gmodentity"
ENT.Author			= "Nebual"
ENT.Spawnable		= false

function ENT:Draw()
	self.Entity:DrawModel()
end
if !Neapon then Neapon = {GunModels = {},BulletModels={}} end
net.Receive("neapon_models",function(len)
	Neapon.GunModels = net.ReadTable()
	Neapon.BulletModels = net.ReadTable()
end)
