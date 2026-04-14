printl("November Master Script Enabled")

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
		printl("November Master Cleanup")

		EntFire("env_sun", "AddOutput", "rendercolor 251 226 200 400")
		EntFire("env_soundscape_proxy*", "Enable")
		SetSkyboxTexture("sky_november_01")

		for (local i = 1; i <= MaxPlayers; i++)
		{
			local Player = PlayerInstanceFromIndex(i)
			if (Player == null)
				continue

			SetPropString(Player, "m_iszScriptThinkFunction", "")
			SetPropInt(Player, "m_Local.m_skybox3d.fog.colorPrimary", MVMNovember_MasterScripting.RGBAToColor32(181, 114, 99, 255))
			SetPropInt(Player, "m_Local.m_fog.colorPrimary", MVMNovember_MasterScripting.RGBAToColor32(181, 114, 99, 255))
		}

		delete ::MVMNovember_MasterScripting
	}

	OnGameEvent_recalculate_holidays = function(_) { if (GetRoundState() == 3) Cleanup() }
    OnGameEvent_mvm_wave_complete = function(_) { Cleanup() }

	// Helper Function :)

	function RGBAToColor32(r, g, b, a)
	{
		return ((r) | (g << 8) | (b << 16) | (a << 24))
	}

	// Bot Tag Application Functions
	function OnGameEvent_player_spawn(params)
	{
		local Player = GetPlayerFromUserID(params.userid)

		if (Player.IsBotOfType(1337))
		{
			EntFireByHandle(Player, "RunScriptCode", "MVMNovember_MasterScripting.BotTagCheck()", 0.0, Player, null);
			return
		}
	}

	function BotTagCheck()
	{
		if(activator.HasBotTag("ChampionGiant"))
		{
			MVMNovember_MasterScripting.ChampionGiantLogic(activator)
		}
	}

	// Champion Giant Functions
	function ChampionGiantLogic(Target)
	{
		SendGlobalGameEvent("show_annotation", {
			id = "ChampionGiantWarning"
			text = "Champion Giant Active!"
			lifetime = 5
			follow_entindex = Target.entindex()
			play_sound = "mvm/mvm_warning.wav"
		})
	}

	// Master Mode Functions
	function OnGameEvent_teamplay_round_start(params)
	{
		if(params.full_reset)
		{
			for (local Ent = null; Ent = FindByClassname(Ent, "trigger_timer_door");)
			{
				local CapturePointName = GetPropString(Ent, "m_iszCapPointName")

				SetPropFloat(Ent, "m_flCapTime", 5)

				Ent.AcceptInput("SetControlPoint", CapturePointName, null, null)
			}
		}

	}

	function NovemberMasterInit()
	{
		if(FindByName(null, "november_master_champion_flagzone"))
		{
			return
		}

		local NovemberMasterChampionFlagZone = SpawnEntityFromTable("trigger_multiple",
		{
			targetname = "november_master_champion_flagzone"
			origin = "-160 -448.5 212"
			wait = 0.5
			spawnflags = 1

			"OnStartTouch" : "filter_champion_giant,TestActivator,,0,-1"
		})
		NovemberMasterChampionFlagZone.SetSize(Vector(-120, -120, -176), Vector(120, 120, 176))
		NovemberMasterChampionFlagZone.EnableDraw()
		NovemberMasterChampionFlagZone.SetSolid(SOLID_BBOX)

		if(FindByName(null, "filter_champion_giant"))
		{
			return
		}

		local NovemberMasterChampionFilter = SpawnEntityFromTable("filter_tf_bot_has_tag", {
			targetname = "filter_champion_giant"
			tags = "ChampionGiant"

			"OnPass" : "control_point,SetOwner,3,0,-1"
		})

		if(FindByName(null, "master_transition_shake"))
		{
			return
		}

		local NovemberMasterTransitionShake = SpawnEntityFromTable("env_shake", {
			targetname = "master_transition_shake"
			amplitude = 12
			duration = 1
			frequency = 40
			spawnflags = 5
		})

		if (FindByName(null, "master_transition_fade"))
		{
			return
		}

		local NovemberMasterTransitionFade = SpawnEntityFromTable("env_fade", {
			targetname = "master_transition_fade"
			duration = 3
			renderamt = 255
			rendercolor = "143 99 181"
			spawnflags = 1
		})
	}
	function NovemberMasterVoidInit()
	{
		printl("November Void Enabled")

		SetSkyboxTexture("sky_void_01")
		EntFire("env_sun", "AddOutput", "rendercolor 234 200 251 400")
		EntFire("env_soundscape_proxy*", "Disable")

		for (local i = 1; i <= MaxPlayers; i++)
		{
			local Player = PlayerInstanceFromIndex(i)
			if (Player == null)
				continue

			SetPropInt(Player, "m_Local.m_skybox3d.fog.colorPrimary", MVMNovember_MasterScripting.RGBAToColor32(143, 99, 181, 255))
			SetPropInt(Player, "m_Local.m_fog.colorPrimary", MVMNovember_MasterScripting.RGBAToColor32(143, 99, 181, 255))
			SetPropInt(Player, "m_Local.m_audio.soundscapeIndex", 153)
		}

		printl("November Void Success")
	}
}

__CollectGameEventCallbacks(MVMNovember_MasterScripting)