local Spehs=Spehs
Spehs.Networking = Spehs.Networking or {} --Where the netcode lives!

local Net = Spehs.Networking --Create a easier variable for us to work with.
Net.Data = Net.Data or {} --Data we will be sending.
Net.Hookers = Net.Hookers or {} --Functions to call when we recieve a message.

/*
Config Options for networking, Make sure you know what your doing before changing!
*/
local ComplexMults = {string=0.2,player=1,entity=1,weapon=1,number=1,vector=1,angle=1,boolean=1,table=1}--The complexity multipliers for
local ServerMaxComplexity = 200 --The maximum complexity total we can send in a single network cycle, per player on the server.
local ClientMaxComplexity = 50 --The maximum complexity a client can send to the server per network cycle.
local MaxBatchSize = 20 --The maximum complexity a single segment can contain.

local NetCycleDelay = 0.1 --How long in seconds between each network cycle.

/*
Exposed Functions.
*/

function Spehs:HookNet(MSG,Func) Net.Hookers[MSG] = Func end --Create a function to hook into the net library.
function Spehs:NetworkData(Name,Data,Ply) --Sends data out
	local MSG = {}--Create the message table.
	--[[Data={Name="example",Val=1,Dat={VName="example"}}]]		
	MSG.Name = Name
	
	local Complexity = Net.DataComplexity(Data) print("Data Complexity: "..Complexity)
	if Complexity > MaxBatchSize and type(Data) == "table" then 
		return Net.SegmentSend(Name,Data,Ply)
	end
	MSG.Val = Complexity 
	
	MSG.Dat = Data
	
	if SERVER then
		if Ply ~= nil then--Is there a variable for ply?
			if IsValid(Ply) then--Check if the client is valid!
				return Net.AddData(MSG,Ply)--Special telegraph!
			else
				--Invalid player entity?
			end
		else
			return Net.AddDataAll(MSG)--Send the data to all clients!
		end
	else
		return Net.AddData(MSG)--Sending stuff to the server eh?
	end
end

--Bulk Data Test. lua_run local Data = {} for I=1,500 do table.insert(Data,{"SPAM"}) end Spehs:NetworkData("Test",Data)
--Large Data Test. lua_run local Data = {} for I=1,5 do local T = {} for X=1,I*10 do table.insert(T,{"SPAM"}) end table.insert(Data,T) end Spehs:NetworkData("Test",Data)
Spehs:HookNet("Test",function(Dat) PrintTable(Dat) end)

/*------------------------------------------------
			Internal Functions Below
------------------------------------------------*/

function Net.SegmentSend(Name,Data,Ply)
	local Msgs = {}
	
	--The id we will use for this batch of segmented data. (Todo: Use a better method to get the ids.)
	local ID = tostring(math.random(1,1000))..Name 
	
	--Lets prepare the data so we can smartly segment it for transmission.
	local Segments = {}
	for tab, dat in pairs( Data ) do
		table.insert(Segments,{Complexity = Net.DataComplexity(dat),Key=tab,Data = dat})
	end
	
	local Processing = true
	while Processing == true do --While we are processing the net message run.
		local MsgComplexity = 0
		local Message = {}
		for tab, dat in pairs( Segments ) do --Lets try combining segments to save on the amount of netmessages we have to make.
			if MsgComplexity == 0 or MsgComplexity+dat.Complexity < MaxBatchSize then --Todo: Make tables above the size, trigger their own segmented send call.
				MsgComplexity=MsgComplexity+dat.Complexity
				
				Message[dat.Key]=dat.Data--Combine the segmented data.
				
				Segments[tab]=nil --Remove the data from the table.
			end
		end
		
		table.insert(Msgs,{Name=Name,ID=ID,Data=Message,Total=0})--Add the message to our list to send.
		
		if table.Count(Segments)<=0 then Processing = false end --Hope this doesnt cause a infinite loop, otherwise ill have to get crazy.
	end
	
	--table.insert(Msgs,{Name=Name,ID=ID,Data=dat,Total=table.Count(Data)})
	
	local SegmentTotal = table.Count(Msgs)
	for tab, dat in pairs( Msgs ) do --Create the segments.
		dat.Total = SegmentTotal
	end
	
	local SuccessAll = true
	for x, Dat in pairs( Msgs ) do
		local MSG = {}
		
		MSG.Name = "Spehs_SegmentedData"
		
		local Complexity = Net.DataComplexity(Dat)
		MSG.Val = Complexity print("Segment Complexity: "..Complexity)
		
		MSG.Dat = Dat	
	
		if SERVER then
			if Ply ~= nil then--Is there a variable for ply?
				if IsValid(Ply) then--Check if the client is valid!
					if Net.AddData(MSG,Ply)==false then --Special telegraph!
						SuccessAll = false
					end
				else
					--Invalid player entity?
				end
			else
				if Net.AddDataAll(MSG) == false then--Send the data to all clients!
					SuccessAll = false
				end
			end
		else
			if Net.AddData(MSG) == false then--Sending stuff to the server eh?
				SuccessAll = false
			end
		end
	end
	
	return SuccessAll
end

local RecievedSegments = {}
function Net.SegmentRecieve(Dat,ply) 
	local Meta = {}
	
	if SERVER then --If the server recieves segment data isolate it per player.
		if RecievedSegments[ply:Nick()] == nil then RecievedSegments[ply:Nick()] = {} end
		if RecievedSegments[ply:Nick()][Dat.ID] == nil then RecievedSegments[ply:Nick()][Dat.ID] = {Segments={},Total=Dat.Total} end
		Meta = RecievedSegments[ply:Nick()][Dat.ID]	
	else --If the client recieves segmented data use a simplier path.
		if RecievedSegments[Dat.ID] == nil then RecievedSegments[Dat.ID] = {Segments={},Total=Dat.Total} end
		Meta = RecievedSegments[Dat.ID]
	end
			
	table.insert(Meta.Segments,Dat.Data)--Add the recieved segments data.
	
	local CountSegments = table.Count(Meta.Segments)
	if CountSegments == Dat.Total then
		local Data = {}
		
		--Time to reconstruct the data.
		for seg, dat in pairs( Meta.Segments ) do
			for tab, var in pairs( dat ) do
				Data[tab]=var
			end
		end
		
		print("Recieved all segments!")
		
		Net:InNetF(Dat.Name,Data) --Call recieved netmessage function with our reconstructed data set.
		
		--Clear the segment data incase a new message gets sent with the same name.
		if SERVER then
			
		else
			RecievedSegments[Dat.ID] = nil
		end
	else
		print("Recieved: "..CountSegments.." out of "..Dat.Total.." segments.")
	end
end
Spehs:HookNet("Spehs_SegmentedData",Net.SegmentRecieve)

local ComplexFuncs = { -- Contains functions that help is figure out the complexity of data.
	string=function(d) return string.len(d) end,
	player=function(d) return 1 end,
	entity=function(d) return 0.1 end,
	number=function(d) return math.Round(d/100,2) end,
	vector=function(d) return 3 end,
	angle=function(d) return 3 end,
	boolean=function(d) return 0.05 end,
	table=function(d) return Net.DataComplexity(d) end,
	weapon=function(d) return 0.1 end
}

--Returns the estimated complexity of data inputed.
function Net.DataComplexity(Data)
	local Complexity = 0
	
	local Type = string.lower(type(Data)) --Get the type of the data were checking.
	if ComplexFuncs[Type]==nil then print("I Dont understand this datatype: "..Type) end
	
	if Type == "table" then --If its a table we want to check all its children.
		for tab, dat in pairs( Data ) do
			local dType = string.lower(type(dat))
			if ComplexFuncs[dType]==nil then print("I Dont understand this datatype: "..dType) end
			Complexity = Complexity+ComplexFuncs[dType](dat)*ComplexMults[dType]
		end
	else
		Complexity = Complexity+ComplexFuncs[Type](Data)*ComplexMults[Type] --Add the detected complexity to our total.
	end
	
	--print(Type.." Complexity: "..Complexity)
	
	return Complexity 
end

--Massive data tables, with the purpose of allowing us to automagically transmit data.
local NumBool = function(V) if V then return 1 else return 0 end end --Bool to number.
local BoolNum = function(V) if V>0 then return true else return false end end --Number to bool.
Net.NetDTWrite = {S=net.WriteString,E=function(V) net.WriteFloat(V:EntIndex()) end,F=net.WriteFloat,V=net.WriteVector,A=net.WriteAngle,B=function(V) net.WriteFloat(NumBool(V)) end}
Net.NetDTRead = {S=net.ReadString,E=function(V) return Entity(net.ReadFloat()) end,F=net.ReadFloat,V=net.ReadVector,A=net.ReadAngle,B=function() return BoolNum(net.ReadFloat()) end}
Net.Types = {string="S",player="E",entity="E",number="F",vector="V",angle="A",boolean="B",table="T"}

--Since converting to json doesnt seem to work 100% of the time anymore made a new set of functions to handle them better.
Net.NetDTWrite["T"] = function(V) 
	net.WriteFloat(table.Count(V)) --How Many variables are we sending?
	
	for I, S in pairs( V ) do Net.WriteData(I,S) end --Transmit our variables.
end

Net.NetDTRead["T"] = function() 
	local Data = {} --Empty Data Table to put our data into.
	
	local Count = net.ReadFloat()
	for I=1,Count do --Read all the variables.
		Data[net.ReadString()]=Net.NetDTRead[net.ReadString()]()
	end
	
	return Data
end

function Net.WriteData(Name,Value)
	local Type = Net.Types[string.lower(type(Value))]
	if Type then
		--print("Sending Data "..Type.." : "..tostring(Value))
		net.WriteString(Name)--Write the variable name.
		net.WriteString(Type)--Write the variables type.
		Net.NetDTWrite[Type](Value)
	else
		print("Unknown Type Entered! "..Type)
	end
end

--Internal function dealing with the transmission of data.
function Net.SendData(Data,Name,ply)
	if not Data.Dat then error("Netcode Failure! Missing Dat table. ["..tostring(Name).."]") return false end --Damn Missing Dat table....
	
	net.Start("sing_basenetmessage") --Start the netmessage, using the base string indentifier for easy recieving.
		
		--print("Transmitting Message: "..Name)
		
		net.WriteString(Name) --Write the name of the hook to call, when recieved.
		net.WriteFloat(table.Count(Data.Dat)) --Write how much data we will be sending.
		
		for I, S in pairs( Data.Dat ) do Net.WriteData(I,S) end --Loop all the variables.
		
	if SERVER then --Are we the server or a client?
		net.Send(ply)
	else
		net.SendToServer()
	end
	return true
end

--Called when we recieve messages.
function Net:InNetF(MSG,Data,ply)
	print("Recieved Message! "..MSG)
	if Net.Hookers[MSG] then --Check if we have a hook for the message recieved.
		xpcall(function() --Always wear protection!
			Net.Hookers[MSG](Data,ply) --Run the function everythings all good here!
		end,ErrorNoHalt)
	else 
		print("Unhandled message... "..MSG) --IMREPORTINGYOU!!!!!
	end 
end

--Function that receives the netmessage.
net.Receive( "sing_basenetmessage", function( length, ply )
	local Name = net.ReadString() --Gets the name of the message.
	local Count = net.ReadFloat() --Get the amount of variables we're recieving.
	
	local D = {}--Create a empty data table.
	for I=1,Count do --Read all the variables.
		local VN = net.ReadString()--Name
		local Ty = net.ReadString()--Type
		if VN == nil or Ty == nil or Net.NetDTRead[Ty] == nil then print(tostring(VN).." "..tostring(Ty)) end
		D[VN]=Net.NetDTRead[Ty]()--Throw the recieved data into the data table.
	end
	Net:InNetF(Name,D,ply)	
end)

if(SERVER)then	
	--[[----------------------------------------------------
	Serverside Networking Handling.
	----------------------------------------------------]]--

	util.AddNetworkString( "sing_basenetmessage" ) --Tell the engine the string we will use for our messages.

	--[[
		Data={Name="example",Val=1,Dat={VName="example"}}
	]]	
	function Net.AddData(Data,ply)
		if not Data.Dat then error("Netcode Failure! Missing Dat table. ["..tostring(Data.Name).."]") return false end --Damn Missing Dat table....
		local T=Net.Data[ply:Nick()]--Get the clients data cache.
		if not T then Net.AddPlay(ply) Net.AddData(Data,ply) return false end--They dont have a cache? Well create one.
		
		table.insert(T.Data,Data) --Put the data in the clients data cache.
		
		return true
	end
	
	--Sends data to all connected players.
	function Net.AddDataAll(Data)
		local SuccessAll = true
		local players = player.GetAll()	
		for _, ply in ipairs( players ) do
			if ply and ply:IsConnected() then
				if Net.AddData(Data,ply) == false then
					SuccessAll = false
				end
			end
		end
		
		return SuccessAll
	end
	
	--Creates the table we will use for each player.
	function Net.AddPlay(ply)
		Net.Data[ply:Nick()]={Data={},Ent=ply}
	end
	hook.Add("PlayerInitialSpawn","SpehsNetworkingSetup",Net.AddPlay)
else
	--Client Side Net functions.
	
	
	surface.CreateFont("lcd2", {font = "digital-7",size = 36,weight = nil,additive = false,antialias = true})
	
	local TransferInProgress = false
	local TransferData = {0,0}
	
	local alpha = 150
	local a = Vector(ScrW(),ScrH()-400,0)
	local Spot = Vector(a.y+12.5,180,0)
	function Draw()
		if not TransferInProgress == true then return end					
		draw.NoTexture()
		draw.RoundedBox(16,20,a.y,268,64, Color(50,50,50,alpha))
		draw.NoTexture()
		
		surface.SetDrawColor(0,0,0,alpha)
		
		local Values = tostring(TransferData[1]).."/"..tostring(TransferData[2])
		draw.DrawText("Data: "..Values, "lcd2",Spot.y,Spot.x,Col, 2)			
	end
	--hook.Add("HUDPaint", "SpehsNPTest", Draw)
	
	--Send Data to the server.
	function Net.AddData(Data) 
		table.insert(Net.Data,Data) 
	end
end

--Setup the think to power the networking.
local NextThink = 0
hook.Add("Think","SpehsNetCode",function() --Todo probably: Slow the think down as to not spam netcode.
	xpcall(function()
		if CurTime()>NextThink then NextThink = CurTime()+NetCycleDelay
			if SERVER then--Are we running server or clientside?
				for nick, pdat in pairs( Net.Data ) do	--Loop all the players to send their data
					local Max = ServerMaxComplexity	--The maximum amount of data we can send per player.
					for id, Data in pairs( pdat.Data ) do
						if Max<=0 then break end--We reached the maximum amount of data for this player.
						Max=Max-Data.Val --Subtract the complexity of the data from our max.
						Net.SendData(Data,Data.Name,pdat.Ent) --
						table.remove(pdat.Data,id)
					end
				end			
			else
				local Max = ClientMaxComplexity --The maximum amount of data we will be sending at once.
				for id, Data in pairs( Net.Data ) do
					if Max<=0 then break end--We reached the maximum amount of data we can send this cycle.
					Max=Max-Data.Val
					Net.SendData(Data,Data.Name)
					table.remove(Net.Data,id)
				end			
			end
		end
	end,ErrorNoHalt)
end)




















