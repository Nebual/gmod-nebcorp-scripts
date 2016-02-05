local Clamp = math.Clamp
local Bounce = {}
local Gravity = {}
local Collision = {}
local ValidParticle = {}

local function get_bounce(message)
    nom = message:ReadEntity()
    Bounce[nom] = message:ReadLong()
end
local function get_collision(message)
    nom = message:ReadEntity()
    local Collide = message:ReadLong()
    if (Collide != 0) then Collision[nom] = true else Collision[nom] = false end
end
local function get_gravity(message)
    nom = message:ReadEntity()
    Gravity[nom] = message:ReadVector()
end

function use_message(message)
    local Ent      = message:ReadEntity()
    local PartType = Ent:GetNetworkedString("Type")
    local Color    = Ent:GetNetworkedVector("RGB")
    local Vel      = Ent:GetNetworkedVector("Vel")
    local centr    = Ent:GetNetworkedVector("Position")
    local em       = ParticleEmitter(centr)
    local part     = em:Add(PartType,centr)
    
    if(em!=nil) then
        
        part:SetColor(Color[1],Color[2],Color[3],255)
        part:SetVelocity(Vel)
        part:SetDieTime(Clamp(tonumber(Ent:GetNetworkedInt("Duration")), 0.001, 10))
        part:SetStartSize(Clamp(tonumber(Ent:GetNetworkedInt("StartSize")),0.1,30))
        part:SetEndSize(Clamp(tonumber(Ent:GetNetworkedInt("EndSize")),0.1,30))
        part:SetAngles(Angle(Ent:GetNetworkedInt("Pitch"),0,0))
    
        if(Gravity[Ent]==nil) then Gravity[Ent] = Vector(0,0,-9.8) end
        if(Collision[Ent]==nil) then Collision[Ent] = true end
        if(Bounce[Ent]==nil) then Bounce[Ent] = 0.3 end
      
        part:SetGravity(Gravity[Ent])
        part:SetCollide(Collision[Ent])
        part:SetBounce(Bounce[Ent])   
    
    end
    
    em:Finish() 
    
end

usermessage.Hook("e2p_bounce", get_bounce)
usermessage.Hook("e2p_collide", get_collision)
usermessage.Hook("e2p_gravity", get_gravity)
usermessage.Hook("e2p_pm", use_message)