SWEP.Author 		= "Nebual"
SWEP.Contact 		= "nebual@nebtown.info"
SWEP.Purpose 		= "Fix shit"
SWEP.Instructions 	= "Left Click to repair Namaged entities\nRight click toggles Namage Immunity (alt for the whole contraption)"
SWEP.Category		= "Nebcorp"

SWEP.Base 			= "weapon_base"
SWEP.ViewModelFOV	= 62
SWEP.ViewModelFlip	= false
SWEP.ViewModel 		= "models/weapons/v_models/v_wrench_engineer.mdl"
SWEP.WorldModel 	= "models/weapons/w_models/w_wrench.mdl"
SWEP.AnimPrefix		= "python"

SWEP.Spawnable			= true
SWEP.AdminSpawnable		= true

SWEP.GotGlobalClip 	= true
SWEP.GotPrimary 	= true
SWEP.GotSecondary 	= false

SWEP.Primary.ClipSize		= 8					// Size of a clip
SWEP.Primary.DefaultClip	= 32				// Default number of bullets in a clip
SWEP.Primary.ShootInWater	= true
SWEP.Primary.Automatic		= true			// Automatic/Semi Auto
SWEP.Primary.Ammo			= "none"
SWEP.Primary.Reload 		= false

SWEP.Secondary.ClipSize 	= -1
SWEP.Secondary.DefaultClip 	= -1
SWEP.Secondary.Automatic 	= false
SWEP.Secondary.Ammo 		= "none"

SWEP.HoldType = "melee"

SWEP.PrintName 			= "Nebcorp Wrench"
SWEP.Slot 				= 2
SWEP.SlotPos 			= 2
SWEP.DrawCrosshair 		= false
SWEP.DrawAmmo			= false					// Should draw the default HL2 ammo counter
SWEP.DrawWeaponInfoBox	= false					// Should draw the weapon info box
SWEP.BounceWeaponIcon   = true					// Should the weapon icon bounce?
SWEP.ReloadTime			= 0
SWEP.Crosshair 			= "sprites/tf_crosshair_01"
SWEP.WepSelectIcon		= surface.GetTextureID( "sprites/bucket_wrench" )
SWEP.RenderGroup 		= RENDERGROUP_OPAQUE

// This is the corner of the speech bubble
SWEP.SpeechBubbleLid	= surface.GetTextureID( "gui/speech_lid" )
killicon.Add("tf_weapon_wrench","sprites/bucket_wrench", Color ( 255, 255, 255, 255 ) )

function SWEP:PrimaryAttack() end
function SWEP:SecondaryAttack() end
function SWEP:Reload() end

local Datatable = {}
local Datachanged = {}

local function maketextbox(parent, y, inputid, desc, outputid)
	local text = vgui.Create( "DLabel", parent )
	text:SetText( desc )
	text:SizeToContents()
	text:SetPos( 10, y )
	text:SetColor( Color( 255, 255, 255, 175 ) )

	local box = vgui.Create( "DTextEntry" , parent )
    box:SetPos( text:GetWide() + 15, y )
    box:SetTall( 20 )
    box:SetWide( parent:GetWide() - (25 + text:GetWide()) )
    box:SetValue( Datatable[inputid] )

    box.OnMousePressed  = function()
        local DermaText = vgui.Create( "DTextEntry" )
        DermaText:SetTall( 20 )
        DermaText:SetEnterAllowed( true )
        DermaText:SetValue(box:GetValue() or "")
        function DermaText:Think()
            local x ,y  = box:GetPos()
            local x2,y2 = parent:GetPos()
            DermaText:SetPos( x2+x,y2+y )
            DermaText:SetWide( box:GetWide( ) )	
        end
        
        DermaText.OnLoseFocus = function()
            box:UpdateConvarValue()
	        hook.Call( "OnTextEntryLoseFocus", nil, box )
            box:SetValue(DermaText:GetValue() or "")
            Datatable[inputid] = DermaText:GetValue()
			Datachanged[inputid] = true
			if outputid then 
				Datatable[outputid] = DermaText:GetValue() 
				Datachanged[outputid] = true
			end
            DermaText:Remove( ) 
        end
        DermaText:MakePopup()
        DermaText:RequestFocus( )
	end
	return text, box
end

local function makecheckbox(parent, y, inputid, desc, outputid)
	local box = vgui.Create( "DCheckBoxLabel", parent )
    box:SetPos( 10 , y )
    box:SetText( desc )
    box:SetValue( Datatable[inputid] or false)
    box:SizeToContents()
    box:SetTextColor(Color( 255, 255, 255, 175 ))
    box.OnChange = function()
        Datatable[inputid] = box.Button:GetChecked()
		Datachanged[inputid] = true
		if outputid then 
			Datatable[outputid] = box.Button:GetChecked()
			Datachanged[outputid] = true
		end
    end
	return box
end

// Help for adding more things to buttons:
// Use wipe(addy) where thats the total amount of y used by additions, including space between additions but not including anything above or below the additions. So a single textbox would be wipe(20), but two would be wipe(45)
// Since maketextbox has two components, it can only be used at the end of a list in {1, 2, 3, maketextbox} or by itself in table.Add(oldtab, {maketextbox})
/*
datastream12.Hook( "nebcorp_wrench_openmenu", function( handle, id, encoded, decoded )
	Datatable = decoded
	Datachanged = {}
	if type(Datatable.eimm) == "number" && Datatable.eimm == 2 then Datatable.efimm = true end
	
	local opts1,opts2,opts3 = {},{},{}

	local frame = vgui.Create( "DFrame" )
		frame:SetTitle( "Namage Utility" )
		frame:SetSize( 400, 90 )
		frame:SetSizable( false )
		//frame:Center()
		frame:SetPos((ScrW() - frame:GetWide()) / 2, ScrH() / 2 - 200)
		frame:MakePopup()
		
	local panel = vgui.Create( "DPanel", frame )
		panel:SetSize( frame:GetWide() - 10, frame:GetTall() - 85 )
		panel:SetPos( 5, 55 )
		function panel.Paint() 
			surface.SetDrawColor( 0, 0, 0, 235 )
			surface.DrawRect( 0, 0, panel:GetWide(), panel:GetTall() )
		end
		
	local apply = vgui.Create( "DButton", frame )
		apply:SetText( "Apply!!!" )
		apply:SetFont("DefaultLarge")
		apply:SetPos( 5 , frame:GetTall() - 28 )
		apply:SetSize(frame:GetWide() - 10, 25 )
		apply.DoClick = function()
			local ret = {ent = Datatable.ent, eimm = Datatable.eimm, ccon = Datatable.ccon, daem = Datatable.daem, daemid = Datatable.daemid, daemdupe = Datatable.daemdupe}
			
			if Datachanged.cimm then 
				if Datatable.cimm then ret.cimm = 1 else ret.cimm = 0 end
			end
			if Datachanged.cfimm && Datatable.cfimm then ret.cimm = 2 end
			if Datachanged.efimm && Datatable.efimm then ret.eimm = 2 end
			if Datachanged.emax then local temp = string.gsub(Datatable.emax, "%D", "") ret.emax = tonumber(temp) end
			if Datachanged.ecur then local temp = string.gsub(Datatable.ecur, "%D", "") ret.ecur = tonumber(temp) end
			datastream12.StreamToServer("nebcorp_wrench_closemenu", ret)
			frame:Remove()
		end
	
	local function wipe(newheight)
		for _,v in ipairs(opts1) do v:Remove() end
		for _,v in ipairs(opts2) do v:Remove() end
		for _,v in ipairs(opts3) do v:Remove() end
		opts1,opts2,opts3 = {},{},{}
		frame:SetSize(frame:GetWide(), 90 + newheight)
		panel:SetSize( frame:GetWide() - 10, frame:GetTall() - 85 )
		apply:SetPos( 5 , frame:GetTall() - 30 )
	end
	
	local button1 = vgui.Create( "DButton", frame )
		button1:SetFont("DefaultLarge")
		button1:SetText("Individual")
		button1:SetPos( 5 , 25 )
		button1:SetSize((frame:GetWide() - 20) / 2, 25 )
		button1.DoClick = function()
			wipe(90)
			opts1 = {
				makecheckbox(frame, 110, "eimm", "- Immunity 1: Won't die"),
				makecheckbox(frame, 130, "efimm", "- Immunity 2: Full"),
			}
			table.Add(opts1, {maketextbox(frame, 60, "emax", "Max Health:")})
			table.Add(opts1, {maketextbox(frame, 85, "ecur", "Set Health:")})
		end
	local button2 = vgui.Create( "DButton", frame )
		button2:SetFont("DefaultLarge")
		button2:SetText( "Contraption" )
		button2:SetPos( 10 + ((frame:GetWide() - 20) / 2) , 25 )
		button2:SetSize((frame:GetWide() - 20) / 2, 25 )
		button2.DoClick = function()
			wipe(120)
			opts2 = {
				makecheckbox(frame, 60, "eimm", "- Immunity 1: Won't die, CAN be ignited and Constraint Broken", "cimm"),
				makecheckbox(frame, 80, "efimm", "- Immunity 2: Full Invulnerability to everything", "cfimm"),
				makecheckbox(frame, 110, "ccon", "- Constraint Breaking (with wrench repairs)"),
				makecheckbox(frame, 140, "daem", "- Daemon Mode: Continuously apply these settings"),
				makecheckbox(frame, 160, "daemdupe", "- Persist Daemon after Duping"),
			}
		end
	//local text = vgui.Create( "DLabel", frame )
	//	text:SetText( "Please choose a model." )
	//	text:SizeToContents()
	//	text:SetPos( ((frame:GetWide() / 2) - (text:GetWide() / 2 )), 53 )
	//	text:SetColor( Color( 255, 255, 255, 175 ) )
	
	button1.DoClick()
	Datachanged = {} // Otherwise it thinks the initialization process is user input
end)
*/

function SWEP:TranslateFOV( current_fov )
	return current_fov
end

function SWEP:DrawWorldModel()
	local ent = self.Weapon
	ent:DrawModel()
	/*local owner = ent:GetOwner()
	if !IsValid(owner) then return true end

	local boneindex = owner:LookupBone("ValveBiped.Anim_Attachment_RH")
	if boneindex then
		local pos, ang = owner:GetBonePosition(boneindex)
		
		ent:SetPos(pos + ang:Forward()*30 + ang:Right()*0)

		ent:SetAngles(ang)
		return true
	end*/
end

function SWEP:CheckState() if IsValid(self) && IsValid(self.Owner) && self.Owner:GetActiveWeapon( ) == self then return true else return false end end

function SWEP:PlayIdle()
	if self:CheckState() then
		self.Weapon:SendWeaponAnim( ACT_VM_IDLE )
		self.Owner:SetAnimation( PLAYER_ATTACK1 )
		return true
	else
		return false
	end
end

/*---------------------------------------------------------
   Name: SWEP:Deploy( )
   Desc: Whip it out
---------------------------------------------------------*/
function SWEP:Deploy( )
	if !self then return end

	self.r_emit = false
	self.add_prim = nil

	self:Draw()
	return true
end

function SWEP:Draw()
	//if self.Owner:GetNetworkedInt( "ammo_metal" ) == 0 then return false end
	self.Weapon:SendWeaponAnim(ACT_VM_DRAW)
	timer.Create( "VM_Idle_anim_timer_2" .. self:EntIndex(), 1.6, 1, function() if self.Owner and (self.Owner:IsNPC() or ( self.Owner:IsPlayer() and self.Owner:GetActiveWeapon( ) == self )) then self:SendWeaponAnim( ACT_VM_IDLE ) end end )
	return true
end