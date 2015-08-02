game.MapDecided = game.MapDecided or false
game.BadMaps = game.BadMaps or {}

local plugins = GetGlobalString( "wfPlugins", "" )
if not table.HasValue( string.Explode( ";", plugins ), "nextmap" ) then
	SetGlobalString( "wfPlugins", plugins .. ";nextmap" )
end

local fuck = CurTime() + 60*3
hook.Add( "InitPostEntity", "Map Picker", function()
	if file.Exists( "maps_old.txt", "DATA" ) then
		game.BadMaps = util.JSONToTable( file.Read( "maps_old.txt", "DATA" ) )
	end

	if #game.BadMaps > 4 then
		table.remove( game.BadMaps, 1 )
	end

	table.insert( game.BadMaps, game.GetMap() )
	file.Write( "maps_old.txt", util.TableToJSON( game.BadMaps ) )
end )

local avoid = ""
function util.getValidMaps()
	local maps = file.Read( "mapcycle.txt", "GAME" )
	maps = string.Explode( "\n", maps )

	local t = {}
	for k, v in pairs( maps ) do
		v = v:gsub( "\n", "" ):Trim()
		if v == "" then continue end
		if v ~= game.GetMap() and v ~= avoid and not table.HasValue( game.BadMaps, v ) then
			t[ #t + 1 ] = v
		end
	end

	return t
end

game.OldGetMapNext = game.OldGetMapNext or game.GetMapNext
function game.GetMapNext( revise )
	if not revise and game.MapDecided then return game.MapDecided end

	local maps = util.getValidMaps()
	for k, v in RandomPairs( maps ) do
		game.MapDecided = v
		return v
	end
end

game.OldLoadNextMap = game.OldLoadNextMap or game.LoadNextMap
function game.LoadNextMap()
	game.ConsoleCommand( "changelevel " .. game.GetMapNext() .. "\n" )

	timer.Simple( 2, function()
		game.OldLoadNextMap()
	end )
end

function game.ChooseDiffMap()
	game.MapDecided = false
end 
game.DidNewMap = game.DidNewMap or {}
game.NomMaps = game.NomMaps or {}

local doing = false
local function changemap( map, instant )
	doing = map
	game.MapDecided = doing
	PrintMessage( 3, "Changing the map to " .. map:gsub( "\n", "" ):Trim() .. "..." )

	timer.Simple( 3, function()
		if instant then
			--RunConsoleCommand( "changelevel", map )
			game.ConsoleCommand( "changelevel " .. map:gsub( "\n", "" ):Trim() .. "\n" )
		elseif GetRoundState() == ROUND_ACTIVE then
			PrintMessage( 3, "The round is active! Delaying the map change until the end of this round." )

			hook.Add( "TTTEndRound", "Map Change", function()
				timer.Simple( 3, function()
					changemap( map, true )
				end )
			end )
		end
	end )
end

local function rtvNeed( oneless )
	return math.floor( (#player.GetAll() - (oneless and 1 or 0)) * 0.7 )
end
local function rtvHas()
	local votes = 0
	for k, v in pairs( player.GetAll() ) do
		if v._rtvoted then votes = votes + 1 end
	end

	return votes
end

local function rtvCheck( oneless )
	if fuck > CurTime() then return end

	local req = rtvNeed( oneless )
	local votes = rtvHas()

	if votes >= req then
		changemap( game.GetMapNext() )
	end
end

hook.Add( "PlayerSay", "Nextmap Cmds", function( ply, text )
	local boots = text:lower()
	local with = boots:Left( #"!badmaps" )
	local the = boots:Left( #"!newmap" )
	local fur = boots:Left( #"!nextmap" )
	local doot = boots:Left( #"!rtv" )
	local dooot = boots:Left( #"rtv" )
	local toot = boots:Left( #"!mapvote" )
	local tooot = boots:Left( #"!maps" )

	if fur == "!nextmap" or fur == "/nextmap" then
		ply:ChatPrint( "Next map: " .. game.GetMapNext() )
		return ""
	elseif with == "!badmaps" or with == "/badmaps" then
		local str = ""
		local last = false
		local did = {}
		for k, v in pairs( game.BadMaps ) do
			if did[ v ] then continue end
			did[ v ] = true

			if last then
				str = (str ~= "" and str .. ", " or "") .. last
			end

			last = v
		end

		str = str == "" and last or str .. ", and " .. last
		ply:ChatPrint( "Maps that cannot be played due to cooldown: " .. str )
		return ""
	elseif (the == "!newmap" or the == "/newmap") and not doing then
		if not game.DidNewMap[ ply:SteamID() ] then
			local te = string.Explode( " ", boots )
			if te[2] then
				local maps = util.getValidMaps()
				local chose = te[2]:Trim()

				if not table.HasValue( maps, chose ) then
					ply:ChatPrint( chose .. " either doesn't exist or has been played too recently." )
					return ""
				end

				if game.NomMaps[ chose ] then
					ply:ChatPrint( "Someone already nominated that. You can only get that map nominated by picking a random map." )
					return ""
				end

				game.NomMaps[ chose ] = true
				game.MapDecided = chose

				PrintMessage( 3, ply:Nick() .. " has chosen the next map! It is now " .. chose )

				game.DidNewMap[ ply:SteamID() ] = true
				return ""
			end

			avoid = game.MapDecided or ""
			local new = game.GetMapNext( true )

			PrintMessage( 3, ply:Nick() .. " has randomized the next map! It is now " .. new )

			game.DidNewMap[ ply:SteamID() ] = true
		end

		return ""
	elseif (dooot == "rtv" or doot == "!rtv" or doot == "/rtv" or toot == "!mapvote" or toot == "/mapvote") then
		if doing then ply:ChatPrint( "Can't do that right now." ) return "" end
		if ply._rtvoted then ply:ChatPrint( "Already did that, man." ) return "" end
		if fuck > CurTime() then ply:ChatPrint( "Have to wait a bit bro." ) return "" end
		ply._rtvoted = true
		PrintMessage( 3, ply:Nick() .. " has voted to change the map. (" .. rtvHas() .. "/" .. rtvNeed() .. ")" )

		rtvCheck()
		return ""
	elseif tooot == "!maps" then
		local maps = util.getValidMaps()

		ply:ChatPrint( "All valid maps printed to your console." )
		for k, v in pairs( maps ) do
			ply:PrintMessage( HUD_PRINTCONSOLE, "- " .. v )
		end

		return ""
	end
end )

hook.Add( "PlayerDisconnected", "RTV Check", function()
	rtvCheck( true )
end )
