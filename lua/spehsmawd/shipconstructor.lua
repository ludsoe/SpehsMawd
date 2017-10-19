/*
	Ship Constructor Library
	
	Handles the data involved in creating and saving ships/space objects.
	
	ToDo:
	Add more Todos.
*/

local Spehs = Spehs

--Centers the entities around the center of the map.
function Spehs.CenterEntities(data)
	local ShipCenter = Vector(0,0,0)
	for ind, ent in pairs( data ) do --Before we can center the spaceship in the map, we have to find its center.
		if IsValid(ent) then
			ShipCenter=ShipCenter+ent:GetPos()
		else
			data[ind]=nil
		end
	end
	local Count = table.Count(data)
	
	ShipCenter = Vector(ShipCenter.x/Count,ShipCenter.y/Count,ShipCenter.z/Count)
	--print("CenterPoint Is at: "..tostring(ShipCenter))
	
	for _, ent in pairs( data ) do --Now Lets center the center of the ship around the map center.... Yeah
		ent:SetPos(ent:GetPos()-ShipCenter)
	end
end

-- {Skin,Model,Position,Angle,Color,EntMods,PerData}
--Returns a entities duplication data.
function Spehs.GetEntityData(Ent,Mode)
	local Data = {}
	
	Data.Model=Ent:GetModel()
	
	local Class = Ent:GetClass()
	if Class~="prop_physics" then Data.Class = Class end
	
	Data.Position=Ent:GetPos()
	Data.Angle=Ent:GetAngles()
	
	local Skin = Ent:GetSkin()
	if Skin~=1 then Data.Skin=Skin end
	
	local Col = Ent:GetColor()
	if Col~=Color(255,255,255,255) then Data.Color=Col end
		
	if Mode == true then--Get entity persistant data.
		if Ent.GetPerData then Data.PerData=Ent:GetPerData() end
		
		if Ent.PreEntityCopy then
			Ent:PreEntityCopy()
			Data.EntMods=Ent.EntityMods
		end
	end
	
	return Data
end

--Returns a table containing all the entities in a ship.
--Setting mode to true will return all data, while setting to false will return a trimmed down version for networking.
function Spehs.GenerateShipData(data,Mode)
	local ShipData = {Entities={}}
	
	if Mode == true then--If mode is set to true then we will grab extra data for the purpose of saving the ship to disk.
		
	end
	
	for _, ent in pairs( data ) do
		if IsValid(ent) then
			ShipData.Entities[ent:EntIndex()] = Spehs.GetEntityData(ent,Mode)
		end
	end
	
	return ShipData
end

--Prepares a ship for use in the game universe.
function Spehs.PrepareShipData(data)
	if string.lower(type(data)) ~= "table" then print("ShipConstructor: GenerateShipData Function wasnt given a proper table.") return end
	
	local UsableEnts = {}
	
	for _, ent in pairs( data ) do --Not sure if we have to sort this out anymore due to instances coming prefiltered now.
		if IsValid(ent) then
			if Spehs.WhiteListedEntities[ent:GetClass()] == true then
				table.insert(UsableEnts,ent)
			end
		end
	end
	
	Spehs.CenterEntities(UsableEnts)
	
	return Spehs.GenerateShipData(UsableEnts,false) --Im assuming this gets whipped off to networking.
end

/* Persistance Functions */



