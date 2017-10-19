--[[------------------------------------------------------------------------------------------------------------------
	Instance Testing Tool UI
------------------------------------------------------------------------------------------------------------------]]--

print("Instance Testing Tool Ui Loaded")

Tool_UI_Base = {}

function Tool_UI_Base:Init()
	self.CallSync = vgui.Create( "DButton" , self)
	self.CallSync:SetText("Sync Instances")
	self.CallSync:SetSize(250,30)
	self.CallSync.DoClick = function()	
		Spehs:NetworkData("instance_tool_request_sync",{})
	end
	
	self.List = vgui.Create( "DPanelList", self )
	self.List:SetSpacing( 2 )
	self.List:SetPadding( 2 )
	self.List:SetPos(0,35)
	self.Instances = {}
	self.SelectedLayer = 1	
	self.NThink = 0
	
	print("Instance Testing Tool Ui Intialized!")
end

function Tool_UI_Base:PerformLayout()
	self:SetTall( 400 )
	
	--self.List:StretchToParent( 0, 0, 0, 0 )
	self.List:SetTall(365)
	self.List:SetWide(250)
end

function Tool_UI_Base:Think()
	if CurTime()>self.NThink then self.NThink = CurTime()+1
		for id, instance in pairs( Spehs.Instances ) do
			if self.Instances[id] == nil then --Make New Buttons if the instance doesnt have one.			
				self.Instances[id] = self:AddLayer(instance)
			else --Update Existing Buttons
				self.Instances[id]:UpdateInfo(instance)
			end
		end
	end
end

function Tool_UI_Base:AddLayer(instance)
	local InstanceButton = vgui.Create("instancebutton",self.List) --vgui.CreateFromTable( layerButtonControl, self.List )
	InstanceButton:SetInstance(instance)
	
	self.List:AddItem( InstanceButton )
	
	return InstanceButton
end

vgui.Register( "instance_tool_base",Tool_UI_Base) 

--Instance Ui Button Below.

InstanceButton = {}

function InstanceButton:Init()	
	self.Selected = false
		
	self.OwnerButton = vgui.Create( "DImageButton", self )
	self.OwnerButton:SetMaterial( "gui/silkicons/user" )

	self.InfoButton = vgui.Create( "DImageButton", self )
	self.InfoButton:SetMaterial( "icon16/package_green.png" )

	self.PlayersButton = vgui.Create( "DImageButton", self )
	self.PlayersButton:SetMaterial( "icon16/group.png" )
end

function InstanceButton:OnMouseReleased( mc )
	for _, otherbutton in pairs( Spehs.Debug.ITUI.List:GetItems() ) do otherbutton.Selected = false end
	
	self.Selected = true
	Spehs.Debug.ITUI.SelectedLayer = self.Instance
	
	Spehs:NetworkData("instance_tool_select",{Selected=self.Instance.Name})
end

function InstanceButton:UpdateInfo(instance)
	self.Instance = instance
	
	local owner = instance.Owner
	local ownername = "World" if owner:IsPlayer() then ownername = owner:Nick() end
	self.OwnerButton:SetTooltip( "Owner: " .. ownername )
	
	self.InfoButton:SetTooltip( "Amount of entities: " .. table.Count((instance.Entities or {})) )
	
	local players = ""
	for _, ply in pairs( instance.Players ) do players = players .. ply:Nick() .. ", " end
	if table.Count(instance.Players) == 0 then players = "None." else players = string.Left( players, #players - 2 ) end
	self.PlayersButton:SetTooltip( "Players: " .. players )
end

function InstanceButton:SetInstance(instance)
	print("Instance Set to "..instance.Name)
	
	self:UpdateInfo(instance)
end

function InstanceButton:PerformLayout()
	self.PlayersButton:SizeToContents()
	self.PlayersButton.y = 4
	self.PlayersButton:AlignRight( 6 )
	
	self.OwnerButton:SizeToContents()
	self.OwnerButton.x = self.PlayersButton.x - self.PlayersButton:GetWide() - 5
	self.OwnerButton.y = 4
	
	self.InfoButton:SizeToContents()
	self.InfoButton.x = self.OwnerButton.x - self.OwnerButton:GetWide() - 5
	self.InfoButton.y = 4
	
	self:SetTall( self.PlayersButton:GetTall() + 8 )
end

function InstanceButton:Paint()
	if self.Selected then
		draw.RoundedBox( 2, 0, 0, self:GetWide(), self:GetTall(), Color( 48, 150, 253, 255 ) )
	else
		draw.RoundedBox( 2, 0, 0, self:GetWide(), self:GetTall(), Color( 121, 121, 121, 150 ) )
	end
	
	draw.SimpleText( self.Instance.Name, "Default", 6, 6, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
	
	return false
end

vgui.Register( "instancebutton",InstanceButton) 
