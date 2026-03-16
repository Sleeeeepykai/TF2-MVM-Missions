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

::BossRush_PlayerAttributes <-
{
	// Cleanup Functions
	function Cleanup()
	{
		for (local i = 1; i <= MaxPlayers; i++)
		{
			local Player = PlayerInstanceFromIndex(i)
			if (Player == null)
				continue

			if ((Player.GetTeam()) == 2)
			{
				Player.TerminateScriptScope()
			}
		}
		delete ::BossRush_PlayerAttributes
	}

	OnGameEvent_recalculate_holidays = function(_) { if (GetRoundState() == GR_STATE_PREROUND) Cleanup() }

	OnGameEvent_post_inventory_application = function (params)
	{
		local Player = GetPlayerFromUserID(params.userid)
		printl("its real")

		if ((Player.GetTeam()) == 2)
		{
			Player.ValidateScriptScope()
			local PlayerScope = Player.GetScriptScope()
			printl("the scope is real")

			if (!("MaxHealthMult" in PlayerScope))
			{
				PlayerScope.MaxHealthMult <- 2
				PlayerScope.CurrentHealthMult <- 3
			}

			EntFireByHandle(Player, "RunScriptCode", "BossRush_PlayerAttributes.PlayerHealthInit(activator)", 0.0, Player, null)
			printl("the thing is real")
		}
	}
	OnGameEvent_player_death = function (params)
	{
		local Player = GetPlayerFromUserID(params.userid)

		if ((Player.GetTeam()) == 2)
		{
			Player.ValidateScriptScope()
			local PlayerScope = Player.GetScriptScope()

			if(GetRoundState() != GR_STATE_RND_RUNNING)
				return

			if("MaxHealthMult" in PlayerScope)
			{
				PlayerScope.MaxHealthMult -= 0.4
				PlayerScope.CurrentHealthMult -= 0.4

				if(PlayerScope.MaxHealthMult < 0)
				{
					PlayerScope.MaxHealthMult = 0
				}
				if(PlayerScope.CurrentHealthMult < 1)
				{
					PlayerScope.CurrentHealthMult = 1
				}
			}
		}
	}
	OnGameEvent_mvm_wave_complete = function (params)
	{
		for (local i = 1; i <= MaxPlayers; i++)
		{
			local Player = PlayerInstanceFromIndex(i)

			if (Player == null)
				continue

			if ((Player.GetTeam()) == 2)
			{
				Player.ValidateScriptScope()
				local PlayerScope = Player.GetScriptScope()

				PlayerScope.MaxHealthMult <- 2
				PlayerScope.CurrentHealthMult <- 3

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
				Player.AddCustomAttribute("max health additive bonus", 125 * PlayerScope.MaxHealthMult, -1)
				Player.SetHealth(125 * PlayerScope.CurrentHealthMult)
				break
			case TF_CLASS_SOLDIER:
				Player.AddCustomAttribute("max health additive bonus", 200 * PlayerScope.MaxHealthMult, -1)
				Player.SetHealth(200 * PlayerScope.CurrentHealthMult)
				break
			case TF_CLASS_PYRO:
				Player.AddCustomAttribute("max health additive bonus", 175 * PlayerScope.MaxHealthMult, -1)
				Player.SetHealth(175 * PlayerScope.CurrentHealthMult)
				break
			case TF_CLASS_DEMOMAN:
				Player.AddCustomAttribute("max health additive bonus", 175 * PlayerScope.MaxHealthMult, -1)
				Player.SetHealth(175 * PlayerScope.CurrentHealthMult)
				break
			case TF_CLASS_HEAVYWEAPONS:
				Player.AddCustomAttribute("max health additive bonus", 300 * PlayerScope.MaxHealthMult, -1)
				Player.SetHealth(300 * PlayerScope.CurrentHealthMult)
				break
			case TF_CLASS_ENGINEER:
				Player.AddCustomAttribute("max health additive bonus", 125 * PlayerScope.MaxHealthMult, -1)
				Player.SetHealth(125 * PlayerScope.CurrentHealthMult)
				break
			case TF_CLASS_MEDIC:
				Player.AddCustomAttribute("max health additive bonus", 150 * PlayerScope.MaxHealthMult, -1)
				Player.SetHealth(150 * PlayerScope.CurrentHealthMult)
				break
			case TF_CLASS_SNIPER:
				Player.AddCustomAttribute("max health additive bonus", 125 * PlayerScope.MaxHealthMult, -1)
				Player.SetHealth(125 * PlayerScope.CurrentHealthMult)
				break
			case TF_CLASS_SPY:
				Player.AddCustomAttribute("max health additive bonus", 125 * PlayerScope.MaxHealthMult, -1)
				Player.SetHealth(125 * PlayerScope.CurrentHealthMult)
				break
			default:
				printl("Invalid Class")
				break
		}
	}
}

for (local i = 1; i <= MaxPlayers; i++)
{
	local Player = PlayerInstanceFromIndex(i)

	if (Player == null)
		continue

	if ((Player.GetTeam()) == 2)
	{
		Player.ValidateScriptScope()
		local PlayerScope = Player.GetScriptScope()

		if (!("MaxHealthMult" in PlayerScope))
		{
			PlayerScope.MaxHealthMult <- 2
			PlayerScope.CurrentHealthMult <- 3
		}

		EntFireByHandle(Player, "RunScriptCode", "BossRush_PlayerAttributes.PlayerHealthInit(activator)", 0.0, Player, null)
	}
}

__CollectGameEventCallbacks(BossRush_PlayerAttributes)