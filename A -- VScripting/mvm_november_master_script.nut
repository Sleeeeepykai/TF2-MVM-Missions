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
			SetPropInt(Player, "m_Local.m_skybox3d.fog.colorPrimary", 11891299)
			SetPropInt(Player, "m_Local.m_fog.colorPrimary", 11891299)
		}

		delete ::MVMNovember_MasterScripting
	}

	OnGameEvent_recalculate_holidays = function(_) { if (GetRoundState() == 3) Cleanup() }
    OnGameEvent_mvm_wave_complete = function(_) { Cleanup() }

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
	function OnGameEvent_player_death(params)
	{
		local Player = GetPlayerFromUserID(params.userid)

		if (Player.IsBotOfType(1337))
		{
			SetPropString(Player, "m_iszScriptThinkFunction", "")

			Player.ValidateScriptScope()
			local PlayerScope = Player.GetScriptScope()

			if( ("Wearables" in PlayerScope) )
			{
				foreach(Wearable in PlayerScope.Wearables)
				{
					Wearable.Kill()
				}
			}
		}

		for (local Entity; Entity = FindByClassnameWithin(Entity, "item_currencypack_*", Player.GetOrigin(), 100 );)
		{
			Entity.ValidateScriptScope()
			local EntityScope = Entity.GetScriptScope()
			EntityScope.RealOrigin <- Entity.GetOrigin()

			function CollectPack()
			{
				local MoneyPack = self

				if (!MoneyPack.IsValid())
				{
					return
				}
				if (GetPropBool(MoneyPack, "m_bDistributed"))
				{
					return
				}

				local MoneyOrigin = EntityScope.RealOrigin
				local MoneyOwner = GetPropEntity(MoneyPack, "m_hOwnerEntity")
				local MoneyModel = MoneyPack.GetModelName()

				local ObjectiveResource = FindByClassname(null, "tf_objective_resource")

				local OldCashCount = GetPropInt(ObjectiveResource, "m_nMvMWorldMoney")
				MoneyPack.Kill()
				local NewCashCount = GetPropInt(ObjectiveResource, "m_nMvMWorldMoney")

				local MoneyPackCurrencyCount = OldCashCount - NewCashCount

				local MVMStats = FindByClassname(null, "tf_mann_vs_machine_stats")
				SetPropInt(MVMStats, "m_currentWaveStats.nCreditsAcquired", GetPropInt(MVMStats, "m_currentWaveStats.nCreditsAcquired") + MoneyPackCurrencyCount)

				for (local i = 1; i <= MaxPlayers; i++)
				{
					local Player = PlayerInstanceFromIndex(i)
					if (Player && !Player.IsBotOfType(1337))
					{
						Player.AddCurrency(MoneyPackCurrencyCount)
					}
				}

				local RedMoneyPack = CreateByClassname("item_currencypack_custom")
				SetPropBool(RedMoneyPack, "m_bDistributed", true )
				SetPropEntity(RedMoneyPack, "m_hOwnerEntity", MoneyPack)
				DispatchSpawn(RedMoneyPack)
				RedMoneyPack.SetModel(MoneyModel)

				TraceWorld <-
				{
					start = MoneyOrigin,
					end = MoneyOrigin - Vector( 0, 0, 50000 )
					mask = MASK_SOLID_BRUSHONLY
				}
				TraceLineEx(TraceWorld)
				if (TraceWorld.hit)
				{
					RedMoneyPack.SetAbsOrigin(TraceWorld.pos + Vector( 0, 0, 5 ))
				}
				else
				{
					RedMoneyPack.SetAbsOrigin(MoneyOrigin)
				}

				EntityScope.DespawnTime <- Time() + 30
				function DespawnThink()
				{
					if ( Time() < DespawnTime )
					{
						return
					}

					RedMoneyPack.Kill()
				}
				AddThinkToEnt(RedMoneyPack, "DespawnThink")
			}
			EntityScope.CollectPack <- CollectPack

			Entity.SetAbsOrigin(Vector( -1000000, -1000000, -1000000 ))
			EntFireByHandle(Entity, "CallScriptFunction", "CollectPack", 0, null, null)
		}
	}

	function BotTagCheck()
	{
		if(activator.HasBotTag("ChampionGiant"))
		{
			MVMNovember_MasterScripting.ChampionGiantLogic(activator)
		}
	}

	// Cosmetic Application Functions
	function GivePlayerCosmetic(Player, ItemID, ModelPath = null)
	{
		local Weapon = CreateByClassname("tf_weapon_parachute")
		SetPropInt(Weapon, "m_AttributeManager.m_Item.m_iItemDefinitionIndex", 1101)
		SetPropBool(Weapon, "m_AttributeManager.m_Item.m_bInitialized", true)
		Weapon.SetTeam(Player.GetTeam())
		Weapon.DispatchSpawn()
		Player.Weapon_Equip(Weapon)
		local Wearable = GetPropEntity(Weapon, "m_hExtraWearable")
		Weapon.Kill()

		SetPropInt(Wearable, "m_AttributeManager.m_Item.m_iItemDefinitionIndex", ItemID)
		SetPropBool(Wearable, "m_AttributeManager.m_Item.m_bInitialized", true)
		SetPropBool(Wearable, "m_bValidatedAttachedEntity", true)
		Wearable.DispatchSpawn()

		// (optional) Set the model to something new. (Obeys econ's ragdoll physics when ragdolling as well)
		if (ModelPath)
			Wearable.SetModelSimple(ModelPath)

		// (optional) if one wants to delete the item entity, collect them within the player's scope, then send Kill() to the entities within the scope.
		Player.ValidateScriptScope()
		local PlayerScope = Player.GetScriptScope()
		if (!("Wearables" in PlayerScope))
			PlayerScope.Wearables <- []
		PlayerScope.Wearables.append(Wearable)

		return Wearable
	}

	// Champion Giant Functions
	function ChampionGiantLogic(Target)
	{
		GivePlayerCosmetic(Target, 342, "models/player/items/demo/crown.mdl")
		GivePlayerCosmetic(Target, 30517, "models/workshop/player/items/demo/sf14_deadking_pauldrons/sf14_deadking_pauldrons.mdl")

		SetPropBool(Target, "m_bGlowEnabled", true)

		SendGlobalGameEvent("show_annotation", {
			id = "ChampionGiantWarning"
			text = "Champion Giant Active!"
			lifetime = 4
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

				SetPropFloat(Ent, "m_flCapTime", 10)

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

			SetPropInt(Player, "m_Local.m_skybox3d.fog.colorPrimary", 9397173)
			SetPropInt(Player, "m_Local.m_fog.colorPrimary", 9397173)
			SetPropInt(Player, "m_Local.m_audio.soundscapeIndex", 153)
		}

		for (local Soundscape; Soundscape = FindByClassname(Soundscape, "env_soundscape");)
		{
			printl(Soundscape)
			Soundscape.KeyValueFromString("soundscape", "November.Void")
			Soundscape.DispatchSpawn()
		}

		printl("November Void Success")
	}

}

__CollectGameEventCallbacks(MVMNovember_MasterScripting)