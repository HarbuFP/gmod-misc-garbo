-- player.Find( "test" ) for regular search.
-- player.Find( "@test" ) for explicit lowercase search.
-- player.Find( "$Test" ) for case-sensitive explicit search.

local REGULAR, EXPLICIT, EXPLICITCASE = 1, 2, 3
local modes = {["@"]=2,["$"]=3}
function util.Find( tab, str, multiselect, func )
	local mode = modes[str:Left(1)] or REGULAR
	local find = mode == REGULAR and str or str:sub( 2, #str )

	local found = {}
	local searchfor = mode == EXPLICITCASE and find or find:lower()
	local check
	for k, v in pairs( tab ) do
		check = func and func( v ) or v
		if mode == EXPLICITCASE then
			if check == searchfor then
				return { v }
			end
		else
			if string.find( check:lower(), searchfor, 1, true ) then
				found[ #found + 1 ] = v
			end
		end
	end

	return multiselect and found or found[1] or false
end

function player.Find( str, multiselect )
	return util.Find( player.GetAll(), str, multiselect, function( v ) return v:Nick() end )
end
