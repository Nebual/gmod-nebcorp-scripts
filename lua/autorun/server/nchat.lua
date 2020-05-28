-- Nebual Apr 2020 (nebual@nebtown.info)
-- NChat - Nebcorp Chat Bridge Module
-- Requires https://github.com/FredyH/GWSockets/releases (put the .dll in garrysmod/lua/bin/)

-- TODO move Slack specific code over to Gateway

NChat = NChat or {}

-- [CONFIG]
NChat.channel = "702359083293999124" --"#gmod" -- Default channel (lowercase)
NChat.botname = "Gman" -- Name of the bot which listens for messages
NChat.prefix  = "" -- Prefix for Gmod users nicknames in IRC
NChat.webPrefix = "[IRC]" -- Prefix for Web users to show in Gmod
-- [END CONFIG]

local nchat_debug = CreateConVar("nchat_debug", 0)

local function printd(...)
	if(nchat_debug:GetBool()) then print(unpack(arg)) end
end

if not NChat.loaded then
	--Reloading will not reload this section.
	NChat.loaded = true
	AddCSLuaFile("autorun/client/cl_nchat.lua")
	util.AddNetworkString("nchat_say")
	if not GMSockets then
		require("gwsockets")
	end
	timer.Simple(0.4, function()
		NChat.Say("Currently loaded on: "..game.GetMap())
	end)
	NChat.deadLetters = {}
end

concommand.Add("nchat_reload", function()
	timer.Destroy("nchat_websocket_reconnect")
	include("autorun/server/nchat.lua")
end)
concommand.Add("nchat_refresh", function()
	timer.Destroy("nchat_websocket_reconnect")
	NChat.Shutdown()
	timer.Create("NChat_Refresh", 2, 1, function() NChat = nil include("autorun/server/nchat.lua") end)
end)

local reconnectDelay = 0
function NChat.ReconnectWebsocket()
	if (NChat.websocket) then
		NChat.Shutdown(true)
	end

	local wsClient = GWSockets.createWebSocket("wss://gmanman.nebtown.info/gateway/messages")
	NChat.websocket = wsClient
	function wsClient:onConnected()
		wsClient:write(util.TableToJSON({ type = "ping" }))
		if (#NChat.deadLetters > 0) then
			print("NChat: sending " .. #NChat.deadLetters .. " dead letters")
			while (#NChat.deadLetters > 10) do
				table.remove(NChat.deadLetters, 1)
			end
			while (#NChat.deadLetters > 0) do
				wsClient:write(util.TableToJSON(table.remove(NChat.deadLetters, 1)))
			end
		end
	end
	function wsClient:onMessage(data)
		printd("NChat: received packet", data)
		local payload = util.JSONToTable(data) or {}
		if (payload.type == "message") then
			NChat.HearWeb(payload.name, payload.message, payload.channel)
		elseif payload.type == "ping" then
			wsClient:write(util.TableToJSON({ type = "pong" }))
		elseif payload.type == "pong" then
			print("NChat: received (ping) pong from Bridge, all is well")
		else
			print("NChat: unhandled packet", data)
		end
		if (reconnectDelay > 0) then reconnectDelay = reconnectDelay - 1 end
	end
	function wsClient:onDisconnected()
		if (wsClient ~= NChat.websocket) then
			return
		end
		print("NChat: Lost websocket connection, reopening")
		reconnectDelay = reconnectDelay + 1
		timer.Create("nchat_websocket_reconnect", reconnectDelay, 1, NChat.ReconnectWebsocket)
	end
	function wsClient:onError(txt)
		print("NChat Error: ", txt)
	end
	wsClient:open()
end
NChat.ReconnectWebsocket()

function NChat.Send(nick, msg, ply, channel)
	local payload = {
		type = "message",
		name = NChat.prefix .. nick,
		message = msg,
	}
	if (channel) then
		payload.channel = channel
	end
	if (ply and NChat.GetPlayerAvatarURL(ply)) then
		payload.avatar = NChat.GetPlayerAvatarURL(ply)
	end

	if (NChat.websocket == nil or not NChat.websocket:isConnected()) then
		print("NChat: queuing message: websocket closed")
		table.insert(NChat.deadLetters, payload)
		return
	end
	NChat.websocket:write(util.TableToJSON(payload))
end

function NChat.Shutdown(quiet)
	if (not quiet) then
		NChat.Say("See y'all, I'm out")
	end

	local wsClient = NChat.websocket
	NChat.websocket = nil
	if (wsClient:isConnected()) then
		wsClient:close()
	end
end
hook.Add("ShutDown", "NChat.Shutdown", NChat.Shutdown)

function NChat.GetPlayerAvatarURL(ply)
	if(ply.AvatarURL) then
		return ply.AvatarURL
	end

	-- Else we need to go get it asynchronously
	local steamID = ply:SteamID64()
	HTTP({
		method = 'get',
		url = 'http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/',
		parameters = { 
			key = '16D54C8DB27D36D10F81FE0B098C' .. '7C45', 
			steamids = steamID
		},
		success = function(code, body, headers)
			local tbl = util.JSONToTable(body)
			if(not istable(tbl) or not tbl.response or not IsValid(ply)) then return false end
			ply.AvatarURL = tbl.response.players[1].avatarfull
		end
	})
	return ''
end

hook.Add("PlayerConnect", "NChatAnnouncePlayerConnect", function(name)
	if string.Left(name, 3) == "Bot" or name == string.char(1) then return true end -- Don't let bots or the SETTI server checker join
	
	NChat.Send(name, "_Is connecting..._")
	NChat.GmodSay(name, "Is connecting...")
	--[[timer.Create("NChat.DisconnectFailedConnects_"..name, 600, 1, function()
		-- After 10 minutes, check if the player exists, disconnect him otherwise
		for _,v in pairs(player.GetAll()) do
			if string.find(string.lower(v:Nick()), string.lower(name)) then return end
		end
		NChat.Disconnect(name)
	end)--]]
end)

function NChat.Disconnect(nick)
	if(string.Left(nick, 3) ~= 'Bot') then
		NChat.Send(nick, "_left the game_.")
	end
end

-- It uses EntityRemoved because PlayerDisconnected doesn't catch all disconnects.
hook.Add("EntityRemoved","NChat.Disconnect",function(ent)
	if ent:IsValid() and ent:IsPlayer() then
		NChat.Disconnect(ent:Nick())
	end
end)

hook.Add("PlayerInitialSpawn","NChat.AnnounceInitialSpawn",function(ply)
	if string.Left(ply:Nick(), 3) == "Bot" then return end
	
	--NChat.Send(ply:Nick(), "-- Has finished connecting.", ply)
	NChat.GmodSay(NChat.botname, ply:Nick().." has finished loading.")
end)

function NChat.HearWeb(nick, msg, channel)
	if string.Left(nick, 4) == NChat.prefix or string.Left(nick,4) == "[MC]" or string.Left(nick, 3) == "[--" or nick == 'slackbot' then return end -- Skip it if its just a Gmodder
	if string.Left(nick, 1) ~= "[" then nick = NChat.webPrefix..nick end
	if channel == nil or string.lower(channel) == NChat.channel then
		local displayMsg = string.gsub(msg, "(Fuck|fuck|FUCK)", "Fish")
		NChat.GmodSay(nick, displayMsg)
		E2IRCLastSpoke = nick -- NTE
		E2IRCLastSaid = msg -- NTE
		print(nick..": "..displayMsg)
		NChat.LogChat(nick, msg.."\n")
	else
		print("[NChat] Unknown: " .. msg)
	end
	if (NChat.GmanProcess) then
		NChat.GmanProcess(nick, msg, channel) -- NTE
	end
end

function NChat.HearGmod(ply, msg)
	if msg:sub(1,1) == "!" then return end
	NChat.Say(ply:Nick(),msg, ply)
	if (NChat.GmanProcess) then
		NChat.GmanProcess(ply:Nick(), msg) -- NTE
	end
end
hook.Add( "PlayerSay", "NChat_HearGmod", NChat.HearGmod)

-- Chat Logs
-- We write to a temporary cache variable to reduce disk writes
if (not NChat.chatLogCache) then
	NChat.chatLogCache = "[SRCDS server started on "..os.date("%A %B %d, %Y")..".]\n"
end
function NChat.LogChat(nick, msg)
	nick = string.sub(nick, 1, 15)
	NChat.chatLogCache = NChat.chatLogCache .. os.date("[%H:%M]")..string.rep(" ", 15 - string.len(nick))..nick..": "..msg
end
local filename = os.date("nebcorp/chats/%Y-%B/%d-%A.txt")
file.CreateDir(  os.date("nebcorp/chats/%Y-%B"))
local filecache = file.Read(filename,"DATA") or ""
timer.Create("Nebcorp_ChatLogWrite", 30, 0, function()
	if NChat.chatLogCache ~= "" then
		filecache = filecache .. NChat.chatLogCache
		file.Write(filename, filecache)
		NChat.chatLogCache = ""
	end
end)

function NChat.Say(nick, msg, ply, channel)
	if not msg then
		msg = nick 
		nick = NChat.botname
		NChat.GmodSay(nick, msg)
		print(NChat.botname..": "..msg)
	end
	NChat.Send(nick, string.gsub(msg, "fuck", "Fish"), ply, channel)
	NChat.LogChat(nick, msg.."\n")
end
concommand.Add("y", function(ply,cmd,args,said)
	NChat.Say(said)
end)

function NChat.GmodSay(nick, msg)
	net.Start("nchat_say")
		net.WriteString(nick)
		net.WriteString(msg)
	net.Broadcast()
end
function NChat.WebSay(nick, msg, ply)
	if not msg then
		msg = nick 
		nick = NChat.botname
	end
	NChat.Send(nick, msg, ply)
end


if (file.Exists("nchat_nebtown.lua", "LUA")) then
	include("nchat_nebtown.lua") -- NTE
end

print("[NChat - Nebcorp's Chat Bridge Loaded]")
