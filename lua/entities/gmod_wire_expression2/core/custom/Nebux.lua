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
	0: Bill is worthless, forged, or entity is not a bill.
	N: The banknote's current value.

atmDeposit(Account, Entity bill) -- Consumes a Nebux bank note, depositing its value
	-1: Invalid Argument. (Account is not a string or Player.)
	0: Deposit failed, or bill is forged.
	N: The value deposited.

atmAuthenticate(Account, string pin) -- Attempts to authorize this E2 to make withdrawls
	0: Authorization Denied.
	1: Authorization Granted.
	2: Creating new account, please ask end user to re-enter their PIN a second time

atmBalance(Account) -- Returns the current bank footprint of the specified account holder
	* Requires Authentication
	-1: Not Authorized. (Use atmAuthenticate first.)
	N: Available funds

atmWithdraw(Account, amount, vector position) -- Attempts to withdraw a Nebux bank note
	* Requires Authentication
	-1: Not Authorized (Use atmAuthenticate first,) or Invalid Argument. (Account is not a string or Player.)
	0: Withdrawal failed, or account has no funds.
	Entity: The spawned bank note.

Entity:setOverlayText(string text) -- May be used to write comments on bills

*/

Nebbux=Nebbux or {}
Nebbux.ATM_SALT = Nebbux.ATM_SALT or math.random(1111, 99999)
Nebbux.SALT_DELTA = 10^-7
Nebbux.SALT_DELTA2 = 1 - Nebbux.SALT_DELTA
Nebbux.ACCOUNT_FILE = "nebcorp/atm.txt"
Nebbux.PIN_FILE = "nebcorp/atm_pins.txt"
Nebbux.STARTING_BALANCE = 20

registerCallback("construct", function(self)
	self.data.ATMAuthentications = {}
end)
registerCallback("destruct", function(self)
	self.data.ATMAuthentications = nil
end)

--################################################## ACCOUNT MANAGEMENT
function Nebbux.loadAccounts()
	return util.JSONToTable(file.Read(Nebbux.ACCOUNT_FILE,"DATA") or "{}")
end
function Nebbux.saveAccounts(accounts)
	file.Write(Nebbux.ACCOUNT_FILE, util.TableToJSON(accounts))
end
function Nebbux.translateAccountName(account)
	if(type(account)=="Player") then account=account:SteamID() end
	if(type(account)=="string") then return account end
	return nil
end
function Nebbux.adjustBalance(account,amount)
--force: boolean or nil. True bypasses normal protections, which for example can credit accounts into negative values.
	local account=Nebbux.translateAccountName(account)
	if(account)
	then
		local accounts=Nebbux.loadAccounts()
		local balance=accounts[account] or Nebbux.STARTING_BALANCE
		if(not force)
		then
			if(-amount>balance) then amount=-balance end
		end
		accounts[account]=balance+amount
		Nebbux.saveAccounts(accounts)
		return amount
	end
	return 0
end
function Nebbux.getBalance(account)
	local account=Nebbux.translateAccountName(account)
	if(account)
	then
		local accounts=Nebbux.loadAccounts()
		return accounts[account] or Nebbux.STARTING_BALANCE
	end
	return -1
end

--################################################## BILL MANIPULATION
function Nebbux.closeEnough(value)
	local diff = value % 1
	return value != 0 && (diff < Nebbux.SALT_DELTA || diff > Nebbux.SALT_DELTA2)
end
function Nebbux.setBillValue(bill,amount)
	if not IsValid(bill) then return end
	bill.bill = amount * (bill:EntIndex() * Nebbux.ATM_SALT)^2
	bill:SetNetworkedString("WireName", amount .. " Nebux")
	bill:SetOverlayText("")
end
function Nebbux.getBillValue(bill)
	if not IsValid(bill) or not bill.bill then return 0 end
	local value = bill.bill / ((Nebbux.ATM_SALT * bill:EntIndex())^2)
	if !Nebbux.closeEnough(value) then return 0 end
	return value
end
function Nebbux.createBill(amount,pos)
	local Data = {
		Pos		= E2Lib.clampPos(pos),
		Angle	= Angle(),
		Model	= "models/props/cs_assault/money.mdl",
	}
	local prop = ents.Create( "base_wire_entity" )
	if not prop then return end
	duplicator.DoGeneric( prop, Data )
	prop.Namage = False
	Nebbux.setBillValue(prop,amount)
	prop:SetNetworkedString("FounderName", "Gman")
	prop:CPPISetOwnerless(true)
	prop:Spawn()
	duplicator.DoGenericPhysics( prop, game.GetWorld(), Data )
	local snd = CreateSound( prop, "physics/cardboard/cardboard_box_strain1.wav" )
	snd:ChangePitch(70 + math.random()*15, 0)
	snd:ChangeVolume(0.66, 0)
	snd:Play()
	DoPropSpawnedEffect( prop )
	prop:Activate()
	prop:GetPhysicsObject():Wake()
	return prop
end
function Nebbux.destroyBill(bill,fancySFX)
	bill:Remove()
	--We'll leave this for now, but I suspect we can put a death animation in here.
end

--################################################## WITHDRAWALS AND DEPOSITS
function Nebbux.deposit(account, bill)
	if not IsValid(bill) or not bill.bill then return 0 end
	
	local value = Nebbux.getBillValue(bill)
	local deposited=Nebbux.adjustBalance(account,value)
	value=value-deposited
	
	if(account==nil or value<=0)
	then
		Nebbux.destroyBill(bill)
	else
		Nebbux.setBillValue(bill)
	end
	return deposited
end
function Nebbux.withdraw(account,amount,pos)
	if amount <= 0 then return 0 end
	local bill=Nebbux.createBill(0,pos)
	--We create the bill first because it's more likely to fail. It will be deleted if the withdrawal fails.
	local withdrawn=-Nebbux.adjustBalance(account,-amount)
	if(withdrawn<=0)
	then
		Nebbux.destroyBill(bill,false)
	else
		Nebbux.setBillValue(bill,withdrawn)
	end
	return bill,withdrawn
end


--################################################## EXPRESSION 2 BOILERPLATE
function Nebbux.getE2Authentication(self,account)
	account=Nebbux.translateAccountName(account)
	if(account==nil) then return false end
	return self.data.ATMAuthentications[account] or false
end
function Nebbux.authenticateE2(self,account,pin)
	account=Nebbux.translateAccountName(account)
	local accounts = util.JSONToTable(file.Read(Nebbux.PIN_FILE,"DATA") or "{}")
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

e2function normal atmValue(entity ent)
	return Nebbux.getBillValue(ent)
end
e2function normal atmBalance(entity ply)
	if(!IsValid(ply) or !ply:IsPlayer() or !Nebbux.getE2Authentication(self,ply)) then return -1 end
	return Nebbux.getBalance(ply)
end
e2function normal atmBalance(string account)
	if(!Nebbux.getE2Authentication(self,account)) then return -1 end
	return Nebbux.getBalance(account)
end

e2function normal atmAuthenticate(entity ply,string pin)
	if(!IsValid(ply) or !ply:IsPlayer()) then return -1 end
	return Nebbux.authenticateE2(self,ply,pin)
end
e2function normal atmAuthenticate(string account,string pin)
	return Nebbux.authenticateE2(self,account,pin)
end

e2function entity atmWithdraw(entity ply,normal amount,vector pos)
	if(!IsValid(ply) or !ply:IsPlayer() or !Nebbux.getE2Authentication(self,ply)) then return -1 end
	local bill,withdrawn=Nebbux.withdraw(ply,amount,Vector(pos[1],pos[2],pos[3]))
	return bill
end
e2function entity atmWithdraw(string account,normal amount,vector pos)
	if(!IsValid(ply) or !ply:IsPlayer() or !Nebbux.getE2Authentication(self,account)) then return -1 end
	local bill,withdrawn=Nebbux.withdraw(account,amount,Vector(pos[1],pos[2],pos[3]))
	return bill
end

e2function normal atmDeposit(entity ply,entity bill)
	if(!IsValid(ply) or !ply:IsPlayer() or !IsValid(bill)) then return -1 end
	return Nebbux.deposit(ply,bill)
end
e2function normal atmDeposit(string account,entity bill)
	if(!IsValid(bill)) then return -1 end
	return Nebbux.deposit(account,bill)
end