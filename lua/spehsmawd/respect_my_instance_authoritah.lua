/*
	Instance Management Library
	
	All the functions related to creating and managing instances go here.
	
	ToDo:
	Cleanup Code further and make it more readable --Id say its much better now then when i started.
	Migrate from outdated networking systems to more optimised ones.
*/

local Spehs = Spehs --Localise!
Spehs.Instances = Spehs.Instances or {}

--Config
Spehs.MainSpace = "MainSpace" --Name of the fallback instance used for any entities that get spawned without one.

function Spehs.GetInstanceData() --Returns a baseline instance table data.
	return {
		Name = "NotSet",			--The name of the instance for human read ability.
		Owner = game.GetWorld(),	--The owner of the instance, could be a player or the world.
		
		Entities = {},				--A easy cache of all the entities contained in the instance.
		Players = {}				--A cache of all the players currently withen this instance.
	}
end

/*
Look Into these
	https://wiki.garrysmod.com/page/ENTITY/UpdateTransmitState
	https://wiki.garrysmod.com/page/Entity/SetPreventTransmit
	https://wiki.garrysmod.com/page/Entity/InitializeAsClientEntity
	https://facepunch.com/showthread.php?t=1372766
*/

/* Internal Functions Below */

--Creates and configures a instance ready to be used.
function Spehs:CreateInstance(Name)
	if(not Spehs.Instances[Name])then --Check if the instance already exists.
		print("Generating [ "..Name.." ] instance")			
		local Instance = Spehs.GetInstanceData() --Get the preset data for a instance.
		
		Instance.Name = Name --Give it a name.
		Spehs.Instances[Name]=Instance --Throw it into the data pile.
	else
		print("Error Instance: [ "..Name.." ] already exists!")
	end
end

--Make our test instances here.
if SERVER then Spehs:CreateInstance(Spehs.MainSpace) Spehs:CreateInstance("NullSpace") end

/* Instance Networking Solution */

if SERVER then
	function Spehs.SyncInstances()
		--print("Syncing Instance "..Name)
		for id, instance in pairs( Spehs.Instances ) do
			local Data = {
				Name = instance.Name,
				Owner = instance.Owner,
				Entities = instance.Entities,
				Players = instance.Players
			}
			
			--PrintTable(instance)
			
			Spehs:NetworkData("Instance_Sync",Data)
		end
	end
else
	Spehs:HookNet("Instance_Sync",function(D)
		local name = D.Name
		if not Spehs.Instances[id] then Spehs:CreateInstance(name) end
		Spehs.Instances[name].Entities = D.Entities
		Spehs.Instances[name].Players = D.Players
		Spehs.Instances[name].Owner = D.Owner
		
		--PrintTable(D)	
		--PrintTable(Spehs.Instances)
	end)
end

/* Hooks and Meta Table editing. */

local ENT,PLY = FindMetaTable( "Entity" ),FindMetaTable( "Player" )

Spehs.OldFunctions = {}
local OldFunks = Spehs.OldFunctions

--Returns if two entities should collide.
function Spehs:ShouldCollide( ent1, ent2 )
	return ent1:GetInstance() == ent2:GetInstance()
end

--The hook function to handle entity collisions.
function ShouldEntitiesCollide( ent1, ent2 )
	if (ent1:IsWorld() or ent2:IsWorld())then return true end
	if ( ent1 == ent2 ) then return false end
	return Spehs:ShouldCollide( ent1 , ent2  )
end
hook.Add( "ShouldCollide", "InstanceSeperator", ShouldEntitiesCollide )

if(SERVER)then
	function Spehs.EntitySpawnLayer( ply, ent ) ent:SetInstance( ply:GetInstance() ) ent:SetCustomCollisionCheck(true) end
	function Spehs.EntitySpawnLayerProxy( ply, mdl, ent ) Spehs.EntitySpawnLayer( ply, ent ) end
	function Spehs.OnEntityCreated( ent ) ent:SetCustomCollisionCheck(true) if ent:GetInstance()=="" then ent:SetInstance(Spehs.MainSpace) end end	
	function Spehs.OnEntityRemove( ent ) Spehs.Instances[ent:GetInstance()].Entities[ent:EntIndex()]=nil end
	
	function Spehs.InitializePlayerLayer( ply ) 
		ply:SetInstance(Spehs.MainSpace) 
		ply:SetCustomCollisionCheck(true) 
	end	
	
	function Spehs.HandlePlayerSpawn(ply)
		local Spawns = ents.FindByClass("sing_spawn")
		if table.Count(Spawns or {}) > 0 then
			Spawn = table.Random(Spawns)
			ply:SetPos(Spawn:GetPos()+Vector(0,0,20))
			ply:SetInstance(Spawn:GetInstance())
		else
			ply:SetInstance(Spehs.MainSpace)
		end
	end
	
	hook.Add("PlayerSpawnedSENT","Instancing",Spehs.EntitySpawnLayer)
	hook.Add("PlayerSpawnedNPC","Instancing",Spehs.EntitySpawnLayer)
	hook.Add("PlayerSpawnedVehicle","Instancing",Spehs.EntitySpawnLayer)
	hook.Add("PlayerSpawnedProp","Instancing",Spehs.EntitySpawnLayerProxy)
	hook.Add("PlayerSpawnedEffect","Instancing",Spehs.EntitySpawnLayerProxy)
	hook.Add("PlayerSpawnedRagdoll","Instancing",Spehs.EntitySpawnLayerProxy)
	hook.Add("PlayerInitialSpawn","Instancing",Spehs.InitializePlayerLayer)
	hook.Add("PlayerSpawn","Instancing",Spehs.HandlePlayerSpawn)	
	hook.Add("OnEntityCreated","Instancing",Spehs.OnEntityCreated)
	hook.Add("OnRemove","Instancing",Spehs.OnEntityRemove)		
end	

--[[------------------------------------------------------------------------------------------------------------------
	Basic set and get instance functions
------------------------------------------------------------------------------------------------------------------]]--

function ENT:SetInstance( instance )
	if ( not self:IsPlayer() and Spehs.WhiteListedEntities[self:GetClass()]~=true ) or self:IsWorld() then return end--I Shouldnt be put into a instance.
	
	--print("Im "..self:GetClass().." being set into instance "..instance)
	
	local OldIn = self:GetInstance()
	if OldIn==instance then return end --Dont run if were trying to change to the same instance

	if self:IsPlayer() then
		if OldIn~="" then Spehs.Instances[OldIn].Players[self:EntIndex()]=nil end
		Spehs.Instances[instance].Players[self:EntIndex()]=self
		
		--print(self:Nick().."'s instance is set to "..instance)
		
		if not self.UsingCamera then self:SetViewInstance( instance ) end
	else
		if OldIn~="" then Spehs.Instances[OldIn].Entities[self:EntIndex()]=nil end
		Spehs.Instances[instance].Entities[self:EntIndex()]=self		
	end
	
	self.Instance = Spehs.Instances[instance]
	
	--self:SetNWString( "Instance", instance ) Phasing this out.
end

function ENT:GetInstance()
	if self.Instance ~= nil then return self.Instance.Name end
	if IsValid(self:GetParent()) then return self:GetParent():GetInstance() end
	return ""
end

function ENT:SetViewInstance( instance ) self:SetNWString( "ViewInstance", instance ) end

function ENT:GetViewInstance()
	return self:GetNWString("ViewInstance",Spehs.MainSpace)
end

--[[------------------------------------------------------------------------------------------------------------------
	Trace modification
------------------------------------------------------------------------------------------------------------------]]--

if(not OldFunks.OriginalTraceLine)then OldFunks.OriginalTraceLine = util.TraceLine end
function util.TraceLine( td, subspace )
	if not subspace then if(SERVER)then subspace = "Global" else subspace = LocalPlayer():GetInstance() end end
	local originalResult = OldFunks.OriginalTraceLine( td )
	if not IsValid(originalResult.Entity) or originalResult.Entity:GetInstance() == subspace or subspace=="Global" then
		return originalResult
	else
		if ( td.filter ) then
			if ( type( td.filter ) == "table" ) then
				table.insert( td.filter, originalResult.Entity )
			else
				td.filter = { td.filter, originalResult.Entity }
			end
		else
			td.filter = originalResult.Entity
		end
		
		return util.TraceLine( td )
	end
end

if not OldFunks.OriginalPlayerTrace then OldFunks.OriginalPlayerTrace = util.GetPlayerTrace end
function util.GetPlayerTrace( ply, dir )
	local originalResult = OldFunks.OriginalPlayerTrace( ply, dir )
	originalResult.filter = { ply }
	
	for _, ent in ipairs( ents.GetAll() ) do
		if ent:GetInstance() ~= ply:GetInstance() then
			table.insert( originalResult.filter, ent )
		end
	end
	
	return originalResult
end

if not OldFunks.OriginalEyeTrace then OldFunks.OriginalEyeTrace = PLY.GetEyeTrace end
function PLY:GetEyeTrace()
	local Table = util.GetPlayerTrace( self, self:GetAimVector() )
	
	return  util.TraceLine( Table, self:GetInstance() )
end

if(SERVER)then
	if not OldFunks.OldSetViewEntity then OldFunks.OldSetViewEntity = PLY.SetViewEntity end
	function PLY:SetViewEntity( ent )
		self:SetViewInstance( ent:GetInstance() )
		return OldFunks.OldSetViewEntity( self, ent )
	end
		
	if not OldFunks.OriginalAddCount then OldFunks.OriginalAddCount = PLY.AddCount end
	function PLY:AddCount( type, ent )
		ent:SetInstance( self:GetInstance() )
		return OldFunks.OriginalAddCount( self, type, ent )
	end
	
	if not OldFunks.OriginalCleanup then OldFunks.OriginalCleanup = cleanup.Add end
	function cleanup.Add( ply, type, ent )
		if ( ent ) then ent:SetInstance( ply:GetInstance() ) end
		return OldFunks.OriginalCleanup( ply, type, ent )
	end		
else
	if not OldFunks.oldEmitSound then OldFunks.oldEmitSound = ENT.EmitSound end
	function ENT:EmitSound( filename, soundlevel, pitchpercent )
		if LocalPlayer():GetInstance() ~= self:GetInstance() then return end
		
		OldFunks.oldEmitSound( self, filename, soundlevel, pitchpercent )
	end
end		 
