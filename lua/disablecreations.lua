-- Announce creation pastes
hook.Add("InitPostEntity","NCDelayedArmDupeInit",function()
	net.Receive( "ArmDupe", function( len, client )
		//if not client.UserRank or client.UserRank == 1 then NADMOD.Message("New users are not allowed pasting creations.",client) return end
		-- ^This is how I'm personally disabling creations
		
		local len		= net.ReadUInt( 32 )
		local data		= net.ReadData( len )

		if ( !IsValid( client ) ) then return end

		-- Hook.. can arn dupe..

		local uncompressed = util.Decompress( data )
		if ( !uncompressed ) then 
			MsgN( "Couldn't decompress dupe!" )
		return end

		local Dupe = util.JSONToTable( uncompressed )
		if ( !istable( Dupe ) ) then return end
		if ( !isvector( Dupe.Mins ) ) then return end
		if ( !isvector( Dupe.Maxs ) ) then return end

		client.CurrentDupe = Dupe;
		print(client:Nick().." is pasting a creation.") -- Maybe broadcast this to your clients? I do

		client:ConCommand( "gmod_tool duplicator" );

		--
		-- Disable the Spawn Button
		--
		net.Start( "CopiedDupe" )
			net.WriteUInt( 0, 1 );
		net.Send( client )
	end )
end)