--[[
	Function: surface.fPlaySound( table info[, ply ] )
	
	This fakes playing a song through atmosphere and plays a local song file.

	If this is called on the server, the second argument can be the player to
	play the song on. If called on the client, it only takes the first argument.

	Example: surface.fPlaySound( {
		file = "mycoolsound.mp3",
		artist = "Hello",
		song = "world!",
		length = 13,
		endround = true,
	} )
]]

if SERVER then
	AddCSLuaFile()
	surface = surface or {}
	
	util.AddNetworkString( "atmosphere FakePlay" )
	function surface.fPlaySound( info, ply )
		if not atmosphere then return error( "Atmosphere isn't installed!" ) end
		if not ( info.file and info.artist and info.song and tonumber( info.length ) ) then return error( "Invalid/missing args" ) end
		net.Start( "atmosphere FakePlay" )
			net.WriteTable( info )
		if ply then net.Send( ply ) else net.Broadcast() end
	end

	return
end

function surface.fPlaySound( info )
	if atmosphere.current and IsValid( atmosphere.panel ) then return end
	if info.endround then
		if atmosphere.endround_music then return end
		if GetConVarNumber( "ttt_atmosphere_endround" ) ~= 1 then return end
	end

	surface.PlaySound( info.file )
	atmosphere:Play( "9BifiioaIos", info.artist, info.song, info.length, 0, CurTime(), true, true )
end

net.Receive( "atmosphere FakePlay", function()
	local info = net.ReadTable()
	surface.fPlaySound( info )
end )
