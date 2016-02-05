local ParticlesThisSecond   = {}
local MaxParticlesPerSecond = 10
local Grav                  = {}
local Particles             = {}
local rad2deg               = 180 / math.pi
local asin                  = math.asin
local atan2                 = math.atan2
local AlwaysRender          = 0
Particles[0]="effects/blooddrop"
Particles[1]="effects/bloodstream"
Particles[2]="effects/laser_tracer"
Particles[3]="effects/select_dot"
Particles[4]="effects/select_ring"
Particles[5]="effects/tool_tracer"
Particles[6]="effects/wheel_ring"
Particles[7]="effects/base"
Particles[8]="effects/blood"
Particles[9]="effects/blood2"
Particles[10]="effects/blood_core"
Particles[11]="effects/blood_drop"
Particles[12]="effects/blood_gore"
Particles[13]="effects/blood_puff"
Particles[14]="effects/blueblackflash"
Particles[15]="effects/blueblacklargebeam"
Particles[16]="effects/blueflare1"
Particles[17]="effects/bluelaser1"
Particles[18]="effects/bluemuzzle"
Particles[19]="effects/bluespark"
Particles[20]="effects/bubble"
Particles[21]="effects/combinemuzzle1"
Particles[22]="effects/combinemuzzle1_dark"
Particles[23]="effects/combinemuzzle2"
Particles[24]="effects/combinemuzzle2_dark"
Particles[25]="effects/energyball"
Particles[26]="effects/energysplash"
Particles[27]="effects/exit1"
Particles[28]="effects/fire_cloud1"
Particles[29]="effects/fire_cloud2"
Particles[30]="effects/fire_embers1"
Particles[31]="effects/fire_embers2"
Particles[32]="effects/fire_embers3"
Particles[33]="effects/fleck_glass1"
Particles[34]="effects/fleck_glass2"
Particles[35]="effects/fleck_glass3"
Particles[36]="effects/fleck_tile1"
Particles[37]="effects/fleck_tile2"
Particles[38]="effects/fleck_wood1"
Particles[39]="effects/fleck_wood2"
Particles[40]="effects/fog_d1_trainstation_02"
Particles[41]="effects/gunshipmuzzle"
Particles[42]="effects/gunshiptracer"
Particles[43]="effects/hydragutbeam"
Particles[44]="effects/hydragutbeamcap"
Particles[45]="effects/hydraspinalcord"
Particles[46]="effects/laser1"
Particles[47]="effects/laser_citadel1"
Particles[48]="effects/mh_blood1"
Particles[49]="effects/mh_blood2"
Particles[50]="effects/mh_blood3"
Particles[51]="effects/muzzleflash1"
Particles[52]="effects/muzzleflash2"
Particles[53]="effects/muzzleflash3"
Particles[54]="effects/muzzleflash4"
Particles[55]="effects/redflare"
Particles[56]="effects/rollerglow"
Particles[57]="effects/slime1"
Particles[59]="effects/spark"
Particles[59]="effects/splash1"
Particles[60]="effects/splash2"
Particles[61]="effects/splash3"
Particles[62]="effects/splash4"
Particles[63]="effects/splashwake1"
Particles[64]="effects/splashwake3"
Particles[65]="effects/splashwake4"
Particles[66]="effects/strider_bulge_dudv"
Particles[67]="effects/strider_muzzle"
Particles[68]="effects/strider_pinch_dudv"
Particles[69]="effects/strider_tracer"
Particles[70]="effects/stunstick"
Particles[71]="effects/tracer_cap"
Particles[72]="effects/tracer_middle"
Particles[73]="effects/tracer_middle2"
Particles[74]="effects/water_highlight"
Particles[75]="effects/yellowflare"
Particles[76]="effects/muzzleflashX"
Particles[77]="effects/ember_swirling001"
Particles[78]="shadertest/eyeball"
Particles[79]="sprites/bloodparticle"
Particles[80]="sprites/animglow02"
Particles[81]="sprites/ar2_muzzle1"
Particles[82]="sprites/ar2_muzzle3"
Particles[83]="sprites/ar2_muzzle4"
Particles[84]="sprites/flamelet1"
Particles[85]="sprites/flamelet2"
Particles[86]="sprites/flamelet3"
Particles[87]="sprites/flamelet4"
Particles[88]="sprites/flamelet5"
Particles[89]="sprites/glow03"
Particles[90]="sprites/light_glow02"
Particles[91]="sprites/orangecore1"
Particles[92]="sprites/orangecore2"
Particles[93]="sprites/orangeflare1"
Particles[94]="sprites/plasmaember"
Particles[95]="sprites/redglow1"
Particles[96]="sprites/redglow2"
Particles[97]="sprites/rico1"
Particles[98]="sprites/strider_blackball"
Particles[99]="sprites/strider_bluebeam"
Particles[100]="sprites/tp_beam001"
Particles[101]="sprites/yellowflare"
Particles[102]="sprites/frostbreath"
Particles[103]="sprites/sent_ball"

local function bearing(pos, plyer)
    pos = plyer:WorldToLocal(Vector(pos[1],pos[2],pos[3]))
    return rad2deg*-atan2(pos.y, pos.x)
end

local function elevation(pos, plyer)
    pos = plyer:WorldToLocal(Vector(pos[1],pos[2],pos[3]))
    local len = pos:Length()
    if len < delta then return 0 end
    return rad2deg*asin(pos.z / len)
end

local function message(Duration, StartSize, EndSize, RGB, Position, Velocity, String, nom, Pitch)
    local eplayers = RecipientFilter()
    if(AlwaysRender==0) then
        for k, v in pairs(player.GetAll()) do
            local ply = v
            if(IsValid(ply)) then 
                if(Grav[nom]==nil) then Grav[nom] = Vector(0,0,-9.8) end
                Gravi = Vector(Grav[nom][1],Grav[nom][2],Grav[nom][3])
                local Posi = Vector(Position[1],Position[2],Position[3])
                for i=1,5 do
                    local Velo = Vector(Velocity[1],Velocity[2],Velocity[3])-(Gravi*i)
                    local P = bearing(Posi+(Velo*i),ply)
                    local Y = elevation(Posi+(Velo*i),ply)
                    if (math.abs(Y) < 100) then
                        if (math.abs(P) < 100) then
                            eplayers:AddPlayer(ply)
                            break
                        end
                    end
                end
            end
        end
    else
        eplayers:AddAllPlayers()
    end
    nom:SetNetworkedInt("Duration", Duration)
    nom:SetNetworkedInt("StartSize", StartSize)
    nom:SetNetworkedInt("EndSize", EndSize)
    nom:SetNetworkedVector("Position", Vector(Position[1],Position[2],Position[3]))
    nom:SetNetworkedVector("RGB", Vector(RGB[1],RGB[2],RGB[3]))
    nom:SetNetworkedVector("Vel", Vector(Velocity[1],Velocity[2],Velocity[3]))
    nom:SetNetworkedString("Type", String) 
    nom:SetNetworkedInt("Pitch", Pitch)
    umsg.Start("e2p_pm",eplayers)
    umsg.Entity(nom)
    umsg.End()
    eplayers:RemoveAllPlayers()
end
 
local function SetMaxE2Particles( player, command, arguments)
        if(player:IsAdmin()) then
                MaxParticlesPerSecond = tonumber(arguments[1])
        end
end

local function SetAlwaysRenderParticles( player, command, arguments)
        if(player:IsAdmin()) then
                AlwaysRender = tonumber(arguments[1])
        end
end

concommand.Add("wire_e2_SetAlwaysRenderParticles",SetAlwaysRenderParticles)
concommand.Add("wire_e2_maxParticlesPerSecond",SetMaxE2Particles)

__e2setcost(20)

e2function void particle(Duration, StartSize, EndSize, string String, vector RGB, vector Position, vector Velocity)
        local Ply       = self.player
        local PlyID     = Ply:EntIndex()
        local timerName = "e2p_"..PlyID
        if(ParticlesThisSecond[PlyID] == nil) then ParticlesThisSecond[PlyID] = 0 end
        if ( ParticlesThisSecond[PlyID] <= MaxParticlesPerSecond or Ply:IsAdmin() == true) then
                message(Duration, StartSize, EndSize, RGB, Position, Velocity, String, self.entity, 0)
                ParticlesThisSecond[PlyID] = ParticlesThisSecond[PlyID] + 1
                if(timer.Exists(timerName) == false) then
                        timer.Create(timerName, 1, 0, function()
                                timer.Destroy(timerName)
                                ParticlesThisSecond[PlyID] = 0
                        end)
                end
        end
end

e2function void particle(Duration, StartSize, EndSize, string String, vector RGB, vector Position, vector Velocity, Pitch)
        local Ply       = self.player
        local PlyID     = Ply:EntIndex()
        local timerName = "e2p_"..PlyID
        if(ParticlesThisSecond[PlyID] == nil) then ParticlesThisSecond[PlyID] = 0 end
        if ( ParticlesThisSecond[PlyID] <= MaxParticlesPerSecond or Ply:IsAdmin() == true) then
                message(Duration, StartSize, EndSize, RGB, Position, Velocity, String, self.entity, Pitch)
                ParticlesThisSecond[PlyID] = ParticlesThisSecond[PlyID] + 1
                if(timer.Exists(timerName) == false) then
                        timer.Create(timerName, 1, 0, function()
                                timer.Destroy(timerName)
                                ParticlesThisSecond[PlyID] = 0
                        end)
                end
        end
end

__e2setcost(5)

e2function void particleBounce(Bounce)
    umsg.Start("e2p_bounce")
    umsg.Entity(self.entity)
    umsg.Long(math.Round(Bounce))
    umsg.End()
end

e2function void particleGravity(vector Gravity)
    umsg.Start("e2p_gravity")
    umsg.Entity(self.entity)
    umsg.Vector(Vector(Gravity[1],Gravity[2],Gravity[3]))
    umsg.End()
    Grav[self.entity] = Gravity
end

e2function void particleCollision(Number)
    umsg.Start("e2p_collide")
    umsg.Entity(self.entity)
    umsg.Long(Number)
    umsg.End()
end
e2function array particlesList()
    return Particles
end
