local groups = {
	"superadmin",
	"owner",
	"godzilla",
}
local function canSaveShit( user )
	return IsValid( user ) and table.HasValue( groups, user:GetUserGroup() ) or false
end

local saved_data = {}
local function saveEnt( ent )
	if not saved_data[ game.GetMap() ] then saved_data[ game.GetMap() ] = {} end

	local t = {
		class = ent:GetClass(),
		pos = ent:GetPos(),
		ang = ent:GetAngles(),
		mtype = ent:GetMoveType(),
		model = ent:GetModel(),
	}

	table.insert( saved_data[ game.GetMap() ], t )
	file.Write( "saved_ents.txt", util.TableToJSON( saved_data ) )

	return true
end

local function removeEnt( ent )
	if not saved_data[ game.GetMap() ] then return false end

	local data = ent._estag
	if not data then return false end

	for k, v in pairs( saved_data[ game.GetMap() ] ) do
		if v.class == data.class
			and v.pos == data.pos
			and v.ang == data.ang
			and v.mtype == data.mtype
			and v.model == data.model then

			table.remove( saved_data[ game.GetMap() ], k )
			file.Write( "saved_ents.txt", util.TableToJSON( saved_data ) )
			return true
		end
	end

	return false
end

local function loadEnts()
	local data = saved_data[ game.GetMap() ]
	if not data then return end

	for k, v in pairs( data ) do
		local e = ents.Create( v.class )
		e:SetPos( v.pos )
		e:SetAngles( v.ang )
		e:SetMoveType( v.mtype )
		if v.class:Left( #"prop_" ) == "prop_" then
			e:SetModel( v.model )
		end
		e:Spawn()

		e._estag = v
	end
end

local function loadData()
	if not file.Exists( "saved_ents.txt", "DATA" ) then return end

	local data = util.JSONToTable( file.Read( "saved_ents.txt", "DATA" ) )
	saved_data = data
end
loadData()

game._oldClean = game._oldClean or game.CleanUpMap
function game.CleanUpMap( ... )
	game._oldClean( ... )

	loadEnts()
end

-- commands

concommand.Add( "es_save", function( ply )
	if not canSaveShit( ply ) then return end

	local ent = ply:GetEyeTrace().Entity
	if not IsValid( ent )
		or ent == game.GetWorld()
		or ent:IsPlayer() then
		ply:ChatPrint( "You cannot save this entity!" )
		return
	end

	saveEnt( ent )
	ply:ChatPrint( "Entity saved!" )
end )

concommand.Add( "es_remove", function( ply )
	if not canSaveShit( ply ) then return end

	local ent = ply:GetEyeTrace().Entity
	if not IsValid( ent ) or not ent._estag then
		ply:ChatPrint( "This entity was not autospawned!" )
		return
	end

	local worked = removeEnt( ent )
	if worked then ply:ChatPrint( "Entity removed!" ) return end
	ply:ChatPrint( "Entity removal failed!" )
end )
