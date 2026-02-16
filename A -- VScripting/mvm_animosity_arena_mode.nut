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
		SetValue("tf_bot_flag_escort_max_count", 4)

		EntFire("point_commentary_node*", "Kill", null, 0.0, null)

		for (local i = 1; i <= MaxPlayers; i++)
		{
			local Player = PlayerInstanceFromIndex(i)
			if (Player && Player.IsAlive() && Player.IsBotOfType(1337) && (Player.GetTeam()) == 2)
			{
				Player.ForceChangeTeam(TEAM_SPECTATOR, false)
			}
		}

        delete ::MVMAnimosity_ArenaMode
    }
    OnGameEvent_recalculate_holidays = function(_) { if (GetRoundState() == 3) Cleanup() }

	function SetDestroyCallback(entity, callback)
    {
        entity.ValidateScriptScope();
        local scope = entity.GetScriptScope();
        scope.setdelegate({}.setdelegate({
                parent   = scope.getdelegate()
                id       = entity.GetScriptId()
                index    = entity.entindex()
                callback = callback
                _get = function(k)
                {
                    return parent[k];
                }
                _delslot = function(k)
                {
                    if (k == id)
                    {
                        entity = EntIndexToHScript(index);
                        local scope = entity.GetScriptScope();
                        scope.self <- entity;
                        callback.pcall(scope);
                    }
                    delete parent[k];
                }
            })
        );
    }

	// Search Functions
	OnGameEvent_player_spawn = function(params)
	{
		local Player = GetPlayerFromUserID(params.userid)

		if (Player.IsBotOfType(1337))
		{
			// Will only work with 1 RED Robot Present
			if ( (Player.GetTeam()) == 2 )
			{
				EntFireByHandle(Player, "RunScriptCode", "MVMAnimosity_ArenaMode.ArenaVIPObjectiveInit(activator)", 0.0, Player, null);
				MVMAnimosity_ArenaMode.ArenaVIPReadyUp(Player.GetEntityIndex())
				return
			}
			EntFireByHandle(Player, "RunScriptCode", "MVMAnimosity_ArenaMode.BotTagCheck()", 0.0, Player, null);
			return
		}
	}
	OnGameEvent_player_death = function(params)
	{
		local Player = GetPlayerFromUserID(params.userid)

		if(Player && Player.IsAlive() && Player.IsBotOfType(1337) && (Player.GetTeam()) == 2)
		{
			MVMAnimosity_ArenaMode.ArenaVIPLoss()
			Player.ForceChangeTeam(TEAM_SPECTATOR, false)
			return
		}
	}

	OnGameEvent_mvm_begin_wave = function (params)
	{
		if(FindByName(null, "arena_mode_commentary_node"))
			return

		local ObjectiveCommNode = SpawnEntityFromTable("point_commentary_node",
		{
			targetname = "arena_mode_commentary_node"
		})
	}
	OnGameEvent_mvm_wave_complete = function(params)
	{
		EntFire("point_commentary_node*", "Kill", null, 0.0, null)

		for (local i = 1; i <= MaxPlayers; i++)
		{
			local Player = PlayerInstanceFromIndex(i)
			if (Player && Player.IsAlive() && Player.IsBotOfType(1337) && (Player.GetTeam()) == 2)
			{
				EntFireByHandle(Player, "RunScriptCode", "MVMAnimosity_ArenaMode.ArenaVIPReadyUp(activator.GetEntityIndex())", 0.0, Player, null);
				return
			}
		}
	}

	OnScriptHook_OnTakeDamage = function(params)
	{
		local Attacker = params.attacker
		local Victim = params.const_entity

		if ( !Attacker.IsPlayer() || !Attacker.IsBotOfType(1337) )
			return

		if ( !Victim.IsPlayer() || !Victim.IsBotOfType(1337) )
			return

		if ( Attacker == Victim )
			return

		if ( Attacker.HasBotTag("LethalBot") && Victim.HasBotTag("FriendlyBot") )
			params.damage = 500
	}

	// Bot Tags
	function BotTagCheck()
	{
		if(activator.HasBotTag("Glow"))
		{
			MVMAnimosity_ArenaMode.BotGlow(activator)
		}

		if(activator.HasBotTag("NoGlow"))
		{
			MVMAnimosity_ArenaMode.NoBotGlow(activator)
		}
	}
	function BotGlow(Target)
	{
		SetPropBool(Target, "m_bGlowEnabled", true)
	}
	function NoBotGlow(Target)
	{
		SetPropBool(Target, "m_bGlowEnabled", false)

		local Bomb = FindByClassname(null, "item_teamflag")

		SetPropBool(Bomb, "m_bGlowEnabled", false)
	}

	// VIP Objective Functions //

	function ArenaVIPStatsInit(Target)
	{
		Target.RemoveWeaponRestriction(7)
		Target.ClearAllBotAttributes()
		Target.ClearAllBotTags()
		Target.SetCustomModelWithClassAnimations(null)
		Target.SetDifficulty(3)
		Target.SetMaxVisionRangeOverride(9999)

		SetFakeClientConVarValue(Target, "name", "Guard-I.A.N.")
		Target.SetCustomModelWithClassAnimations("models/bots/demo_boss/bot_demo_boss.mdl")
		Target.SetModelScale(2, -1)
		SetPropBool(Target, "m_bGlowEnabled", true)

		Target.AddBotAttribute(1)
		Target.AddBotAttribute(2048)
		Target.SetIsMiniBoss(true)
		Target.SetUseBossHealthBar(true)

		Target.AddWeaponRestriction(2)

		Target.AddBotTag("bot_giant")
		Target.AddBotTag("FriendlyBot")

		SetPropString(Target, "m_PlayerClass.m_iszClassIcon", "red_lite")

		Target.AddCustomAttribute("max health additive bonus", 3825, -1)
		Target.SetHealth(4000)

		Target.AddCustomAttribute("move speed penalty", 0.5, -1)
		Target.AddCustomAttribute("damage force reduction", 0.1, -1)
		Target.AddCustomAttribute("airblast vulnerability multiplier", 0.1, -1)
		Target.AddCustomAttribute("health regen", 40, -1)
		Target.AddCustomAttribute("ammo regen", 1, -1)

		Target.AddCustomAttribute("override footstep sound set", 4, -1)
		Target.AddCustomAttribute("voice pitch scale", 0, -1)

		local Weapon = Target.GetActiveWeapon()

		Weapon.AddAttribute("fire rate bonus", 0.75, -1)
		Weapon.AddAttribute("faster reload rate", 0.001, -1)
	}

	function ArenaVIPInit()
	{
		SetValue("tf_mvm_defenders_team_size", 7)
		SetValue("tf_bot_flag_escort_max_count", 0)

		if(FindByName(null, "arena_mode_objective_nobuild"))
			return

		local ObjectiveNobuild = SpawnEntityFromTable("func_nobuild",
		{
			targetname = "arena_mode_objective_nobuild"
			origin = "578 2726 140"
		})
		ObjectiveNobuild.SetSize(Vector(-64, -64, -32), Vector(64, 64, 32))

		if(FindByName(null, "arena_mode_objective_spawner"))
			return

		local ObjectiveSpawner = SpawnEntityFromTable("bot_generator",
		{
			targetname = "arena_mode_objective_spawner"
			origin = "578 2726 160"
			team = "red"
			count = 1
			maxActive = 1
			interval = 0
			useTeamSpawnPoint = 0
			spawnOnlyWhenTriggered = 1

			"OnSpawned" : "!activator,RunScriptCode,MVMAnimosity_ArenaMode.ArenaVIPStatsInit(self),0,-1"
		})
		SetPropString(ObjectiveSpawner, "m_className", "demoman")
		EntFire("arena_mode_objective_spawner", "SpawnBot", null, 0.0, null)

		if(FindByName(null, "arena_mode_objective_point"))
			return

		local ObjectivePoint = SpawnEntityFromTable("bot_action_point",
		{
			targetname = "arena_mode_objective_point"
			origin = "578 2726 160"
			desired_distance = 64
			stay_time = 99999
		})
		EntFire("arena_mode_objective_spawner", "CommandGotoActionPoint", "arena_mode_objective_point", 1.0, null)
	}

	function ArenaVIPObjectiveInit(target)
	{

		if(FindByName(null, "arena_mode_objective_bomb"))
			return

		local ObjectiveBombProp = SpawnEntityFromTable("prop_dynamic",
		{
			targetname = "arena_mode_objective_bomb"
			model = "models/props_td/atom_bomb.mdl"
			solid = 0
			disableshadows = 1
			DisableBoneFollowers = 1
		})

		EntFire("arena_mode_objective_bomb", "SetParent", "!activator", 0.0, target)
		EntFire("arena_mode_objective_bomb", "SetParentAttachment", "flag", 0.05, target)

		if(FindByName(null, "arena_mode_objective_bomblight"))
			return

		local ObjectiveBombLight = SpawnEntityFromTable("info_particle_system",
		{
			targetname = "arena_mode_objective_bomblight"
			effect_name = "cart_flashinglight"
			start_active = 1
		})

		EntFire("arena_mode_objective_bomblight", "SetParent", "arena_mode_objective_bomb", 0.0, null)
		EntFire("arena_mode_objective_bomblight", "SetParentAttachment", "siren", 0.05, null)

		if(FindByName(null, "arena_mode_objective_bombexplosion"))
			return

		local ObjectiveBombExplosion = SpawnEntityFromTable("info_particle_system",
		{
			targetname = "arena_mode_objective_bombexplosion"
			origin = "578 2726 140"
			effect_name = "mvm_hatch_destroy"
			start_active = 0
		})
	}

	function ArenaVIPReadyUp(playerIndex)
	{
		local Gamerules = FindByClassname(null, "tf_gamerules")
		SetPropBoolArray(Gamerules, "m_bPlayerReady", true, playerIndex)
	}

	function ArenaVIPKill()
	{
		for (local i = 1; i <= MaxPlayers; i++)
		{
			local Player = PlayerInstanceFromIndex(i)
			if (Player.IsBotOfType(1337) && (Player.GetTeam()) == 2)
			{
				Player.TakeDamage(99999, 0, null)
			}
		}
	}
	function ArenaVIPLoss()
	{
		EntFire("arena_mode_loss_relay", "Trigger", null, 0.0, null)
		EntFire("arena_mode_objective_bombexplosion", "Start", null, 0.0, null)

		EntFire("arena_mode_objective_bomb", "Kill", null, 0.0, null)
		EntFire("arena_mode_objective_bomblight", "Kill", null, 0.0, null)

		PrecacheScriptSound("MVM.GiantCommonExplodes")
		PrecacheScriptSound("MVM.BombExplodes")

		EmitSoundEx({
			sound_name = "MVM.GiantCommonExplodes"
			channel = 6
			filter_type = 5
		})
		EmitSoundEx({
			sound_name = "MVM.BombExplodes"
			channel = 6
			filter_type = 5
		})
	}
}

__CollectGameEventCallbacks(MVMAnimosity_ArenaMode)