/*

Nebux API Guidebook
	Regulation 10

The Bakn of Nebux guarantees that some precautions may have been taken to secure clients funds; 
a partial list follows:
	All transactions are atomic
	Bills are Namage resistant
	Bills float in water; generally
	Bills are tamperproof, and immune to various forms of reloading
	Bills cannot be duplicated or reproduced
	Bills exposed during a map change will be retired
	Bills retain no memory of their initial owner
	Writing on the face of a bill, while legal, cannot be used to obfuscate the bill's value

Glossery:
	Account - Refers to either a Player, or a string accountname, such as for a business.


atmAmount(Entity bill) -- Returns the accurate Nebux value of the specified banknote
	0: Possible forgery detected
	N: The banknote's current value

atmDeposit(Account, Entity bill) -- Consumes a Nebux bank note, depositing its value
	0: Possible forgery detected
	N: The value deposited

atmAuthenticate(Account, string pin) -- Attempts to authorize this E2 to make withdrawls
	0: Authorization declined
	1: Authorization granted
	2: Creating new account, please ask end user to re-enter their PIN a second time

atmBalance(Account) -- Returns the current bank footprint of the specified account holder
	-1: Non-authorized account access
	N: Available funds

atmWithdraw(Account, amount, vector position) -- Attempts to withdraw a Nebux bank note
	0: Non-authorized account access, or non-sufficient funds
	Entity: The spawned bank note
	* requires authentication

Entity:setOverlayText(string text) -- May be used to write comments on bills

*/

ATMSalt = ATMSalt or math.random(1111, 99999)
local SaltDelta = 10^-7
local SaltDelta2 = 1 - SaltDelta

registerCallback("construct", function(self)
	self.data.ATMAuthentications = {}
end)
registerCallback("destruct", function(self)
	self.data.ATMAuthentications = nil
end)

local function closeEnough(value)
	local diff = value % 1
	return value != 0 && (diff < SaltDelta || diff > SaltDelta2)
end

local function atmDeposit(account, bill)
	if not IsValid(bill) or not bill.bill then return 0 end
	local value = bill.bill / ((ATMSalt * bill:EntIndex())^2)
	if !closeEnough(value) then return 0 end
	
	local accounts = util.JSONToTable(file.Read("nebcorp/atm.txt","DATA") or "{}")
	accounts[account] = (accounts[account] or 0) + value
	file.Write("nebcorp/atm.txt", util.TableToJSON(accounts))
	bill:Remove()
	return value
end

e2function number atmDeposit(entity ply, entity bill)
	if not IsValid(ply) or not ply:IsPlayer() then return 0 end
	return atmDeposit(ply:SteamID(), bill)
end
e2function number atmDeposit(string account, entity bill)
	--if string.find(account, "STEAM_") then return 0 end
	return atmDeposit(account, bill)
end

local function atmWithdraw(self, account, amount, pos)
	if not self.data.ATMAuthentications[account] then return 0 end
	if amount <= 0 then return 0 end 
	
	local accounts = util.JSONToTable(file.Read("nebcorp/atm.txt","DATA") or "{}")
	if !accounts[account] or accounts[account] < amount then return 0 end
	accounts[account] = accounts[account] - amount
	file.Write("nebcorp/atm.txt", util.TableToJSON(accounts))

	local Data = {
		Pos		= E2Lib.clampPos(pos),
		Angle	= Angle(),
		Model	= "models/props/cs_assault/money.mdl",
	}
	local prop = ents.Create( "base_wire_entity" )
	if not prop then return end
	duplicator.DoGeneric( prop, Data )
	prop.Namage = False
	prop:SetNetworkedString("WireName", amount .. " Nebux")
	prop:SetOverlayText("")
	prop:SetNetworkedString("FounderName", "Gman")
	prop:CPPISetOwnerless(true)
	prop:Spawn()
	duplicator.DoGenericPhysics( prop, game.GetWorld(), Data )
	local snd = CreateSound( prop, "physics/cardboard/cardboard_box_strain1.wav" )
	snd:ChangePitch(70 + math.random()*15, 0)
	snd:ChangeVolume(0.66, 0)
	snd:Play()
	DoPropSpawnedEffect( prop )
	
	prop.bill = amount * (prop:EntIndex() * ATMSalt)^2
	prop:Activate()
	prop:GetPhysicsObject():Wake()
	return prop
end

e2function entity atmWithdraw(entity ply, amount, vector pos)
	if not IsValid(ply) or not ply:IsPlayer() then return 0 end
	return atmWithdraw(self, ply:SteamID(), math.floor(amount), Vector(pos[1],pos[2],pos[3]))
end
e2function entity atmWithdraw(string account, amount, vector pos)
	--if string.find(account, "STEAM_") then return 0 end
	return atmWithdraw(self, account, math.floor(amount), Vector(pos[1],pos[2],pos[3]))
end

e2function number atmValue(entity bill)
	if not IsValid(bill) or not bill.bill then return 0 end
	local value = bill.bill / ((ATMSalt * bill:EntIndex())^2)
	if !closeEnough(value) then return 0 end
	return value
end

local function atmBalance(self, account)
	if not self.data.ATMAuthentications[account] then return -1 end
	
	local accounts = util.JSONToTable(file.Read("nebcorp/atm.txt","DATA") or "{}")
	return accounts[account] or 0
end

e2function number atmBalance(entity ply)
	if not IsValid(ply) or not ply:IsPlayer() then return 0 end
	return atmBalance(self, ply:SteamID())
end
e2function number atmBalance(string account)
	return atmBalance(self, account)
end

local function atmAuthenticate(self, account, pin)
	local accounts = util.JSONToTable(file.Read("nebcorp/atm_pins.txt","DATA") or "{}")
	if !accounts[account] then
		if self.data.ATMAuthentications[account] == nil then
			self.data.ATMAuthentications[account] = false
			return 2
		else
			accounts[account] = pin
			file.Write("nebcorp/atm_pins.txt", util.TableToJSON(accounts))
			
			local balances = util.JSONToTable(file.Read("nebcorp/atm.txt","DATA") or "{}")
			balances[account] = 20
			file.Write("nebcorp/atm.txt", util.TableToJSON(balances))
		end
	end
	if accounts[account] == pin then
		self.data.ATMAuthentications[account] = true
		return 1
	end
	return 0
end

e2function number atmAuthenticate(entity ply, string pin)
	if not IsValid(ply) or not ply:IsPlayer() then return 0 end
	return atmAuthenticate(self, ply:SteamID(), pin)
end
e2function number atmAuthenticate(string account, string pin)
	return atmAuthenticate(self, account, pin)
end
