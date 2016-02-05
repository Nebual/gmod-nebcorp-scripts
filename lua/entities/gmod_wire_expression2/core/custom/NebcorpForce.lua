// Most of these are fairly unorganized; latest work at the bottom :D

--- Sleeps <this>'s physics object (a lightweight Freeze)
e2function void entity:sleep()
	if validPhysics(this) then this:GetPhysicsObject():Sleep() end
end

--- Wakes <this>'s physics object
e2function void entity:wake()
	if validPhysics(this) then this:GetPhysicsObject():Wake() end
end

--- Sets <this>'s velocity to <vec>
e2function void entity:setVelocity(vector vec)
	local ent = IsValid(this) and this
	if ent then
		if ent:IsNPC() or ent:IsPlayer() then
			if ent:IsPlayer() then
				if ent:GetGravity() != 0 then
					ent:SetMoveType(MOVETYPE_WALK)
				end
			end
			ent:SetVelocity(Vector(vec[1],vec[2],vec[3]))
		elseif validPhysics(ent) then
			ent:GetPhysicsObject():SetVelocity(Vector(vec[1],vec[2],vec[3]))
		end
	end
end

--- Applies force <vector> to <this>, with respect to Mass.
e2function void entity:applyNiceForce(vector vector)
	local x,y,z = vector[1],vector[2],vector[3]
	if !this || !this:IsValid() || !validPhysics(this) then return end
	local phys = this:GetPhysicsObject()
	local mass = phys:GetMass()
	if this:GetClass() == "prop_ragdoll" then mass = 100 end
	phys:ApplyForceCenter(Vector(mass * x, mass * y, mass * z))
end

--- Applies force <vector> to <this>, with respect to Mass and Forward Direction
e2function void entity:applyNiceRightForce(num)
	if !this || !this:IsValid() || !validPhysics(this) then return end
	local phys = this:GetPhysicsObject()
	local mass = phys:GetMass()
	if this:GetClass() == "prop_ragdoll" then mass = 100 end
	mass = mass * num
	local right = this:GetRight()
	phys:ApplyForceCenter(Vector(mass * right[1], mass * right[2], mass * right[3]))
end

--- Applies force <vector> to <this>, with respect to Mass and Forward Direction
e2function void entity:applyNiceForwardForce(num)
	if !this || !this:IsValid() || !validPhysics(this) then return end
	local phys = this:GetPhysicsObject()
	local mass = phys:GetMass()
	if this:GetClass() == "prop_ragdoll" then mass = 100 end
	mass = mass * num
	local forward = this:GetForward()
	phys:ApplyForceCenter(Vector(mass * forward[1], mass * forward[2], mass * forward[3]))
end

// ----------------- NOLPHIN-BASED ANGULAR THRUST ----------------------

/*
------ Formula to guess appropriate side to use in radius -----
local boxsize = entity:OBBMaxs() - entity:OBBMins()
local x,y,z = boxsize.x,boxsize.y,boxsize.z
local radius = z
if (x > y && x < z) || (x < y && x > z) then radius = x
elseif (y > x && y < z) || (y < x && y > z) then radius = y end
if radiusMod && radiusMod > 0 then radius = radius * radiusMod end
*/

--- Applies <angles> thrust to all entities in the array <this> with a radius modifier of <radiusMod>
e2function void array:applyNomAngleForce(angle angles, radiusMod)
	local pitch,yaw,roll = angles[1],angles[2],angles[3]
	for _,v in ipairs(this) do
		local entity = IsValid(v) and v
		if validPhysics(entity) then
			local phys = entity:GetPhysicsObject()
			local radius = entity:BoundingRadius() * radiusMod
			if entity:GetClass() == "prop_ragdoll" then radius = 100 end
			local inertia = phys:GetInertia()
			local cmass = phys:GetMassCenter()
			local up,right = entity:GetUp(), entity:GetRight()
			
			local rollmul = roll * inertia.x / 5
			phys:ApplyForceOffset(Vector( rollmul * up[1], rollmul * up[2], rollmul * up[3]), entity:LocalToWorld(Vector(0,-radius,0)) + cmass)
			phys:ApplyForceOffset(Vector(-rollmul * up[1],-rollmul * up[2],-rollmul * up[3]), entity:LocalToWorld(Vector(0,radius,0)) + cmass)

			local pitchmul = pitch * inertia.y / 5
			phys:ApplyForceOffset(Vector( pitchmul * up[1], pitchmul * up[2], pitchmul * up[3]), entity:LocalToWorld(Vector(radius,0,0)) + cmass)
			phys:ApplyForceOffset(Vector(-pitchmul * up[1],-pitchmul * up[2],-pitchmul * up[3]), entity:LocalToWorld(Vector(-radius,0,0)) + cmass)

			local yawmul = yaw * inertia.z / 10
			phys:ApplyForceOffset(Vector( yawmul * right[1], yawmul * right[2], yawmul * right[3]), entity:LocalToWorld(Vector(radius,-radius,0)) + cmass)
			phys:ApplyForceOffset(Vector(-yawmul * right[1],-yawmul * right[2],-yawmul * right[3]), entity:LocalToWorld(Vector(-radius,radius,0)) + cmass)
		end
	end
end

--- Applies <angles> thrust to <this> with a radius modifier of <radiusMod>
e2function void entity:applyNomAngleForce(angle angles, radiusMod)
	local entity = IsValid(this) and this
	if validPhysics(entity) then
		local phys = entity:GetPhysicsObject()
		local radius = entity:BoundingRadius() * radiusMod
		if entity:GetClass() == "prop_ragdoll" then radius = 100 end
		local inertia = phys:GetInertia()
		local cmass = phys:GetMassCenter()
		local up,right = entity:GetUp(), entity:GetRight()
		
		local rollmul = angles[3] * inertia.x / 5
		phys:ApplyForceOffset(Vector( rollmul * up[1], rollmul * up[2], rollmul * up[3]), entity:LocalToWorld(Vector(0,-radius,0)) + cmass)
		phys:ApplyForceOffset(Vector(-rollmul * up[1],-rollmul * up[2],-rollmul * up[3]), entity:LocalToWorld(Vector(0,radius,0)) + cmass)

		local pitchmul = angles[1] * inertia.y / 5
		phys:ApplyForceOffset(Vector( pitchmul * up[1], pitchmul * up[2], pitchmul * up[3]), entity:LocalToWorld(Vector(radius,0,0)) + cmass)
		phys:ApplyForceOffset(Vector(-pitchmul * up[1],-pitchmul * up[2],-pitchmul * up[3]), entity:LocalToWorld(Vector(-radius,0,0)) + cmass)

		local yawmul = angles[2] * inertia.z / 10
		phys:ApplyForceOffset(Vector( yawmul * right[1], yawmul * right[2], yawmul * right[3]), entity:LocalToWorld(Vector(radius,-radius,0)) + cmass)
		phys:ApplyForceOffset(Vector(-yawmul * right[1],-yawmul * right[2],-yawmul * right[3]), entity:LocalToWorld(Vector(-radius,radius,0)) + cmass)
	end
end

--- Applies <yaw> yaw thrust to <this> with a radius modifier of <radiusMod> (a simpler applyNomAngleForce)
e2function void entity:applyNomYawForce(yaw, radiusMod)
	local entity = IsValid(this) and this
	if validPhysics(entity) then
		local phys = entity:GetPhysicsObject()
		local radius = entity:BoundingRadius() * radiusMod
		local inertia = phys:GetInertia()
		local cmass = phys:GetMassCenter()
		local right = entity:GetRight()
		
		local yawmul = yaw * inertia.z / 10
		phys:ApplyForceOffset(Vector( yawmul * right[1], yawmul * right[2], yawmul * right[3]), entity:LocalToWorld(Vector(radius,-radius,0)) + cmass)
		phys:ApplyForceOffset(Vector(-yawmul * right[1],-yawmul * right[2],-yawmul * right[3]), entity:LocalToWorld(Vector(-radius,radius,0)) + cmass)
	end
end