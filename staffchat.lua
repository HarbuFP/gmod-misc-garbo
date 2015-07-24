local function isAdmin( ply )
	if not IsValid( ply ) then return false end

	return ply:IsUserGroup( "operator" ) or ply:IsAdmin()
end

hook.Add( "PlayerSay", "Staff Chat", function( ply, text )
	if not isAdmin( ply ) then return end

	if text:Left( 1 ) == "@" then
		local start = 2

		if text:lower():Left( 3 ) == "@p " then
			local rest = text:sub( start + 2, #text )
			local pomf = string.Explode( " ", rest )[ 1 ]

			local targ
			local soft = false
			for k, v in pairs( player.GetAll() ) do
				if not string.find( v:Nick():lower(), pomf:lower() ) then continue end

				if v:Nick() == pomf then
					targ = v
					break
				elseif v:Nick():lower() == pomf:lower() then
					targ = v
					soft = true
				elseif not soft then
					targ = v
				end
			end

			if not targ then
				ply:ChatPrint( "No target found!" )
				return ""
			end

			local send = rest:sub( #pomf + 2, #text )

			targ:ChatPrint( "(From " .. ply:Nick() .. ") " .. send )

			if not isAdmin( targ ) then
				for k, v in pairs( player.GetAll() ) do
					if not isAdmin( v ) then continue end

					local str = "(" .. ply:Nick() .. " -> " .. targ:Nick() .. ") " .. send

					v:ChatPrint( str )
					ServerLog( "SC: " .. str .. "\n" )
				end
			else ply:ChatPrint( "(To " .. targ:Nick() .. ") " .. send ) end
		else
			local is_all = text:Left( start ) == "@!"
			if is_all then start = start + 1 end
			start = text:sub( start, start ) == " " and start + 1 or start

			local send = text:sub( start, #text )
			local str = ( is_all and "(GLOBAL) " or "(STAFF) " ) .. ply:Nick() .. ": " .. send

			for k, v in pairs( player.GetAll() ) do
				if not is_all and not isAdmin( v ) then continue end

				v:ChatPrint( str )
			end

			ServerLog( "SC: " .. str .. "\n" )
		end

		return ""
	end
end )
