net.Receive("nchat_say", function(len)
    chat.AddText(Color(180, 240, 240), net.ReadString(), Color(255, 255, 255), ": " .. net.ReadString())
end)
