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

::MaxPlayers <- MaxClients().tointeger()

::MVMAnimosity_ArenaMode <-
{
	// Cleanup Functions
	function Cleanup()
    {
		for (local i = 1; i <= MaxPlayers; i++)
		{
			local player = PlayerInstanceFromIndex(i)
			NetProps.SetPropString(player, "m_iszScriptThinkFunction", "")
		}
        delete ::MVMAnimosity_ArenaMode
    }
    OnGameEvent_recalculate_holidays = function(_) { if (GetRoundState() == 3) Cleanup() }
	OnGameEvent_mvm_wave_complete = function(_) { Cleanup() }

	// Search Functions
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

	function GetPlayerName(player)
	{
		return NetProps.GetPropString(player, "m_szNetname")
	}

	// Bot Tags
	function BotTagCheck()
	{
		if(activator.HasBotTag("FriendlyBot"))
		{
			MVMAnimosity_ArenaMode.ArenaFriendlyBot(activator)
		}
		if(activator.HasBotTag("Glow"))
		{
			MVMAnimosity_ArenaMode.BotGlow(activator)
		}
	}

	function ArenaFriendlyBot(target)
	{
		target.ForceChangeTeam( TF_TEAM_PVE_DEFENDERS, false )
		target.AddCustomAttribute( "ammo regen", 999.0, -1 )
	}
	function BotGlow(target)
	{
		NetProps.SetPropBool(target, "m_bGlowEnabled", true)
	}

	// Bot Manipulation Functions
	function RemoveRobot(target)
	{
		local PlayerTarget
		for (local i = 1; i <= MaxPlayers; i++)
		{
			local player = PlayerInstanceFromIndex(i)
			if (player == null)
				continue
			if (GetPlayerName(player) == target)
			{
				PlayerTarget = player;
				break;
			}
		}

		PlayerTarget.TakeDamage(999999, 1, null)
		PlayerTarget.ForceChangeTeam(TEAM_SPECTATOR, true)
	}
}

__CollectGameEventCallbacks(MVMAnimosity_ArenaMode)