--[[------------------------------------------------------------------------------------------------------------------
	Instances STOOL
		Description: Put entities in different instances.
		Usage: Left click to set the instance of an entity and right click to set the instances you're in yourself.
------------------------------------------------------------------------------------------------------------------]]--

TOOL.Category = "Construction"
TOOL.Name = "#Instances"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.ClientConVar[ "instance" ] = 1

if CLIENT then
	language.Add( "Tool.instances.name", "Instance Management" )
	language.Add( "Tool.instances.desc", "Construct in multiple instance." )
	language.Add( "Tool.instances.0", "Left click to set the instance of an entity, right click to set the instance you're in yourself." )
else
	Spehs:HookNet("instance_tool_select",function(D,Ply) Ply.SelectedInstance = D.Selected print(Ply:Nick().." selected Instance "..D.Selected) end)
	Spehs:HookNet("instance_tool_request_sync",function(D,Ply) Spehs.SyncInstances() end) --Maybe add a admin check if needed.
end 

--[[------------------------------------------------------------------------------------------------------------------
	Left click to set the instance of an entity.
------------------------------------------------------------------------------------------------------------------]]--

function TOOL:LeftClick( tr )
	if ( not IsValid(tr.Entity) ) then return false end
	if ( CLIENT ) then return true end
	
	local entities = constraint.GetAllConstrainedEntities( tr.Entity )
	
	for _, ent in pairs( entities ) do
		ent:SetInstance(self:GetOwner().SelectedInstance /*Spehs.MainSpace*/)
	end
	
	return true
end

function TOOL:RightClick( tr )
	if CLIENT then return true end
	
	local ply = self:GetOwner()
	
	ply:SetInstance(self:GetOwner().SelectedInstance /*Spehs.MainSpace*/)
	
	return true
end

function TOOL:Reload() end
	
if ( CLIENT ) then
	function TOOL.BuildCPanel( pnl )	
		Spehs.Debug.ITUI = vgui.Create( "instance_tool_base" )
		pnl:AddPanel( Spehs.Debug.ITUI )
	end
end 