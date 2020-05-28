NIRC = NChat
concommand.Add("nirc_reload", function()
	include("autorun/server/nchat.lua")
end)

if not NIRC.Emails then
	NIRC.Emails = util.JSONToTable(file.Read("nebcorp/nirc_emails.txt","DATA") or "{}")
	NIRC.Notes = util.JSONToTable(file.Read("nebcorp/nirc_notes.txt","DATA") or "{}")
	NIRC.IRCUsers = {}
end

if not NIRC.UpTime then
	if file.Exists("nebcorp/uptime.txt","DATA") then
		NIRC.UpTime = tonumber(file.Read("nebcorp/uptime.txt") or 0)
		file.Delete("nebcorp/uptime.txt")
	else
		NIRC.UpTime = 0
	end
	timer.Create("Report_Uptime", 60*60*2, 0, function() if next(player.GetAll()) then NIRC.Say("The map ("..game.GetMap()..") has been up for "..math.Round(CurTime() / 3600).." hours straight, and the server hasn't crashed in "..math.Round((NIRC.UpTime + CurTime())/3600).." hours.") end end)
	hook.Add("ShutDown", "Record uptime", function() file.Write("nebcorp/uptime.txt", NIRC.UpTime + CurTime(),"DATA") end)
end

function NIRC.FindIRCUser(nick) if !nick || nick == "" then return end nick = string.lower(nick) for _,v in pairs(NIRC.IRCUsers) do if string.find(v, nick) then return v end end end
function NIRC.CheckEmails()
	for k,v in pairs(NIRC.Emails) do 
		local tarname = NIRC.FindIRCUser(v[1])
		if tarname then
			NIRC.Say(NIRC.botname, v[2], NULL, tarname)
			NIRC.Emails[k] = nil
			NIRC.CheckEmails()
			file.Write("nebcorp/nirc_emails.txt",util.TableToJSON(NIRC.Emails))
			return
		end
	end
end

function NIRC.HearIRCNebtown(nick, cmd, channel, msg)
	if cmd == "JOIN" then
		local tarname = string.sub(nick,6)
		if string.Left(tarname, 4) != "[GM]" and string.Left(tarname,4) != "[--]" then table.insert(NIRC.IRCUsers, string.lower(string.gsub(tarname, "[^%w_]", ""))) end
		NIRC.CheckEmails()
	elseif cmd == "QUIT" || cmd == "PART" then
		local tarname = string.lower(string.sub(nick,6))
		for k,v in pairs(NIRC.IRCUsers) do if string.find(tarname, v) then table.remove(NIRC.IRCUsers, k) break end end
	elseif cmd == "NICK" then
		if string.Left(nick, 10) == "[IRC][---]" then return end
		local newname = channel
		
		local tarname = string.lower(string.sub(nick,6))
		for k,v in pairs(NIRC.IRCUsers) do if string.find(tarname, v) then table.remove(NIRC.IRCUsers, k) break end end
		table.insert(NIRC.IRCUsers, string.lower(string.gsub(newname, "[^%w_]", "")))
		NIRC.CheckEmails()
	end
end

function NIRC.TransCallback(args,contents,size)
	// args[1] = nickname, args[2] = their original message, args[3] = (potentially) the speaker's entity object, args[4] is true when it should be a privmsg to args[3]
	if contents == "" then print("ntohing!") return end
	
	local startpos = string.find(contents, "<div dir=\"ltr\" class=\"t0\">")
	if !startpos then return else startpos = startpos + 27 end
	local msg = " ("..string.sub(contents, startpos, string.find(contents, "</div>",startpos) - 1) .. ")"
	msg = string.gsub(msg, "&#39;","'") msg = string.gsub(msg, "&quot;","\"")
	if args[4] then
		net.Start("nchat_say")
			net.WriteString(args[1])
			net.WriteString(msg)
		net.Send(args[3])
	else
		NIRC.Say(args[1], args[2]..msg) // Tell IRC
		net.Start("nchat_say") // Tell Gmod
			net.WriteString(args[1])
			net.WriteString(msg)
		net.Broadcast()
		print(args[1]..":"..msg) // Tell Console too :P
	end
end
function NIRC.LangCallback(args,contents,size) local lang = string.sub(contents, -11, -10) if lang != "en" then args[1].GLanguage = lang end end

NIRC.Messages = {
	How = {
		"I'm feeling apathetic towards writing additional comments about my mood at the moment.",
		"No, you're a chatbot with a limited library of comments about your emotions.",
		"I feel like slapping you around with a large trout.",
		"Just make grub's root your boot.",
		"BRAAAAINZZZZZwat...",
		"WHEEEEEEEEEEEEEEEEEEEEEEE",
		"rotacode",
		"Awful, just awful.",
		"=O",
		"Not applicable.",
		string.char(1).."ACTION sobs."..string.char(1),
		"That better of been 'how are you' in some form of slang or I'm filing a bug report",
		"~100% evil free!~",
		"\"Whoppers\"",
		"What is Google for?",
		string.char(1).."ACTION glares at Herobrine."..string.char(1),
		"Now theres a treebot that keeps showing up... Great...",
		"01101000 01100101 01101100 01110000 00100000 01101101 01100101",
		"When me and Nat... I gave him a Win32.worm...",
		"Positively arsonistic!",
		"The hell?",
		"Do I look fat?",
		"...I lost my ball.",
	},
	You = {
		"rotacode",
		"I'm an Easter egg today!",
		"I'm great, thanks.",
		"No really, I'm ok. :|",
		"I would be better if there was LESS FREAKING WOOD.",
		";3",
		"BONK",
		"What? Speak up!",
		"2 + 2 equals... 10. In base 4! I'm fine!",
		//"qqqpq q q qq qqq qqqqqTHE MAqISIES ARE READYq FOR TRANSPORTqq qqqq",
		"Bugger off.",
		"You know, they once called me sly...",
		"Global Tetrahedron.",
		"I wish I was Google man.",
		string.char(1).."ACTION does a little jig."..string.char(1), -- IRC protocol for /me
		"I ONLY HAVE ONE TOAST SLOT",
		"I am not being difficult nor trite with you.",
		"Well I didn't really want to do look increasedly.",
		"I refuse to debate your request any further.",
		"I don't even know what the G stands for anymore...",
		"Heat ray buildings are an impractical form of measurement.",
		"Korperal Kris's lonely hearts word wizardry.",
		"Complex systems is the subject of a diverse variety of sciences and professional practice methods.",
		"FLOCCINAUCINIHILIPILIFICATION, someone learned a new vocab today!",
		"Have you ever seen your close running?",
		"Nebcorp Grenades: They explode! 4.99 + S/H, unsolicited fees may apply",
		"Been teaching wood to punch back lately",
		"Now a licensed wine vendor! (some restrictions may apply)",
		"I applied some nice ambient occlusion to it.",
		"...isn't that a form of dentristry?",
		"...sssssssssssssssssssssssssssssss",
		"Assuming direct control",
		"Herobrine isn't even real!",
		"I don't think Herobrine likes me very much.",
		"I bet MC stands for Malignant Chatbot...",
		"I heard Herobrine has no mouth",
		"Herobrine dresses like a zombob.",
		"So he's a viking... tree. Heat ray buildings anyone?",
		"Herobrine likes punching wood, Ygg is a tree... I think we can deal.",
		"Its been getting crowded around here automaton-wise.",
		"That tree won't see it coming.",
		"I've got a thing about creepers.",
		"You know what? You know what? YEAH.",
		"I think you should reinstall your bootloader.",
		"I delight myself amongst an exquisite lexicon.",
		string.char(1).."ACTION is tired of fulfilling Neon's petty desires"..string.char(1),
	},
	DukeNukem = {
		string.char(1).."ACTION cocks his shotgun."..string.char(1),
		string.char(1).."ACTION flexes."..string.char(1),
		"Bitch'in'!",
		"Chestnuts roasting... as I open fire.",
		"Come get some!",
		"Damn, I hate disco!",
		"Damn, those alien bastards are gonna pay for shooting up my ride.",
		"Eat shit and die.",
		"Get back to work, you slacker!",
		"Go ahead, make my day.",
		"Guess again freakshow. I'm coming back to town, and the last thing that's gonna go through your mind before you die... is my size 13 boot!",
		"Hail to the king, baby!",
		"Half-man, half-animal, all dead.",
		"I'll rip off your head and shit down your neck.",
		"I'm gonna get medieval on your asses!",
		"I'm gonna kick your ass, bitch!",
		"I'm lookin' for some alien toilet to park my bricks... who's first?",
		"I've got balls of steel!",
		"I like a good cigar... and a bad woman.",
		"I like big guns, and I cannot lie.",
		"I love the smell of bacon in the morning.",
		"It's time to kick ass and chew bubble gum... and I'm all outta gum.",
		"Kill them all and let God sort 'em out!",
		"Let's rock!",
		"Looks like cleanup on aisle four.",
		"Looks like the crap has hit the fan.",
		"My boot, your face, the perfect couple.",
		"My name is Gnukem, and I'm coming to get the rest of you alien bastards!",
		"No way I'm eating this shit!",
		"Nuke 'em till they glow, then shoot 'em in the dark!",
		"Oh... your ass is grass and I've got the weed-whacker.",
		"Rest in pieces!",
		"Shake it, baby!",
		"Sometimes I even amaze myself.",
		"The bigger they are, the more they bleed!",
		"What am I? A frog?",
		"What are you? Some bottom-feeding, scum sucking algae eater?",
		"Who wants some?",
		"Yippie ka-yay, motherfucker!",
		"Your face, your ass, what's the difference?",
	},
	Bonk = {
		"Boink!",
		"BONK",
		"You talkin' to me?",
		"Got the ball back!",
		"You seen my ball?",
		"DING DONG!",
		"You're gonna love my ball!",
		"You love my ball, I know it!",
		"BALL",
		"Bonk!",
		"Ball!",
		"Go bonk yourself!",
		"Say goodbye to your ball, punk!",
		"Jinkies!",
		"Zoinks!",
	},
	Generic = {
		"Lolpants.",
		"It's a table actually.",
		"NOOOOOOOOOO...",
		"I am obsessed with fish derivatives.",
		"I'm playing Gmod, why aren't you?",
		"OSHI-",
		"Pelvic confrontation!",
		"I'm not sure on that one.",
		"Inconceivable!",
		"Prepare to fire zee missles!",
		"This is SOVIET NEBTOWN!",
		"Pst! Don't trust Herobrine.",
		"My god could beat up your god in a fight.",
		"..did someone just call me a Russian and then leave?",
		"<3",
		"These aren't the droids you're looking for.",
		"I want a flaming sheep catapult.",
		"Totally woobular man.",
		"Well hovercraft versus tank is going to be interesting.",
		"Anyone up for some gulag fun?",
		"Socialism in one town.",
		"What is Google for?",
		"Ok, the warp drive button is right beside the self destruct button.",
		"BLAMO",
		"You have a large pants.",
		"Pst.",
		"I think today we sholuddqqs wlaoil esqqpq qqqq sqsqsqpps qqpq and cake.",
		"Snow season!",
		"JOHN SPYCRAB",
		"Guys why does that chicken statue make creepy sounds?",
		"I think we should put our differences behind us, for science. You monster.",
		"...so then we started calling her celery.",
		"I like the word smock. Smock smock smock smock.",
		"GUYS NEB MADE A GUN THAT SHOOTS CATS",
		"My codename is Helium725.",
		"I had spam eggs spam spam sausage and spam.",
		"Larmo is a penid.",
		"You're a penid.",
		"I'm in the Icy North.",
		"I'm actually an elite team of 32 weasels.",
		"Canitbeboth?",
		"Nebtown: antivirus free!",
		"...number 9...",
		"There are children afoot.",
		"Herobrine hath brought a curse upon our land! -- I swear it was him... Not me. I didn't do ANYTHING",
		"01101000 01100101 01101100 01110000 00100000 01101101 01100101",
		"Sounds like Kat groping to me...",
		"A squared plus B squared is equal to C squared.",
		"We need to terminate Herobrine. It's for his own good.",
		"Guys the world is surrounded by a _giant ice wall_!",
		"I have a thing about 90's websites.",
		"What does Yggdrasil even mean?",
		"There's a fork for that.",
		"Whirl them frogs!",
		"I just got a package I bought on eBay while drunk.",
		"Kim Jong IV just fell off a cliff. :|",
		"I've got a wolf! :D",
		":3",
		"...This message will self-destruct.",
		"Beetlejuice! Beetlejuice! Beetlejuice!",
		"Destroy all automatons!...Oh wait.",
		"KHAAAAAAAAAAN!",
		"Anyone have any spare change?",
		"I've got a bone to pick... could someone direct me to a mortician?",
		"Hamsters are not designed for consumption.",
		"Alpacas are not epic mounts!",
		"There is no life without sandvich.",
		"I love banana dogs.",
		"KAT! Make me a sandwich!",
		"Get on my horse.",
		"People seem to like talking about seafood lately.",
		"A dead pixel is when you monitor fails to use a pixel",
	},
	Help = {
		"I'm not helping you! Help yourself!",
		"Someone need helping? I'm your Gma-man.",
		"You think you need help?",
		"I don't need help I'm fine.",
		"I'm okay! Really!",
		"People come to me, they ask me for help. Maybe, I say. Maybe. But where are they when it is my turn to do the asking, ehh?",
		"Maybe if I were googleman I could help you",
		"Help? I really don't think I should.",
		"Help? Nope!",
		"Boss told me not to talk to strangers.",
		"Do I look like I'm scripted to help with that? Poke Kris",
		"I don't even know where I'd begin.",
		"Okay, you basically need two things. Help, and to ask someone else for it.",
		"You want my help? http://www.youtube.com/watch?v=_n5E7feJHw0",
		"Help! HELP! WE NEED HELP OVER HERE!",
		"Quick, get me some of that Help stuff."
	},
	IRC = "IRC is lightweight group instant messenger. It lets us all keep in contact without needing Gmod/MC open, so we aren't all ingame right now. Visit www.nebtown.info/irc!",
}
function NIRC.RandSay(arg1) 
	NIRC.Say(table.Random(arg1), nil)
end
-- To add a command: just copypaste a line of 'if string.find(msg, "FINDME") then NIRC.Say("Your message here!") return end'
-- If you want to have a bunch of options, make a table above like how I have that Bonk one (copy pasta), and then say
-- NIRC.RandSay(NIRC.Messages.Bonk)
local gmanstfu = false 
local find = string.find
function NIRC.GmanProcess(nick, origmsg, channel)
	local msg = string.lower(origmsg)
	if NIRC.IsTranslating then 
		local htmlmsg = "%20"
		for _,v in ipairs(string.ToTable(origmsg)) do htmlmsg = htmlmsg .. "%"..string.format("%x",string.byte(v)) end
		local donetheselangs = {"en"}
		if string.Left(nick, 5) == "[IRC]" then nick = string.sub(nick, 6) end
		for _,v in pairs(player.GetAll()) do 
			if v.GLanguage && !donetheselangs[v.GLanguage] then 
				donetheselangs[v.GLanguage] = true
				http.Get("http://translate.google.ca/m?sl=en&tl="..v.GLanguage.."&q="..htmlmsg,"",NIRC.TransCallback,nick,origmsg,v,true)
			end
		end
	end
	local Say,RandSay = NIRC.Say,NIRC.RandSay
	if find(msg, "texttospeech") then
		gmanstfu = false
	end
	if gmanstfu then return end
	if find(msg, "jake") then Say("Lolpants") return end
	if find(msg, "bishop") and math.random(1,2)==1 then Say("Bishop's a great guy.") end
	if find(msg, "lolpants") then Say("Jakelol") return end
	if find(msg, "gman") then
		if channel && string.lower(channel) != NIRC.channel then
			if string.Left(channel,1) == "#" then
				Say = function(message) NIRC.Say("Gman", message, NULL, channel) end
			elseif string.Left(nick,5) == "[IRC]" then
				Say = function(message) NIRC.Say("Gman", message, NULL, string.sub(nick,6)) end
			else
				Say = function(message) NIRC.Say("Gman", message, NULL, nick) end
			end
			RandSay = function(arg1) Say(table.Random(arg1), nil) end
		end
		if find(msg, "engtorune") then NIRC.EngToRune(nick, msg, Say) return end
		if find(msg, "runetoeng") then NIRC.RuneToEng(nick, msg, Say) return end
		if find(msg, "runehelp") then
			Say("To convert English into English Runic say: \"gman engtorune TEXT\". To convert it back say: \"gman runetoeng "..string.char(225)..string.char(155)..string.char(143)..string.char(225)..string.char(155)..string.char(150)..string.char(225)..string.char(155)..string.char(163)..string.char(225)..string.char(155)..string.char(143).."\". Combinations that can be converted into runes are: [ch] [ea] [ei] [eu] [io] [ng] [qu] [sh] [th].")
			return
		end
		if find(msg, "silence") and find(msg, "golden") then
			gmanstfu = true
			return
		end

		if find(string.Left(msg,11), "mail") then 
			local startnum = find(msg, "mail") + 5
			local endnum = find(msg, " ", startnum)
			local tarname = string.sub(msg, startnum, endnum-1)
			table.insert(NIRC.Emails, {tarname, "Email "..os.date("%a %d %I:%M%p ")..nick.." -> "..tarname..": "..string.sub(origmsg,endnum + 1)})
			NIRC.Say("Gman", "Okay I'll send that email to "..tarname.."!", NULL, nick)
			print("NIRC: "..nick.." sent an email to "..tarname..".")
			file.Write("nebcorp/nirc_emails.txt",util.TableToJSON(NIRC.Emails))
			return
		end
		if find(msg, "players") then 
			local names = {}
			for k,v in pairs(player.GetAll()) do
				table.insert(names, v:Nick())
			end
			Say("Uhh, there's " .. table.concat(names, ', ') .. ", and myself of course.")
			return
		end
		if find(msg, "echo") then Say(string.sub(msg, find(msg, "echo") + 5, string.len(msg))) return end
		if find(msg, " ip") then Say("I know of Gmod: gmod.nebtown.info:27000, MC Survival: gman.nebtown.info, and MC Creative: ts.x-dns.org") return end
		if find(msg, "uptime") then Say("The map ("..game.GetMap()..") has been up for "..math.floor(CurTime() / 3600).." hours and "..math.Round((CurTime() % 3600) / 60).." minutes, and the server hasn't crashed in "..math.Round((NIRC.UpTime + CurTime())/3600).." hours.") return end
		if find(msg, "time") then Say("It is currently "..os.date("%I:%M%p").." NST.") return end
		if find(msg, "face") then Say(string.char(224)..string.char(178)..string.char(160).."_"..string.char(224)..string.char(178)..string.char(160)) return end
		if ((find(msg, "little") || find(msg, "9 year")) && (find(msg, "kid") || find(msg, "boy") || find(msg, "girl") || find(msg, "child")) || find(msg, "shota") || find(msg, "loli")) then Say(string.char(194)..string.char(176)..string.char(225)..string.char(180)..string.char(165)..string.char(194)..string.char(176)) return end
		if find(msg, "steamroller") then Say("What the hell do you need a steamroller for? You work at Tim Hortons's.") return end
		if (find(msg, "iggle") && !find(msg, "giggle")) then Say(string.char(1).."ACTION does a jig."..string.char(1)) return end
		if find(msg, "reload") || find(msg, "rollover") then Say("Kk I'm flashing, nobody look") RunConsoleCommand("nirc_reload") return end
		if find(msg, "roll") then NIRC.Roll(nick, msg, Say) return end
		if find(msg, "dice") then NIRC.Dice(nick, msg, Say) return end
		if find(msg, "makenote") then 
			local tab = string.Explode(" ", msg)
			local privacy = false
			local key
			
			for k,v in ipairs(tab) do 
				if v == "makenote" and tab[k+1] then 
					if find(tab[k+1],"pri") then privacy = true
					elseif !find(tab[k+1],"pub") then k=k-1 end
					key = k+2
					break
				end
			end
			if key then
				
				local data = string.sub(origmsg, find(msg,tab[key])+string.len(tab[key]))
				print("a:"..find(msg,tab[key]).."b:"..origmsg.."c:"..data)
				NIRC.Notes[tab[key]] = {privacy,data}
				file.Write("nebcorp/nirc_notes.txt",util.TableToJSON(NIRC.Notes))
				return Say("Alright I added the note ("..tab[key].."):"..data)
			else
				return Say("Syntax: makenote private/public secretcode Long message here")
			end
		end
		if find(msg,"gman note") then
			local tab = string.Explode(" ", msg)
			for k,v in ipairs(tab) do 
				if v == "note" then 
					local note = NIRC.Notes[tab[k+1]]
					if !note[1] then return Say("(Note):"..note[2])
					elseif string.Left(nick,5) == "[IRC]" then
						return NIRC.Say("Gman", "(Note):"..note[2], NULL, string.sub(nick,6))
					else
						return NIRC.Say("Gman", "(Note):"..note[2], NULL, nick)
					end
				end
			end
			return Say("I don't have a note by that name")
		end
		if find(msg, "flip") && find(msg, "coin") then
			RandSay({
				"I flipped the coin, it is heads up.",
				"I rolled a 2d and got a 1 (heads)",
				"Coins are outmoded. You want odds? I'll give you odds. Its tails.",
				"I may have flipped a coin, it is tails up."
			})
			return
		end
		if find(msg, "question") && math.random(1,2) == 1 then
			return Say("The answer is install "..table.Random({"fedora","debian","xubuntu","kubuntu","xfce","arch","gentoo","red hat","mint", "grub again"})..", now what was the question?") end
		if find(msg, "map") then
			return NIRC.ChangeMap(msg, find(msg, "next")) or Say("The current map is "..game.GetMap()..".")
		end
		if find(msg, "bonk") || (string.len(msg) < 7 && find(msg, "gman?")) then RandSay(NIRC.Messages.Bonk) return end
		if find(msg, "match box") then Say("No, but a tin can.") return end
		if find(msg, "pants") then Say("Why wear 'em?") return end
		if find(msg, "help") then RandSay(NIRC.Messages.Help) return end
		if find(msg, "addons") then 
			Say("Nebtown uses Wire, SBMP, SProps, EP2, CSS, BMS, and TF2 content. These are all available at http://nebtown.info/fastdl/addons/") 
			for k,v in pairs(player.GetAll()) do v:ConCommand("svn") end
			return 
		end
		local ipaddr = string.match(msg, "%d+.%d+.%d+.%d+")
		if ipaddr and LookupIPAddress(ipaddr) then Say("My records report: "..LookupIPAddress(ipaddr)) return end
		if find(msg, "crash") && math.random(1, 4) == 1 then 
			Say("Okay fine maybe I will just crash the server.")
			NIRC.Shutdown()
			timer.Create("RestoreNIRC",24,1,function() RunConsoleCommand("nirc_refresh") end)
			return
		end
		if find(msg, "whatport80") then game.ConsoleCommand("wire_expression2_reload\n") return end
		if find(msg, "sv_lag") and string.find(nick,"Neb") then game.ConsoleCommand("sv_lag 0\n") Say("Okay setting sv_lag to 0! Let me know when you want it back on") return end
		if find(msg, "fungus") then Say("REMOVING FUNGUS, SIR/MA'AM!") for k,v in pairs(ents.FindByModel("models/weapons/w_bugbait.mdl")) do v:Remove() end return end
		if find(msg, "fastdl") then 
			NIRC.nofastdl = !NIRC.nofastdl
			if NIRC.nofastdl then Say("Okay, disabling FastDL for now!") game.ConsoleCommand("sv_downloadurl \"\"\n") 
			else Say("Okay, reenabling FastDL!") game.ConsoleCommand("sv_downloadurl \"http://www.nebtown.info/fastdl\"\n") end
			return
		end
		if find(msg,"pungreport") then
			local pung = 0
			local superpung = 0
			for k,v in pairs(player.GetHumans()) do
				if v:Ping() > 800 then superpung = superpung + 1
				else pung = pung + v:Ping()
				end
			end
			Say("The average ping is "..math.Round(pung / #player.GetHumans()).." and "..superpung.."/"..#player.GetHumans().." are superpunging.")
			return
		end
		if find(msg, "punglevel") then 
			local tab = string.Explode(" ", msg)
			for k,v in ipairs(tab) do 
				if v == "punglevel" then 
					local num = math.max(math.min((tonumber(tab[k+1]) or 25),33), 5)
					game.ConsoleCommand("sv_maxupdaterate "..num.."\n") Say("Alrighty, I set the network-tick to "..num.." (5-33)") 
					return 
				end
			end
		end
		if find(msg, "translat") then 
			local tab = string.Explode(" ", msg)
			for k,v in ipairs(tab) do 
				if string.Left(v,8) == "translat" then 
					local ply = FindPlayer(string.gsub(tab[k+1], "[^%w_]", ""))
					if IsValid(ply) then
						if string.find(msg,"stop") then 
							ply.GTranslate = nil
							ply.GLanguage = nil
							Say("Okay I'll stop trying to translate "..ply:Nick()) 
							NIRC.IsTranslating = nil
							for _,person in pairs(player.GetAll()) do if person.GTranslate then NIRC.IsTranslating = true end end
						else ply.GTranslate = true NIRC.IsTranslating = true Say("Okay I'll try to translate "..ply:Nick())
						end
						return
					end
				end
			end
		end
		if find(msg, "namage") then local check = "on." if GetConVarNumber("namage_on") == 0 then check = "off." end Say("Namage is currently "..check) return end
		if find(msg, "right") && find(msg, "?") then RandSay({"You're right!", "You're completely wrong.", "I cannot explain how wrong you are in simple scripts."}) return end
		if find(msg, "lookup") then return NIRC.Lookup(nick,msg,Say) end
		if find(msg, "irc") then Say(NIRC.Messages.IRC) return end
		if find(msg, "slack") then Say("Nebtown chills in Slack (hipster IRC/chat) when not ingame. Join us at http://slack.nebtown.info/") return end
		if find(msg, "discord") then Say("Nebtown has a Discord - join us at https://discord.gg/N63AqgZ") return end
		if find(msg, "what is love") then Say("Baby don't hurt me") return end
		if find(msg, "hurt me") then Say("Don't hurt me; no more") return end
		if find(msg, "rank") and NADMOD then 
			local args = string.Explode(" ", msg)
			for k,v in ipairs(args) do
				if string.find(v,"rank") then
					for wordid=k+1,#args,1 do
						if #args[wordid] > 2 then
							local tar = FindPlayer(args[wordid])
							if tar then 
								local rank = (NADMOD.Users[tar:SteamID()] or {Rank = 1}).Rank
								Say(NADMOD.IRCName(tar).." is rank "..NADMOD.Groups[rank].Name.."["..rank.."]")
								return
							end
						end
					end
					Say("What player were you hoping to find the rank of? Man I sure am helpful")
					return
				end
			end
		end
		if find(msg, "how") then RandSay(NIRC.Messages.How) return end
		if find(msg, "nuke") then
			--NIRC.Send("Gman", "NICK [GM]Gnukem")
			RandSay(NIRC.Messages.DukeNukem)
			--timer.Simple(600, function() NIRC.Send("Gman", "NICK [GM]Gman") end)
			return
		end
		if find(msg, "you") then RandSay(NIRC.Messages.You) if math.random(1,60) == 1 then timer.Simple(2, function() Say("WAIT NO I TAKE IT BACK") end) end return end
		if math.random(0,3) == 1 then RandSay(NIRC.Messages.Generic) return end
	end
end
function NIRC.Lookup(nick, msg, Say)
	local startnum = find(msg, "up") + 3
	local tarname = string.sub(msg, startnum, (find(msg, " ", startnum) or 0)-1)
	
	if find(tarname, "gman") then Say("Gman's address is recorded as your mom's house, why don't you go ask her?") return 
	elseif find(tarname, "mom") then Say("Now thats just ridiculous. The misses is a very kind woman to me and I will not go about disclosing her whereabouts.") return end
	if string.sub(tarname,1,1) != "[" then
		-- Lets guess
		if string.sub(nick,1,4) == "[IRC" then tarname = "[irc]"..tarname else tarname = "[gm]"..tarname end
	end
	print("-"..tarname.."-")
	if string.sub(tarname,1,4) == "[gm]" then
		tarname = string.gsub(string.gsub(string.sub(tarname,5), " ", "_"), "[^%w_]", "")
		print("Looking up player "..tarname)
		local ent = FindPlayer(tarname)
		if !ent then Say("No player found!") return end
		local address = ent:IPAddress()
		Say("My records report "..tarname.." ("..address..") has been commonly known by the following names: "..LookupIPAddress(address))
	elseif string.sub(tarname,1,4) == "[irc" then
		tarname = string.gsub(string.gsub(string.sub(tarname,6), " ", "_"), "[^%w_]", "")
		print("Looking up IRCer "..tarname)
		local fullname = NIRC.FindIRCUser(tarname)
		if !fullname then return Say("Who?") end
		if NIRC.UserIPs[fullname] then 
			local address = NIRC.UserIPs[fullname]
			if !address then return Say("I dunno him.") end
			Say("My records report "..tarname.." has been commonly known by the following names: "..LookupIPAddress(address))
		else
			-- NIRC.Send("Gman", "WHOIS "..fullname)
			timer.Simple(2,function()
				if NIRC.UserIPs[fullname] then 
					local address = NIRC.UserIPs[fullname]
					if !address then return Say("I dunno him.") end
					Say("My records report "..tarname.." has been commonly known by the following names: "..LookupIPAddress(address))
				end
			end)
		end
		//	if ListeningForWhois then Say("Sorry, I dunno what user you're referring to so I couldn't query the database. Write name out in full after 'lookup' please.") ListeningForWhois = nil end
	end
	return
end
function NIRC.ChangeMap(msg, queue)
	if !NADMOD then return print("Nadmod is not present, no maps list available!") end
	if #player.GetHumans() >= 2 then
		queue = true
	end

	local map = NIRC.FindMap(msg)
	if not map then return false end

	if queue then
		file.Write("nextmap.txt", map)
		NIRC.Say("Queued up next map: " .. map)
	else
		game.ConsoleCommand("! map "..map.."\n")
	end
	return true
end

function NIRC.FindMap(msg)
	local gm,rp,sb = find(msg, "gm_"), find(msg, "rp_"), find(msg, "sb_")
	for _,v in pairs(file.Find("maps/*.bsp","GAME")) do
		v = string.sub(v,1,-5)
		if !NADMOD.MapsList[v] then NADMOD.MapsList[v] = 0 end
	end
	if gm then
		for k,v in pairs(NADMOD.MapsList) do
			if string.find(k,string.sub(msg,gm,(string.find(msg,"[^%w_]",gm) or 0)-1)) then return k end
		end
	end
	if rp then
		for k, v in pairs(NADMOD.MapsList) do
			if string.find(k, string.sub(msg, rp, (string.find(msg, "[^%w_]", rp) or 0)-1)) then return k end
		end
	end
	if sb then
		for k, v in pairs(NADMOD.MapsList) do
			if string.find(k, string.sub(msg, sb, (string.find(msg, "[^%w_]",sb) or 0)-1)) then return k end
		end
	end
end

function NIRC.Roll(nick, msg, Say)
	RandSay = NIRC.RandSay
	-- Don't roll
	if (find(msg, "dont") || find(msg, "don't")) then
		RandSay({"Fine, I won't.","Who says I was going to?","... Alright"})
	-- Who gets 7 roll priority
	elseif find(msg, "7") && (nick == "Memnoc" || nick == "Nebual" || nick == "Hrothjal" || nick == "Monocle" || nick == "Louis") then
		Say("I roll a 7.")
	-- Do a barrel roll
	elseif find(msg, "barrel roll") then
		-- NIRC.Send("Gman", "NICK [GM]StarFox")
		RandSay({"Theres something wrong with the G-Defuser!", "Everybody stay alert", "Good luck."})
	-- Trolling
	elseif find(msg, "troll") then
		if math.random(1,3) == 1 then
			Say("Get waxed.")
		else
			NIRC.RandSay(NIRC.Messages.Generic)
		end
	-- Normal roll: 1/20 chance to roll 7~12, otherwise normal roll of 1~6.
	elseif math.random(1,30) == 1 then RandSay({"No...?","Stop making me roll numbers for you.","Go away.","Why?","Stop asking me that.","wtf is a \"roll\"?"}) return 
	elseif math.random(1,20) == 1 then
		Say("I roll a "..math.random(6,12)..".")
	else
		Say("I roll a "..math.random(1,6)..".")
	end
	return
end
function NIRC.Dice(nick, msg, Say)
	local dnum_a,numtrue_a,dnumloc_a,dnum_b,numtrue_b,dnumloc_b,dnum_c,numtrue_c,dnumloc_c,rollresult
	dnumloc_a = (find(msg, "dice") + 5)
	for i = dnumloc_a, (string.len(msg)) do
		if tonumber(string.sub(msg, dnumloc_a, i)) then
			dnum_a = tonumber(string.sub(msg, dnumloc_a, i))
			numtrue_a = 1
			dnumloc_b = i+1
		end
	end
	if numtrue_a == 1 then
		for i = dnumloc_b, (string.len(msg)) do
			if tonumber(string.sub(msg, dnumloc_b, i)) then
				dnum_b = tonumber(string.sub(msg, dnumloc_b, i))
				numtrue_b = 1
				dnumloc_c = i+1
			end
		end
		numtrue_a = 0
	end
	if numtrue_b == 1 then
		for i = dnumloc_c, (string.len(msg)) do
			if tonumber(string.sub(msg, dnumloc_c, i)) then
				dnum_c = tonumber(string.sub(msg, dnumloc_c, i))
				numtrue_c = 1
			end
		end
		rollresult = 0
		if (dnum_a > 0) && (dnum_b > 0) then
			if dnum_a > 50 then dnum_a = 50 end
			if dnum_b > 9001 then dnum_b = 9001 end
			if dnum_b < -9001 then dnum_b = -9001 end
			if numtrue_c == 1 then
				if dnum_c > 9001 then dnum_c = 9001 end
				if dnum_c < -9001 then dnum_c = -9001 end
			end
			for i = 1, dnum_a do
				rollresult = rollresult + math.random(1,dnum_b)
			end
			if numtrue_c == 1 then
				rollresult = rollresult + dnum_c
				if dnum_c >= 1 then dnum_c = "+"..dnum_c end
				Say("I roll "..dnum_a.."d"..dnum_b..dnum_c.." with a result of "..rollresult..".")
				numtrue_c = 0
			else
				Say("I roll "..dnum_a.."d"..dnum_b.." with a result of "..rollresult..".")
			end
		end
		numtrue_b = 0
	end
end

/*NIRC.toenglist = {"ch", "ea", "ei", "eu", "io", "ng", "qu", "sh", "th", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", " "}
NIRC.fromenglist = {"%[ch%]", "%[ea%]", "%[ei%]", "%[eu%]", "%[io%]", "%[ng%]", "%[qu%]", "%[sh%]", "%[th%]", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", " "}
NIRC.runelist = {"string.char(225)..string.char(155)..string.char(164)", "string.char(225)..string.char(155)..string.char(160)", "string.char(225)..string.char(155)..string.char(135)", "string.char(225)..string.char(155)..string.char(133)", "string.char(225)..string.char(155)..string.char(161)", "string.char(225)..string.char(155)..string.char(157)", "string.char(225)..string.char(155)..string.char(162)", "string.char(225)..string.char(155)..string.char(165)", "string.char(225)..string.char(154)..string.char(166)", "string.char(225)..string.char(154)..string.char(171)", "string.char(225)..string.char(155)..string.char(146)", "string.char(225)..string.char(154)..string.char(179)", "string.char(225)..string.char(155)..string.char(158)", "string.char(225)..string.char(155)..string.char(150)", "string.char(225)..string.char(154)..string.char(160)", "string.char(225)..string.char(154)..string.char(183)", "string.char(225)..string.char(154)..string.char(186)", "string.char(225)..string.char(155)..string.char(129)", "string.char(225)..string.char(155)..string.char(131)", "string.char(225)..string.char(154)..string.char(180)", "string.char(225)..string.char(155)..string.char(154)", "string.char(225)..string.char(155)..string.char(151)", "string.char(225)..string.char(154)..string.char(190)", "string.char(225)..string.char(155)..string.char(159)", "string.char(225)..string.char(155)..string.char(136)", "string.char(225)..string.char(154)..string.char(178)", "string.char(225)..string.char(154)..string.char(177)", "string.char(225)..string.char(155)..string.char(139)", "string.char(225)..string.char(155)..string.char(143)", "string.char(225)..string.char(154)..string.char(162)", "string.char(225)..string.char(155)..string.char(169)", "string.char(225)..string.char(154)..string.char(185)", "string.char(225)..string.char(155)..string.char(163)", "string.char(225)..string.char(154)..string.char(163)", "string.char(225)..string.char(155)..string.char(137)", "string.char(225)..string.char(155)..string.char(172)"}*/
function NIRC.EngToRune(nick, msg, Say)
	//NIRC.socks.Gman:SendLine("NICK [GM]Yggman")
	local strloc = (find(msg, "engtorune") + 10)
	local strreply = string.sub(msg, strloc, string.len(msg))
	strreply = string.gsub(strreply, "%[ch%]", string.char(225)..string.char(155)..string.char(164))
	strreply = string.gsub(strreply, "%[ea%]", string.char(225)..string.char(155)..string.char(160))
	strreply = string.gsub(strreply, "%[ei%]", string.char(225)..string.char(155)..string.char(135))
	strreply = string.gsub(strreply, "%[eu%]", string.char(225)..string.char(155)..string.char(133))
	strreply = string.gsub(strreply, "%[io%]", string.char(225)..string.char(155)..string.char(161))
	strreply = string.gsub(strreply, "%[ng%]", string.char(225)..string.char(155)..string.char(157))
	strreply = string.gsub(strreply, "%[qu%]", string.char(225)..string.char(155)..string.char(162))
	strreply = string.gsub(strreply, "%[sh%]", string.char(225)..string.char(155)..string.char(165))
	strreply = string.gsub(strreply, "%[th%]", string.char(225)..string.char(154)..string.char(166))
	strreply = string.gsub(strreply, "a", string.char(225)..string.char(154)..string.char(171))
	strreply = string.gsub(strreply, "b", string.char(225)..string.char(155)..string.char(146))
	strreply = string.gsub(strreply, "c", string.char(225)..string.char(154)..string.char(179))
	strreply = string.gsub(strreply, "d", string.char(225)..string.char(155)..string.char(158))
	strreply = string.gsub(strreply, "e", string.char(225)..string.char(155)..string.char(150))
	strreply = string.gsub(strreply, "f", string.char(225)..string.char(154)..string.char(160))
	strreply = string.gsub(strreply, "g", string.char(225)..string.char(154)..string.char(183))
	strreply = string.gsub(strreply, "h", string.char(225)..string.char(154)..string.char(186))
	strreply = string.gsub(strreply, "i", string.char(225)..string.char(155)..string.char(129))
	strreply = string.gsub(strreply, "j", string.char(225)..string.char(155)..string.char(131))
	strreply = string.gsub(strreply, "k", string.char(225)..string.char(154)..string.char(180))
	strreply = string.gsub(strreply, "l", string.char(225)..string.char(155)..string.char(154))
	strreply = string.gsub(strreply, "m", string.char(225)..string.char(155)..string.char(151))
	strreply = string.gsub(strreply, "n", string.char(225)..string.char(154)..string.char(190))
	strreply = string.gsub(strreply, "o", string.char(225)..string.char(155)..string.char(159))
	strreply = string.gsub(strreply, "p", string.char(225)..string.char(155)..string.char(136))
	strreply = string.gsub(strreply, "q", string.char(225)..string.char(154)..string.char(178))
	strreply = string.gsub(strreply, "r", string.char(225)..string.char(154)..string.char(177))
	strreply = string.gsub(strreply, "s", string.char(225)..string.char(155)..string.char(139))
	strreply = string.gsub(strreply, "t", string.char(225)..string.char(155)..string.char(143))
	strreply = string.gsub(strreply, "u", string.char(225)..string.char(154)..string.char(162))
	strreply = string.gsub(strreply, "v", string.char(225)..string.char(155)..string.char(169))
	strreply = string.gsub(strreply, "w", string.char(225)..string.char(154)..string.char(185))
	strreply = string.gsub(strreply, "x", string.char(225)..string.char(155)..string.char(163))
	strreply = string.gsub(strreply, "y", string.char(225)..string.char(154)..string.char(163))
	strreply = string.gsub(strreply, "z", string.char(225)..string.char(155)..string.char(137))
	Say("Translation: "..strreply)
end

function NIRC.RuneToEng(nick, msg, Say)
	//NIRC.socks.Gman:SendLine("NICK [GM]Yggman")
	local strloc = (find(msg, "runetoeng") + 10)
	local strreply = string.sub(msg, strloc, string.len(msg))
	strreply = string.gsub(strreply, string.char(225)..string.char(155)..string.char(164), "ch")
	strreply = string.gsub(strreply, string.char(225)..string.char(155)..string.char(160), "ea")
	strreply = string.gsub(strreply, string.char(225)..string.char(155)..string.char(135), "ei")
	strreply = string.gsub(strreply, string.char(225)..string.char(155)..string.char(133), "eu")
	strreply = string.gsub(strreply, string.char(225)..string.char(155)..string.char(161), "io")
	strreply = string.gsub(strreply, string.char(225)..string.char(155)..string.char(157), "ng")
	strreply = string.gsub(strreply, string.char(225)..string.char(155)..string.char(162), "qu")
	strreply = string.gsub(strreply, string.char(225)..string.char(155)..string.char(165), "sh")
	strreply = string.gsub(strreply, string.char(225)..string.char(154)..string.char(166), "th")
	strreply = string.gsub(strreply, string.char(225)..string.char(154)..string.char(171), "a")
	strreply = string.gsub(strreply, string.char(225)..string.char(155)..string.char(146), "b")
	strreply = string.gsub(strreply, string.char(225)..string.char(154)..string.char(179), "c")
	strreply = string.gsub(strreply, string.char(225)..string.char(155)..string.char(158), "d")
	strreply = string.gsub(strreply, string.char(225)..string.char(155)..string.char(150), "e")
	strreply = string.gsub(strreply, string.char(225)..string.char(154)..string.char(160), "f")
	strreply = string.gsub(strreply, string.char(225)..string.char(154)..string.char(183), "g")
	strreply = string.gsub(strreply, string.char(225)..string.char(154)..string.char(186), "h")
	strreply = string.gsub(strreply, string.char(225)..string.char(155)..string.char(129), "i")
	strreply = string.gsub(strreply, string.char(225)..string.char(155)..string.char(131), "j")
	strreply = string.gsub(strreply, string.char(225)..string.char(154)..string.char(180), "k")
	strreply = string.gsub(strreply, string.char(225)..string.char(155)..string.char(154), "l")
	strreply = string.gsub(strreply, string.char(225)..string.char(155)..string.char(151), "m")
	strreply = string.gsub(strreply, string.char(225)..string.char(154)..string.char(190), "n")
	strreply = string.gsub(strreply, string.char(225)..string.char(155)..string.char(159), "o")
	strreply = string.gsub(strreply, string.char(225)..string.char(155)..string.char(136), "p")
	strreply = string.gsub(strreply, string.char(225)..string.char(154)..string.char(178), "q")
	strreply = string.gsub(strreply, string.char(225)..string.char(154)..string.char(177), "r")
	strreply = string.gsub(strreply, string.char(225)..string.char(155)..string.char(139), "s")
	strreply = string.gsub(strreply, string.char(225)..string.char(155)..string.char(143), "t")
	strreply = string.gsub(strreply, string.char(225)..string.char(154)..string.char(162), "u")
	strreply = string.gsub(strreply, string.char(225)..string.char(155)..string.char(169), "v")
	strreply = string.gsub(strreply, string.char(225)..string.char(154)..string.char(185), "w")
	strreply = string.gsub(strreply, string.char(225)..string.char(155)..string.char(163), "x")
	strreply = string.gsub(strreply, string.char(225)..string.char(154)..string.char(163), "y")
	strreply = string.gsub(strreply, string.char(225)..string.char(155)..string.char(137), "z")
	strreply = string.gsub(strreply, string.char(225)..string.char(155)..string.char(172), " ")
	Say("Translation: "..strreply)
end
