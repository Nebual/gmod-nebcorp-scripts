net.Receive("nirc_say",function(len) chat.AddText(Color(180,240,240), net.ReadString(), Color(255,255,255), ": "..net.ReadString()) end)
net.Receive("nirc_usrmsg",function(len) chat.AddText(Color(180,240,240), net.ReadString(), Color(255,255,255), " "..net.ReadString()) end)
net.Receive("nirc_sysmsg",function(len) chat.AddText(Color(150,150,150), net.ReadString()) end)