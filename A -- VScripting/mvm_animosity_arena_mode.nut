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
		local player = GetPlayerFromUserID(params.userid)

		if (player.IsBotOfType(1337))
		{
			// Will only work with 1 RED Robot Present
			if ( (player.GetTeam()) == 2 )
			{
				EntFireByHandle(player, "RunScriptCode", "MVMAnimosity_ArenaMode.ArenaVIPObjectiveInit(activator)", 0.0, player, null);
				MVMAnimosity_ArenaMode.ArenaVIPReadyUp(player.GetEntityIndex())
				return
			}
			EntFireByHandle(player, "RunScriptCode", "MVMAnimosity_ArenaMode.BotTagCheck()", 0.0, player, null);
			return
		}
	}
	OnGameEvent_player_death = function(params)
	{
		local player = GetPlayerFromUserID(params.userid)

		if(player.IsBotOfType(1337) && (player.GetTeam()) == 2)
		{
			MVMAnimosity_ArenaMode.ArenaVIPLoss()
			player.ForceChangeTeam(TEAM_SPECTATOR, false)
			return
		}
	}

	OnGameEvent_mvm_begin_wave = function (params)
	{
		if(FindByName(null, "arena_mode_commentary_node"))
			return

		local objectivecommnode = SpawnEntityFromTable("point_commentary_node",
		{
			targetname = "arena_mode_commentary_node"
		})
	}
	OnGameEvent_mvm_wave_complete = function(params)
	{
		EntFire("arena_mode_commentary_node", "Kill", null, 0.0, null)

		for (local i = 1, player; i <= MaxPlayers; i++)
			if (player.IsBotOfType(1337) && (player.GetTeam()) == 2)
				MVMAnimosity_ArenaMode.ArenaVIPReadyUp(player.GetEntityIndex())
	}

	OnScriptHook_OnTakeDamage = function(params)
	{
		local attacker = params.attacker
		local victim = params.const_entity

		if ( !attacker.IsPlayer() || !attacker.IsBotOfType(1337) )
			return

		if ( !victim.IsPlayer() || !victim.IsBotOfType(1337) )
			return

		if ( attacker == victim )
			return

		if ( attacker.HasBotTag("LethalBot") && victim.HasBotTag("FriendlyBot") )
			params.damage = 800
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
	function BotGlow(target)
	{
		SetPropBool(target, "m_bGlowEnabled", true)
	}
	function NoBotGlow(target)
	{
		SetPropBool(target, "m_bGlowEnabled", false)

		local bomb = FindByClassname(null, "item_teamflag")

		SetPropBool(bomb, "m_bGlowEnabled", false)
	}

	// VIP Objective Functions //

	function ArenaVIPStatsInit(target)
	{
		target.RemoveWeaponRestriction(7)
		target.ClearAllBotAttributes()
		target.ClearAllBotTags()
		target.SetCustomModelWithClassAnimations(null)
		target.SetDifficulty(3)
		target.SetMaxVisionRangeOverride(9999)

		SetFakeClientConVarValue(target, "name", "Guard-I.A.N.")
		target.SetCustomModelWithClassAnimations("models/bots/demo_boss/bot_demo_boss.mdl")
		target.SetModelScale(2, -1)
		SetPropBool(target, "m_bGlowEnabled", true)

		target.AddBotAttribute(1)
		target.AddBotAttribute(2048)
		target.SetIsMiniBoss(true)
		target.SetUseBossHealthBar(true)

		target.AddWeaponRestriction(2)

		target.AddBotTag("bot_giant")
		target.AddBotTag("FriendlyBot")

		SetPropString(target, "m_PlayerClass.m_iszClassIcon", "red_lite")

		target.AddCustomAttribute("max health additive bonus", 2825, -1)
		target.SetHealth(3000)

		target.AddCustomAttribute("move speed penalty", 0.5, -1)
		target.AddCustomAttribute("damage force reduction", 0.1, -1)
		target.AddCustomAttribute("airblast vulnerability multiplier", 0.1, -1)
		target.AddCustomAttribute("health regen", 100, -1)
		target.AddCustomAttribute("ammo regen", 1, -1)

		target.AddCustomAttribute("override footstep sound set", 4, -1)
		target.AddCustomAttribute("voice pitch scale", 0, -1)

		local weapon = target.GetActiveWeapon()

		weapon.AddAttribute("fire rate bonus", 0.75, -1)
		weapon.AddAttribute("faster reload rate", 0.6, -1)
	}

	function ArenaVIPInit()
	{
		if(FindByName(null, "arena_mode_objective_nobuild"))
			return

		local objectivenobuild = SpawnEntityFromTable("func_nobuild",
		{
			targetname = "arena_mode_objective_nobuild"
			origin = "578 2726 101"
		})
		objectivenobuild.SetSize(Vector(-48, -48, -32), Vector(48, 48, 32))

		if(FindByName(null, "arena_mode_objective_spawner"))
			return

		local objectivespawner = SpawnEntityFromTable("bot_generator",
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
		SetPropString(objectivespawner, "m_className", "demoman")
		EntFire("arena_mode_objective_spawner", "SpawnBot", null, 0.0, null)

		if(FindByName(null, "arena_mode_objective_point"))
			return

		local objectivepoint = SpawnEntityFromTable("bot_action_point",
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

		local objectivebombprop = SpawnEntityFromTable("prop_dynamic",
		{
			targetname = "arena_mode_objective_bomb"
			model = "models/props_td/atom_bomb.mdl"
			solid = 0
			disableshadows = 1
		})

		EntFire("arena_mode_objective_bomb", "SetParent", "!activator", 0.0, target)
		EntFire("arena_mode_objective_bomb", "SetParentAttachment", "flag", 0.05, target)

		if(FindByName(null, "arena_mode_objective_bomblight"))
			return

		local objectivebomblight = SpawnEntityFromTable("info_particle_system",
		{
			targetname = "arena_mode_objective_bomblight"
			effect_name = "cart_flashinglight"
			start_active = 1
		})

		EntFire("arena_mode_objective_bomblight", "SetParent", "arena_mode_objective_bomb", 0.0, null)
		EntFire("arena_mode_objective_bomblight", "SetParentAttachment", "siren", 0.05, null)

		if(FindByName(null, "arena_mode_objective_bombexplosion"))
			return

		local objectivebombexplosion = SpawnEntityFromTable("info_particle_system",
		{
			targetname = "arena_mode_objective_bombexplosion"
			origin = "578 2726 140"
			effect_name = "mvm_hatch_destroy"
			start_active = 0
		})
	}

	function ArenaVIPReadyUp(playerIndex)
	{
		local gamerules = FindByClassname(null, "tf_gamerules")
		SetPropBoolArray(gamerules, "m_bPlayerReady", true, playerIndex)
	}

	function ArenaVIPKill()
	{
		for (local i = 1, player; i <= MaxPlayers; i++)
			if (player.IsBotOfType(1337) && (player.GetTeam()) == 2)
				player.TakeDamage(99999, 0, null)
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