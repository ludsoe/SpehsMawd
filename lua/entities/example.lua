AddCSLuaFile( "aix_sim.lua" )

ENT.Type 			= "anim"
ENT.Base 			= "base_gmodentity"
ENT.PrintName		= "Example Entity"
ENT.Author			= "Ludsoe"
ENT.Category		= "Other"

ENT.Spawnable		= false
ENT.AdminSpawnable	= false

if(SERVER)then
	function ENT:Initialize()
		self:SetModel("models/sbep_community/d12shieldemitter.mdl")
		
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
	end
	
	function ENT:Think()
		--Do Think Stuff
	end
	
	function ENT:OnRemove()
		--Blah
	end
else

end