if (SERVER) then
	AddCSLuaFile( "shared.lua" )
	SWEP.Weight		= 15
end

if ( CLIENT ) then
	SWEP.DrawAmmo			= false
	SWEP.PrintName			= "Handsless Swep"
	SWEP.Author				= "Nebual" // Sorta stolen from Cheesylard http://www.garrysmod.org/downloads/?a=view&id=38625
	SWEP.DrawCrosshair		= true
	//SWEP.WepSelectIcon		= surface.GetTextureID( "vgui/entities/weaponless" )
end

SWEP.Instructions	= ";D"

SWEP.Category = "Nebcorp" 

SWEP.Spawnable     			= true
SWEP.AdminSpawnable  		= false
SWEP.ViewModel				= ""
SWEP.WorldModel				= ""
SWEP.Slot 				= 2
SWEP.SlotPos 			= 3

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Ammo = "none"
SWEP.Primary.Automatic		= false
SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Ammo = false
SWEP.Secondary.Automatic = false

function SWEP:Initialize()
	self:SetWeaponHoldType("normal")
end 
function SWEP:Deploy()
	return true
end

function SWEP:PrimaryAttack()

end
function SWEP:SecondaryAttack()

end
function SWEP:Reload()

end