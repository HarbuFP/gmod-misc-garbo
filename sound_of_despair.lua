-- this shit was painful to make. it's also unorganized and messy so you're probably gonna find redundant/stupid things.
local function isVowel( str )
	str = str:lower()
	return not ( str ~= "a" and str ~= "e" and str ~= "i" and str ~= "o" and str ~= "u" )
end

local matching_brackets = {
	["["] = "]",
	["("] = ")",
}

local likes = {}
for i = 97, 122 do likes[#likes+1] = string.char( i ) end -- a-z

local function cleanName( str )
	local s = ""
	local t = string.ToTable( str )
	local starting_bracket = false

	for k, v in pairs( t ) do
		if starting_bracket then
			if v ~= matching_brackets[ starting_bracket ] then
				continue
			else
				starting_bracket = false
			end
		else
			if matching_brackets[ v ] then
				starting_bracket = v
			elseif table.HasValue( likes, v:lower() ) then
				s = s .. v
			end
		end
	end

	return s
end

function util.babyName( str )
	str =  cleanName( str )

	local foreign = { "x", "z", "p", "h" } -- french/weird shit = x, chinese/weird shit = z
	local names = { 
		{ "Baby%s", string.lower },
		{ "%s Jr", function(s) return s end },
		{ "%s CENA", string.upper },
	}

	local db = function(s) end--PrintMessage( HUD_PRINTCONSOLE, s ) end

	local should_stop = 0 -- 0 inactive, 1 did a vowel, 2 did a consonant after vowel(s)
	local consonant_count = 0
	local vowel_count = 0
	local was_special = false
	local lasttime = ""
	local lastchar = ""

	local curname = ""
	for i = 1, string.len( str ) do
		local char = string.sub( str, i, i )
		local jd = false
		db( "started char: " .. char )

		if isVowel( char ) then
			db( "is vowel" )
			consonant_count = 0

			db( "should stop is " .. tostring(should_stop ) )
			if should_stop == 0 then
				should_stop = 1
				db( "setting should stop t 1" )
			elseif should_stop == 2 then
				local ending_e = false
				if char == "e" then
					local next = string.sub( str, i + 1, i + 1 )
					if lasttype == "consonant" and (next == " " or next == "") then
						ending_e = true
					end
				end

				if table.HasValue( foreign, char:lower() ) then
					should_stop = 1
					was_special = true
					jd = true
					db( "should stop going 1, char is special" )
				elseif not ending_e and not was_special then
					db( "breaking loop, char isn't special" )
					break
				end
			end

			if lastchar ~= "" and lastchar:lower() ~= lastchar:upper() and -- lastchar defined and has lower/upper variants
				lastchar:lower() == lastchar and -- lastchar is in lower variant
				char:lower() ~= char:upper() and -- char has lower/upper variants
				char == char:upper() then -- char is in upper variant
				db( "lastchar is in lower variant with char in upper variant. casing separation. breaking.")
				break
			end

			curname = curname .. char
			lasttype = "vowel"
			lastchar = char
			db( "curname is now " .. curname )

			if was_special and not jd then break end

			vowel_count = vowel_count + 1
			if vowel_count >= 5 then
				db( "vowel count too high, breaking" )
				break
			end
		elseif tonumber( char ) then
			db( "char is num, ignoring" )
			continue
		else
			vowel_count = 0
			db( "char isn't vowel or num, assuming consonant" )

			if lastchar ~= "" and lastchar:lower() ~= lastchar:upper() and -- lastchar defined and has lower/upper variants
				lastchar:lower() == lastchar and -- lastchar is in lower variant
				char:lower() ~= char:upper() and -- char has lower/upper variants
				char == char:upper() then -- char is in upper variant
				db( "lastchar is in lower variant with char in upper variant. casing separation. breaking.")
				break
			end

			curname = curname .. char
			lasttype = "consonant"
			lastchar = char

			if was_special then break end
			db( "curname is now " .. curname )
			if should_stop == 1 then
				db( "should stop was 1, now 2" )
				should_stop = 2
			end

			if table.HasValue( foreign, char:lower() ) then
				was_special = true
			end

			consonant_count = consonant_count + 1
			if consonant_count >= 5 then
				db( "consonant count was over 5, breaking" )
				break
			end
		end
	end

	if curname == "" then curname = str:sub( 1, 5 ) end

	local replace = table.Random( names )
	replace = Format( replace[1], replace[2]( curname ) )

	return replace
end
