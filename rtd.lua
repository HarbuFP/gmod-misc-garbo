local RATE_COMMON, RATE_UNCOMMON, RATE_RARE, RATE_OMG = 1, 2, 3, 4
local function isTTT() return string.find( string.lower(gmod.GetGamemode().Name), "trouble in terrorist town" ) end
local function _notify( ply, str ) if ply.PS_Notify then ply:PS_Notify( "(RTD) " .. str ) else ply:PrintMessage( 3, "(RTD) " .. str ) end end
local function doNotify( ply, str ) if type( ply ) == "string" then for k,v in pairs(player.GetAll()) do _notify( v, ply ) end else if IsValid( ply ) then _notify( ply, str ) end end end
local rtd_items = {
	[RATE_COMMON] = {},
	[RATE_UNCOMMON] = {},
	[RATE_RARE] = {},
	[RATE_OMG] = {}
}

local function addItem( rate, func, exists )
	local count = #rtd_items[ rate ]
	rtd_items[ rate ][ count + 1 ] = { ["func"] = func, ["should_exist"] = exists or function() return true end }
end

local function doItem( ply, rarity )
	for k, v in RandomPairs( rtd_items[rarity] ) do
		if v.should_exist( ply ) then
			v.func( ply )
			return true
		end
	end

	if rarity == RATE_COMMON then
		doNotify( ply, "Unable to find proper item. Notify the person who set this up, they clearly did it wrong." )
		return
	end

	return doItem( ply, rarity - 1 )
end

local function doRTD( ply )
	if not IsValid( ply ) or not ply:Alive() or ply:Team() == TEAM_SPECTATOR then if IsValid( ply ) then doNotify( ply, "You need to be alive to roll the dice!" ) end return end
	if ply._countRTD and ply._countRTD < 1 then doNotify( ply, "You cannot roll the dice at this time." ) return end
	if maghazia then
		if not maghazia:IsEnabled( ply, "upgrade_rtd" ) then
			doNotify( ply, "You must own the \"RTD Access\" upgrade in the PointShop to use this! Press F4 to open it." )
			return
		end
	end
	if GetRoundState then
		if GetRoundState() ~= ROUND_ACTIVE then
			doNotify( ply, "You may only roll the dice during an active round." )
			return
		end
	end

	local rand = math.random( 1, 100 )
	if rand == 100 then
		doItem( ply, RATE_OMG )
	elseif rand >= 84 then
		doItem( ply, RATE_RARE )
	elseif rand >=50 then
		doItem( ply, RATE_UNCOMMON )
	else
		doItem( ply, RATE_COMMON )
	end

	ply._countRTD = ply._countRTD and ply._countRTD - 1 or 0
end

hook.Add( "PlayerSpawn", "RTD :: Enabling", function( ply )
	ply._countRTD = 1
end )

concommand.Add( "rtd", doRTD )
hook.Add( "PlayerSay", "RTD :: Chat Cmd", function( ply, t )
	local lower = string.lower( t )
	if lower == "rtd" or lower == "/rtd" or lower == "!rtd" or lower == "!temptfate" or lower == "/temptfate" then
		doRTD( ply )
		return ""
	end
end )

-- DEFINE ITEMS BELOW HERE
-- DEFINE ITEMS BELOW HERE
-- DEFINE ITEMS BELOW HERE
local rand = math.random

addItem( RATE_COMMON, function( ply )
	ply:SetColor( Color( rand( 0, 255 ), rand( 0, 255 ), rand( 0, 255 ), 255 ) )
	doNotify( ply:Nick() .. " had his color changed!" )
end, function( ply ) end )

addItem( RATE_COMMON, function( ply )
	ply._rtd_orikol = ply:GetColor()

	ply:Freeze( true )
	ply:SetColor( Color( 0, 0, 255, 255 ) )
	ply:EmitSound( "physics/glass/glass_sheet_break1.wav" )

	doNotify( ply:Nick() .. " has been frozen for 15 seconds!" )
	timer.Simple( 15, function()
		if not IsValid( ply ) then return end
		if ply:Alive() and ply:Team() ~= TEAM_SPECTATOR then doNotify( ply:Nick() .. " has been unfrozen." ) end

		ply:Freeze( false )
		ply:SetColor( ply._rtd_orikol or Color( 255, 255, 255, 255 ) )
	end )
end )

addItem( RATE_COMMON, function( ply )
	ply:Give( "weapon_ttt_health_station" )

	doNotify( ply:Nick() .. " has just received a health station!" )
	doNotify( ply, "If you did not have an item in Slot 7, you will have received a health station." )
end, isTTT )

addItem( RATE_COMMON, function( ply )
	ply:StripWeapons()
	ply:Give("weapon_zm_improvised")
	ply:Give("weapon_zm_carry")
	ply:Give("weapon_ttt_unarmed")
	ply:Give("weapon_zm_mac10")
	ply:Give("weapon_zm_revolver")

	doNotify( ply:Nick() .. " just received some new guns!" )
end, isTTT )

addItem( RATE_COMMON, function( ply )
	if ply:GetMoveType() == MOVETYPE_NOCLIP then
		ply:SetMoveType( MOVETYPE_WALK )
	end

	ply:SetVelocity(Vector(0, 0, 9999))
	timer.Simple(3, function()
		if not IsValid( ply ) or not ply:Alive() or ply:Team() == TEAM_SPECTATOR then return end

		local exp = ents.Create("env_explosion")
		exp:SetPos( ply:GetPos() )
		exp:Spawn()
		exp:Fire( "Explode", 0, 0 )
		ply:Kill()
	end )

	if ply.mTrail and IsValid( ply.mTrail ) then ply.mTrail:Remove() end
	if ply.Trail and IsValid( ply.Trail ) then ply.Trail:Remove() end
	
	ply.mTrail = util.SpriteTrail( ply, 0, Color(255, 255, 255, 255), false, 15, 1, 4, 0.125, "trails/smoke.vmt" )
	ply.mTrailID = nil
	ply.TrailID = nil

	doNotify( ply:Nick() .. " wanted to be a Rocket Man!" )
end )

addItem( RATE_COMMON, function( ply )
	ply:EmitSound("npc/fast_zombie/fz_scream1.wav", 500, 20)
	ply:EmitSound("npc/fast_zombie/fz_scream1.wav", 500, 30)
	ply:EmitSound("npc/fast_zombie/fz_scream1.wav", 500, 40)
	ply:EmitSound("npc/fast_zombie/fz_scream1.wav", 500, 50)
	ply:EmitSound("npc/fast_zombie/fz_scream1.wav", 500, 60)
	ply:EmitSound("npc/fast_zombie/fz_scream1.wav", 500, 70)
	ply:EmitSound("npc/fast_zombie/fz_scream1.wav", 500, 80)
	ply:EmitSound("npc/fast_zombie/fz_scream1.wav", 500, 90)

	doNotify( ply:Nick() .. " doesn't like surprises." )
end )

-- Uncommon items

addItem( RATE_UNCOMMON, function( ply )
	ply:Give("weapon_ttt_wtester")

	doNotify( ply:Nick() .. " found a DNA scanner!" )
end, isTTT )

addItem( RATE_UNCOMMON, function( ply )
	ply:Freeze( true )
	ply:SetColor( Color( 255, 0, 0, 255 ) )
	
	local jail = ents.Create("prop_physics")
	jail.was_pushed = {att=ply, t=CurTime()}
	jail:SetModel( "models/props_junk/TrashDumpster02.mdl" )
	jail:SetPos( ply:GetPos() + Vector(0, 0, 60) )
	jail:SetAngles( Angle(0, 0, 180) )
	jail:SetMoveType( MOVETYPE_NONE )

	jail:Spawn()
	jail:Activate()
	jail:SetRenderMode(1)
	jail:SetColor( Color( 255, 0, 0, 100 ) )

	local phys = jail:GetPhysicsObject()
	if IsValid( phys ) then
		phys:EnableMotion( false )
	end

	doNotify( ply:Nick() .. " was arrested (for the next 15 seconds)!" )
	
	timer.Simple( 15, function()
		if IsValid( ply ) then
			ply:Freeze( false )
			ply:SetColor( Color( 255, 255, 255, 255) )

			if ply:Alive() and ply:Team() ~= TEAM_SPECTATOR then
				doNotify( ply:Nick() .. " has been released from his personal jail!" )
			end
		end
		
		if IsValid( jail ) then	
			jail:Remove()
		end
	end)
end )

addItem( RATE_UNCOMMON, function( ply )
	if ply:GetMoveType() == MOVETYPE_NOCLIP then
		ply:SetMoveType(MOVETYPE_WALK)
	end

	local models = {
		"models/props_c17/FurnitureWashingmachine001a.mdl",
		"models/props_wasteland/rockcliff_cluster02a.mdl",
		"models/props_wasteland/rockcliff05f.mdl",
		"models/props_wasteland/rockcliff_cluster03c.mdl",
		"models/props_junk/TrashDumpster02.mdl",
		"models/props_wasteland/cargo_container01.mdl",
		"models/props_wasteland/laundry_dryer002.mdl",
	}
	
	local ent = ents.Create("prop_physics")
	ent.was_pushed = { att=ply, t=CurTime() }
	ent:SetModel( table.Random(models) )
	ent:SetPos( ply:GetPos()+Vector(0, 0, 500) )
	ent:Spawn()
	
	phys = ent:GetPhysicsObject()
	phys:SetMass(999)
	ent:SetVelocity(Vector(0, 0, -999))

	doNotify( ply:Nick() .. " has to think fast!" )	
	timer.Simple(6, function()
		if IsValid( ent ) then
			ent:Remove()
		end
	end)
end )

-- Rare items.

addItem( RATE_RARE, function( ply )
	local wep = ply:GetActiveWeapon()

	if IsValid( wep ) then
		TTTRPG:SetLevel( ply:GetActiveWeapon(), 10 )
	end
	doNotify( ply:Nick() .. " just had his weapon set to level 10!" )
end, function( ply )
	return IsValid( ply:GetActiveWeapon() ) and TTTRPG
end )

addItem( RATE_RARE, function( ply )
	ply:SetHealth( ply:Health() + 100 )

	doNotify( ply:Nick() .. " just received 100HP!" )
end )

addItem( RATE_RARE, function( ply )
	ply:Ignite( 15, 0 )

	doNotify( ply:Nick() .. " has just been set on fire for the next 15 seconds!" )
end )

addItem( RATE_RARE, function( ply )
	ply:PS_GivePoints( 5 )

	doNotify( ply:Nick() .. " won 5 points!" )
end, function( ply ) return ply.PS_GivePoints and true or false end )

-- Very rare items.

addItem( RATE_OMG, function( ply )
	ply:Kill()

	doNotify( ply:Nick() .. " had discovered the meaning of life and was no longer able to continue." )
end )

addItem( RATE_OMG, function( ply )
	ply:PS_GivePoints( 50 )

	doNotify( ply:Nick() .. " won 50 points!" )
end, function( ply ) return ply.PS_GivePoints and true or false end )

addItem( RATE_OMG, function( ply )
	local item = maghazia.GetItemFromName( "Max" )
	if not item then return end -- redundancy, woo!

	ply:AddHat( item.ID, nil, nil, true ) -- ( id, particle_to_add, is_disguiser_hat, can_be_dropped )

	doNotify( ply:Nick() .. " put on a \"Max\" hat!" )
end, function( ply )
	if maghazia then
		local item = maghazia.GetItemFromName( "Max" )
		if not item then return false end

		return ply:IsHatOn( item.ID )
	end
	return false
end )

addItem( RATE_OMG, function( ply )
	local item = maghazia.GetItemFromName( "octo-booty" )
	if not item then return end -- redundancy, woo!

	ply:AddHat( item.ID, nil, nil, true ) -- ( id, particle_to_add, is_disguiser_hat, can_be_dropped )

	doNotify( ply:Nick() .. " put on an \"Octo-Booty\" hat!" )
end, function( ply )
	if not ply:IsUserGroup( "vip" ) and not ply:IsUserGroup( "operator" ) and not ply:IsAdmin() then return false end
	if maghazia then
		local item = maghazia.GetItemFromName( "octo-booty" )
		if not item then return false end

		return ply:IsHatOn( item.ID )
	end
	return false
end )
