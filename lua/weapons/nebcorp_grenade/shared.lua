AddCSLuaFile( "shared.lua" )

SWEP.PrintName			= "Nebcorp Grenade"
SWEP.Author				= "Nebual"
SWEP.Instructions		= ";D"
SWEP.Category 			= "Nebcorp" 

SWEP.Spawnable     		= true
SWEP.AdminSpawnable  	= false
SWEP.AutoSwitchTo		= true
SWEP.ViewModel 			= "models/weapons/v_eq_fraggrenade.mdl"
SWEP.WorldModel 		= "models/weapons/w_eq_fraggrenade.mdl"
SWEP.Slot 				= 4
SWEP.SlotPos 			= 1
SWEP.DrawCrosshair		= true
SWEP.DrawAmmo			= false

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Ammo 			= "none"
SWEP.Primary.Automatic		= false
SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Ammo 		= false
SWEP.Secondary.Automatic 	= false

SWEP.LastFire = 0
SWEP.Speed = 100 // More for Mouse1, less mouse2
for k=1, 7 do resource.AddFile("sound/grenade_"..k..".mp3" ) end
local PlayerChoices = {}
local PlayerPowers = {}

EMPStart = {
	gmod_wire_expression2 = function(ent)
		if !ent.Execute_EMPd then
			if ent.context then
				for name,_ in pairs(ent.context.data['timer'].timers) do timer.Pause("e2_" .. ent.context.data['timer'].timerid .. "_" .. name) end
			end
			ent.Execute_EMPd = ent.Execute
			ent.Execute = function() end
		end
	end,
	prop_vehicle_jeep = function(ent)
		ent:Fire("TurnOff",1,0)
	end,
}
EMPEnd = {
	gmod_wire_expression2 = function(ent)
		if ent.Execute_EMPd then
			ent.Execute = ent.Execute_EMPd
			ent.Execute_EMPd = nil
			if ent.context then
				for name,_ in pairs(ent.context.data['timer'].timers) do timer.UnPause("e2_" .. ent.context.data['timer'].timerid .. "_" .. name) end
			end
		end
	end,
	prop_vehicle_jeep = function(ent)
		ent:Fire("TurnOn",1,0)
	end,
}
NebcorpGrenades = {
	Frag = function(self)
		self.Shake = true
		self.Smoke = true
		self.ExplosionDamage = true
	end,
	Gravityless = function(self) 
		self.Shake = true
		self.Entity:GetPhysicsObject():EnableGravity(false)
		self.Smoke = true
		self.Sticky = true
		self.ExplosionDamage = true
		self.ExplosionPower = 80
		//self.Timer = 5
		self.Special = function(self)
			local arr = ents.FindInSphere(self.Entity:GetPos(),300)
			for k,v in pairs(arr) do 
				if v:IsPlayer() || v:IsNPC() then v:SetGravity(0.0001) v:SetVelocity(Vector(0,0,20) + v:WorldToLocal(self:GetPos()):GetNormalized()*40)
				elseif IsValid(v:GetPhysicsObject()) then v:GetPhysicsObject():EnableGravity(false) end 
			end
			timer.Create("GrenadeGravity_"..self.Entity:EntIndex(),math.Rand(2.5,4.5),1,function() 
				for k,v in pairs(arr) do 
					if IsValid(v) then 
						if v:IsPlayer() || v:IsNPC() then v:SetGravity(1)
						elseif IsValid(v:GetPhysicsObject()) then v:GetPhysicsObject():EnableGravity(true) end
					end
				end
			end)
		end
	end,
	Sticky = function(self)
		self.Shake = true
		self.Smoke = true
		self.ExplosionDamage = true
		self.Sticky = true
	end,
	Longbow = function(self)
		self.Shake = true
		self.Smoke = true
		self.ExplosionDamage = true
		self.Timer = 6 --Basically a punishment :P
		local vec,ent = self:GetPlayer():GetEyeTraceNoCursor().HitPos, self:GetPlayer():GetEyeTraceNoCursor().Entity
		timer.Create("Longbow_"..self.Entity:EntIndex(), 0.25, 1, function() 
			if (!IsValid(ent) && !ent:IsWorld()) || !IsValid(self.Entity) then return end
			self.Entity:EmitSound(Sound("HEGrenade.Bounce"))
			self.Entity:SetPos(vec) 
			constraint.Weld(self.Entity, ent, 0, 0, 0, true) 
		end)
	end,
	Bounce = function(self)
		self.Shake = true
		self.Smoke = true
		self.ExplosionDamage = true
		self.Timer = 5
		self.PhysicsCollide = function(self,data,phys)
			self.Entity:EmitSound(Sound("HEGrenade.Bounce"))
			phys:ApplyForceCenter((-data.Speed * data.HitNormal * 2) + (data.OurOldVelocity * -2.5))
		end
	end,
	Shark = function(self)
		self.Shake = true
		self.Timer = 3.5
		self.Special = function(self)
			local ent = ents.Create("prop_ragdoll")
			ent:SetModel("models/megalodon/megalodon.mdl")
			ent:SetPos(self.Entity:GetPos() + Vector(0,0,40))
			local vel = self.Entity:GetPhysicsObject():GetVelocity()
			if vel:Length() < 3 then vel = Vector(1,0,0) end
			ent:SetAngles(vel:Angle())
			ent:Spawn()
			timer.Create(ent:EntIndex().."Kill", 13, 1, function() if IsValid(ent) then ent:Remove() end end)
		end
	end,
	Electrolatency = function(self)
		self.Shake = true
		self.Timer = 9
		local time = CurTime() + 9.1
		self.Entity.EMP = function(self,time)
			for k,v in pairs(ents.FindInSphere(self.Entity:GetPos(), 360)) do
				local func = EMPStart[v:GetClass()]
				if func then 
					func(v)
					timer.Create("Undo_Electrolatency_"..v:EntIndex(), 1, 1, function()
						if !v:IsValid() then return end
						local func = EMPEnd[v:GetClass()]
						if func then func(v) end
					end)
				end
			end
		end
		timer.Create("StartElectrolatency"..self:EntIndex(),2,1,function()
			local spark = ents.Create("env_spark")
			spark:SetKeyValue("TrailLength",3)
			spark:SetKeyValue("MaxDelay",0.8)
			spark:SetKeyValue("Magnitude",8)
			spark:Fire("StartSpark",1,0)
			spark:SetPos(self.Entity:GetPos())
			spark:Spawn()
			timer.Create("PulseElectrolatency"..self.Entity:EntIndex(),0.5,13,function() spark:SetPos(self.Entity:GetPos()) self.Entity:EMP(time) end)
			timer.Create("KillElectrolatencySpark"..self.Entity:EntIndex(),7,1,function() spark:Remove() end)
		end)
	end,
	Bees = function(self)
		self.Special = function(self)
			local code = string.gsub( file.Read("e2storeddata/e2s/bee_v2.txt","DATA"), "%[br%]", "\n" )
			for k=1,8 do 
				local ent = createE2(self:GetPlayer(), code, self.Entity:GetPos() + Vector(0,0,10*k))
				timer.Create("KillE2"..ent:EntIndex(), math.random(20,40), 1, function() if ent:IsValid() then ent:Remove() end end)
			end
		end
	end,
	Waterbomb = function(self)
		self.ExplosionFire = false
		self.Shake = true
		self.Timer = 1.25
		self.Special = function(self)
			local pos = self.Entity:GetPos()
			local effectdata = EffectData()
			effectdata:SetOrigin( pos )
			effectdata:SetNormal( Vector(0,0,1) )
			effectdata:SetRadius( 350 )
			effectdata:SetScale( 350 )
			timer.Create("WaterBombSplash"..self.Entity:EntIndex(),0.15,5, function() util.Effect( "watersplash", effectdata ) end)
			timer.Create("WaterBombAction"..self.Entity:EntIndex(),0.75,1,function() 
				for _,v in pairs(ents.FindInSphere(pos,290)) do if v:IsOnFire() then v:Extinguish() elseif v:GetClass() == "npc_rollermine" then v:Fire("InteractivePowerDown",1,0) end end 
			end)
		end
	end,
	Boink = function(self)
		self.ExplosionFire = false
		self.Timer = 10
		local rand = table.Random({"Ball","Building","Sandvich","Scout","SoSmall"})
		self.Bonks = self.AllBonks[rand]
		local timername = "BoinkGrenade_"..self.Entity:EntIndex()
		local last
		self.TempFunc = function()
			if !IsValid(self.Entity) then return end
			local snd = table.Random(self.Bonks)
			while last == snd do snd = table.Random(self.Bonks) end
			last = snd
			self.Entity:EmitSound(snd)
			print(snd)
			timer.Create(timername,SoundDuration(snd)+0.1,1, self.TempFunc)
		end
		timer.Create(timername,1,1,self.TempFunc)
	end,
	Mine = function(self)
		self:SetModel("models/weapons/w_models/w_stickybomb.mdl")
		SetScale(self.Entity,Vector(0.4,0.4,0.4))
		self.Timer = 140
		self.Smoke = true
		self.ExplosionDamage = true
		self.Sticky = true
		self.Shake = true
		self:GetPlayer():GetActiveWeapon().LastFire = CurTime() + 0.3
		self.Think = function(self)
			if self.Done then return end
			for k,v in pairs(ents.FindInSphere(self.Entity:GetPos(),60)) do
				local class = v:GetClass()
				if string.Left(class,4) == "npc_" || class == "player" then 
					timer.Create("ExplodeGrenade_"..self.Entity:EntIndex(),0.65,1,function() self.Entity:Explode() end)
					self.Entity:EmitSound(Sound("weapons/c4/c4_beep1.wav"))
					timer.Create("ExplodeBeep_"..self.Entity:EntIndex(),0.25,2,function() self.Entity:EmitSound(Sound("weapons/c4/c4_beep1.wav")) end)
					self.Done = true return
				end
			end
			self.Entity:NextThink(CurTime() + 0.15) return true
		end
		self.OnRemove = function(self)
			self:Explode()
		end
		self.Entity:NextThink(CurTime() + 3)
	end,
	Force = function(self)
		self.Timer = 2.5
		self.Special = function(self)
			if !IsValid(self.Entity) then return end
			for k,v in pairs(ents.FindInSphere(self.Entity:GetPos(),300)) do
				if !IsValid(v:GetPhysicsObject()) then continue end
				v:GetPhysicsObject():ApplyForceCenter((v:GetPos() - self:GetPos() + Vector(0,0,60)):GetNormalized() * (200 - (v:GetPos():Distance(self:GetPos())))*4 *(  v:GetPhysicsObject():GetMass() / 100 ) ^ 0.8 * 300)
			end
		end
	end,
	Incendiary = function(self)
		self.Timer = 4
		self.Special = function(self)
			for k,v in pairs(ents.FindInSphere(self.Entity:GetPos(),200)) do
				time = (200 - (v:GetPos():Distance(self:GetPos())))/25
				v:Ignite(time)
				timer.Create("Unignite_"..v:EntIndex(),time+0.2,2,function() if v:IsValid() then v:Extinguish() end end)
			end
		end
	end,
	Lightning = function(self)
		self.Timer = 13
		self.Booms = {} 
		self.PlayedSound = false
		self.ThunderSounds = {}
		self.StrikeTick = function(self)
			for k=1,3 do
				if #self.Vecs==0 then break end
				CurVec = table.remove(self.Vecs,1)
				ZDist = (CurVec.z - self.BottomPos.z)*-0.6
				Pow = ZDist/2 // Width of vector spawning zone (lower to ground = more constrained, higher = arc wilder)
				
				local max=1
				if #self.Vecs < 6 then max=1+math.random(0,2) end
				for splits=1,max do
					CurDest = CurVec + Vector(math.random(-Pow,Pow),math.random(-Pow,Pow),ZDist)
					CurDest = CurDest + (self.BottomPos - CurDest) * Vector(0.1,0.1,0)
					//Removing this line will cause vectors to go out randomly, making it more realistic, but harder to aim.
					//Also, the 0.6 is really very arbitrary. Closer to 1 clamps the points harder.
					//NOTE: If you put this code into weather mod, remove it entirely or set the number to zero.
					if (CurVec.z + ZDist) > (self.BottomPos.z+60) then table.insert(self.Vecs,CurDest)
					else
						CurDest.z = self.BottomPos.z
						table.insert(self.Booms,CurDest)
					end
					
					local rope = constraint.CreateKeyframeRope( self:GetPos(), 20, "cable/blue_elec", nil, self, self:WorldToLocal(CurVec), 0, game.GetWorld(), CurDest, 0,{Slack = 0, Collide = 0})
					if ( IsValid( rope ) ) then
						rope:SetTable({
							Type 		= "Rope",
							Ent1 		= self,		Ent2 		= game.GetWorld(),
							Bone1 		= 0, Bone2 = 0,
							LPos1 		= LPos1,	LPos2 		= LPos2,
							addlength 	= 0,
							forcelimit 	= 0,
							width 		= 20,
							material 	= "cable/blue_elec",
							rigid		= false
						})
						constraint.AddConstraintTable( self, rope )
					end
				end
			end
			if #self.Vecs == 0 then
				if !self.PlayedSound then
					self.PlayedSound = true
					for k,v in pairs(player.GetAll()) do
						self.ThunderSounds[v] = CreateSound(v,"ambient/thunder"..math.random(2,4)..".wav")
					end
				end
				
				if #self.Booms == 0 then
					constraint.RemoveConstraints(self, "Rope")
					timer.Destroy("Lightning_"..self:EntIndex())
					return
				else
					for k,v in pairs(ents.FindInSphere(table.remove(self.Booms), 100)) do
						local dmginfo = DamageInfo()
						dmginfo:SetDamage( math.random(50,200) )
						dmginfo:SetDamageType( 64 )
						dmginfo:SetAttacker( self:GetPlayer() )
						v:TakeDamageInfo(dmginfo)
					end
				end
			end
		end
		self.Special = function(self)
			for k,v in pairs(self.ThunderSounds) do v:Stop() end
		end
		timer.Create("StartLightning_"..self:EntIndex(),3,1,function()
			local tr = util.TraceLine{start = self:GetPos(), endpos = self:GetPos() + Vector(0,0,3000), mask = bit.bor(MASK_WATER, CONTENTS_SOLID)}
			self.Vecs = {tr.HitPos}
			self.BottomPos = util.TraceLine{start = self:GetPos(), endpos = self:GetPos() + Vector(0,0,-30000), mask = MASK_WATER}.HitPos
			timer.Create("Lightning_"..self:EntIndex(),0.2,99,function() self:StrikeTick() end)
			//self.Namage.Immune = 1 // So it doesn't die before cleaning up
		end)
	end,

// self.ExplosionDamage[default on] self.ExplosionFire self.Timer self.Unfreeze self.Smoke self.Sticky self.Shake
}

function SWEP:Initialize() self:SetWeaponHoldType("grenade") end
function SWEP:Deploy()
	self.LastFire = CurTime() + 0.75
	self.Weapon:SendWeaponAnim(ACT_VM_DRAW)
	return true
end

function NebcorpGrenadePrep(self)
	if self.LastFire > CurTime() then return end
	self.LastFire = CurTime() + 60
	if CLIENT then 
		timer.Create("NebcorpGrenade",0.1,0,function()
			if !input.IsKeyDown(IN_ATTACK) then 
				self.LastFire = CurTime() + 1
				timer.Destroy("NebcorpGrenade")
			end
		end)
		return 
	end
	
	self.Weapon:SendWeaponAnim(ACT_VM_PULLPIN)
	local id = self.Owner:EntIndex()
	timer.Create("NCGrenade.Throw1_"..id,0.1,0,function()
		if !IsValid(self.Owner) || !IsValid(self.Weapon) then timer.Destroy("NCGrenade.Throw1_"..id) return end
		if !self.Owner:KeyDown(IN_ATTACK) then
			self.Weapon:SendWeaponAnim(ACT_VM_THROW)
			self.Owner:SetAnimation(PLAYER_ATTACK1)
			timer.Create("NCGrenade.Throw2_"..id,0.35,1, function() NebcorpGrenadeThrow(self) timer.Destroy("NCGrenade.Throw2_"..id) end)
			timer.Destroy("NCGrenade.Throw1_"..id)
		end
	end)
end
function NebcorpGrenadeThrow(self)
	if !IsValid(self.Owner) then return end
	self.LastFire = CurTime() + 1
	local ent = ents.Create("nebcorp_grenade_ent")
	ent.Kind = PlayerChoices[self.Owner] or "Frag" -- Set its type
	
	local v = self.Owner:GetShootPos() + self.Owner:GetForward() + self.Owner:GetRight() * 3 + self.Owner:GetUp()
	ent:SetPos( v )
	ent:SetAngles(Angle( math.Rand(-180, 180), math.Rand(-180, 180), math.Rand(-180, 180) ))
	ent:SetPlayer(self.Owner)
	ent.Owner = self.Owner
	ent:Spawn()
	ent:EmitSound(Sound("grenade_"..math.random(1,7)..".mp3"))
	
	local phys = ent:GetPhysicsObject()
	local force
	if self.Owner:KeyDown( IN_FORWARD ) then
		force = 3200
	elseif self.Owner:KeyDown( IN_BACK ) then
		force = 2100
	//elseif self.Owner:KeyDown( IN_MOVELEFT ) then
	//	force = 2500
	//elseif self.Owner:KeyDown( IN_MOVERIGHT ) then
	//	force = 2500
	else
		force = 2500
	end

	phys:ApplyForceCenter(self.Owner:GetAimVector() * force * (PlayerPowers[self.Owner] or 1.2)*0.9 + Vector(0,0,200) ) //1.65mul worked nicely before the power thing
	phys:AddAngleVelocity(Vector(math.random(-500,500),math.random(-500,500),math.random(-500,500)))
	
	local timerid = "NCGrenade.Throw3_"..self.Owner:EntIndex()
	timer.Create(timerid,0.6,1, function() if IsValid(self.Weapon) then self.Weapon:SendWeaponAnim(ACT_VM_DRAW) end timer.Destroy(timerid) end)
end
SWEP.PrimaryAttack = NebcorpGrenadePrep
function SWEP:SecondaryAttack() end
//function NebcorpGrenadeReload(self) return end
//function SWEP:Reload() NebcorpGrenadeReload(self) end


if SERVER then
	concommand.Add( "nebcorp_grenade_type", function(ply,_,args) PlayerChoices[ply] = args[1] end)
	concommand.Add( "nebcorp_grenade_power", function(ply,_,args) PlayerPowers[ply] = args[1] end)
end
if CLIENT then
	local highlighted = nil
	local PressingReload,PressingMouse1= false,false
	local screenCenterX = ScrW() / 2		-- X center
	local screenCenterY = ScrH() / 2		-- Y center
	local deadzone = 40 -- Size of emerald hill zone
	local throwstrength = 1
	//local lockstrength
	local LockThrow
	GrenadeDisplay = {}
	/*local lastlockstrengthadjusttime = 0
	function SWEP:SecondaryAttack() -- an old idea that doesn't really fit anymore
		if lastlockstrengthadjusttime > CurTime() then return end
		lastlockstrengthadjusttime = CurTime() + 0.2
		lockstrength = !lockstrength
		print("Lobkcstrentghrocvklobstah is now "..tostring(lockstrength))
	end*/
	function SWEP:Think()
		if PressingReload != self.Owner:KeyDown( IN_RELOAD ) then
			PressingReload = !PressingReload
			gui.EnableScreenClicker(PressingReload)
			if PressingReload then
				gui.SetMousePos(screenCenterX, screenCenterY) -- Set cursor centerscreen
			else
				if highlighted then RunConsoleCommand("nebcorp_grenade_type", highlighted) end
			end
			highlighted = nil -- Now we dont have a selected tool
		end
		
		if PressingMouse1 != self.Owner:KeyDown( IN_ATTACK ) then
			PressingMouse1 = !PressingMouse1
			if !LockThrow && !PressingMouse1 then 
				RunConsoleCommand("nebcorp_grenade_power", throwstrength) 
				print("Throwing "..throwstrength..", calc: "..throwstrength*1.45)
				LockThrow = true
				timer.Create("ReleaseGrenadeLockThrow",1.35,1,function() LockThrow = nil end)
			end
			throwstrength = 0
		end
	end

	local function DrawItem(itemText, itemXpos, itemYpos, labelWidth, labelHeight, boxColor, textColor)
		if not itemText then return end
		draw.RoundedBox(8, (itemXpos - (labelWidth / 2) - 5), (itemYpos - (labelHeight / 2) - 2), labelWidth + 10, labelHeight + 4, boxColor)
		draw.SimpleText(itemText, radialMenuFont, itemXpos, itemYpos, textColor, 1, 1)
	end
	
	
	function CalculateGrenadeMenuLayout()
		local angle = 0				-- Our starting angle
		local longestName = 0	-- The length of the longest name, used to calculate x/y position
		local menusplitterlength = 60
		local pi = 4 * math.atan2(1, 1)			-- Pi (Yum :)
		
		local count = 0
		-- Find the pixelsize of the largest word, to get an even circle
		for key in pairs(NebcorpGrenades) do
			-- Is this the longest name yet?
			surface.SetFont("DermaDefault")
			local tw, th = surface.GetTextSize(key)
			
			if tw > longestName then longestName = tw end
			count = count + 1
		end
		local entrySize = math.floor(360 / count)

		-- Loop through all tools, and calculate span-angle, x/y position and menu-splitter
		for key in pairs(NebcorpGrenades) do
			local value = {}
			table.insert(GrenadeDisplay, value)
			value.name = key
			value.minangle = angle - (entrySize / 2)
			if value.minangle < 0 then value.minangle = 360 + value.minangle end	-- First tool MinAngle will always dip below 0, and have to "wrap" down from 360
			value.maxangle = angle + (entrySize / 2)

			value.xpos = screenCenterX - ((deadzone + 12 + (longestName / 2)) * math.sin((360 - angle) * (pi / 180)))	-- X position of the menu point text
			value.ypos = screenCenterY - ((deadzone + 12 + (longestName / 2)) * math.cos((360 - angle) * (pi / 180)))	-- Y position of the menu point text

			value.menusplitxinner = screenCenterX - (deadzone * math.sin((360 - value.minangle) * (pi / 180)))	-- Used to draw a split-line from center-screen, 100 pixels out
			value.menusplityinner = screenCenterY - (deadzone * math.cos((360 - value.minangle) * (pi / 180)))	-- -O-
			value.menusplitxouter = screenCenterX - ((menusplitterlength + deadzone) * math.sin((360 - value.minangle) * (pi / 180)))
			value.menusplityouter = screenCenterY - ((menusplitterlength + deadzone) * math.cos((360 - value.minangle) * (pi / 180)))

			-- Should labels be the same size or not?
			local tw, th = surface.GetTextSize(key)
			
			//if radialConfig["gbr-menulabelssizedindividually"] == 1 then
				-- Labels are individually sized
				value.labelwidth = tw
				value.labelheight = th
			//else
			//	-- Labels are same size (ie, size of the longest name)
			//	value.labelwidth = longestName
			//	value.labelheight = th
			//end

			-- Increase the angle
			angle = angle + entrySize
		end
		
		-- Set the last entrys max to the first entrys min, so we don't get any "empty" menu-space
		GrenadeDisplay[#GrenadeDisplay].maxangle = GrenadeDisplay[1].minangle
	end
	CalculateGrenadeMenuLayout()

	local barposx,barposy = ScrW() / 2 - 80, ScrH()/2 - 50
	function SWEP:DrawHUD()
		if PressingMouse1 then -- Draw/calculate the power slider only if hes pushing leftclick
			surface.SetDrawColor( 0, 0, 0, 180) 
			surface.DrawRect(barposx,barposy, 40, 100 )
			surface.SetDrawColor( 255, 0, 0, 200) 
			throwstrength = throwstrength + FrameTime()
			if throwstrength > 1.8 then throwstrength = 1.8 end
			local num = 92 * (1.8-throwstrength)/1.8
			surface.DrawRect(barposx+4,barposy+4 + num, 32, 92 - num)
			return 
		end
		
		if PressingReload then -- DRAW THE RADIAL MENU
			-- Is the distance from screen-center to the cursor larger than the set deadspace?
			if math.Dist(screenCenterX, screenCenterY, gui.MouseX(), gui.MouseY()) > deadzone then
				-- We have moved out of the deadzone
				-- Calculate the angle from screen-center to the mousecursor, so we can determine which radial element the cursor is over
				local radialSelectAngle = 360 - (math.deg(math.atan2(gui.MouseX() - screenCenterX, gui.MouseY() - screenCenterY)) + 180)	-- Manipulate the degrees, so we get 0 to be upwards, and increasing clockwise

				-- Loop tools them and find out which one is active
				for key,value in pairs(GrenadeDisplay) do
					-- Check for a "normal" entry first (one that doesn't span 0)
					if (value.minangle <= radialSelectAngle) and (value.maxangle > radialSelectAngle) then
						highlighted = value.name -- We have found the active tool
						break
					end

					if value.minangle > value.maxangle then
						-- MinAngle is larger than MaxAngle, we have the entry that spans 0 degrees (straight up)
						if (value.minangle <= radialSelectAngle) or (value.maxangle > radialSelectAngle) then
							highlighted = value.name -- We have found the active tool
							break
						end
					end
				end
			end
			
			-- Draw the tool menu entries
			for key,value in pairs(GrenadeDisplay) do
				if value.name == highlighted then
					-- This is the selected tool
					DrawItem(value.name, value.xpos, value.ypos, value.labelwidth, value.labelheight, Color(150, 150, 150, 255), Color(255, 255, 255, 255))
				else
					-- This is not the selected tool
					DrawItem(value.name, value.xpos, value.ypos, value.labelwidth, value.labelheight, Color(100, 100, 100, 255), Color(255, 255, 255, 255))
				end
				
				-- Draw the splitter-line, if the user wants to
				//if radialConfig["gbr-menushowsplitters"] == 1 then
					surface.SetDrawColor(255, 255, 255, 80)
					surface.DrawLine(value.menusplitxinner, value.menusplityinner, value.menusplitxouter, value.menusplityouter)			
				//end
			end
		end
	end
	usermessage.Hook("nebcorp_newgrenade", function(um) 
		NebcorpGrenades[um:ReadString()] = true
		GrenadeDisplay = {}
		CalculateGrenadeMenuLayout()
	end)
	
	function SWEP:OnRemove()
		gui.EnableScreenClicker(false)
	end
end

function SWEP:Precache() 
	for k=1, 7 do util.PrecacheSound( "grenade_"..k..".mp3" ) end
end

function AddNewGrenade(name, func)
	if func then NebcorpGrenades[name] = func end
	umsg.Start("nebcorp_newgrenade")
	umsg.String(name)
	umsg.End()
end