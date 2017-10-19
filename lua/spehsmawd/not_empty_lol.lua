-------Temporary file I'm testing stuffs in (so we don't accidentally edit the same file during the same commit), will merge with other files later

--Temp spawn platform, can mess with that later
--models/hunter/plates/plate32x32.mdl

if SERVER then
	local Spehs = Spehs	or {}					--I really should test if this actually gives any speed increase or not
	Spehs.Objects = Spehs.Objects or {}		--Here is where the universe's objects lie (for this test anyway)
	
	Spehs.ObjectLoadDistance = 10000			--Distance at which nodes load surrounding objects, meaning divide by 2 for minimum actual object load distance and multiply by 2 for maximum actual object load distance (radius)
	
	
	--[[local function Distance3D(Vec1,Vec2)
		local dx, dy, dz = Vec1.x - Vec2.x, Vec1.y - Vec2.y, Vec1.z - Vec2.z
		return (dx * dx + dy * dy + dz * dz) ^ 0.5
	end]]--

	--Basic object adding function, will need expanded and probably another function added for mass added objects/dynamic objects
	function Spehs.AddObject(Name,Model,Type,Position,Angle,Velocity,Material,Skin)
		--Check to make sure the required variables are good
		if type(Name) == "string" and type(Model) == "string" and type(Type) == "number" and type(Position) == "Vector" and type(Angle) == "Angle" then
			--Next check to see if a Node is with-in range
			local NodeKey = "NoNodeFound"
			local NodeCount = table.Count(Spehs.Objects)
			if NodeCount > 0 then
				local nodepos = Vector(0,0,0)
				local distance = 0
				for k, v in pairs(Spehs.Objects) do
					if type(v) == "table" then
						if type(v.Location) == "Vector" then
							nodepos = v.Location
							distance = nodepos:Distance(Position)
							--print(distance)
							if distance < Spehs.ObjectLoadDistance*0.5 then
								NodeKey = k
							end
						end
					end
				end
			end
			if NodeKey == "NoNodeFound" then
				NodeKey = "Node"..tostring(NodeCount+1)
				Spehs.Objects[NodeKey] = {}
				Spehs.Objects[NodeKey].Location = Position
			end
			if type(Spehs.Objects[NodeKey][Name]) == "table" then
				print("Spehs.AddObject Error:  Object of the same name already exists.")
				return
			end
			Spehs.Objects[NodeKey][Name] = {}
			Spehs.Objects[NodeKey][Name]["Model"] = Model
			--Type variable determines what the object can do - 0 = generic unmoveable, 1 = generic moveable, 2 = mineable asteroid, ect will figure out these later
			Spehs.Objects[NodeKey][Name]["Type"] = Type
			Spehs.Objects[NodeKey][Name]["Position"] = Position
			Spehs.Objects[NodeKey][Name]["Angle"] = Angle
			--Optional Variables
			if type(Velocity) == "Vector" then Spehs.Objects[NodeKey][Name]["Velocity"] = Velocity end
			if type(Material) == "string" then Spehs.Objects[NodeKey][Name]["Material"] = Material end
			if type(Skin) == "number" then Spehs.Objects[NodeKey][Name]["Skin"] = Skin end
		end
	end

	--Example object additions
	Spehs.AddObject("UniversePotato","models/props_phx/misc/potato.mdl",0,Vector(0,0,0),Angle(0,0,0))
	Spehs.AddObject("OtherPotato","models/props_phx/misc/potato.mdl",0,Vector(2000,2000,-100),Angle(90,90,90))
	Spehs.AddObject("FarAwayPotato","models/props_phx/misc/potato.mdl",0,Vector(10000,0,0),Angle(69,42,101))
	Spehs.AddObject("OtherOtherPotato","models/props_phx/misc/potato.mdl",0,Vector(100,100,-100),Angle(90,90,90))
	
	--Give players the list of objects on first join
	function SyncSpehsToClient(Ply)
		if not Spehs.Objects then
			print("SyncSpehsToClient Error:  Cannot find object table!  O_O")
			return
		end
		Spehs:NetworkData("SyncSpehsToClient",Spehs.Objects,Ply)
	end
	hook.Add( "PlayerInitialSpawn", "SyncSpehsToClient", SyncSpehsToClient )
	
	
end

if CLIENT then
	local Spehs = Spehs or {}
	Spehs.Objects = Spehs.Objects or {}
	
	--Receive the list of objects
	Spehs:HookNet("SyncSpehsToClient",
		function(Data)
			if type(Data) == "table" then
				Spehs.Objects = Data
				print("SyncSpehsToClient: Object list received from server")
				PrintTable(Data)
			end
		end
	)
end