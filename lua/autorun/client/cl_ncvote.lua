-- By nebual@nebtown.info 2012
local VotePanel, VoteList
function OpenVoteDerma(title, headings, options)
	if VotePanel then VotePanel:Remove() VoteList = nil end
	VotePanel = vgui.Create( "DFrame" )
	VotePanel:SetTitle( title )
	VotePanel:SetVisible( true )
	VotePanel:SetDraggable( true )
	VotePanel:ShowCloseButton( true )
	
	VoteList = vgui.Create("DListView", VotePanel)
	VoteList:SetPos(10, 35)
	VoteList:SetMultiSelect(false)
	for k,v in ipairs(headings) do
		VoteList:AddColumn(v)
	end
	
	function VoteList:OnRowSelected(LineID, Line )
		RunConsoleCommand("nc_vote", Line:GetValue(1))
	end
	
	for k,v in pairs(options) do
		VoteList:AddLine(unpack(v))
	end
	VoteList:SortByColumn(#headings-1, true)
	
	
	local height = math.Min(500, #options * VoteList:GetDataHeight())
	VotePanel:SetSize( 300, 42 + VoteList:GetHeaderHeight() + height )
	VotePanel:MakePopup()
	VotePanel:Center()
	VoteList:SetSize(280, VoteList:GetHeaderHeight() + height)
end
net.Receive("NC_StartVote",function(len)
	OpenVoteDerma(net.ReadString(), net.ReadTable(), net.ReadTable())
end)
net.Receive("NC_HearVote",function(len)
	if not IsValid(VoteList) or not IsValid(VotePanel) then return end
	local option, numvotes = net.ReadString(), net.ReadUInt(8)
	local voteid = #VoteList.Columns -- Number of votes is stored as the last column
	for k,v in pairs(VoteList:GetLines()) do
		if v:GetColumnText(1) == option then
			v:SetColumnText(voteid, numvotes)
			return
		end
	end
end)
net.Receive("NC_EndVote",function(len) 
	if VotePanel then VotePanel:Remove() end
	VoteList = nil
	VotePanel = nil
end)