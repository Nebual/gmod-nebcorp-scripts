-- Nebual Jan 2016 (nebual@nebtown.info)
-- NSlack - Nebcorp Slack Integration Module
-- Requires https://github.com/Bromvlieg/gm_bromsock (put the .dll in garrysmod/lua/bin/)
NSlack = NSlack or {}

-- [CONFIG]
NSlack.port = 27079
NSlack.channel = "#gmod" -- Default channel (lowercase)
NSlack.slackIncomingWebhook = "https://hooks.slack.com/services/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"
NSlack.timeout = 25 -- If clients keep getting dropped by the IRC server try lowering this
NSlack.botname = "Gman" -- Name of the bot which listens for messages
NSlack.prefix  = "[GM]" -- Prefix for Gmod users nicknames in IRC
-- [END CONFIG]

local nslack_debug = CreateConVar("nslack_debug", 0)

local function printd(...)
	if(nslack_debug:GetBool()) then print(unpack(arg)) end
end

if not NSlack.loaded then
	-- Reloading the script will not reload this section
	NSlack.loaded = true
	concommand.Add("nslack_reload", function() include("autorun/server/nslack.lua") end)
	concommand.Add("nslack_refresh", function()
		NSlack.Shutdown()
		timer.Create("NSlack_Refresh", 2, 1, function() NSlack = nil include("autorun/server/nslack.lua") end)
	end)
	AddCSLuaFile("autorun/client/cl_nirc.lua")

	if not BromSock then require("bromsock") end

	timer.Simple(0.4, function()
		NSlack.Say("HEY BILLY MAYS HERE")
	end)
	util.AddNetworkString("nirc_say")
end



if(NSlack.sock) then
	NSlack.sock:Close()
end

local function url_decode(str)
  if not str then return nil end
  str = string.gsub (str, "+", " ")
  str = string.gsub (str, "%%(%x%x)", function(h) return string.char(tonumber(h,16)) end)
  str = string.gsub(str, "&lt;", "<")
  str = string.gsub(str, "&gt;", ">")
  str = string.gsub(str, "&quot;", '"')
  str = string.gsub(str, "&amp;", "&")
  str = string.gsub (str, "\r\n", "\n")
  return str
end

function NSlack.Init(port)
	servsock = BromSock()
	
	if (not servsock:Listen(port)) then
		print("[NSlack] Failed to listen!")
	else
		print("[NSlack] Server listening on port "..port.."...")
	end
	
	servsock:SetCallbackAccept(function(serversock, clientsock)
		printd("[NSlack] Accepted:", serversock, clientsock)
		
		local headers = nil
		
		clientsock:SetCallbackReceive(function(sock, packet)
			printd("[NSlack] Received:", sock, packet)
			
			local data = packet:ReadStringAll()
			
			printd("[NSlack] Raw: " .. data)
			if(not headers) then
				headers = {}
				local rawheaders = string.Explode("\r\n", data)
				for _, header in pairs(rawheaders) do
					local splited = string.Explode(":", header)
					headers[splited[1]] = #splited > 1 and splited[2] or ""
				end
				sock:Receive(tonumber(headers["Content-Length"]));
			else
				local parts = string.Explode("&", data)
				local fields = {}
				for _, part in pairs(parts) do
					local halves = string.Explode("=", part)
					fields[halves[1]] = halves[2]
				end
				NSlack.HearSlack(fields['user_name'], url_decode(fields['text']), '#'..fields['channel_name'])
				
				
				local responsePacket = BromPacket()
				responsePacket:WriteLine("HTTP/1.1 200 OK")
				sock:SetCallbackSend(function(sock, a, b, c)
					printd("[NSlack] Send packet 2:", sock, a, b, c)
					sock:Close()
				end)
				sock:Send(responsePacket, true)
			end
		end)
		
		clientsock:SetCallbackDisconnect(function(sock)
			printd("[NSlack] Disconnected:", sock)
		end)
		
		clientsock:SetCallbackSend(function(sock, a, b, c)
			printd("[NSlack] Send packet:", sock, a, b, c)
		end)
		
		clientsock:SetTimeout(1000)
		clientsock:ReceiveUntil("\r\n\r\n")
		
		serversock:Accept()
	end)
	
	servsock:Accept()
	return servsock
end
NSlack.sock = NSlack.Init(NSlack.port)


function NSlack.Send(nick, msg, ply)
	local postData = {
		text = msg, 
		username = NSlack.prefix .. nick
	}
	if(ply and NSlack.GetPlayerAvatarURL(ply)) then
		postData['icon_url'] = NSlack.GetPlayerAvatarURL(ply)
	end
	http.Post("https://hooks.slack.com/services/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", {
			payload = util.TableToJSON(postData)
		}, function(responseText, contentLength, headers, statusCode)
		end
	)
end


function NSlack.GetPlayerAvatarURL(ply)
	if(ply.AvatarURL) then
		return ply.AvatarURL
	end

	-- Else we need to go get it asyncroneously
	local steamID = ply:SteamID64()
	HTTP({
		method = 'get',
		url = 'http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/',
		parameters = { 
			key = '16D54C8DB27D36D10F81FE0B098C7C45', 
			steamids = steamID
		},
		success = function(code, body, headers)
			local tbl = util.JSONToTable(body)
			if(!istable(tbl) or !tbl.response or !IsValid(ply)) then return false end
			ply.AvatarURL = tbl.response.players[1].avatarfull
		end
	})
	return ''
end







function NSlack.Shutdown()
	NSlack.Say("See y'all, I'm out")
	NSlack.sock.Disconnect()
end
hook.Add("ShutDown", "NSlack.Shutdown", NSlack.Shutdown)

hook.Add("PlayerConnect", "NSlackAnnouncePlayerConnect", function(name)
	if string.Left(name, 3) == "Bot" || name == string.char(1) then return true end // Don't let bots or the SETTI server checker join
	
	NSlack.Send(name, "_Is connecting..._")
	net.Start("nirc_say") // Tell Gmod
		net.WriteString(name)
		net.WriteString("Is connecting...")
	net.Broadcast()
	--[[timer.Create("NSlack.DisconnectFailedConnects_"..name, 600, 1, function()
		-- After 10 minutes, check if the player exists, disconnect him otherwise
		for _,v in pairs(player.GetAll()) do
			if string.find(string.lower(v:Nick()), string.lower(name)) then return end
		end
		NSlack.Disconnect(name)
	end)--]]
end)

function NSlack.Disconnect(nick)
	if(string.Left(nick, 3) != 'Bot') then
		NSlack.Send(nick, "_left the game_.")
	end
end

-- It uses EntityRemoved because PlayerDisconnected doesn't catch all disconnects.
hook.Add("EntityRemoved","NSlack.Disconnect",function(ent)
	if ent:IsValid() and ent.Nick then
		NSlack.Disconnect(ent:Nick())
	end
end)

hook.Add("PlayerInitialSpawn","NSlack.AnnounceInitialSpawn",function(ply)
	if string.Left(ply:Nick(), 3) == "Bot" then return end
	
	--NSlack.Send(ply:Nick(), "-- Has finished connecting.", ply)
	net.Start("nirc_say")
		net.WriteString(NSlack.botname)
		net.WriteString(ply:Nick().." has finished loading.")
	net.Broadcast()
end)

timer.Create("NSlack_Pong", 180, 0, function()
	--for nick, v in pairs(NSlack.socks) do NSlack.Send(nick, "PONG 5") end
end)

function NSlack.HearSlack(nick, msg, channel)
	if string.Left(nick, 4) == NSlack.prefix or string.Left(nick,4) == "[MC]" or string.Left(nick, 3) == "[--" or nick == 'slackbot' then return end -- Skip it if its just a Gmodder
	if string.Left(nick, 1) != "[" then nick = "[IRC]"..nick end
	--if cmd == "PRIVMSG" then
		if string.lower(channel) == NSlack.channel then
			net.Start("nirc_say")
				net.WriteString(nick)
				net.WriteString(string.gsub(msg, "(Fuck|fuck|FUCK)", "Fish"))
			net.Broadcast()
			E2IRCLastSpoke = nick -- NTE
			E2IRCLastSaid = msg -- NTE
			print(nick..": "..string.gsub(msg, "(Fuck|fuck|FUCK)", "Fish"))
			NSlack.LogChat(nick, msg.."\n")
		else
			print("[NSlack] Unknown: " .. msg)
		end
		NIRC.GmanProcess(nick, msg, channel) -- NTE
end

hook.Add( "PlayerSay", "NSlack_HearGmod", function(ply, msg)
	if msg:sub(1,1) == "!" then return end
	NSlack.Say(ply:Nick(),msg, ply)
	NIRC.GmanProcess(ply:Nick(), msg) -- NTE
end)

-- Chat Logs
-- We write to a temporary cache variable to reduce disk writes
local chatcache = "[SRCDS server started on "..os.date("%A %B %d, %Y")..".]\n"
function NSlack.LogChat(nick, msg)
	nick = string.sub(nick, 1, 15)
	chatcache = chatcache .. os.date("[%H:%M]")..string.rep(" ", 15 - string.len(nick))..nick..": "..msg
end
local filename = os.date("nebcorp/chats/%Y-%B/%d-%A.txt")
file.CreateDir(  os.date("nebcorp/chats/%Y-%B"))
local filecache = file.Read(filename,"DATA") or ""
timer.Create("Nebcorp_ChatLogWrite", 30, 0, function()
	if chatcache != "" then 
		filecache = filecache .. chatcache
		file.Write(filename, filecache)
		chatcache = ""
	end
end)

function NSlack.Say(nick, msg, ply)
	if !msg then 
		msg = nick 
		nick = NSlack.botname
		net.Start("nirc_say") // Tell Gmod
			net.WriteString(NSlack.botname)
			net.WriteString(msg)
		net.Broadcast()
		print(NSlack.botname..": "..msg)
	end
	NSlack.Send(nick, string.gsub(msg, "fuck", "Fish"), ply)
	NSlack.LogChat(nick, msg.."\n")
end

function NSlack.WebSay(nick, msg, ply)
	if !msg then 
		msg = nick 
		nick = NSlack.botname
	end
	NSlack.Send(nick, msg, ply)
end

concommand.Add("y", function(ply,cmd,args,said)
	NSlack.Say(said)
end)


NIRC = NSlack
include("autorun/server/nirc_nebtown.lua") -- NTE

print("[NSlack - Nebcorp's Slack Integration Loaded]")
