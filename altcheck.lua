if not sql.TableExists( "_ipalts" ) then
	sql.Query( "CREATE TABLE IF NOT EXISTS _ipalts ( ip TEXT NOT NULL PRIMARY KEY, data TEXT );" )
end
if not sql.TableExists( "_altips" ) then
	sql.Query( "CREATE TABLE IF NOT EXISTS _altips ( id TEXT NOT NULL PRIMARY KEY, data TEXT );" )
end

local function aNotify( str )
	for k, v in pairs( player.GetAll() ) do
		if not v:IsAdmin() and not v:IsUserGroup( "operator" ) then continue end

		v:ChatPrint( str )
	end
end

/**
	Returns a table with the following structure:
	{
		{
			id = ( STEAMID string ),
			nick = ( NAME string ),
			when = ( TIME number )
		}
	}
*/
local function getAccountsFromIP( ip )
	local data = sql.QueryValue( "SELECT data FROM _ipalts WHERE ip = " .. SQLStr( ip ) .. " LIMIT 1;" )
	return data and util.JSONToTable( data ) or {}
end
local function addAccountToIP( ip, data, ply )
	data[ #data + 1 ] = {
		id = ply:SteamID(),
		nick = ply:Nick(),
		when = os.time()
	}

	sql.Query( "REPLACE INTO _ipalts ( ip, data ) VALUES ( " .. SQLStr( ip ) .. ", " .. SQLStr( util.TableToJSON( data ) ) .. " );" )
end

/**
	Returns a table with the following structure:
	{
		( IP string ),
	}
*/
local function getIPsFromAccount( id )
	local data = sql.QueryValue( "SELECT data FROM _altips WHERE id = " .. SQLStr( id ) .. " LIMIT 1;" )
	return data and util.JSONToTable( data ) or {}
end
local function addIPToAccount( id, data, ip )
	data[ #data + 1 ] = ip

	sql.Query( "REPLACE INTO _altips ( id, data ) VALUES ( " .. SQLStr( id ) .. ", " .. SQLStr( util.TableToJSON( data ) ) .. " );" )
end

/**
	getAllData returns a table with the following structure:
	{
		{
			id = ( STEAMID string ),
			nick = ( NAME string ),
			when = ( TIME number )
		}
	}
*/

local function loop( ips, accounts )
	local new = false

	for k, v in pairs( accounts ) do
		local ip = getIPsFromAccount( v.id )
		for a, b in pairs( ip ) do
			if not table.HasValue( ips, b ) then
				ips[ #ips + 1 ] = b
				new = true
			end
		end
	end

	for k, v in pairs( ips ) do
		local acc = getAccountsFromIP( v )
		for a, b in pairs( acc ) do
			local found = false
			for e, r in pairs( accounts ) do
				if found then continue end
				if r.id == b.id then
					found = true
				end
			end

			if not found then
				accounts[ #accounts + 1 ] = b
				new = true
			end
		end	
	end

	return new and loop( ips, accounts ) or ips, accounts
end
local function getAllData( original_ip, original_id )
	local ips, accounts = loop( getIPsFromAccount( original_id ), getAccountsFromIP( original_ip ) )
	
	return ips, accounts
end

function util.getAllData( ply )
	local ips, accounts = loop( getIPsFromAccount( ply:SteamID() ), getAccountsFromIP( string.Explode( ":", ply:IPAddress() )[1] ) )
	
	return ips, accounts
end

hook.Add( "PlayerInitialSpawn", "IP Check", function( ply )
	local ip = string.Explode( ":", ply:IPAddress() )[1]
	if not ip then return end -- ?

	local _ips, data = getAllData( ip, ply:SteamID() )

	local alts = false
	local found = false
	for k, v in pairs( data ) do
		if v.id == ply:SteamID() then
			found = true
		else alts = true end
	end

	if alts then
		aNotify( ply:Nick() .. " has connected to this server on a different account before." .. (found and "" or " This is his first time playing here on this account.") )
		aNotify( "Type !alts to view alt information in your console." )
	end

	if not found then
		addAccountToIP( ip, data, ply )
		addIPToAccount( ply:SteamID(), _ips, ip )
	end

	ply.alt_data = data
end )

hook.Add( "PlayerSay", "Alt Data", function( ply, text )
	if not ply:IsAdmin() and not ply:IsUserGroup( "operator" ) then return end

	text = text:lower()
	local check = text:Left( #"!alts" )
	local first = false

	if check == "!alts" or check == "/alts" then
		ply:PrintMessage( HUD_PRINTCONSOLE, "------- Alt Info -------" )
		for k, v in pairs( player.GetAll() ) do
			if not v.alt_data then continue end
			if table.Count( v.alt_data ) <= 1 then continue end

			ply:PrintMessage( HUD_PRINTCONSOLE, (first and "\n" or "") .. "Player: " .. v:Nick() )

			if not first then first = true end
			for a, b in pairs( v.alt_data ) do
				if b.id == v:SteamID() then continue end
				ply:PrintMessage( HUD_PRINTCONSOLE, "\tNick: " .. b.nick )
				ply:PrintMessage( HUD_PRINTCONSOLE, "\tSteamID: " .. b.id )
			end
		end
		ply:PrintMessage( HUD_PRINTCONSOLE, "------- Alt Info -------" )
		return ""
	end
end )
