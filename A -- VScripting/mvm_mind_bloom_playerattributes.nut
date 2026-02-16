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

::BossRush_PlayerAttributes <-
{
	// Cleanup Functions
	function Cleanup()
	{
		delete ::BossRush_PlayerAttributes
	}

	OnGameEvent_recalculate_holidays = function(_) { if (GetRoundState() == GR_STATE_PREROUND) Cleanup() }

	OnGameEvent_player_spawn = function (params)
	{
		local Player = GetPlayerFromUserID(params.userid)

		if (!Player.IsBotOfType(1337) && (Player.GetTeam()) == 0)
		{
			Player.ValidateScriptScope()
			local PlayerScope = Player.GetScriptScope()

			PlayerScope.MaxHealthMult <- 2
		}
		if (!Player.IsBotOfType(1337) && (Player.GetTeam()) == 2)
		{
			EntFireByHandle(Player, "RunScriptCode", "BossRush_PlayerAttributes.PlayerHealthInit(activator)", 0.0, Player, null);
		}
	}
	OnGameEvent_player_death = function (params)
	{
		local Player = GetPlayerFromUserID(params.userid)

		if (!Player.IsBotOfType(1337) && (Player.GetTeam()) == 2)
		{
			Player.ValidateScriptScope()
			local PlayerScope = Player.GetScriptScope()

			if(GetRoundState() != GR_STATE_RND_RUNNING)
				return

			if("MaxHealthMult" in PlayerScope)
			{
				PlayerScope.MaxHealthMult -= 0.4

				if(PlayerScope.MaxHealthMult < 0)
				{
					PlayerScope.MaxHealthMult = 0
				}
			}
		}
	}
	OnGameEvent_mvm_wave_complete = function (params)
	{
		for (local i = 1; i <= MaxPlayers; i++)
		{
			local Player = PlayerInstanceFromIndex(i)
			if (!Player.IsBotOfType(1337) && (Player.GetTeam()) == 2)
			{
				PlayerScope.MaxHealthMult = 2
				BossRush_PlayerAttributes.PlayerHealthInit(Player)
			}
		}
	}

	function PlayerHealthInit(Player)
	{
		local PlayerClass = Player.GetPlayerClass()
		local PlayerScope = Player.GetScriptScope()

		switch(PlayerClass)
		{
			case TF_CLASS_SCOUT:
				Target.AddCustomAttribute("max health additive bonus", (125 * PlayerScope.MaxHealthMult), -1)
				Target.SetHealth(125 * PlayerScope.MaxHealthMult)
				break
			case TF_CLASS_SOLDIER:
				Target.AddCustomAttribute("max health additive bonus", (200 * PlayerScope.MaxHealthMult), -1)
				Target.SetHealth(200 * PlayerScope.MaxHealthMult)
				break
			case TF_CLASS_PYRO:
				Target.AddCustomAttribute("max health additive bonus", (175 * PlayerScope.MaxHealthMult), -1)
				Target.SetHealth(175 * PlayerScope.MaxHealthMult)
				break
			case TF_CLASS_DEMOMAN:
				Target.AddCustomAttribute("max health additive bonus", (175 * PlayerScope.MaxHealthMult), -1)
				Target.SetHealth(175 * PlayerScope.MaxHealthMult)
				break
			case TF_CLASS_HEAVYWEAPONS:
				Target.AddCustomAttribute("max health additive bonus", (300 * PlayerScope.MaxHealthMult), -1)
				Target.SetHealth(300 * PlayerScope.MaxHealthMult)
				break
			case TF_CLASS_ENGINEER:
				Target.AddCustomAttribute("max health additive bonus", (125 * PlayerScope.MaxHealthMult), -1)
				Target.SetHealth(125 * PlayerScope.MaxHealthMult)
				break
			case TF_CLASS_MEDIC:
				Target.AddCustomAttribute("max health additive bonus", (150 * PlayerScope.MaxHealthMult), -1)
				Target.SetHealth(150 * PlayerScope.MaxHealthMult)
				break
			case TF_CLASS_SNIPER:
				Target.AddCustomAttribute("max health additive bonus", (125 * PlayerScope.MaxHealthMult), -1)
				Target.SetHealth(125 * PlayerScope.MaxHealthMult)
				break
			case TF_CLASS_SPY:
				Target.AddCustomAttribute("max health additive bonus", (125 * PlayerScope.MaxHealthMult), -1)
				Target.SetHealth(125 * PlayerScope.MaxHealthMult)
				break
			default:
				printl("Invalid Class")
				break
		}
	}
}

__CollectGameEventCallbacks(BossRush_PlayerAttributes)