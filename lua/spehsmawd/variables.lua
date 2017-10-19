/*
	Variables
	
	Where Im keeping variables used in multiple luas.
*/

local Spehs = Spehs

Spehs.WhiteListedEntities = {} --The entity classes we will be handling with the instance and ship constructor systems.
function WhiteListEntityClass(class)Spehs.WhiteListedEntities[class]=true end

WhiteListEntityClass("prop_physics")--The majority of entities players will have probably.