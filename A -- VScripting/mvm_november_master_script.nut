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

::MVMNovember_MasterScripting <-
{
	// Cleanup Functions
	function Cleanup()
	{
		for (local i = 1; i <= MaxPlayers; i++)
		{
			local Player = PlayerInstanceFromIndex(i)
			if (Player == null)
				continue

			SetPropString(Player, "m_iszScriptThinkFunction", "")
		}

		delete ::MVMNovember_MasterScripting
	}

	OnGameEvent_recalculate_holidays = function(_) { if (GetRoundState() == 3) Cleanup() }

	// Master Init Functions
	function NovemberMasterInit()
	{
		EntFire("control_point_area", "AddOutput", "area_time_to_cap 10")

		if(FindByName(null, "november_master_champion_flagzone"))
		{
			return
		}

		local NovemberMasterChampionFlagZone = SpawnEntityFromTable("trigger_multiple",
		{
			targetname = "november_master_champion_flagzone"
			origin = "-160 -448.5 336"
			filtername = "filter_champion_giant"
			wait = 0.5
			spawnflags = 1

			"OnStartTouch" : "control_point_area,CaptureCurrentCP,null,0,-1"
		})
		NovemberMasterChampionFlagZone.SetSize(Vector(-120, -120, -176), Vector(120, 120, 176))

		if(FindByName(null, "filter_champion_giant"))
		{
			return
		}

		local NovemberMasterChampionFilter = SpawnEntityFromTable("filter_tf_bot_has_tag", {
			targetname = "filter_champion_giant"
			tags = "ChampionGiant"
		})
	}

	// Bot Tag Application Functions
	OnGameEvent_player_spawn = function(params)
	{
		local Player = GetPlayerFromUserID(params.userid)

		if (Player.IsBotOfType(1337))
		{
			EntFireByHandle(Player, "RunScriptCode", "MVMNovember_MasterScripting.BotTagCheck()", 0.0, Player, null);
			return
		}
	}
	OnGameEvent_player_death = function(params)
	{
		local Player = GetPlayerFromUserID(params.userid)

		if (Player.IsBotOfType(1337))
		{
			SetPropString(Player, "m_iszScriptThinkFunction", "")
		}
	}

	function BotTagCheck()
	{
		if(activator.HasBotTag("ChampionGiant"))
		{
			MVMNovember_MasterScripting.ChampionGiantLogic(activator)
		}
	}

	function ChampionGiantLogic(Target)
	{
		SetPropBool(Target, "m_bGlowEnabled", true)

		SendGlobalGameEvent("show_annotation", {
			id = "ChampionGiantWarning"
			text = "Champion Giant Active!"
			lifetime = 5
			follow_entindex = Target
			play_sound = "mvm/mvm_warning.wav"
		})
	}
}