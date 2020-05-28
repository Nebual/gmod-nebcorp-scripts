local function AddVehicle( t, class )
	list.Set( "Vehicles", class, t )
end


local Category = "Half-Life 2"
AddVehicle( {
	Name = "Jalopy",
	Model = "models/vehicle.mdl",
	Class = "prop_vehicle_jeep",
	Category = Category,

	Author = "VALVe",
	Information = "The muscle car from Episode 2",

	KeyValues = {
		vehiclescript = "scripts/vehicles/jalopy.txt"
	}
}, "Jalopy" )
AddVehicle( {
	Name = "Jalopy Seat",
	Model = "models/nova/jalopy_seat.mdl",
	Class = "prop_vehicle_prisoner_pod",
	Category = Category,

	Author = "VALVe",
	Information = "A Seat from VALVe's Jalopy",

	KeyValues = {
		vehiclescript = "scripts/vehicles/prisoner_pod.txt",
		limitview = "0"
	},
	Members = {
		HandleAnimation = HandleRollercoasterAnimation,
	}
} , "Seat_Jalopy" )


local Category = "Half-Life 2"

local function ADD_ITEM( name, class )

	list.Set( "SpawnableEntities", class, { PrintName = name, ClassName = class, Category = Category, NormalOffset = 32, DropToFloor = true, Author = "VALVe" } )
	duplicator.Allow( class )

end
game.AddParticles( "particles/striderbuster.pcf" )
ADD_ITEM( "Magnusson", "weapon_striderbuster" )


local function AddNPC( t, class )
	list.Set( "NPC", class or t.Class, t )
end

local Category = "Humans + Resistance"
	AddNPC( {
		Name = "Uriah",
		Class = "npc_vortigaunt",
		Category = Category,
		Model = "models/vortigaunt_doctor.mdl",
		KeyValues = { SquadName = "resistance" }
	}, "VortigauntUriah" )

	AddNPC( {
		Name = "Dr. Arne Magnusson",
		Class = "npc_magnusson",
		Category = Category
	} )
	AddNPC( {
		Name = "Fisherman",
		Class = "npc_fisherman",
		Category = Category,
		Weapons = { "weapon_oldmanharpoon" }
	} ) -- Has no death sequence
	
	
Category = "Zombies + Enemy Aliens"
	game.AddParticles( "particles/grub_blood.pcf" )
	game.AddParticles( "particles/antlion_gib_02.pcf" )
	game.AddParticles( "particles/antlion_worker.pcf" )

	AddNPC( {
			Name = "Antlion Guardian",
			Class = "npc_antlionguard",
			Category = Category,
			KeyValues = { cavernbreed = 1, incavern = 1, SquadName = "antlions" },
			Material = "Models/antlion_guard/antlionGuard2"
	}, "npc_antlionguardian" )

	AddNPC( {
		Name = "Antlion Grub",
		Class = "npc_antlion_grub",
		Category = Category,
			NoDrop = true,
			Offset = 1
	} )

	AddNPC( {
		Name = "Antlion Worker",
		Class = "npc_antlion_worker",
		Category = Category,
		KeyValues = { SquadName = "antlions" }
	} )
	AddNPC( {
		Name = "Zombine",
		Class = "npc_zombine",
		Category = Category,
		KeyValues = { SquadName = "zombies" }
	} )
	
Category = "Animals"
	AddNPC( {
		Name = "Hunter",
		Class = "npc_hunter",
		Category = Category,
		KeyValues = { SquadName = "overwatch" }
	} )