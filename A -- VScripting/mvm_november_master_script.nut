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
			lifetime = 5
			follow_entindex = Target.entindex()
			play_sound = "mvm/mvm_warning.wav"
		})
	}

	// Master Mode Functions
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
	}
}

__CollectGameEventCallbacks(MVMNovember_MasterScripting)