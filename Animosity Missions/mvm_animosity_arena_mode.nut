printl("Animosity Arena Mode Script Enabled")

::CONST <- getconsttable()
::ROOT <- getroottable()

// Classes Folding
foreach( _class in [ "NetProps", "Entities", "EntityOutputs", "NavMesh", "Convars" ] )
	foreach( k, v in ROOT[_class].getclass() )
		if ( !( k in ROOT ) && k != "IsValid" )
			ROOT[k] <- ROOT[_class][k].bindenv( ROOT[_class] )

// Constants Folding
if (!("ConstantNamingConvention" in ROOT)) // make sure folding is only done once
{
	foreach (enum_table in Constants)
	{
		foreach (name, value in enum_table)
		{
			if (value == null)
				value = 0

			CONST[name] <- value
			ROOT[name] <- value
		}
	}
}

::MVMAnimosity_ArenaMode <-
{
	function Cleanup()
    {
		for ( local player; player = Entities.FindByClassname( player, "player" ); ) {
			NetProps.SetPropString(player, "m_iszScriptThinkFunction", "")
		}
        delete ::MVMAnimosity_ArenaMode
    }
    OnGameEvent_recalculate_holidays = function(_) { if (GetRoundState() == 3) Cleanup() }
	OnGameEvent_mvm_wave_complete = function(_) { Cleanup() }

	OnGameEvent_player_spawn = function(params)
	{
		local player = GetPlayerFromUserID(params.userid)

		if (player.IsBotOfType(1337)) { EntFireByHandle(player, "RunScriptCode", "MVMAnimosity_ArenaMode.BotTagCheck()", -1.0, player, null); return }

		if (player.GetScriptScope() == null) player.ValidateScriptScope()

		local scope = player.GetScriptScope()
	}
	OnGameEvent_player_death = function(params)
	{
		local player = GetPlayerFromUserID(params.userid)

		NetProps.SetPropString(player, "m_iszScriptThinkFunction", "")
	}

	function BotTagCheck()
	{
		if(activator.HasBotTag("BombHolder"))
		{
			MVMAnimosity_ArenaMode.ArenaBombHolder(activator, null)
		}
	}

	function ArenaBombHolder(target)
	{
		target.ValidateScriptScope()
		local scope = target.GetScriptScope()

		local bomb = GetPropEntity( bot, "m_hItem" )

		NetProps.SetPropBool(bomb, "m_bGlowEnabled", false)
	}
}

__CollectGameEventCallbacks(MVMAnimosity_ArenaMode)