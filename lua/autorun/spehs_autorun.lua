/* Spehs Mod Autorun 
	Here we setup the global table and stuff, I dont know yet.	
*/
----------------------------------------------------]]--
local Breaker = "*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*"
print(Breaker) print("SpehsMawd Initialising!! SPAAAAAAAACE!") print(Breaker)
local StartTime = SysTime() --Logging the time for the mod loads, just because we can.

Spehs = Spehs or {}
local Spehs = Spehs --Localise!

Spehs.Debug = Spehs.Debug or {}
Spehs.Debug["DebugMode"] = true

--Create our helper load file function.
local NetInstance = {client=0,shared=1,server=3}
function Spehs.LoadFile(Path,Mode)
	if type(Mode)=="string" then --Did we get passed a string?
		Mode = NetInstance[string.lower(Mode)]--Make sure the strings lowercased
	else
		Mode=Mode or 1--We either got handled number or null
	end
	
	if SERVER then
		if Mode >= 1 then
			include(Path)
			if Mode == 1 then
				AddCSLuaFile(Path)
			end
		else
			AddCSLuaFile(Path)
		end
	else
		if Mode <= 1 then
			include(Path)
		end
	end
end

local Path = "spehsmawd/" --Just incase we want to change the folder name later.

Spehs.LoadFile(Path.."variables.lua","shared")

Spehs.LoadFile(Path.."networking.lua","shared")
Spehs.LoadFile(Path.."respect_my_instance_authoritah.lua","shared")
Spehs.LoadFile(Path.."shipconstructor.lua","shared")
Spehs.LoadFile(Path.."not_empty_lol.lua","shared")

if SERVER then
	resource.AddWorkshop( "926488706" ) --SpehsModContentPack
	
	/* Copied from envx lua, sort these out later.
	resource.AddWorkshop( "174935590" ) --Spore Models
	resource.AddWorkshop( "160250458" ) --Wire Models
	resource.AddWorkshop( "148070174" ) --Mandrac Models
	resource.AddWorkshop( "182803531" ) --SBEP Models
	resource.AddWorkshop( "247007332" ) --Envx
	resource.AddWorkshop( "231698363" ) --Npc Models
	*/
else
	--Load ClientSide gui!
	
	
end

print(Breaker) print("SpehsMawd Initialised! Took "..(SysTime()-StartTime).."'s to load.") print(Breaker)
