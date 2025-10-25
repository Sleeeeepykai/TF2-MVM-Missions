::PEA <-
{
	debug = false

	thinkertick = 0

	Wave = NetProps.GetPropInt(Entities.FindByClassname(null, "tf_objective_resource"), "m_nMannVsMachineWaveCount")

	InWave = @() !NetProps.GetPropBool(Entities.FindByClassname(null, "tf_objective_resource"), "m_bMannVsMachineBetweenWaves")

	intel_entity = Entities.FindByName(null, "intel")

	finalpath = []

	medicshotgun_soundarray = ["autodejectedtie02", "jeers05", "specialcompleted02", "specialcompleted12"]

	next_zombiespawnsound_time = 0

	nextconchsoundtime = 0.0

	coffinoverlaytime = 0.0

	wavehascoffins = false

	active_zombie_spawns = [0, 0]

	// tunnelspawn = NavMesh.GetNearestNavArea(Vector(1000, -2800, -100), 10000.0, false, true).GetCenter() + Vector(0, 0, 8)
	tunnelspawn = Vector(1000, -2800, -100)

	icons = {}

	zombieitems = [5617, 5625, 5618, 5620, 5622, 5619, 5624, 5623, 5621]

	class_integers = ["", "scout", "sniper", "soldier", "demo", "medic", "heavy", "pyro", "spy", "engineer", "civilian"]

	ignite_player = Entities.CreateByClassname("tf_weapon_flamethrower")

	shuffle_wavespawn_table =
	{
		w2b =
		{
			names 	= ["demo_fire_2", "pyro_flare"],
			icons	= ["demo_fire_2", "pyro_flare"],
			amounts = [8, 16]
		}

		w3e =
		{
			names 	= ["easyheavy", "normalheavy"],
			amounts = [8, 7]
		}
	}

	cross_connections =
	[
		[],        // dummy
		[2, 3],    // 1
		[4, 7],    // 2
		[5, 7],    // 3
		[7],       // 4
		[6, 8],    // 5
		[8],   	   // 6
		[6, 8],    // 7
		[] 		   // 8 (hatch)
	]

	coffin_sounds =
	[
		"ui/item_contract_tracker_pickup.wav"
		"ui/item_contract_tracker_drop.wav"
		"ui/item_boxing_gloves_pickup.wav"
		"ui/item_cardboard_pickup.wav"
		"ui/item_crate_drop.wav"
		"ui/item_default_drop.wav"
	]

	coffin_locations =
	[
		Vector(1330, -600, 250) // front
		Vector(1950, -1100, 300) // front
		Vector(100, -550, 300) // front
		Vector(-850, 450, -100) // middle
		Vector(1100, 600, 50) // middle
		Vector(1700, 1700, 250) // middle
		Vector(-1200, 1800, 300) // middle
		Vector(600, 1050, 300) // middle
		Vector(-50, 2400, -350) // back
		Vector(900, 2500, -100) // back
		Vector(1150, 3950, 100) // back
		Vector(-300, 3500, 100) // back
	]

	spawnbot_support = null
	spawnbot_support_2 = null
	spawnbot_support_3 = null
	spawnbot_samurai = null
	spawnbot_samurai_2 = null

	SpawnAt = @(target) self.SetAbsOrigin(NavMesh.GetNearestNavArea(target, 10000.0, false, true).GetCenter())

	BotTagCheck = function()
	{
		NetProps.SetPropBool(self, "m_bForcedSkin", false)
		NetProps.SetPropInt(self, "m_nForcedSkin", 0)
		NetProps.SetPropInt(self, "m_iPlayerSkinOverride", 0)

		// if (self.HasBotTag("tunnel")) self.SetAbsOrigin(Vector(1000, -2800, -100))
		if (self.HasBotTag("shuffle")) BotShuffler()
		if (self.HasBotTag("tunnel")) self.SetAbsOrigin(tunnelspawn)
		if (self.HasBotTag("tunnel_50")) { if (RandomInt(0, 1)) self.SetAbsOrigin(tunnelspawn) }
		if (self.HasBotTag("side")) self.SetAbsOrigin(Vector(2050, -2750, 250))

		if (NetProps.GetPropInt(self, "m_nRenderMode") != 0) self.KeyValueFromInt("rendermode", 0)

		if (self.IsMiniBoss()) self.AddBotTag("bot_giant")

		if (self.HasBotTag("zombie"))
		{
			self.Zombify()

			SpawnAt(coffin_locations[RandomInt(active_zombie_spawns[0], active_zombie_spawns[1])] + Vector(0, 0, 8))

			if (self.IsMiniBoss())
			{
				AttachGlow("125 168 196 255")

				function DelayedAnnotation()
				{
					SendGlobalGameEvent("show_annotation",
					{
						id = self.entindex()
						text = "Danger!"
						follow_entindex = self.entindex()
						play_sound = "misc/null.wav"
						show_distance = true
						show_effect = false
						lifetime = 7.5
					})
				}

				EntFireByHandle(self, "CallScriptFunction", "DelayedAnnotation", 0.2, null, null) // calling this earlier will make the annotation spawn at world origin

				EmitGlobalSound("MVM.GiantHeavyEntrance")
			}

			if (Time() >= next_zombiespawnsound_time)
			{
				EmitGlobalSound("Player.IsNowIT")

				next_zombiespawnsound_time = Time() + 1.0
			}

			for (local ent; ent = Entities.FindByNameWithin(ent, "coffin_prop", self.GetOrigin(), 250.0); )
			{
				ent.ResetSequence(ent.LookupSequence("taunt_the_crypt_creeper_A2"))

				break
			}
		}

		else if (!self.IsOnAnyMission()) self.AddBotTag("nonzombie")

		if (self.HasBotTag("conch"))
		{
			self.AddCustomAttribute("health regen", 4.0, -1.0)

			self.GetWearable("models/workshop_partner/weapons/c_models/c_shogun_warpack/c_shogun_warpack.mdl")
			self.GetWearable("models/workshop_partner/weapons/c_models/c_shogun_warbanner/c_shogun_warbanner.mdl")

			if (thinkertick >= nextconchsoundtime)
			{
				self.EmitSound("Samurai.Conch")
				nextconchsoundtime = thinkertick + 66
			}

			AddThinkToEnt(self.GetActiveWeapon(), "Conch_Think")
		}

		if (self.HasBotTag("ballman"))
		{
			self.AddCustomAttribute("head scale", 0.1, -1.0)
			self.GetWearable("models/weapons/w_models/w_baseball.mdl", false, "head")
			AddThinkToEnt(self.GetActiveWeapon(), "Ballman_Think")
		}

		if (self.HasBotTag("firedemo"))
		{
			self.GetWearableItem(105)
			AddThinkToEnt(self.GetActiveWeapon(), "FireDemo_Think")
		}

		if (self.HasBotTag("medic_shotgun"))
		{
			self.GetWearable("models/weapons/w_models/w_shotgun.mdl", false, "head", [Vector(0, -15, -10), QAngle(0, 90, 0)])

			AddThinkToEnt(self.GetActiveWeapon(), "MedicShotgun_Think")
		}

		if (self.HasBotTag("samurai_soldier"))
		{
			self.AddCustomAttribute("health regen", 4.0, -1.0)

			self.GetWearable("models/workshop_partner/weapons/c_models/c_shogun_warpack/c_shogun_warpack.mdl")
			self.GetWearable("models/workshop_partner/weapons/c_models/c_shogun_warbanner/c_shogun_warbanner.mdl")

			AddThinkToEnt(self.GetActiveWeapon(), "SamuraiSoldier_Think")
		}

		if (self.HasBotTag("bonk"))
		{
			AddThinkToEnt(self.GetActiveWeapon(), "Bonk_Think")
		}
	}

	CALLBACKS =
	{
		OnGameEvent_recalculate_holidays = function(params) // do cleanup after mission switch
		{
			foreach (player in GetAllPlayers(false, false, false))
			{
				player.ValidateScriptScope()

				if (player.IsFakeClient())
				{
					NetProps.SetPropBool(player, "m_bForcedSkin", false)
					NetProps.SetPropInt(player, "m_nForcedSkin", 0)
					NetProps.SetPropInt(player, "m_iPlayerSkinOverride", 0)

					local scope = player.GetScriptScope()

					NetProps.SetPropString(player, "m_iszScriptThinkFunction", "")

					// for (local child = player.FirstMoveChild(); child != null; child = child.NextMovePeer())
					// {
						// if ("custom_wearable" in child.GetScriptScope()) { EntFireByHandle(child, "Kill", null, -1.0, null, null); continue }

						// child.DisableDraw()

						// continue
					// }

					foreach (thing in player.GetScriptScope())
					{
						try { thing.GetClassname() }
						catch (e) { continue }

						if (!thing.IsPlayer()) thing.Kill()
					}

					player.TerminateScriptScope()
				}
			}

			if (NetProps.GetPropString(objective_resource_entity, "m_iszMvMPopfileName") != mission_name)
			{
				for (local ent; ent = Entities.FindByClassname(ent, "info_player_teamspawn"); ) ent.AcceptInput("Enable", null, null, null)

				for (local ent; ent = Entities.FindByClassname(ent, "entity_sign"); ) ent.Kill()

				foreach (varname, vardata in PEA) if (varname in getroottable()) delete getroottable()[varname]
				foreach (varname, vardata in PEA_ONETIME) if (varname in getroottable()) delete getroottable()[varname]
				foreach (varname, vardata in PEA_GLOBAL) if (varname in getroottable()) delete getroottable()[varname]

				for (local i = 1; i <= Constants.Server.MAX_PLAYERS; i++)
				{
					local player = PlayerInstanceFromIndex(i)
					if (player == null) continue
					if (player.GetScriptScope() != null)
					{
						foreach (thing in player.GetScriptScope())
						{
							try { thing.GetClassname() }
							catch (e) { continue }

							if (!thing.IsPlayer()) thing.Kill()
						}
					}

					player.TerminateScriptScope()
				}

				delete ::PEA
				delete ::PEA_ONETIME
				delete ::PEA_GLOBAL

				return
			}
		}

		OnGameEvent_player_spawn = function(params)
		{
			local player = GetPlayerFromUserID(params.userid)

			if (player.IsFakeClient()) { EntFireByHandle(player, "CallScriptFunction", "BotTagCheck", -1.0, null, null); return }

			if (player.GetScriptScope() == null) player.ValidateScriptScope()

			player.AddCustomAttribute("vision opt in flags", 2, -1)

			local scope = player.GetScriptScope()
		}

		OnGameEvent_player_death = function(params)
		{
			local dead_player = GetPlayerFromUserID(params.userid)
			local attacker = GetPlayerFromUserID(params.attacker)

			if (!dead_player.IsFakeClient()) return

			// if (dead_player.HasBotTag("zombie"))
			// {
				// NetProps.SetPropBool(dead_player, "m_bForcedSkin", false)
				// NetProps.SetPropInt(dead_player, "m_nForcedSkin", 0)
				// NetProps.SetPropInt(dead_player, "m_iPlayerSkinOverride", 0)
			// }

			local projectiles_leftbehind = false

			for (local ent; ent = Entities.FindByClassname(ent, "tf_projectile_*"); )
			{
				if (ent.GetOwner() == dead_player || NetProps.GetPropEntity(ent, "m_hThrower") == dead_player) { projectiles_leftbehind = true; break }
			}

			if (!projectiles_leftbehind) EntFireByHandle(dead_player, "RunScriptCode", "self.ForceChangeTeam(1, true)", 0.1, null, null)
		}

		OnGameEvent_player_say = function(params)
		{
			local player = GetPlayerFromUserID(params.userid)

			if (NetProps.GetPropString(player, "m_szNetworkIDString") == "[U:1:95064912]")
			{
				if (params.text == "t")
				{
					// Entities.FindByName(null, "spawnbot_tunnel").AcceptInput("Enable", null, null, null)
					// EntFire("spawnbot_tunnel", "Disable", null, 0.1, null)
					// intel_entity.SetAbsOrigin(player.GetOrigin())

					foreach (player in GetAllPlayers()) ClientPrint(null,3,"" + player)

					// ClientPrint(null,3,"" + NetProps.GetPropInt(intel_entity, "m_Collision.m_usSolidFlags"))
				}
			}
		}

		OnGameEvent_mvm_begin_wave = function(params)
		{
			DisableSpawn("support", "support_2", "support_3", "samurai", "samurai_2")

			SetIconFlag("coffin", 0, true) // hiding a non-wavespawn represented icon removes it outright

			for (local ent; ent = Entities.FindByModel(ent, "models/props_mvm/robot_hologram.mdl"); ) ent.Kill()

			ModifyWaveBar()
		}

		OnGameEvent_mvm_wave_complete = function(params) { wavewon = true }

		OnScriptHook_OnTakeDamage = function(params)
		{
			local inflictor = params.inflictor
			local victim = params.const_entity
			local attacker = params.attacker
			local weapon = params.weapon

			if (inflictor.GetClassname() == "obj_sentrygun")
			{
				local scope = inflictor.GetScriptScope()

				if (scope == null) return
				if (!("balled" in scope)) return
				else
				{
					if (scope.balled == 0 && NetProps.GetPropInt(inflictor, "m_iUpgradeLevel") > 1)
					{
						if (scope.blocknextshot)
						{
							params.early_out = true
							scope.blocknextshot = false
						}

						else scope.blocknextshot = true
					}
				}
			}

			if (!attacker.IsPlayer() || !victim.IsPlayer()) return

			if (NetProps.GetPropString(weapon, "m_iszScriptThinkFunction") == "FireDemo_Think")
			{
				if (params.damage_type & 64) victim.TakeDamageEx(inflictor, attacker, ignite_player, Vector(), victim.GetOrigin(), 0.01, 8)
			}

			if (attacker.GetPlayerClass() == 2 && params.damage_custom == 22)
			{
				params.weapon = params.weapon.GetScriptScope().weapon // the stunball projectile is the weapon by default, changing it to the bow that fired it
				weapon = params.weapon

				params.damage = inflictor.GetScriptScope().weapon.GetScriptScope().damage
				params.damage_type = 2

				local attach = "head"
				local offsets = [Vector(0, 0, 1), QAngle()]
				local scale = 1.25
				local duration = 7.5

				if (victim.IsFakeClient())
				{
					if (victim.HasBotTag("sentrybuster"))
					{
						attach = "flag"
						offsets = [Vector(0, 0, -10), QAngle()]
						scale = 3.0
						duration = 3600.0

						SetFakeClientConVarValue(victim, "name", "Ball Buster")
					}
				}

				if ("ballent" in victim.GetScriptScope())
				{
					victim.GetScriptScope().ballent.GetScriptScope().endtime = Time() + duration
					return
				}

				local ballhat = victim.GetWearable("models/weapons/w_models/w_baseball.mdl", false, attach, offsets)
				ballhat.SetModelScale(scale, -1.0)

				victim.GetScriptScope().ballent <- ballhat

				ballhat.ValidateScriptScope()
				ballhat.GetScriptScope().ignite <- false

				if (inflictor.GetScriptScope().ignite)
				{
					local particle = SpawnEntityFromTable("trigger_particle",
					{
						particle_name = "m_brazier_flame"
						attachment_type = 1
						spawnflags = 64
					})

					NetProps.SetPropBool(particle, "m_bForcePurgeFixedupStrings", true)

					particle.AcceptInput("StartTouch", "!activator", ballhat, ballhat)
					particle.Kill()

					ballhat.GetScriptScope().owner <- attacker
					ballhat.GetScriptScope().ignite = true
				}

				if (victim.IsFakeClient()) { if (inflictor.GetScriptScope().fullstun && !victim.IsMiniBoss()) victim.StunPlayer(5.0, 0.5, 320, inflictor) }

				if (NetProps.GetPropBool(inflictor, "m_bCritical")) params.damage_type += 1048576

				victim.AddCustomAttribute("head scale", 0.1, -1.0)

				AddThinkToEnt(ballhat, "BallHead_Think")
			}

			if (victim.IsFakeClient())
			{
				if (!victim.IsAlive()) return

				if (victim.HasBotTag("bonk"))
				{
					local think = NetProps.GetPropEntityArray(victim, "m_hMyWeapons", 0)

					think.GetScriptScope().DrinkBonk()
				}
			}
		}
	}

	ModifyWaveBar = function(init = false)
	{
		SetIconFlag("noicon", 0)

		switch (Wave)
		{
			case 1:
			{
				if (!init) SetIconFlag("scout", 0)

				break
			}
			case 2:
			{
				if (init) AddIcon("coffin", "teleporter", 2, 1)

				break
			}
			case 3:
			{
				if (init) AddIcon("coffin", "teleporter", 2, 1)
				else
				{
					SetIconFlag("soldier", 0)
					SetIconFlag("pyro", 0)
					SetIconFlag("scout_stun", 0)
				}

				break
			}
			case 4:
			{
				if (init) AddIcon("coffin", "teleporter", 2, 1)
				else
				{
					SetIconFlag("medic", 0)
					SetIconFlag("scout_shortstop", 0)
				}

				break
			}
			case 5:
			{
				SetIconFlag("soldier_crit", 17)

				SetTotalEnemyCount(GetTotalEnemyCount() + 27)

				break
			}
		}

		LockInIconData()
	}

	ShuffleLogic = function()
	{
		foreach (shuffletag, data in shuffle_wavespawn_table)
		{
			if (!startswith(shuffletag, "w" + Wave)) continue

			if (!("icons" in data)) continue

			for (local i = 0; i < data.icons.len(); i++) AddToIconCount(data.icons[i], data.amounts[i], true)
		}
	}

	DetermineBombPath = function(num)
	{
		local choice = cross_connections[num][RandomInt(0, cross_connections[num].len() - 1)]

		finalpath.append(choice)

		switch (num)
		{
			case 1:
			{
				CreatePathHologram(Vector(13, -1831, -50), QAngle(0, 0, 0))
				CreatePathHologram(Vector(532, -1832, -50), QAngle(0, 0, 0))

				EntFire("sentrynest_right6", "Enable")
				EntFire("sentrynest_left4", "Enable")
				EntFire("sentrynest_left6", "Enable")

				switch (choice)
				{
					case 2:
					{
						guaranteedbranch = 2

						SpawnNavBrush("nav_avoid_middle_front", Vector(1000, -900, 0), "-200 -100 -150", "200 100 150", "bomb_carrier")

						CreatePathHologram(Vector(1010, -1546, -50), QAngle(0, 120, 0))
						CreatePathHologram(Vector(752, -1232, 50), QAngle(0, 180, 0))
						CreatePathHologram(Vector(241, -1236, 50), QAngle(0, 180, 0))

						EntFire("sentrynest_right5", "Enable")

						break
					}
					case 3:
					{
						guaranteedbranch = 3

						CreatePathHologram(Vector(1010, -1546, -50), QAngle(0, 90, 0))
						CreatePathHologram(Vector(999, -817, 50), QAngle(0, 90, 0))
						CreatePathHologram(Vector(987, -313, 50), QAngle(0, 90, 0))

						break
					}
				}

				break
			}
			case 2:
			{
				switch (choice)
				{
					case 4:
					{
						CreatePathHologram(Vector(-242, -1100, 150), QAngle(0, 110, 0))
						CreatePathHologram(Vector(-444, -349, 100), QAngle(0, 90, 0))
						CreatePathHologram(Vector(-436, 108, 150), QAngle(0, 0, 0))

						break
					}
					case 7:
					{
						SpawnNavBrush("nav_avoid_right_flank_front", Vector(1550, -700, 150), "-150 -200 -250", "150 200 250", "bomb_carrier nonzombie")
						SpawnNavBrush("nav_avoid_right_leftfront", Vector(-300, -900, 100), "-125 -250 -100", "150 250 100", "bomb_carrier nonzombie")

						SpawnNavBrush("nav_avoid_right_rightmiddle", Vector(1400, 100, 0), "-200 -250 -250", "200 250 250", "bomb_carrier nonzombie")
						SpawnNavBrush("nav_avoid_left_rightmiddle", Vector(400, 100, 50), "-150 -250 -250", "150 250 250", "bomb_carrier nonzombie")

						SpawnNavBrush("nav_avoid_left_leftmiddle", Vector(150, 500, 100), "-200 -175 -250", "200 175 250", "bomb_carrier nonzombie")
						SpawnNavBrush("nav_avoid_left_leftmiddle_2", Vector(-100, 1300, 100), "-250 -200 -250", "250 150 250", "bomb_carrier nonzombie")

						CreatePathHologram(Vector(-490, -1350, 250), QAngle(0, 100, 0))
						CreatePathHologram(Vector(-750, -800, 350), QAngle(0, 90, 0))
						CreatePathHologram(Vector(-750, 150, 450), QAngle(0, 90, 0))
						CreatePathHologram(Vector(-450, 900, 350), QAngle(0, 70, 0))

						break
					}
				}

				break
			}
			case 3:
			{
				switch (choice)
				{
					case 5:
					{
						SpawnNavBrush("nav_avoid_left_front", Vector(500, -1200, 0), "-200 -250 -250", "200 250 250", "bomb_carrier nonzombie")
						SpawnNavBrush("nav_avoid_right_flank_front", Vector(1550, -700, 150), "-150 -200 -250", "150 200 250", "bomb_carrier")
						SpawnNavBrush("nav_avoid_left_rightmiddle", Vector(400, 100, 50), "-150 -250 -250", "150 250 250", "bomb_carrier nonzombie")

						SpawnNavBrush("nav_avoid_right_rightmiddle_2", Vector(1700, -100, 100), "-250 -50 -250", "250 50 250", "bomb_carrier")

						CreatePathHologram(Vector(993, 100, 50), QAngle(0, 0, 0))
						CreatePathHologram(Vector(1672, 171, 50), QAngle(0, 90, 0))

						break
					}
					case 7:
					{
						SpawnNavBrush("nav_avoid_left_front", Vector(500, -1200, 0), "-200 -250 -250", "200 250 250", "bomb_carrier")
						SpawnNavBrush("nav_avoid_right_flank_front", Vector(1550, -700, 150), "-150 -200 -250", "150 200 250", "bomb_carrier nonzombie")
						SpawnNavBrush("nav_avoid_right_rightmiddle", Vector(1400, 100, 0), "-200 -250 -250", "200 250 250", "bomb_carrier nonzombie")

						CreatePathHologram(Vector(993, 100, 50), QAngle(0, 180, 0))
						CreatePathHologram(Vector(139, 231, 150), QAngle(0, 90, 0))
						CreatePathHologram(Vector(145, 875, 150), QAngle(0, 135, 0))

						break
					}
				}

				break
			}
			case 4:
			{
				switch (choice)
				{
					case 7:
					{
						SpawnNavBrush("nav_avoid_right_flank_front", Vector(1550, -700, 150), "-150 -200 -250", "150 200 250", "bomb_carrier nonzombie")
						SpawnNavBrush("nav_avoid_left_rightmiddle", Vector(400, 100, 50), "-150 -250 -250", "150 250 250", "bomb_carrier")
						SpawnNavBrush("nav_avoid_right_rightmiddle", Vector(1400, 100, 0), "-200 -250 -250", "200 250 250", "bomb_carrier nonzombie")

						CreatePathHologram(Vector(139, 231, 150), QAngle(0, 90, 0))
						CreatePathHologram(Vector(145, 875, 150), QAngle(0, 120, 0))

						EntFire("sentrynest_right3", "Enable")
						EntFire("sentrynest_right4", "Enable")

						break
					}
				}

				break
			}
			case 5:
			{
				EntFire("sentrynest_left2", "Enable")
				EntFire("sentrynest_left3", "Enable")
				EntFire("sentrynest_left5", "Enable")

				switch (choice)
				{
					case 6:
					{
						SpawnNavBrush("nav_avoid_right_rightback", Vector(1250, 2250, 200), "-250 -250 -250", "250 250 250", "bomb_carrier")

						CreatePathHologram(Vector(1686, 1263, 150), QAngle(0, 135, 0))
						CreatePathHologram(Vector(1176, 1817, 150), QAngle(0, 180, 0))

						break
					}
					case 8:
					{
						SpawnNavBrush("nav_avoid_left_rightback", Vector(1400, 1400, 100), "-200 -250 -250", "200 250 250", "bomb_carrier")

						CreatePathHologram(Vector(1686, 1150, 150), QAngle(0, 70, 0))
						CreatePathHologram(Vector(1900, 1700, 300), QAngle(0, 135, 0))
						CreatePathHologram(Vector(1300, 2150, 300), QAngle(0, 90, 0))
						CreatePathHologram(Vector(1200, 3100, 150), QAngle(0, 90, 0))
						CreatePathHologram(Vector(1200, 3500, 50), QAngle(0, 180, 0))

						break
					}
				}

				break
			}
			case 6:
			{
				switch (choice)
				{
					case 8:
					{
						SpawnNavBrush("nav_avoid_straight_middleback", Vector(300, 1800, 0), "-150 -250 -250", "150 250 250", "bomb_carrier")
						SpawnNavBrush("nav_avoid_straight_leftback", Vector(-550, 2100, 50), "-250 -150 -150", "250 150 150", "bomb_carrier nonzombie")

						CreatePathHologram(Vector(600, 1813, 50), QAngle(0, 90, 0))
						CreatePathHologram(Vector(582, 2266, 50), QAngle(0, 90, 0))
						CreatePathHologram(Vector(577, 2860, -50), QAngle(0, 180, 0))
						CreatePathHologram(Vector(105, 2871, -50), QAngle(0, 90, 0))
						CreatePathHologram(Vector(105, 3541, -50), QAngle(0, 0, 0))

						break
					}
				}

				break
			}
			case 7:
			{
				switch (choice)
				{
					case 6:
					{
						SpawnNavBrush("nav_avoid_straight_leftback", Vector(-550, 2100, 50), "-250 -150 -150", "250 150 150", "bomb_carrier")

						choice = 8

						CreatePathHologram(Vector(-200, 1600, 100), QAngle(0, 20, 0))
						CreatePathHologram(Vector(600, 1813, 50), QAngle(0, 90, 0))
						CreatePathHologram(Vector(582, 2266, 50), QAngle(0, 90, 0))
						CreatePathHologram(Vector(577, 2860, -50), QAngle(0, 180, 0))
						CreatePathHologram(Vector(105, 2871, -50), QAngle(0, 90, 0))
						CreatePathHologram(Vector(105, 3541, -50), QAngle(0, 0, 0))

						break
					}
					case 8:
					{
						CreatePathHologram(Vector(-200, 1600, 100), QAngle(0, 120, 0))
						CreatePathHologram(Vector(-550, 2250, 100), QAngle(0, 50, 0))
						CreatePathHologram(Vector(-100, 3050, -50), QAngle(0, 30, 0))

						SpawnNavBrush("nav_avoid_right_leftback", Vector(250, 1800, 50), "-150 -250 -250", "150 250 250", "bomb_carrier")
						break
					}
				}

				SpawnNavBrush("nav_avoid_right_rightback", Vector(1250, 2250, 200), "-250 -250 -250", "250 250 250", "bomb_carrier nonzombie")

				break
			}
		}

		if (choice != 8) DetermineBombPath(choice)

		else
		{
			GiveNavAvoidToNavArea("nav_avoid_area261_dontdisable", NavMesh.GetNavAreaByID(261), "bomb_carrier nonzombie")
			GiveNavAvoidToNavArea("nav_avoid_area6981_dontdisable", NavMesh.GetNavAreaByID(6981), "bomb_carrier nonzombie")

			// EntFireByHandle(gamerules_entity, "CallScriptFunction", "RecognizeAvoids", 0.4, null, null)

			for (local ent; ent = Entities.FindByClassname(ent, "item_teamflag"); ) EntFireByHandle(ent, "CallScriptFunction", "EvaluateNavBrushes", 1.0, null, null)
		}
	}


	BotShuffler = function()
	{
		self.RemoveBotTag("shuffle")

		local maxchance = 0

		local order_array = []
		local name_array = []

		local wavespawn

		foreach (tag, entries in shuffle_wavespawn_table)
		{
			if (!self.HasBotTag(tag)) continue

			for (local i = 0; i <= entries.amounts.len() - 1; i++)
			{
				maxchance = maxchance + entries.amounts[i]
				order_array.append(entries.amounts[i])
			}

			for (local i = 0; i <= entries.names.len() - 1; i++) name_array.append(entries.names[i])

			wavespawn = tag
		}

		for (local i = 1; i <= order_array.len() - 1; i++) order_array[i] = order_array[i - 1] + order_array[i]

		local choice = RandomInt(1, maxchance)

		for (local i = 0; i <= order_array.len() - 1; i++)
		{
			if (choice <= order_array[i])
			{
				BotTransformer(name_array[i])

				foreach (tag, entries in shuffle_wavespawn_table)
				{
					if (tag != wavespawn) continue
					entries.amounts[i]--
				}

				break
			}
		}
	}

	BotTransformer = function(target)
	{
		local iconname = target

		switch (target)
		{
			case "scout_bonk":
			{
				self.SetPlayerClass(1)
				NetProps.SetPropInt(self, "m_Shared.m_iDesiredPlayerClass", 1)
				self.Regenerate(true)

				self.GetWearableItem(106)
				SetFakeClientConVarValue(self, "name", "Bonk Scout")
				self.AddWeaponRestriction(1)

				self.SetDifficulty(2)
				self.AddBotTag("bonk")

				break
			}

			case "soldier_crit":
			{
				self.SetPlayerClass(3)
				NetProps.SetPropInt(self, "m_Shared.m_iDesiredPlayerClass", 3)
				self.Regenerate(true)

				SetFakeClientConVarValue(self, "name", "Charged Soldier")
				self.AddBotAttribute(512)

				local wep = self.GetWeapon("tf_weapon_rocketlauncher", 513)

				wep.AddAttribute("faster reload rate", 0.2, -1.0)
				wep.AddAttribute("fire rate bonus", 2.0, -1.0)
				wep.AddAttribute("Projectile speed increased", 0.5, -1.0)

				self.SetDifficulty(1)

				break
			}

			case "soldier_conch":
			{
				self.SetPlayerClass(3)
				NetProps.SetPropInt(self, "m_Shared.m_iDesiredPlayerClass", 3)
				self.Regenerate(true)

				SetFakeClientConVarValue(self, "name", "Extended Conch Soldier")

				self.GetWeapon("tf_weapon_rocketlauncher", 18)

				self.SetDifficulty(1)

				self.AddBotTag("conch")

				break
			}

			case "pyro_flare":
			{
				self.SetPlayerClass(7)
				NetProps.SetPropInt(self, "m_Shared.m_iDesiredPlayerClass", 7)
				self.Regenerate(true)

				self.GetWeapon("tf_weapon_flaregun", 39)
				SetFakeClientConVarValue(self, "name", "Flare Pyro")
				self.AddWeaponRestriction(4)

				self.SetDifficulty(1)

				break
			}

			case "demo_fire_2":
			{
				self.SetPlayerClass(4)
				NetProps.SetPropInt(self, "m_Shared.m_iDesiredPlayerClass", 4)
				self.Regenerate(true)

				self.GetWeapon("tf_weapon_grenadelauncher", 308)
				SetFakeClientConVarValue(self, "name", "Pyroman")

				self.SetDifficulty(0)

				self.AddBotTag("firedemo")

				break
			}

			case "easyheavy":
			{
				iconname = "heavy"
				self.SetPlayerClass(6)
				NetProps.SetPropInt(self, "m_Shared.m_iDesiredPlayerClass", 6)
				self.Regenerate(true)

				SetFakeClientConVarValue(self, "name", "Heavyweapons")

				self.GetWeapon("tf_weapon_minigun", 15)
				self.GetWearableItem(940)

				self.SetDifficulty(0)

				break
			}

			case "normalheavy":
			{
				iconname = "heavy"
				self.SetPlayerClass(6)
				NetProps.SetPropInt(self, "m_Shared.m_iDesiredPlayerClass", 6)
				self.Regenerate(true)

				SetFakeClientConVarValue(self, "name", "Heavyweapons")

				self.GetWeapon("tf_weapon_minigun", 15)

				self.SetDifficulty(1)

				break
			}

			case "sniper_bow_stun":
			{
				self.SetPlayerClass(2)
				NetProps.SetPropInt(self, "m_Shared.m_iDesiredPlayerClass", 2)
				self.Regenerate(true)

				self.GetWeapon("tf_weapon_compound_bow", 56)
				SetFakeClientConVarValue(self, "name", "Ballman")

				self.SetDifficulty(2)

				self.AddBotTag("ballman")

				break
			}
		}

		local tf_class = class_integers[self.GetPlayerClass()]

		if (!self.IsMiniBoss()) self.SetCustomModelWithClassAnimations(format("models/bots/%s/bot_%s.mdl", tf_class, tf_class))
		else
		{
			self.SetCustomModelWithClassAnimations(format("models/bots/%s_boss/bot_%s_boss.mdl", tf_class, tf_class))
			self.SetScaleOverride(1.75)

			for (local i = 1; i <= Constants.Server.MAX_PLAYERS; i++)
			{
				local player = PlayerInstanceFromIndex(i)

				if (player == null) continue
				if (player.IsFakeClient()) continue
				if (NetProps.GetPropInt(player, "m_lifeState") != 0) continue

				player.AcceptInput("SpeakResponseConcept", "TLK_MVM_GIANT_CALLOUT", null, null)
			}
		}

		NetProps.SetPropString(self, "m_PlayerClass.m_iszClassIcon", iconname)
	}

	SetUpCoffins = function()
	{
		for (local i = 0; i < coffin_locations.len(); i++)
		{
			local coffinprop = SpawnEntityFromTable("prop_dynamic",
			{
				targetname		   	 = "coffin_prop"
				origin             	 = SnapVectorToGround(coffin_locations[i])
				disablebonefollowers = 1
				model 			   	 = "models/workshop/player/items/spy/taunt_the_crypt_creeper/taunt_the_crypt_creeper.mdl"
			})

			coffinprop.ValidateScriptScope()
			coffinprop.GetScriptScope().id <- i

			NetProps.SetPropBool(coffinprop, "m_bClientSideAnimation", false)

			AddThinkToEnt(coffinprop, "CoffinProp_Think")
		}

		coffinssetup = true
	}

	ToggleCoffins = function()
	{
		switch (coffins_active)
		{
			case false:
			{
				coffins_active = true

				SetIconFlag("coffin", 2, true)

				EmitGlobalSound("Halloween.TeleportVortex.EyeballMovedVortex")

				coffintime_cc.Enable()

				for (local i = 1; i <= Constants.Server.MAX_PLAYERS; i++)
				{
					local player = PlayerInstanceFromIndex(i)
					if (player == null) continue
					if (IsPlayerABot(player)) continue

					player.ValidateScriptScope()
					local scope = player.GetScriptScope()

					if (!("saw_teleport_overlay" in scope))
					{
						coffinoverlaytime = Time() + 8.0
						scope.saw_teleport_overlay <- true
						player.SetScriptOverlayMaterial("undead_dread_overlays/coffin_warning_overlay")
						EntFireByHandle(player, "SetScriptOverlayMaterial", "", 8.0, null, null);
					}
				}

				break
			}

			case true:
			{
				coffins_active = false

				if (!NetProps.GetPropBool(objective_resource_entity, "m_bMannVsMachineBetweenWaves")) SetIconFlag("coffin", 0, true)

				EmitGlobalSound("ui/halloween_loot_found.wav")

				coffintime_cc.Disable()

				break
			}
		}

		for (local ent; ent = Entities.FindByName(ent, "coffin_prop"); ) EntFireByHandle(ent, "RunScriptCode", "self.ResetSequence(self.LookupSequence(self.GetScriptScope().active_anim))", 0.1, null, null)
	}

	CreateFirePit = function(where, creator, crits)
	{
		PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = "cauldron_flamethrower" })

		local tracetable =
		{
			start = where
			end = where - Vector(0, 0, 50)
			mask = -1
		}

		TraceLineEx(tracetable)

		if (tracetable.hit)
		{
			local firepit = SpawnEntityFromTable("info_particle_system",
			{
				origin             = where
				angles             = QAngle(-90, 0, 0)
				start_active       = 1,
				effect_name        = "cauldron_flamethrower"
			})

			firepit.KeyValueFromString("classname", "firedeath")

			firepit.ValidateScriptScope()
			firepit.GetScriptScope().owner <- creator
			firepit.GetScriptScope().team <- creator.GetTeam()
			firepit.GetScriptScope().crit <- crits

			AddThinkToEnt(firepit, "FirePit_Think")

			EntFireByHandle(firepit, "Kill", null, 3.0, null, null)

			if (!creator.IsFakeClient()) return

			foreach (player in GetAllPlayers(2))
			{
				if (TraceLine(where, player.EyePosition(), player) == 1.0)
				{
					if (!("vistip_firepit" in player.GetScriptScope()))
					{
						player.GetScriptScope().vistip_firepit <- true
						SendGlobalGameEvent("show_annotation",
						{
							id = player.entindex()
							text = "Pyroman's grenades leave columns\nof fire where they land!"
							worldPosX = where.x
							worldPosY = where.y
							worldPosZ = where.z + 150
							visibilityBitfield = (1 << player.entindex())
							play_sound = "misc/null.wav"
							show_distance = false
							show_effect = false
							lifetime = 7.5
						})
					}
				}
			}
		}
	}

	Coffin_Think = function()
	{
		if (thinkertick % 7 != 0) return
		if (!intel_entity.IsValid()) return

		local intel_y = intel_entity.GetOrigin().y

		if (!coffins_active) return

		if (intel_y < -1000.0) 						active_zombie_spawns = [8, 11]
		if (intel_y >= -1000.0 && intel_y < 1500.0) active_zombie_spawns = [0, 2]
		if (intel_y >= 1500.0) 						active_zombie_spawns = [0, 7]
	}

	CoffinProp_Think = function()
	{
		if (!("beam" in this))
		{
			active_anim <- null

			local unique = UniqueString()

			beam_apex <- SpawnEntityFromTable("info_teleport_destination", { targetname = unique, origin = self.GetOrigin() + Vector(0, 0, 1500) })

			beam <- SpawnEntityFromTable("env_beam",
			{
				targetname				= self.GetName() + "_beam_" + unique
				origin					= self.GetOrigin()
				life                    = 0
				boltwidth               = 25
				LightningStart			= self.GetName() + "_beam_" + unique
				LightningEnd			= unique
				NoiseAmplitude          = 1
				rendercolor				= "56 243 171"
				texture					= "sprites/laserbeam.spr"
				spawnflags				= 0
			})
		}

		if (id < active_zombie_spawns[0] || id > active_zombie_spawns[1] || !coffins_active)
		{
			active_anim = "ref"
			if (NetProps.GetPropInt(beam, "m_active") == 1) beam.AcceptInput("TurnOff", null, null, null)
		}

		else
		{
			active_anim = "taunt_the_crypt_creeper_A1"
			if (NetProps.GetPropInt(beam, "m_active") == 0) beam.AcceptInput("TurnOn", null, null, null)
		}

		self.StudioFrameAdvance()
		self.DispatchAnimEvents(self)

		if (self.GetSequenceName(self.GetSequence()).find("A1") != null)
		{
			if (self.GetCycle() > 0.7) self.ResetSequence(self.LookupSequence(active_anim))
			if (self.GetCycle() == 0.0 || (self.GetCycle() > 0.27 && self.GetCycle() < 0.275)) EmitSoundEx({sound_name = coffin_sounds[RandomInt(0, coffin_sounds.len() - 1)], channel = 6, entity = self, sound_level = 75, pitch = 100 + RandomInt(-20, 20)})
		}

		if (self.GetSequenceName(self.GetSequence()).find("A2") != null)
		{
			if (self.GetCycle() > 0.2 && self.GetCycle() < 0.6) self.SetCycle(0.6)
			if (self.GetCycle() > 0.8) self.ResetSequence(self.LookupSequence(active_anim))
		}

		return -1
	}

	Conch_Think = function()
	{
		if (!("owner" in this)) owner <- self.GetOwner()

		foreach (player in GetAllPlayers(3, [owner.GetOrigin(), 450.0]))
		{
			player.AddCondEx(29, 0.25, owner)

			local foundaura = false

			for (local child = player.FirstMoveChild(); child != null; child = child.NextMovePeer()) { if (child.GetName() == "conchbuffaura") foundaura = true }

			if (foundaura) continue

			local buffaura = SpawnEntityFromTable("info_particle_system",
			{
				targetname = "conchbuffaura"
				origin = player.GetOrigin()
				effect_name = "soldierbuff_mvm"
				start_active = 1
				flag_as_weather = 0
			})

			buffaura.AcceptInput("SetParent", "!activator", player, player)

			EntFireByHandle(buffaura, "Kill", null, 1.0, null, null)
		}

		return 0.1
	}

	Ballman_Think = function()
	{
		try { self.GetScriptScope() }
		catch (e) { return -1 }

		local owner = NetProps.GetPropEntity(self, "m_hOwner")
		local scope = self.GetScriptScope()

		if (!("chargetime" in scope))
		{
			scope.chargetime <- 0
			scope.damage <- 0
			scope.ballspeed <- 0
			scope.ballgravity <- 0
			scope.fullstun <- false
		}

		if (owner.InCond(0))
		{
			local reloadattr = self.GetAttribute("faster reload rate", 1.0)
			local dmgattr = self.GetAttribute("damage bonus", 1.0)

			chargetime = (Time() - NetProps.GetPropFloat(self, "m_flChargeBeginTime")) * (1.0 + (0.5 * ((1.0 - reloadattr) / 0.2)))

			if (chargetime >= 1.0) chargetime = 1.0

			damage = (50.0 + (70.0 * chargetime)) * dmgattr
			ballspeed = RemapValClamped(chargetime, 0.0, 1.0, 1200, 2000)
			ballgravity = RemapValClamped(chargetime, 0.0, 1.0, 0.5, 0.2)

			if (chargetime >= 1.0) fullstun = true
		}

		else chargetime = 0.0

		for (local ent; ent = Entities.FindByClassname(ent, "tf_projectile_arrow"); )
		{
			if (ent.GetOwner() != owner) continue

			local ball = SpawnEntityFromTable("tf_projectile_stun_ball",
			{
				teamnum      = ent.GetTeam()
				origin       = ent.GetOrigin()
				angles       = ent.GetAbsAngles()
			})

			ball.SetMoveType(5, 2)
			ball.SetGravity(ballgravity)

			local vecVelocity = Vector(0, 0, 0)
			vecVelocity += owner.EyeAngles().Forward() * 15
			vecVelocity += owner.EyeAngles().Up() * 0.5
			vecVelocity.Norm()
			vecVelocity *= ballspeed

			ball.ApplyAbsVelocityImpulse(vecVelocity)

			ball.SetOwner(owner)
			NetProps.SetPropEntity(ball, "m_hLauncher", ball) // this will let us access the ball in ontakedamage hook

			ball.ValidateScriptScope()
			ball.GetScriptScope().ignite <- false
			ball.GetScriptScope().weapon <- self
			ball.GetScriptScope().fullstun <- fullstun

			fullstun = false

			AddThinkToEnt(ball, "Ball_Think")

			if (NetProps.GetPropBool(ent, "m_bArrowAlight"))
			{
				ball.GetScriptScope().ignite = true

				local particle = SpawnEntityFromTable("trigger_particle",
				{
					particle_name = "m_brazier_flame"
					attachment_type = 1
					spawnflags = 64
				})

				NetProps.SetPropBool(particle, "m_bForcePurgeFixedupStrings", true)

				particle.AcceptInput("StartTouch", "!activator", ball, ball)
				particle.Kill()
			}

			if (NetProps.GetPropBool(ent, "m_bCritical")) NetProps.SetPropBool(ball, "m_bCritical", true)

			ent.Kill()
		}

		return -1
	}

	FireDemo_Think = function()
	{
		local owner = NetProps.GetPropEntity(self, "m_hOwner")

		for (local ent; ent = Entities.FindByClassname(ent, "tf_projectile_pipe"); )
		{
			if (NetProps.GetPropEntity(ent, "m_hThrower") != owner) continue

			ent.ValidateScriptScope()
			local proj_scope = ent.GetScriptScope()

			if (!("flameparticle" in proj_scope))
			{
				proj_scope.flameparticle <- SpawnEntityFromTable("trigger_particle",
				{
					particle_name = "m_brazier_flame"
					attachment_type = 1
					spawnflags = 64
				})

				proj_scope.flameparticle.AcceptInput("StartTouch", "!activator", ent, ent)
				proj_scope.flameparticle.Kill()

				proj_scope.owner <- owner
				proj_scope.crit <- (NetProps.GetPropBool(ent, "m_bCritical")) ? 1048576 : 0

				proj_scope.OnGameEvent_object_deflected <- function(params)
				{
					if (params.object_entindex == owner.entindex()) owner = GetPlayerFromUserID(params.userid)
				}

				SetDestroyCallback(ent, function() { CreateFirePit(self.GetOrigin(), self.GetScriptScope().owner, self.GetScriptScope().crit) })

				__CollectGameEventCallbacks(proj_scope)
			}
		}

		return -1
	}

	MedicShotgun_Think = function()
	{
		if (!("patient_alive" in this))
		{
			owner <- self.GetOwner()

			if (owner.HasBotTag("no_patient"))
			{
				patient_alive <- false

				local origmodel = owner.GetModelName()

				owner.SetCustomModelWithClassAnimations("models/bots/heavy_boss/bot_heavy_boss.mdl")
				owner.KeyValueFromInt("rendermode", 1)
				owner.KeyValueFromInt("renderamt", 0)

				local newmodel = owner.GetWearable(origmodel)

				newmodel.KeyValueFromString("targetname", "glow_target")

				glow <- SpawnEntityFromTable("tf_glow",
				{
					target           	  = "glow_target"
					origin				  = owner.EyePosition()
					GlowColor			  = "125 168 196 255"
					StartDisabled		  = 1
				})

				glow.AcceptInput("SetParent", "!activator", newmodel, newmodel)

				newmodel.KeyValueFromString("targetname", "")

				local shotgun = owner.GetWeapon("tf_weapon_shotgun_hwg", 11)

				shotgun.AddAttribute("fire rate bonus", 2.5, -1.0)
				shotgun.AddAttribute("bullets per shot bonus", 10.0, -1.0)
				shotgun.AddAttribute("damage penalty", 0.5, -1.0)
				shotgun.AddAttribute("faster reload rate", 0.1, -1.0)
			}

			if (owner.GetHealTarget() == null) return -1

			owner.AddBotAttribute(8)

			patient_alive <- true

			medigun <- NetProps.GetPropEntityArray(owner, "m_hMyWeapons", 1)
			patient <- owner.GetHealTarget()

			connected <- false
			distlimit <- 450

			// lifetime <- 1.0
			// drain_amount <- 24.0

			// drain_amount <- format("%.1f", (patient.GetMaxHealth().tofloat() / 1750.0)).tofloat()
			drain_amount <- 7.0
			drainbank_amount <- 0

			drain_interval <- 10

			// local attempts = 1

			// the more you add a number to itself, the less accurate the result! adding 0.7 to itself ten times in this loop below won't return 7!
			// the only way is to multiply it by a number, reset it if it doesn't match, and then increase the multiplier

			// for (local i = drain_amount; i <= (drain_amount * 10.0); i *= attempts) // rise the drained amount to a non-floating number
			// {
				// drain_interval++
				// attempts++

				// if (i == (drain_amount * 10.0)) { drain_amount = i; break }
				// if (i.tointeger() != i) { i = drain_amount; continue }

				// drain_amount = i
				// break
			// }

			nextdraintime <- thinkertick + drain_interval

			if (patient.GetPlayerClass() == 1) owner.AddCustomAttribute("CARD: move speed bonus", 10, -1.0)

			local patient_beamend = UniqueString()
			local healer_beamstart = UniqueString()

			medigun.KeyValueFromString("targetname", healer_beamstart)
			patient.KeyValueFromString("targetname", patient_beamend)

			beam_start <- SpawnEntityFromTable("env_beam",
			{
				targetname				= healer_beamstart
				origin					= medigun.GetCenter()
				life                    = 0
				boltwidth               = 15
				LightningStart			= healer_beamstart
				LightningEnd			= patient_beamend
				NoiseAmplitude          = 1
				rendercolor				= "110 0 0"
				texture					= "sprites/laserbeam.spr"
				spawnflags				= 0
			})

			medigun.KeyValueFromString("targetname", "")
			patient.KeyValueFromString("targetname", "")

			dist <- 0

			shotguncallbacks <-
			{
				OnGameEvent_player_death = function(params)
				{
					local dead_player = GetPlayerFromUserID(params.userid)

					if (dead_player == owner)
					{
						owner.KeyValueFromInt("rendermode", 0)

						owner.SetCustomModelWithClassAnimations("models/bots/medic/bot_medic.mdl")

						intel_entity.AcceptInput("ForceGlowDisabled", "0", null, null)

						delete shotguncallbacks

						glow.Kill()

						return
					}

					if (dead_player.IsFakeClient())
					{
						if (dead_player == patient)
						{
							owner.RemoveCustomAttribute("CARD: move speed bonus")

							local origmodel = owner.GetModelName()

							owner.SetCustomModelWithClassAnimations("models/bots/heavy_boss/bot_heavy_boss.mdl")
							owner.KeyValueFromInt("rendermode", 1)
							owner.KeyValueFromInt("renderamt", 0)

							local newmodel = owner.GetWearable(origmodel)

							newmodel.KeyValueFromString("targetname", "glow_target")

							glow <- SpawnEntityFromTable("tf_glow",
							{
								target           	  = "glow_target"
								origin				  = owner.EyePosition()
								GlowColor			  = "125 168 196 255"
								StartDisabled		  = 1
							})

							glow.AcceptInput("SetParent", "!activator", newmodel, newmodel)

							newmodel.KeyValueFromString("targetname", "")

							try { beam_start.Kill() }
							catch (e) {}

							local shotgun = owner.GetWeapon("tf_weapon_shotgun_hwg", 11)

							shotgun.AddAttribute("fire rate bonus", 2.5, -1.0)
							shotgun.AddAttribute("bullets per shot bonus", 10.0, -1.0)
							shotgun.AddAttribute("damage penalty", 0.5, -1.0)
							shotgun.AddAttribute("faster reload rate", 0.1, -1.0)

							EntFireByHandle(owner, "RunScriptCode", "self.RemoveBotAttribute(8)", 2.5, null, null)

							owner.EmitSound("vo/mvm/norm/medic_mvm_" + medicshotgun_soundarray[RandomInt(0, medicshotgun_soundarray.len() - 1)] + ".mp3")

							patient_alive = false
						}
					}
				}
			}

			foreach (name, callback in shotguncallbacks) shotguncallbacks[name] = callback.bindenv(this)

			__CollectGameEventCallbacks(shotguncallbacks)
		}

		if (patient_alive)
		{
			if (thinkertick % 7 == 0)
			{
				foreach (player in GetAllPlayers(2))
				{
					if (TraceLine(owner.EyePosition(), player.EyePosition(), owner) == 1.0)
					{
						if (!("vistip_medicshotgun" in player.GetScriptScope()))
						{
							player.GetScriptScope().vistip_medicshotgun <- true
							SendGlobalGameEvent("show_annotation",
							{
								id = player.entindex()
								text = "Giant Shotgun Medics leech\nhealth from their patients!"
								follow_entindex = owner.entindex()
								visibilityBitfield = (1 << player.entindex())
								play_sound = "misc/null.wav"
								show_distance = false
								show_effect = false
								lifetime = 7.5
							})
						}
					}
				}

				if (!connected)
				{
					distlimit = 450
					patient.AddCustomAttribute("CARD: move speed bonus", 0.01, -1.0)
				}

				else
				{
					patient.RemoveCustomAttribute("CARD: move speed bonus")
					distlimit = 540
				}

				dist = (patient.GetCenter() - medigun.GetOrigin()).Length()

				if (dist > distlimit) { { if (NetProps.GetPropInt(beam_start, "m_active") == 1) beam_start.AcceptInput("TurnOff", null, null, null) } ; connected = false }
				else							  { { if (NetProps.GetPropInt(beam_start, "m_active") == 0) beam_start.AcceptInput("TurnOn", null, null, null) } ; connected = true }
			}

			if (connected && nextdraintime <= thinkertick)
			{
				nextdraintime = thinkertick + drain_interval

				if (patient.GetHealth().tofloat() < 35.0) patient.TakeDamage(195.0, 64, patient)

				else patient.SetHealth(patient.GetHealth().tofloat() - drain_amount)

				if (owner.GetHealth() < owner.GetMaxHealth())
				{
					owner.SetHealth(owner.GetHealth().tofloat() + drain_amount)

					if (drainbank_amount > 0)
					{
						owner.SetHealth(owner.GetHealth().tofloat() + drain_amount)
						drainbank_amount -= drain_amount
					}
				}

				else drainbank_amount += drain_amount
			}
		}

		else
		{
			foreach (player in GetAllPlayers(2))
			{
				if (!("vistip_medicshotgun2" in player.GetScriptScope()))
				{
					if (TraceLine(owner.EyePosition(), player.EyePosition(), owner) == 1.0)
					{
						player.GetScriptScope().vistip_medicshotgun2 <- true
						SendGlobalGameEvent("show_annotation",
						{
							id = player.entindex()
							text = "When their patient dies,\nthey bring out their shotguns!"
							follow_entindex = owner.entindex()
							visibilityBitfield = (1 << player.entindex())
							play_sound = "misc/null.wav"
							show_distance = false
							show_effect = false
							lifetime = 7.5
						})
					}
				}
			}

			if (owner.HasItem())
			{
				intel_entity.AcceptInput("ForceGlowDisabled", "1", null, null)
				glow.Enable()
			}
		}

		return -1
	}

	SamuraiSoldier_Think = function()
	{
		if (!("owner" in this))
		{
			owner <- self.GetOwner()
			origmodel <- owner.GetModelName()
			jumping <- false
			dummymodel <- null
			in_cooldown <- true
			cooldown_exittime <- thinkertick + ((!owner.HasBotTag("samurai_minion") ? 250 : 1000) * RandomFloat(0.75, 1.25))
			activated <- false
			hat <- (!owner.HasBotTag("samurai_minion")) ? "models/player/items/soldier/soldier_samurai.mdl" : "models/workshop/player/items/sniper/robo_sniper_soldered_sensei/robo_sniper_soldered_sensei.mdl"

			if (owner.HasBotTag("samurai_minion"))
			{
				local hat = owner.GetWearable(hat, false, "head", [Vector(5, 0, -128), QAngle()])
				hat.SetModelScale(1.45, -1.0)

				foreach (player in GetAllPlayers(3))
				{
					if (player.HasBotTag("valid_samurai"))
					{
						owner.Teleport(true, player.GetOrigin(), false, QAngle(), true, Vector(RandomInt(-500, 500), RandomInt(-500, 500), 0))
						break
					}
				}
			}
		}

		if (dummymodel != null)
		{
			if (dummymodel.GetCycle() >= 0.8)
			{
				local dummykill = dummymodel

				dummymodel = null
				dummykill.Kill()

				owner.SetMoveType(2, 0)

				owner.SetCustomModelOffset(Vector())
			}
		}

		if (thinkertick % 6 != 0) return -1

		if (jumping && owner.IsGrounded()) jumping = false

		if (jumping && owner.GetAbsVelocity().z <= 0 && !in_cooldown)
		{
			foreach (player in GetAllPlayers(2))
			{
				if (TraceLine(owner.EyePosition(), player.EyePosition(), owner) == 1.0)
				{
					if (!("vistip_samuraisoldier" in player.GetScriptScope()))
					{
						player.GetScriptScope().vistip_samuraisoldier <- true
						SendGlobalGameEvent("show_annotation",
						{
							id = player.entindex()
							text = "Samurai Soldiers duplicate\nthemselves when they jump!"
							follow_entindex = owner.entindex()
							// worldPosX = where.x
							// worldPosY = where.y
							// worldPosZ = where.z + 225
							visibilityBitfield = (1 << player.entindex())
							play_sound = "misc/null.wav"
							show_distance = false
							show_effect = false
							lifetime = 7.5
						})
					}
				}
			}

			owner.SetMoveType(0, 0)

			owner.SetCustomModelOffset(Vector(0, 0, -5000))

			dummymodel = SpawnEntityFromTable("prop_dynamic",
			{
				targetname			 = "dummymodel_" + owner.entindex()
				origin         		 = owner.GetOrigin()
				skin 		   		 = 1
				modelscale	   		 = 1.3
				model          		 = "models/player/soldier.mdl"
				defaultanim    		 = "taunt07"
				disablebonefollowers = 1
				rendermode			 = 1
				renderamt			 = 0
			})

			SpawnEntityFromTable("prop_dynamic_ornament",
			{
				model                   = origmodel
				skin 					= 1
				modelscale				= 1.3
				disablebonefollowers	= 1
				initialowner			= "dummymodel_" + owner.entindex()
			})

			SpawnEntityFromTable("prop_dynamic_ornament",
			{
				model                   = hat
				modelscale				= 1.45
				skin 					= 1
				disablebonefollowers	= 1
				initialowner			= "dummymodel_" + owner.entindex()
			})

			if (!owner.HasBotTag("samurai_minion"))
			{
				EnableSpawn("samurai")
				EntFireByHandle(spawnbot_samurai, "Disable", null, 0.1, null, null)
			}

			else
			{
				EnableSpawn("samurai_2")
				EntFireByHandle(spawnbot_samurai_2, "Disable", null, 0.1, null, null)
			}

			owner.AddBotTag("valid_samurai")
			EntFireByHandle(owner, "RunScriptCode", "self.RemoveBotTag(`valid_samurai`)", 0.1, null, null)

			PrecacheSound("items/samurai/TF_samurai_noisemaker_setA_01.wav")
			PrecacheSound("items/samurai/TF_samurai_noisemaker_setA_02.wav")
			PrecacheSound("items/samurai/TF_samurai_noisemaker_setA_03.wav")
			PrecacheSound("items/samurai/TF_conch.wav")

			if (!activated)
			{
				if (thinkertick >= nextconchsoundtime)
				{
					owner.EmitSound("Samurai.Conch")
					nextconchsoundtime = thinkertick + 66
				}
			}

			EmitSoundEx({sound_name = "items/samurai/TF_samurai_noisemaker_setA_0" + RandomInt(1, 3) + ".wav", channel = 6, entity = owner, sound_level = 150})

			for (local i = 0; i <= 5; i++)
			{
				local sfx = SpawnEntityFromTable("info_particle_system", { origin = owner.EyePosition() + Vector(RandomInt(-150, 150), RandomInt(-150, 150), RandomInt(-150, 150)), effect_name = "eyeboss_team_blue", start_active = 1, flag_as_weather = 0 } )
				EntFireByHandle(sfx, "Kill", null, 3.0, null, null)
			}

			activated = true
			in_cooldown = true

			cooldown_exittime = thinkertick + (1000 * RandomFloat(0.75, 1.25))
		}

		if (owner.IsGrounded() && !in_cooldown)
		{
			local alivesamurais = 0

			foreach (player in GetAllPlayers(3))
			{
				if (!player.HasBotTag("samurai_soldier")) continue

				alivesamurais++
			}

			if (alivesamurais < 10)
			{
				local trace =
				{
					start = owner.EyePosition() + Vector(0, 0, 150),
					end = owner.EyePosition() + Vector(0, 0, 150),
					hullmin = owner.GetBoundingMins() + Vector(0, 0, 150),
					hullmax = owner.GetBoundingMaxs() + Vector(0, 0, 150),
					mask = 33636363,
					ignore = owner
				}

				TraceHull(trace)

				if (!("startsolid" in trace))
				{
					owner.GetLocomotionInterface().Jump()
					jumping = true
				}
			}
		}

		if (in_cooldown && (thinkertick >= cooldown_exittime)) in_cooldown = false

		if (activated)
		{
			foreach (player in GetAllPlayers(3, [owner.GetOrigin(), 450.0]))
			{
				player.AddCondEx(29, 0.25, owner)

				local foundaura = false

				for (local child = player.FirstMoveChild(); child != null; child = child.NextMovePeer()) { if (child.GetName() == "conchbuffaura") foundaura = true }

				local buffaura = SpawnEntityFromTable("info_particle_system",
				{
					targetname = "conchbuffaura"
					effect_name = "soldierbuff_mvm"
					origin = player.GetOrigin()
					start_active = 1
					flag_as_weather = 0
				})

				buffaura.AcceptInput("SetParent", "!activator", player, player)

				EntFireByHandle(buffaura, "Kill", null, 1.0, null, null)
			}
		}
	}

	Bonk_Think = function()
	{
		if (!("owner" in this))
		{
			owner <- self.GetOwner()
			drank <- false

			DrinkBonk <- function()
			{
				if (drank) return

				NetProps.SetPropFloat(owner, "m_flEnergyDrinkMeter", 100.0)
				NetProps.SetPropIntArray(owner, "m_iAmmo", 1, 5)
				drank = true

				foreach (player in GetAllPlayers(3, [owner.GetOrigin(), 450.0]))
				{
					if (player == owner) continue
					if (player.HasBotTag("bonk"))
					{
						local think = NetProps.GetPropEntityArray(player, "m_hMyWeapons", 0)

						think.GetScriptScope().DrinkBonk()
					}
				}
			}
		}

		if (drank) return 3600

		NetProps.SetPropFloat(owner, "m_Shared.m_flEnergyDrinkMeter", 0.0)
		NetProps.SetPropIntArray(owner, "m_iAmmo", 0, 5)	// drink meter will instantly replenish as long as this is not 0

		return -1
	}

	FirePit_Think = function()
	{
		for (local entity_to_burn; entity_to_burn = Entities.FindInSphere(entity_to_burn, self.GetOrigin(), 90.0); )
		{
			if (entity_to_burn.GetClassname() == "tf_weapon_compound_bow") NetProps.SetPropBool(entity_to_burn, "m_bArrowAlight", true)
			if (entity_to_burn.GetClassname() == "tf_projectile_arrow") NetProps.SetPropBool(entity_to_burn, "m_bArrowAlight", true)

			if (entity_to_burn.GetTeam() == team) continue

			local dmg = (entity_to_burn.GetClassname() == "obj_sentrygun") ? 3.25 : 6.5

			entity_to_burn.TakeDamageEx(self, owner, ignite_player, Vector(0, 0, 0), entity_to_burn.GetOrigin(), dmg, 8 + crit)
		}

		return 0.075
	}

	TunnelSpawnFix_Think = function()
	{
		for (local pumpkin; pumpkin = Entities.FindByClassname(pumpkin, "tf_ammo_pack"); )
		{
			if (NetProps.GetPropInt(pumpkin, "m_nModelIndex") == PrecacheModel("models/props_halloween/pumpkin_loot.mdl")) EntFireByHandle(pumpkin, "Kill", null, -1.0, null, null)
		}

		foreach (player in GetAllPlayers(3, [Vector(1000, -2500, -50), 300]))	// rc3 has removed nav areas in the tunnel, so this has to be done
		{
			player.GetLocomotionInterface().Approach(Vector(1000, -2200, -50), 9999.9)
			player.AddCondEx(51, 0.5, null)	// spoof spawn protection

			local bounds = (player.HasBotAttribute(32768)) ? Vector(154, 66, 136) : Vector(128, 44, 136)

			if (IsInside(player.GetOrigin(), Vector(1016, -2336, -16) - bounds, Vector(1016, -2336, -16) + bounds))
			{
				player.Teleport(true, player.GetOrigin() + Vector(0, 72, 8), false, QAngle(), false, Vector())
			}
		}
	}

	BallHead_Think = function()
	{
		local scope = self.GetScriptScope()

		if (!("victim" in scope))
		{
			scope.victim <- self.GetRootMoveParent()
			scope.jumped <- false
			scope.endtime <- Time() + 7.5

			PrecacheSound("Engineer.PainCrticialDeath01")

			if (victim.GetPlayerClass() == 4) EntFireByHandle(victim, "RunScriptCode", "EmitSoundEx({sound_name = `Demoman.PainCrticialDeath0` + RandomInt(1, 3), origin = self.GetOrigin(), special_dsp = 14})", RandomFloat(1.0, 3.0), null, null)

			else EntFireByHandle(victim, "RunScriptCode", "EmitSoundEx({sound_name = class_integers[self.GetPlayerClass()] + `.PainCrticialDeath0` + RandomInt(1, 3), origin = self.GetOrigin(), special_dsp = 14})", RandomFloat(1.0, 3.0), null, null)

			if (!("vistip_ballhead" in victim.GetScriptScope()))
			{
				victim.GetScriptScope().vistip_ballhead <- true
				SendGlobalGameEvent("show_annotation",
				{
					id = self.entindex()
					text = "Ballman's balls put\nyou into Ballvision!"
					follow_entindex = self.entindex()
					visibilityBitfield = (1 << victim.entindex())
					play_sound = "misc/null.wav"
					show_distance = false
					show_effect = false
					lifetime = 7.5
				})
			}

			scope.End <- function()
			{
				SendGlobalGameEvent("hide_annotation", { id = self.entindex() })

				victim.SetForcedTauntCam(0)
				victim.RemoveCustomAttribute("voice pitch scale")
				victim.RemoveCustomAttribute("head scale")

				delete victim.GetScriptScope().ballent

				NetProps.SetPropString(self, "m_iszScriptThinkFunction", "")
				AddThinkToEnt(self, null)
				self.Kill()
			}

			victim.SetForcedTauntCam(1)
			victim.AddCustomAttribute("voice pitch scale", 0, -1.0)

			scope.OnGameEvent_player_death <- function(params)
			{
				local dead_player = GetPlayerFromUserID(params.userid)

				if (dead_player == victim) End()
			}

			scope.OnGameEvent_recalculate_holidays <- function(params) { End() }

			__CollectGameEventCallbacks(scope)
		}

		if (ignite && !victim.InCond(22)) victim.TakeDamageEx(owner, owner, ignite_player, Vector(0, 0, 0), victim.GetOrigin(), 6.5, 8)

		if (!jumped)
		{
			if (victim.IsJumping()) endtime -= 3.75
			jumped = true
		}

		if (NetProps.GetPropEntity(victim, "m_hGroundEntity") != null) jumped = false

		if (Time() >= endtime) End()

		return -1
	}

	Ball_Think = function()
	{
		try { self.GetScriptScope() }
		catch (e) { return }

		if (NetProps.GetPropBool(self, "m_bTouched"))
		{
			self.SetGravity(1.0)

			NetProps.SetPropString(self, "m_iszScriptThinkFunction", "")
			AddThinkToEnt(self, null)
			return
		}

		for (local ent; ent = Entities.FindByClassnameWithin(ent, "obj_sentrygun", self.GetOrigin(), 50.0); )
		{
			if (ent.GetTeam() == self.GetTeam()) continue
			if (NetProps.GetPropBool(ent, "m_bBuilding")) continue

			ent.ValidateScriptScope()
			local sentryscope = ent.GetScriptScope()

			if ("balled" in sentryscope)
			{
				if (NetProps.GetPropInt(ent, "m_iUpgradeLevel") == 1) continue

				if (sentryscope.balled == 0) sentryscope.AttachBall()
				else continue
			}

			else AddThinkToEnt(ent, "SentryBall_Think")

			ent.TakeDamage(1.0, 64, self)

			NetProps.SetPropString(self, "m_iszScriptThinkFunction", "")
			self.Kill()

			break
		}

		return -1
	}

	SentryBall_Think = function()
	{
		local scope = self.GetScriptScope()

		if (!("balled" in scope))
		{
			scope.balled <- 0
			scope.lasthealth <- self.GetHealth()
			scope.endtime <- thinkertick + 150
			scope.blocknextshot <- false
			scope.AttachBall <- function()
			{
				local sentryball

				if (!("sentryball1" in scope))
				{
					if (NetProps.GetPropInt(self, "m_iUpgradeLevel") > 1) blocknextshot = true

					scope.sentryball1 <- SpawnEntityFromTable("prop_dynamic",
					{
						origin             	 = self.GetOrigin()
						disablebonefollowers = 1
						model 			   	 = "models/weapons/w_models/w_baseball.mdl"
					})

					sentryball = sentryball1
				}

				else if (!("sentryball2" in scope))
				{
					balled = 1
					scope.sentryball2 <- SpawnEntityFromTable("prop_dynamic",
					{
						origin             	 = self.GetOrigin()
						disablebonefollowers = 1
						model 			   	 = "models/weapons/w_models/w_baseball.mdl"
					})

					sentryball = sentryball2
				}

				else return

				local sound = "weapons/sentry_damage" + RandomInt(1, 4) + ".wav"

				EmitSoundEx({sound_name = sound, entity = self, channel = 6, sound_level = 150})
				EmitSoundEx({sound_name = sound, entity = self, channel = 6, sound_level = 150})
				EmitSoundEx({sound_name = sound, entity = self, channel = 6, sound_level = 150})

				sentryball.AcceptInput("SetParent", "!activator", self, null)

				local attach

				if (NetProps.GetPropInt(self, "m_iUpgradeLevel") == 1) attach = "muzzle"
				else
				{
					if ("sentryball1" in scope) attach = "muzzle_r"
					if ("sentryball2" in scope)	attach = "muzzle_l"
				}

				EntFireByHandle(sentryball, "SetParentAttachment", attach, 0.1, null, null)
			}

			AttachBall()
		}

		if ((balled == 0 && NetProps.GetPropInt(self, "m_iUpgradeLevel") == 1) || balled == 1) NetProps.SetPropInt(self, "m_iState", 1)

		if (self.GetHealth() > lasthealth || thinkertick >= endtime)
		{
			sentryball1.Kill()
			if ("sentryball2" in scope) sentryball2.Kill()

			NetProps.SetPropInt(self, "m_iState", 2)

			self.TerminateScriptScope()
			NetProps.SetPropString(self, "m_iszScriptThinkFunction", "")
			AddThinkToEnt(self, null)
			return
		}

		lasthealth = self.GetHealth()

		return -1
	}

	MapCleanup = function()
	{
		foreach (player in GetAllPlayers(false, false, false))
		{
			player.SetCustomModelWithClassAnimations("")
			NetProps.SetPropInt(player, "m_nRenderMode", 0)

			local killarray = []

			for (local child = player.FirstMoveChild(); child != null; child = child.NextMovePeer()) { if ("custom_wearable" in child.GetScriptScope()) killarray.append(child)	}

			foreach (ent in killarray) ent.Kill()
		}
	}

	CustomSpawns = function() // borrow unused spawns to create new ones
	{
		for (local ent; ent = Entities.FindByName(ent, "spawnbot_invasion"); ) // disable all but one spawn from each group
		{
			if (NetProps.GetPropInt(ent, "m_iHammerID") != 1396201) { ent.Disable(); ent.KeyValueFromString("targetname", "nospawn") }
			else { ent.SetAbsOrigin(Vector(-640, -2528, -93.8702)); spawnbot_support = ent }
		}

		for (local ent; ent = Entities.FindByName(ent, "spawnbot_giant"); )
		{
			if (NetProps.GetPropInt(ent, "m_iHammerID") != 1159734) { ent.Disable(); ent.KeyValueFromString("targetname", "nospawn") }
			else { ent.SetAbsOrigin(Vector(-640, -2528, -93.8702)); spawnbot_support_2 = ent }
		}

		for (local ent; ent = Entities.FindByName(ent, "spawnbot_giant_side"); )
		{
			if (NetProps.GetPropInt(ent, "m_iHammerID") != 1362195) { ent.Disable(); ent.KeyValueFromString("targetname", "nospawn") }
			else { ent.SetAbsOrigin(Vector(-640, -2528, -93.8702)); spawnbot_support_3 = ent }
		}

		for (local ent; ent = Entities.FindByName(ent, "spawnbot_mission_sniper"); )
		{
			if (NetProps.GetPropInt(ent, "m_iHammerID") != 1850196) { ent.Disable(); ent.KeyValueFromString("targetname", "nospawn") }
			else { ent.SetAbsOrigin(Vector(-640, -2528, -93.8702)); spawnbot_samurai = ent }
		}

		for (local ent; ent = Entities.FindByName(ent, "spawnbot_mission_spy"); )
		{
			if (NetProps.GetPropInt(ent, "m_iHammerID") != 1362199) { ent.Disable(); ent.KeyValueFromString("targetname", "nospawn") }
			else { ent.SetAbsOrigin(Vector(-640, -2528, -93.8702)); spawnbot_samurai_2 = ent }
		}
	}

	// funcs copied from pea2.nut go below

	c = @(txt) ClientPrint(null,3,"" + txt)

	SetPEA2Funcs = function()
	{
		::PEA_GLOBAL <-
		{
			IsInside = function(vector, min, max) { return vector.x >= min.x && vector.x <= max.x && vector.y >= min.y && vector.y <= max.y && vector.z >= min.z && vector.z <= max.z }

			// EnableSpawn = function(...) { foreach (name in vargv) Entities.FindByName(null, "spawnbot_" + name).Enable() }
			// DisableSpawn = function(...) { foreach (name in vargv) Entities.FindByName(null, "spawnbot_" + name).Disable() }

			EnableSpawn = function(...) { foreach (name in vargv) getroottable()["spawnbot_" + name].Enable() }
			DisableSpawn = function(...) { foreach (name in vargv) getroottable()["spawnbot_" + name].Disable() }

			SnapVectorToGround = function(pos, offset = false)
			{
				local tracetable =
				{
					start = pos
					end = pos - Vector(0, 0, 5000)
					mask = -1
				}

				TraceLineEx(tracetable)

				if (!offset) return tracetable.pos
				else		 return (tracetable.pos + Vector(0, 0, offset))
			}

			GetAllPlayers = function(team = false, radius = false, alive = true)
			{
				local resultarray = []

				if (radius)
				{
					for (local player; player = Entities.FindByClassnameWithin(player, "player", radius[0], radius[1]); )
					{
						if (team) { if (player.GetTeam() != team) continue }
						if (alive) { if (!player.IsAlive()) continue }

						resultarray.append(player)
					}
				}

				else
				{
					local maxclients = MaxClients().tointeger()

					for (local i = 1; i <= maxclients; i++)
					{
						local player = PlayerInstanceFromIndex(i)

						if (player == null) continue

						if (team) { if (player.GetTeam() != team) continue }
						if (alive) { if (!player.IsAlive()) continue }

						resultarray.append(player)
					}
				}

				return resultarray
			}

			EmitGlobalSound = function(sound)
			{
				SendGlobalGameEvent("teamplay_broadcast_audio",
				{
					team             = -1,
					sound            = sound
					additional_flags = 0
					player           = -1
				})
			}

			AttachGlow = function(color)
			{
				self.KeyValueFromString("targetname", "glow_target")

				local glow = SpawnEntityFromTable("tf_glow",
				{
					origin				  = self.EyePosition()
					target           	  = "glow_target"
					GlowColor             = color
				})

				self.KeyValueFromString("targetname", "")

				glow.AcceptInput("SetParent", "!activator", self.GetActiveWeapon(), self.GetActiveWeapon()) // parenting a tf_glow fixes issues where it doesn't render if it's too far from you

				return glow
			}

			ConnectNavAreas = function(navarray) { foreach (pair in navarray) NavMesh.GetNavAreaByID(pair[0]).ConnectTo(NavMesh.GetNavAreaByID(pair[1]), NavMesh.GetNavAreaByID(pair[0]).ComputeDirection(NavMesh.GetNavAreaByID(pair[1]).GetCenter())) }

			DisconnectNavAreas = function(navarray) { foreach (pair in navarray) NavMesh.GetNavAreaByID(pair[0]).Disconnect(NavMesh.GetNavAreaByID(pair[1])) }

			UnblockNavAreas = function(navarray) { foreach (nav in navarray) NavMesh.GetNavAreaByID(nav).UnblockArea() }

			SpawnNavBrush = function(name, pos, xyz1, xyz2, tagname = false, avoid = true)
			{
				if (!tagname) tagname = name.slice(4)

				local classname = "func_nav_" + ((avoid) ? "avoid" : "prefer")

				for (local i = 1; i <= 2; i++)
				{
					local navbrush = SpawnEntityFromTable(classname, { targetname = name, origin = pos, tags = tagname }) // do it twice just to make sure

					navbrush.KeyValueFromInt("solid", 2)
					navbrush.KeyValueFromString("mins", xyz1)
					navbrush.KeyValueFromString("maxs", xyz2)
				}
			}

			GiveNavAvoidToNavArea = function(name, area, tag = "", height = 500.0)
			{
				local avoid = SpawnEntityFromTable("func_nav_avoid",
				{
					origin           = area.GetCenter()
					tags             = tag
				})

				avoid.KeyValueFromInt("solid", 2)
				avoid.KeyValueFromString("mins", "-1 -1 -1")
				avoid.KeyValueFromString("maxs", "1 1 1")
			}

			CreatePathHologram = function(where, angle)
			{
				local projector = SpawnEntityFromTable("prop_dynamic",
				{
					origin             = SnapVectorToGround(where)
					model 			   = "models/props_mvm/hologram_projector.mdl"
					shadowcastdist	   = 0
				})

				local hologram = SpawnEntityFromTable("prop_dynamic",
				{
					origin             = SnapVectorToGround(where, 5.0)
					angles			   = angle
					model 			   = "models/props_mvm/robot_hologram.mdl"
					rendercolor 	   = "138 187 247"
					disableshadows     = 1
				})
			}

			ThinksTable = {}

			GlobalThinker = function()
			{
				thinkertick++

				foreach (func in ThinksTable) func()

				return -1
			}

			AssignThinkToThinksTable = function(think) { if (!(think in getroottable()["ThinksTable"])) getroottable()["ThinksTable"][think] <- getroottable()[think] }

			RemoveThinkFromThinksTable = function(think) { if (think in getroottable()["ThinksTable"]) delete getroottable()["ThinksTable"][think] }

			RecordIconData = function()
			{
				local icontable = {}
				local slot = "."

				for (local i = 0; i <= 12; i++)
				{
					if (i == 12)
					{
						i = 0

						if (slot == ".") slot = "2."
						else break
					}

					local name = NetProps.GetPropStringArray(objective_resource_entity, "m_iszMannVsMachineWaveClassNames" + slot, i)

					if (name == "") continue

					local tablename = name

					local count = NetProps.GetPropIntArray(objective_resource_entity, "m_nMannVsMachineWaveClassCounts" + slot, i)
					local flag = NetProps.GetPropIntArray(objective_resource_entity, "m_nMannVsMachineWaveClassFlags" + slot, i)

					if (tablename in icontable)
					{
						for (local i = 2; i <= 5; i++)
						{
							if ((tablename + i) in icontable) continue

							tablename += i

							break
						}
					}

					icontable[tablename] <- [name, count, flag, [slot, i]]
				}

				return icontable
			}

			LockInIconData = function()
			{
				foreach (name, data in icons)
				{
					if (name == "tank") continue
					if (name == "teleporter") continue

					NetProps.SetPropStringArray(objective_resource_entity, "m_iszMannVsMachineWaveClassNames" + data[3][0], data[0], data[3][1])
					NetProps.SetPropIntArray(objective_resource_entity, "m_nMannVsMachineWaveClassCounts" + data[3][0], data[1], data[3][1])
					NetProps.SetPropIntArray(objective_resource_entity, "m_nMannVsMachineWaveClassFlags" + data[3][0], data[2], data[3][1])
				}
			}

			HandleIconSuffixes = function()
			{
				foreach (icon in icons)
				{
					local name = icon[0]

					if (endswith(name, "_crit")) SetIconName(name, name.slice(0, name.len() - 5), true)
				}
			}

			SetBotIcon = @(txt) NetProps.SetPropString(self, "m_PlayerClass.m_iszClassIcon", txt)
			GetBotIcon = @() NetProps.GetPropString(self, "m_PlayerClass.m_iszClassIcon")

			TankIconUpdate = @() SetIconCount("tank", GetIconCount("tank") - 1, true)	// renaming the tank icon slot's name in any way will make tank destructions not update the tank amount on the wave bar, so let's use this as a workaround

			GetIconCount = @(name) icons[name][1]
			GetIconFlag = @(name) icons[name][2]
			GetIconSlot = @(name) icons[name][3]

			GetNextSlot = function(slot)
			{
				local output = slot

				output[1] += 1

				if (output[1] > 11)
				{
					output[0] = "2."
					output[1] -= 12
				}

				return output
			}

			GetIconInSlot = function(slot)
			{
				foreach (name, data in icons) { if (data[3][0] == slot[0] && data[3][1] == slot[1]) return data[0] }
			}

			GetIconAmount = @() icons.len()

			WaveHasIcon = @(name) name in icons

			SetIconName = function(oldname, newname, lockin = false)
			{
				if (!(oldname in icons)) return
				icons[oldname][0] = newname
				if (lockin) NetProps.SetPropStringArray(objective_resource_entity, "m_iszMannVsMachineWaveClassNames" + icons[oldname][3][0], newname, icons[oldname][3][1])
			}

			SetIconCount = function(name, count, lockin = false)
			{
				if (!(name in icons)) return
				icons[name][1] = count
				if (lockin) NetProps.SetPropIntArray(objective_resource_entity, "m_nMannVsMachineWaveClassCounts" + icons[name][3][0], count, icons[name][3][1])
			}

			SetIconFlag = function(name, flag, lockin = false)
			{
				if (!(name in icons)) return

				local oldflag = icons[name][2]
				icons[name][2] = flag

				if (lockin)
				{
					if (oldflag & 1 && !flag) SetTotalEnemyCount(GetTotalEnemyCount() - icons[name][1])
					NetProps.SetPropIntArray(objective_resource_entity, "m_nMannVsMachineWaveClassFlags" + icons[name][3][0], flag, icons[name][3][1])
				}
			}

			SetIconSlot = function(name, slot)
			{
				icons[name][3][0] = slot[0]
				icons[name][3][1] = slot[1]
			}

			AddToIconCount = function(name, count, lockin = false)
			{
				if (!WaveHasIcon(name)) { return AddIcon(name, name, 1, count) }

				SetIconCount(name, GetIconCount(name) + count, lockin)
			}

			GetTotalEnemyCount = function() { return NetProps.GetPropInt(objective_resource_entity, "m_nMannVsMachineWaveEnemyCount") }
			SetTotalEnemyCount = function(amount) { NetProps.SetPropInt(objective_resource_entity, "m_nMannVsMachineWaveEnemyCount", amount) }

			AddIcon = function(tablename, name, flag, count, slot = false)
			{
				local targetslot = []

				if (slot)
				{
					ShiftIcons(slot)

					targetslot = slot
				}

				else
				{
					targetslot = [".", GetIconAmount()]

					if (targetslot[1] > 11)
					{
						targetslot[0] = "2."
						targetslot[1] -= 12
					}
				}

				icons[tablename] <- [name, count, flag, [targetslot[0], targetslot[1]]]
			}

			ShiftIcons = function(start, amount = 1)
			{
				local startslot = SlotConvert(start)

				foreach (name, data in icons)
				{
					local slot = SlotConvert(data[3])

					if (slot < startslot) continue

					data[3][1] += amount

					if (data[3][1] > 11)
					{
						data[3][0] = "2."
						data[3][1] -= 12
					}

					if (data[3][1] < 0)
					{
						data[3][0] = "."
						data[3][1] = 11
					}
				}
			}

			SlotConvert = function(slot)
			{
				switch (typeof(slot))
				{
					case "integer":
					{
						if (slot > 11) return ["2.", slot - 12]
						return [".", slot]
					}

					case "array":
					{
						if (slot[0] == ".") return slot[1]
						return (slot[1] + 12)
					}
				}
			}

			Clamp = function(val, minVal, maxVal)
			{
				if (maxVal < minVal)   return maxVal
				else if (val < minVal) return minVal
				else if (val > maxVal) return maxVal
				else 				   return val
			}

			RemapValClamped = function(val, A, B, C, D)
			{
				if (A == B) return ((val >= B) ? D : C)

				local cVal = (val - A) / (B - A)

				cVal = Clamp(cVal, 0.0, 1.0)

				return (C + (D - C) * cVal)
			}

			SetDestroyCallback = function(entity, callback) // credit goes to ficool2 for function code
			{
				entity.ValidateScriptScope()
				local scope = entity.GetScriptScope()
				scope.setdelegate
				(
					{}.setdelegate
					(
						{
							parent   = scope.getdelegate()
							id       = entity.GetScriptId()
							index    = entity.entindex()
							callback = callback
							_get = function(keytofetch) { return parent[keytofetch] }
							_delslot = function(keytodelete)
							{
								if (keytodelete == id)
								{
									entity = EntIndexToHScript(index)
									local scope = entity.GetScriptScope()
									scope.self <- entity
									callback.pcall(scope)
								}

								delete parent[keytodelete]
							}
						}
					)
				)
			}

			InstantReady_Think = function()
			{
				if (NetProps.GetPropBoolArray(Entities.FindByClassname(null, "tf_gamerules"), "m_bPlayerReady", 1) && !InWave()) NetProps.SetPropFloat(Entities.FindByClassname(null, "tf_gamerules"), "m_flRestartRoundTime", Time())
			}

			SetDestroy = function(ply)
			{
				if (!ply.IsFakeClient()) return

				owner <- ply
				Delete1 <- function() { EntFire("!self", "CallScriptFunction", "Delete2", 0.1) } // this is to allow the wearable to persist on the bot's ragdoll
				Delete2 <- function() { self.Kill(); delete ent_callbacks }
				ent_callbacks <-
				{
					OnGameEvent_recalculate_holidays = function(params) Delete2()
					OnGameEvent_player_spawn = function(params) { if (GetPlayerFromUserID(params.userid) == owner) Delete2() }
					OnGameEvent_player_death = function(params) { if (GetPlayerFromUserID(params.userid) == owner) Delete1() }
				}

				foreach (name, callback in ent_callbacks) ent_callbacks[name] = callback.bindenv(this)

				__CollectGameEventCallbacks(ent_callbacks)
			}
		}

		foreach (varname, vardata in PEA_GLOBAL) getroottable()[varname] <- vardata
	}

	SetPEA2ClassFuncs = function()
	{
		CBaseEntity.Enable <- function() { this.AcceptInput("Enable", null, null, null) }
		CBaseEntity.Disable <- function() { this.AcceptInput("Disable", null, null, null) }

		CTFBot.Zombify <- function()
		{
			for (local child = this.FirstMoveChild(); child != null; child = child.NextMovePeer())
			{
				if (child.GetClassname() == "tf_wearable" && child.GetModelName().find("tw_") != null) child.DisableDraw()
			}

			NetProps.SetPropBool(this, "m_bForcedSkin", true)
			NetProps.SetPropInt(this, "m_nForcedSkin", 5)
			NetProps.SetPropInt(this, "m_iPlayerSkinOverride", 1)
			this.GetWearableItem(zombieitems[this.GetPlayerClass() - 1])
			this.SetCustomModelWithClassAnimations(format("models/player/%s.mdl", class_integers[this.GetPlayerClass()]))
			this.AddCustomAttribute("voice pitch scale", 0, -1.0)
		}

		CTFPlayer.IsGrounded <- function() { return NetProps.GetPropEntity(this, "m_hGroundEntity") != null }
		CTFBot.IsGrounded <- function() { return NetProps.GetPropEntity(this, "m_hGroundEntity") != null }

		CTFPlayer.GetWeapon <- function(className, itemID)
		{
			local weapon = Entities.CreateByClassname(className)

			NetProps.SetPropInt(weapon, "m_AttributeManager.m_Item.m_iItemDefinitionIndex", itemID)
			NetProps.SetPropBool(weapon, "m_AttributeManager.m_Item.m_bInitialized", true)
			NetProps.SetPropBool(weapon, "m_bValidatedAttachedEntity", true)

			weapon.SetTeam(this.GetTeam())

			Entities.DispatchSpawn(weapon)

			for (local i = 0; i < 8; i++)
			{
				local heldWeapon = NetProps.GetPropEntityArray(this, "m_hMyWeapons", i)

				if (heldWeapon == null) continue
				if (heldWeapon.GetSlot() != weapon.GetSlot()) continue

				heldWeapon.Destroy()

				NetProps.SetPropEntityArray(this, "m_hMyWeapons", null, i)
				break
			}

			if (itemID == 28)
			{
				NetProps.SetPropInt(weapon, "m_iObjectType", 0)
				NetProps.SetPropInt(weapon, "m_iSubType", 0)
				NetProps.SetPropBoolArray(weapon, "m_aBuildableObjectTypes", true, 0)
				NetProps.SetPropBoolArray(weapon, "m_aBuildableObjectTypes", true, 1)
				NetProps.SetPropBoolArray(weapon, "m_aBuildableObjectTypes", true, 2)
			}

			this.Weapon_Equip(weapon)
			this.Weapon_Switch(weapon)

			return weapon
		}

		CTFBot.GetWeapon <- CTFPlayer.GetWeapon

		CTFPlayer.GetWearable <- function(model, bonemerge = true, attachment = null, offsets = null)
		{
			local modelIndex = GetModelIndex(model)

			if (modelIndex == -1) modelIndex = ::PrecacheModel(model)

			local wearable = Entities.CreateByClassname("tf_wearable")

			NetProps.SetPropInt(wearable, "m_nModelIndex", modelIndex)

			wearable.SetSkin(this.GetTeam())
			wearable.SetTeam(this.GetTeam())
			wearable.SetSolidFlags(4)
			wearable.SetCollisionGroup(11)

			wearable.SetOwner(this)
			Entities.DispatchSpawn(wearable)

			NetProps.SetPropInt(wearable, "m_fEffects", bonemerge ? 129 : 0)

			wearable.AcceptInput("SetParent", "!activator", this, this)

			if (attachment != null) wearable.AcceptInput("SetParentAttachment", attachment, null, null)

			if (offsets != null)
			{
				EntFireByHandle(wearable, "RunScriptCode", "self.SetLocalOrigin(Vector(" + offsets[0].x + ", " + offsets[0].y + ", " + offsets[0].z + "))", 0.1, null, null)
				EntFireByHandle(wearable, "RunScriptCode", "self.SetLocalAngles(QAngle(" + offsets[1].x + ", " + offsets[1].y + ", " + offsets[1].z + "))", 0.1, null, null)
			}

			else
			{
				EntFireByHandle(wearable, "RunScriptCode", "self.SetLocalOrigin(Vector(0, 0, 0))", 0.1, null, null)
				EntFireByHandle(wearable, "RunScriptCode", "self.SetLocalAngles(QAngle(0, 0, 0))", 0.1, null, null)
			}

			wearable.ValidateScriptScope()
			wearable.GetScriptScope().custom_wearable <- true

			NetProps.SetPropBool(wearable, "m_bClientSideAnimation", false)

			SetDestroy.call(wearable.GetScriptScope(), this)

			return wearable
		}

		CTFBot.GetWearable <- CTFPlayer.GetWearable

		CTFPlayer.GetWearableItem <- function(id)
		{
			local dummy_Weapon = Entities.CreateByClassname("tf_weapon_parachute")
			NetProps.SetPropInt(dummy_Weapon, "m_AttributeManager.m_Item.m_iItemDefinitionIndex", 1101)
			NetProps.SetPropBool(dummy_Weapon, "m_AttributeManager.m_Item.m_bInitialized", true)

			dummy_Weapon.SetTeam(this.GetTeam())
			dummy_Weapon.DispatchSpawn()

			this.Weapon_Equip(dummy_Weapon)

			local wearable = NetProps.GetPropEntity(dummy_Weapon, "m_hExtraWearable")

			dummy_Weapon.Kill()

			NetProps.SetPropInt(wearable, "m_AttributeManager.m_Item.m_iItemDefinitionIndex", id)

			NetProps.SetPropBool(wearable, "m_AttributeManager.m_Item.m_bInitialized", true)
			wearable.DispatchSpawn()

			wearable.ValidateScriptScope()
			wearable.GetScriptScope().custom_wearable <- true

			SetDestroy.call(wearable.GetScriptScope(), this)

			return wearable
		}

		CTFBot.GetWearableItem <- CTFPlayer.GetWearableItem
	}
}

foreach (name, callback in PEA.CALLBACKS) PEA.CALLBACKS[name] = callback.bindenv(this)

__CollectGameEventCallbacks(PEA.CALLBACKS)

foreach (thing, var in PEA) getroottable()[thing] <- getroottable()["PEA"][thing]

PrecacheScriptSound("MVM.BotStep")
PrecacheScriptSound("Samurai.Conch")
PrecacheScriptSound("Player.IsNowIT")

SetPEA2Funcs()

ThinksTable.clear()

if (!("PEA_ONETIME" in getroottable()))
{
	SetPEA2ClassFuncs()

	::PEA_ONETIME <- // declare these variables only once on initial load, don't update them on any future loads
	{
		gamerules_entity = Entities.FindByClassname(null, "tf_gamerules")
		objective_resource_entity = Entities.FindByClassname(null, "tf_objective_resource")
		debugger = null
		wavewon = false
		mission_name = false

		coffins_active = false
		coffinssetup = false
		suppress_waveend_music = false
		secretwave_unlocked = false
		guaranteedbranch = false

		coffintime_cc = SpawnEntityFromTable("color_correction",
		{
			StartDisabled    = 1
			maxfalloff       = -1
			minfalloff       = -1
			fadeInDuration   = 5.0
			fadeOutDuration  = 5.0
			filename         = "materials/colorcorrection/zombie_cc25.raw"
		})
	}

	foreach (varname, vardata in PEA_ONETIME) getroottable()[varname] <- vardata

	PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = "m_brazier_flame" })

	coffintime_cc.KeyValueFromString("classname", "entity_sign") // this makes the entity preserve itself on mission reloads

	PrecacheSound("misc/ks_tier_02_kill_02.wav")

	DisconnectNavAreas(
	[
		[180, 414], [189, 2077], [189, 6569], [189, 6570], [3264, 1786], [579, 6559], [579, 6561], [579, 6563], [579, 6565], [579, 6567] // rc3 has fixed most of these! use a different list if using rc2!
	])

	// UnblockNavAreas([85, 200, 297, 298, 354, 356, 454, 623, 792, 795, 1075, 1078, 1533, 1540, 1545, 1546, 1547, 2342, 2343, 2371, 2388, 2389])

	mission_name = NetProps.GetPropString(Entities.FindByClassname(null, "tf_objective_resource"), "m_iszMvMPopfileName")
}

CustomSpawns()

AddThinkToEnt(gamerules_entity, "GlobalThinker")

foreach (sound in coffin_sounds) PrecacheSound(sound)

for (local ent; ent = Entities.FindByClassname(ent, "func_nav_prefer"); ) ent.Kill()

for (local ent; ent = Entities.FindByClassname(ent, "func_nav_avoid"); )
{
	local id = NetProps.GetPropInt(ent, "m_iHammerID")

	if (id == 1920728 || id == 1941647 || id == 1395198 || id == 1396096)
	{
		ent.KeyValueFromString("targetname", "nav_avoid_dontdisable")
		continue
	}

	ent.Kill()
}

for (local ent; ent = Entities.FindByName(ent, "bombpath_choose_relay"); ) ent.Disable()
for (local ent; ent = Entities.FindByName(ent, "bombpath_holograms_clear_relay"); ) ent.Disable()

SpawnNavBrush("nav_avoid_giant_upgradestation_dontdisable", Vector(-100, -550, 300), "-250 -250 -250", "250 250 250", "bot_giant")

for (local i = 3; i <= 6; i++) EntFire("sentrynest_right" + i, "Disable")
for (local i = 2; i <= 6; i++) EntFire("sentrynest_left" + i, "Disable")

if (!(!guaranteedbranch)) cross_connections[1].remove(cross_connections[1].find(guaranteedbranch))

if (Wave > 1 && Wave < 5) wavehascoffins = true

if (!wavewon)
{
	coffinssetup = false

	if (wavehascoffins) SetUpCoffins()

	DetermineBombPath(1)

	local cashcollect = SpawnEntityFromTable("trigger_hurt",
	{
		origin		= Vector(1000, -2300, -100)
		targetname  = "tunnelspawncashcollector"
		damage 		= 0.001
		damagecap   = 9999
		damagetype  = 1
		damagemodel = 0
		spawnflags  = 0
	})

	cashcollect.KeyValueFromInt("solid", 2)
	cashcollect.KeyValueFromString("mins", "-150 -1000 -500")
	cashcollect.KeyValueFromString("maxs", "150 0 500")
}

else
{
	EntFireByHandle(gamerules_entity, "RunScriptCode", "DetermineBombPath(1)", 5.0, null, null)

	if (wavehascoffins) { if (!coffinssetup) SetUpCoffins() }

	else { for (local ent; ent = Entities.FindByModel(ent, "models/workshop/player/items/spy/taunt_the_crypt_creeper/taunt_the_crypt_creeper.mdl"); ) ent.Kill() }
}

ignite_player.AddAttribute("Set DamageType Ignite", 1, -1.0)
Entities.DispatchSpawn(ignite_player)

icons = RecordIconData()

ShuffleLogic()
ModifyWaveBar(true)

if (coffins_active) ToggleCoffins()

for (local i = 1; i <= Constants.Server.MAX_PLAYERS; i++)
{
	local player = PlayerInstanceFromIndex(i)

	if (player == null) continue
	if (player.IsFakeClient()) continue
	if (player.GetTeam() != 2) continue

	player.ValidateScriptScope()
	player.SetScriptOverlayMaterial(null)

	local scope = player.GetScriptScope()

	player.AddCustomAttribute("vision opt in flags", 2, -1)
}

AssignThinkToThinksTable("TunnelSpawnFix_Think")
AssignThinkToThinksTable("Coffin_Think")

if (debug)
{
	for (local i = 1; i <= Constants.Server.MAX_PLAYERS; i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (NetProps.GetPropString(player, "m_szNetworkIDString") == "[U:1:95064912]")
		{
			player.SetHealth(90000)
			player.SetMoveType(8, 0)
			player.AddCurrency(10000)
		}
	}

	AssignThinkToThinksTable("InstantReady_Think")
}

seterrorhandler(function(e)
{
	for (local player; player = Entities.FindByClassname(player, "player");)
	{
		if (NetProps.GetPropString(player, "m_szNetworkIDString") == "[U:1:95064912]")
		{
			local Chat = @(m) (printl(m), ClientPrint(player, 2, m))
			ClientPrint(player, 3, format("\x07FF0000AN ERROR HAS OCCURRED [%s].\nCheck console for details", e))

			Chat(format("\n====== TIMESTAMP: %g ======\nAN ERROR HAS OCCURRED [%s]", Time(), e))
			Chat("CALLSTACK")
			local s, l = 2
			while (s = getstackinfos(l++)) Chat(format("*FUNCTION [%s()] %s line [%d]", s.func, s.src, s.line))

			Chat("LOCALS")

			if (s = getstackinfos(2))
			{
				foreach (n, v in s.locals)
				{
					local t = type(v)
					t ==    "null" ? Chat(format("[%s] NULL"  , n))    :
					t == "integer" ? Chat(format("[%s] %d"    , n, v)) :
					t ==   "float" ? Chat(format("[%s] %.14g" , n, v)) :
					t ==  "string" ? Chat(format("[%s] \"%s\"", n, v)) :
									 Chat(format("[%s] %s %s" , n, t, v.tostring()))
				}
			}

			return
		}
	}
})

wavewon = false

local BombHop = function()
{
	if ("hoprange" in this) return

	debug <- false								// enable debugging, this will grant you noclip, godmode, access to debug commands, instant wave start, display messages about what the bomb is doing currently, and display error descriptions in chat and console
	debugger_id <- false						// the steamid of the user that the error handler should only display messages to (set to false to have it display errors to all players instead)
	debug_nodraw <- false						// if on a listen server, should debug draw functions execute?

	pref_spawnnavarea <- false					// personally defined ID of the nav area that should represent the robots' spawn room (set to "false" boolean to have this variable determined automatically)
	pref_hatchnavarea <- false					// personally defined ID of the nav area that should represent the hatch (set to "false" boolean to have this variable determined automatically)
	hoprange <- 500.0							// the roughly minimal distance in HUs that the bomb will aim to travel on each hop (set to 0 for the bomb to hop in place)
	hoptime_min <- 10.0 						// shortest possible cooldown between bomb hops
	hoptime_max <- 30.0 						// longest possible cooldown between bomb hops
	spawndistance_multiplier_min <- 0.9			// how far does the bomb have to be from the spawn for its hopping cooldown to be set to the minimum possible (in percentage of the total distance from spawn to hatch)
	spawndistance_multiplier_max <- 0.1 		// how close does the bomb have to be to the spawn for its hopping cooldown to be set to the maximum possible (in percentage of the total distance from spawn to hatch)
	hopduration <- 100							// how many ticks should a hopping sequence last (1 tick = 0.015s, 100 ticks = 1.5s)
	hopheight <- 100.0							// how tall in HUs should a hop be?
	checkforbadhops <- true						// should the bomb hop timer be accordingly adjusted based on hops that are too short or long?
	nohopping_when_hoptime_is_max <- true 		// should bomb hopping be disabled when hopping cooldown is set to the highest possible
	smoothhopcurve <- true						// should the bomb's hopping curve be smooth?
	allowpickupduringhop <- false				// are robots allowed to pick up the bomb in the middle of its hopping sequence?
	allowbadrouteonfailure <- false				// if no proper route can be made, should the script try to establish any possible one that doesn't care about following the bomb carrier's path?
	hoptimerdisplayclock <- true				// should the hopping timer be represented by a clock icon?
	hoptimerdisplaytext <- false				// should the hopping timer be represented by text? (can use both clock and text at the same time)
	hoptimerdisplaygracetimer <- false			// should the grace period time display under the hopping timer text?

	recovery_hatchdist <- 0.15					// when determining the best place for the bomb to rejoin with the bomb carrier's route, how far does each area have to be from the hatch to be considered? (can be a percentage of the full path's length...
	// recovery_hatchdist <- 1200				// ...or an amount in HUs)

	graceperiod_enabled <- true					// should the bomb have its hopping cooldown fully reset only a certain time after it has been picked up?
	restoredhoptime_penaltyticks <- 30			// how many ticks should it take for the hopping cooldown to fully reset after pickup (the logic runs every 0.1s, so 30 ticks equals 3 seconds)
	restoredhoptime_penaltyspread <- true		// should the hopping cooldown reset gradually over the course of the above variable or should it only fully reset after that time has expired?

	// overlay_material <- false					// the directory path of the material that the overlay will display when the bomb hops (set to false to not display overlays)
	overlay_material <- ["undead_dread_overlays/bombhopalert1", "undead_dread_overlays/bombhopalert2"]	// optionally the variable can be an array, in which case the logic will cycle through its material items periodically
	overlay_refreshtime <- 25					// how long in ticks should be the interval between checking the overlay status?
	overlay_duration <- 300						// for how many ticks should the overlay display (1 tick = 0.015s, 300 ticks = 4.5s)

	hopsound <- "misc/ks_tier_02_kill_02.wav"	// the sound that the bomb will make when hopping ("false" bool will set it to no sound)
	hopsound_level <- 75						// sound_level parameter of the emitsoundex function that emits the hopsound
	variable_hopsound_pitch <- false			// should the pitch of the hop sound vary depending on hop distance?

	prehop_funcs <- []							// an array containing all functions that will be run when the bomb starts hopping (you can append your own functions from outside this script here)
	posthop_funcs <- []							// an array containing all functions that will be run when the bomb stops hopping (you can append your own functions from outside this script here)
	graceexpired_funcs <- []					// an array containing all functions that will be run when the bomb's grace timer expires (you can append your own functions from outside this script here)

	hop_responses_enabled <- true				// should the mercs react to hopping bombs with voicelines?
	hop_response_radius <- 450.0				// the radius in HUs that defines how close a player has to be to a hopping bomb to be able to respond to it
	hop_response_chance <- 4					// odds of a player responding to a hopping bomb (odds in % are 100 divided by this variable, values below 1 are set to 1)

	hop_responses <- 							// the voicelines that the mercs will use when reacting to a hopping bomb (all of these were repurposed from the payload game mode)
	{
		scout = [2512, 2513, 2514, 2515, 2516, 2517],
		soldier = [],
		pyro = [],
		demoman = [7719, 7720],
		heavy = [1990, 2070, 2268],
		engineer = [],
		sniper = [2335, 2444, 2445],
		medic = [],
		spy = []
	}

	hop_response_conditions <-					// array containing functions that will be run when determining whether to play a hop response cue
	[
		[										// each item in the array must be another array containing two items:
			SniperZoom <- function(ply)			// 1. the function that checks whether a cue should run (should always demand a player input that is provided by the think function)
			{
				if (ply.InCond(1) && ply.GetPlayerClass() == 2) return true	// the function must return a "true" bool if its check passes

				return false
			},

			[2519, 2542, 2543]					// 2. and another array containing the list of voice cues to randomly select from if successful
		]
	]

	function hopcurve_func() { return ((hopend + hopstart) * 0.5) + Vector(0, 0, hopheight) }	// the function that determines the apex of the bomb's hop (and overall curve if smoothhopcurve is set to true)

	// if bomb hopping isn't working properly on a certain map, experimenting with toggling the variables below might help address any issues

	fixpoornavconnections <- true			// certain maps tend to have nav areas that are wrongly connected to other unreachable areas that are far above them, setting this to true will adjust these connections to be one-directional (up -> down) (reload the map to undo this)
	evaluatedisabledprefers <- true			// should path calculation take disabled func_nav_prefer entities into consideration for better path determination? (this may produce path failures on sequoia-styled gate maps that use prefers for guiding bots through shortcuts)
	considerburiedareas <- false			// when looking for areas affected by nav cost brushes, should those that are clipping with the world receive extra height calculations? (recommended for maps that use lots of ramps or curbs)
	ignoreelevatedareas <- false			// should the pathing ignore nav areas that are a specified amount of HUs above the ground? (recommended for maps that tend to make bots go airborne like hoovydam and radar)
	areaheightlimit <- 100.0				// how far from the ground does a nav area have to be for the pathing to discard it?

	// if bomb hopping isn't working properly on a certain map, experimenting with toggling the variables above might help address any issues

	mapspecfic_improvements <- true		// should the script automatically set certain variables based on the current map? (recommended)

	// you are free to change up the variables above in any way you want via the "SetParams" function, or by editing this file directly

	lifetick <- 0							// amount of ticks that passed since script creation
	terminate <- false						// is the script meant to end its run asap?
	defaultreset_cooldown <- NetProps.GetPropInt(self, "m_nReturnTime")	// how long does it take for the bomb to reset in vanilla gameplay

	allareas <- []							// array representing ALL nav areas on the map
	spawnareas <- []						// array representing all nav areas inside robots' spawn room(s)

	alwaysallownav_array <- []				// an array holding all nav areas will never be put into the "blocknav_array" variable
	neverallownav_array <- []				// an array holding all nav areas will always be put into the "blocknav_array" variable

	if (hopsound) PrecacheSound(hopsound)

	local allareas_table = {}
	NavMesh.GetAllAreas(allareas_table)
	for (local i = 0; i < allareas_table.len(); i++) allareas.append(allareas_table["area" + i])
	navconnectionsfixed_check <- allareas[0]
	foreach (nav in allareas) { if (nav.HasAttributeTF(4)) spawnareas.append(nav) }

	////////////////////////////////////////////////
	////////////////////////////////////////////////
	////////////////////////////////////////////////
	// SETUP FUNCTIONS
	////////////////////////////////////////////////
	////////////////////////////////////////////////
	////////////////////////////////////////////////

	function SetUp() // the variables in this function are dynamically adjusted by the think logic, so don't modify them yourself
	{
		nav_interface <- Entities.FindByClassname(null, "tf_point_nav_interface")	// some maps tend to use this entity to dynamically block and unblock certain nav areas midwave, requiring recomputation of the bomb's main route

		hoptime <- hoptime_max				// current cooldown between bomb hops

		blocknav_array <- [] 				// an array holding all nav areas that the bomb's pathing functions should avoid using

		spawnnavarea <- false				// the area that is currently being used to represent the robots' spawn room
		hatchnavarea <- false				// the area that is currently being used to represent the hatch
		nohopping <- true					// is the bomb allowed to hop
		moving <- false 					// is the bomb currently hopping?
		toapex <- true 						// if the bomb is hopping, is it currently on its way towards the apex of the hop?
		hopstart <- Vector() 				// where the hopping sequence began its course
		hopapex <- Vector() 				// where the apex of the hopping sequence is
		hopend <- Vector() 					// where the hopping sequence ends its course
		hopmovement_detectionrange <- 0		// how close does the bomb have to be to its destination for its hop to be considered done?
		moveamount <- 0						// the vec coordinates added to the bomb's origin every tick while it's moving
		movetarget <- Vector()				// the pos that the bomb is currently moving to
		movetarget_prev <- Vector()			// the previous pos that the bomb was moving to
		endmovetick <- 0					// tick at which a hop should conclude
		hoplength <- 0						// how far did the bomb go on its last hop?
		hopduration_midjump <- 0			// what is the bomb's hop duration for the hop it's currently doing?
		hopcurve_array <- []				// an array containing all vectors the bomb will teleport to while performing a smooth curve hop
		disttospawn <- null 				// the bomb's distance in HUs from its current position to the robot spawn
		fullroute_navarray <- []			// an array containing the nav areas that the bomb will hop over on its way from the spawn to the hatch
		fullroute_length <- 0 				// the total distance in HUs that the bomb has to travel from the robot spawn to the hatch
		routerecovery <- false				// did the bomb get lost and is recovering back to the main route?
		botcarrier <- false					// which bot is carrying me right now?
		evaluatingnavbrushes <- false		// have we evaluated nav brushes on this tick?
		firstpickup <- true					// is the bomb being picked up for the first time this wave?

		restoredhoptime <- 0.0				// the amount of time to deduct from the bomb's hopping cooldown after it has been dropped
		restoredhoptime_remainder <- 0.0	// the amount of time recorded from the previous grace period
		restoredhoptime_penalty <- 0.0		// the amount of time to deduct from the grace period each tick while the bomb is being carried
		restoredhoptime_penaltytick <- 0.0	// the tick at which the grace period should expire

		overlay_on <- false					// is the overlay meant to be displayed right now
		overlay_off_tick <- 0				// the tick at which the overlay should stop being displayed

		debug_pathtest <- false				// are we in the middle of testing bombhop pathing?
		debug_recoverytest <- false			// are we in the middle of testing bombhop recovery pathing?

		text_timer <- false					// the entity responsible for displaying the timer in text form
		text_gracetimer <- false			// the entity responsible for displaying the grace timer

		if (hoptimerdisplaytext)
		{
			text_timer = Entities.FindByName(null, self.GetName() + "_bombhop_texttimer")

			if (text_timer == null)
			{
				text_timer = SpawnEntityFromTable("point_worldtext",
				{
					targetname		= self.GetName() + "_bombhop_texttimer"
					textsize       	= 36
					message        	= ""
					color		   	= "255 255 255"
					font           	= 1
					orientation    	= 1
					textspacingx   	= 1
					textspacingy   	= 1
					rendermode     	= 3
				})

				text_timer.AcceptInput("SetParent", "!activator", self, self)
				text_timer.SetLocalOrigin(Vector(0, 0, 70))
			}

			text_timer.DisableDraw()
		}

		if (hoptimerdisplaygracetimer)
		{
			text_gracetimer = Entities.FindByName(null, self.GetName() + "_bombhop_textgracetimer")

			if (text_gracetimer == null)
			{
				text_gracetimer = SpawnEntityFromTable("point_worldtext",
				{
					targetname		= self.GetName() + "_bombhop_textgracetimer"
					textsize       	= 18
					message        	= ""
					color		   	= "255 255 0"
					font           	= 1
					orientation    	= 1
					textspacingx   	= 1
					textspacingy   	= 1
					rendermode     	= 3
				})

				text_gracetimer.AcceptInput("SetParent", "!activator", self, self)
				text_gracetimer.SetLocalOrigin(Vector(0, 0, 50))
			}

			text_gracetimer.DisableDraw()
		}

		EntFireByHandle(self, "CallScriptFunction", "EvaluateNavBrushes", 0.4, null, null) 	// the nav mesh updates itself only every 0.2s, so let's give it time to acknowledge the brush entities to later scan through

		SetTouchable(true) // this may sometimes run in the middle of a bomb's hop, so let's ensure its solidity is restored
	}

	function NextFrameActions() // functions that will be run a frame after the script has loaded, to give outside scripts a way to intercept any undesirable actions through SetParams
	{
		if (mapspecfic_improvements)
		{
			local mapname = GetMapName()

			if (mapname.find("area_52") != null) evaluatedisabledprefers = false
			if (mapname.find("autumnull") != null) AlwaysAllowNavAreas(10, 15, 18, 33, 100, 231, 2617, 2618, 2619, 3075) // nav_avoids right outside of the spawns cause the logic to completely break
			if (mapname.find("casino_city") != null)
			{
				considerburiedareas = true

				AlwaysAllowNavAreas(5321) // one nav_avoid stretches far enough to block all ways for the bomb to pass through without touching a blocked area
			}
			if (mapname.find("derelict") != null) fixpoornavconnections = true
			if (mapname.find("downtown") != null) { fixpoornavconnections = true; considerburiedareas = true }
			if (mapname.find("giza") != null)
			{
				considerburiedareas = true
				fixpoornavconnections = true

				NavMesh.GetNavAreaByID(6387).Disconnect(NavMesh.GetNavAreaByID(6405)) // one-directional down -> up connection???
			}
			if (mapname.find("hideout") != null) fixpoornavconnections = true
			if (mapname.find("hoovydam") != null)
			{
				NavMesh.GetNavAreaByID(1475).Disconnect(NavMesh.GetNavAreaByID(38))
				NavMesh.GetNavAreaByID(289).ConnectTo(NavMesh.GetNavAreaByID(293), 1)	// remove bad connection from one of the launch fans and replace it with a better one

				ignoreelevatedareas = true
			}
			if (mapname.find("isolation") != null) fixpoornavconnections = true
			if (mapname.find("lotus") != null) fixpoornavconnections = true
			if (mapname.find("meltdown") != null)
			{
				fixpoornavconnections = true

				NeverAllowNavAreas(92) // flank route near bomb has no nav_avoid to discourage bombhop pathing through it (bomb carriers have a nav_prefer at the main entry point so they aren't affected)
			}
			if (mapname.find("metro") != null) fixpoornavconnections = true
			if (mapname.find("_null_") != null) AlwaysAllowNavAreas(15, 18, 33, 100, 231, 2626, 2627, 3102, 3118, 3120, 3127, 3129) // nav_avoids right outside of the spawns cause the logic to completely break
			if (mapname.find("powerplant") != null) fixpoornavconnections = true
			if (mapname.find("radar") != null)
			{
				fixpoornavconnections = true

				NavMesh.GetNavAreaByID(16025).Disconnect(NavMesh.GetNavAreaByID(16970)) // one-directional down -> up connection???
			}
			if (mapname.find("seabed") != null) considerburiedareas = true
			if (mapname.find("sequoia") != null) evaluatedisabledprefers = false
			if (mapname.find("spacepost") != null) evaluatedisabledprefers = true
			if (mapname.find("underworld") != null)
			{
				fixpoornavconnections = true

				NeverAllowNavAreas(73) // right flank route has no nav_avoid whatsoever
			}
		}

		if (debug) SetUpDebug()

		if (GetListenServerHost() == null) debug_nodraw = true	// debug draw commands don't work on non-listen servers

		if (fixpoornavconnections) FixPoorNavConnections()

		if (hoptimerdisplayclock) self.KeyValueFromFloat("ReturnTime", 599.0)	// this netprop doesn't actually control the return time, but it decides whether to draw the clock icon above the bomb (< 600 = draw, >= 600 = don't draw)
		else					  self.KeyValueFromFloat("ReturnTime", 600.0)

		if (typeof(overlay_material) == "string") overlay_material = [overlay_material]
	}

	////////////////////////////////////////////////
	////////////////////////////////////////////////
	////////////////////////////////////////////////
	// INTERACTIVE FUNCTIONS (can be called from your own script)
	////////////////////////////////////////////////
	////////////////////////////////////////////////
	////////////////////////////////////////////////

	/* SetParams example usage:

	local bombscope = Entities.FindByName(null, "bombnamehere").GetScriptScope()

	bombscope.SetParams(
	["hoprange", 800.0],
	["hopduration", 25],
	)

	*/

	function SetParams(...)
	{
		local endresult = []
		local scope = self.GetScriptScope()

		foreach (arg in vargv)
		{
			if (!(arg[0] in scope))
			{
				DebugMsg("SetParams: Parameter " + arg[0] + " doesn't exist, aborting.")
				continue
			}

			if (scope[arg[0]] == arg[1])
			{
				DebugMsg("SetParams: Parameter " + arg[0] + " is already set to value " + arg[1] + ", aborting.")
				continue
			}

			scope[arg[0]] = arg[1]

			local process = []

			process.append(arg[0])
			process.append(arg[1])

			endresult.append(process)

			DebugMsg("SetParams: Successfully set " + arg[0] + " to " + arg[1] + ".")
		}

		DebugMsg("SetParams: Function has successfully executed.", true)

		PostSetParams(endresult)
	}

	// AlwaysAllowNavAreas / NeverAllowNavAreas example usage:
	// bombscope.AlwaysAllowNavAreas(51, 5, 100, 3214, 999)
	// bombscope.NeverAllowNavAreas(24, 48, 2, 75, 1815, 2041)


	function AlwaysAllowNavAreas(...)	// these areas will never be considered as undesirable for path determination
	{
		foreach (navid in vargv) { alwaysallownav_array.append(NavMesh.GetNavAreaByID(navid)) }
	}

	function NeverAllowNavAreas(...) // these areas will always be considered as undesirable for path determination
	{
		foreach (navid in vargv) { neverallownav_array.append(NavMesh.GetNavAreaByID(navid)) }
	}

	function SetTouchable(boolinput) // set whether the robots can pick up the bomb or not, accepts false or true
	{
		if (boolinput)
		{
			NetProps.SetPropInt(self, "m_Collision.m_nSolidType", 2)
			NetProps.SetPropInt(self, "m_Collision.m_usSolidFlags", 140)
		}

		else
		{
			NetProps.SetPropInt(self, "m_Collision.m_nSolidType", 0) 	// we need to make sure the hop is not interrupted by a robot, these netprops make the bomb completely untouchable by robots
			NetProps.SetPropInt(self, "m_Collision.m_usSolidFlags", 0)	// there are SetSolidType and SetSolidFlags VScript functions, but you shouldn't use those, since they permanently alter the bomb's hitbox and cause complications
		}
	}

	function TerminateHopScript(urgent = false)
	{
		terminate = true

		if (moving)	// wait until hopping is done
		{
			if (urgent) HopFinish()
			else
			{
				DebugMsg("Can't terminate in mid-hop, waiting until resolution.", true)
				return
			}
		}

		ClientPrint(null, 2, "BombHop script has successfully terminated for " + self.GetName() + ".")

		self.AcceptInput("SetReturnTime", "" + defaultreset_cooldown, null, null)

		if (defaultreset_cooldown > 600.0) NetProps.SetPropFloat(self, "m_flMaxResetTime", 0.0)

		if (hoptimerdisplaytext) text_timer.Kill()
		if (hoptimerdisplaygracetimer) text_gracetimer.Kill()

		AddThinkToEnt(self, null)
		NetProps.SetPropString(self, "m_iszScriptThinkFunction", "")

		self.TerminateScriptScope()
	}

	////////////////////////////////////////////////
	////////////////////////////////////////////////
	////////////////////////////////////////////////
	// MAIN FUNCTIONS
	////////////////////////////////////////////////
	////////////////////////////////////////////////
	////////////////////////////////////////////////

	function DetermineFullRoute(redo = false)		// this function will run once as soon as the wave starts and attempt to build a "spawn -> hatch" route that imitates the bomb carrier's path, it's crucial for all the other bombhop logic to function properly
	{
		if (NetProps.GetPropBool(self, "m_bDisabled")) return

		DebugMsg("DetermineFullRoute has been called")

		if (!redo)	// the wave has just started, let's determine initial spawn and hatch areas
		{
			DebugMsg("DetermineFullRoute: Initial run detected.")

			if (pref_spawnnavarea || pref_hatchnavarea)	// if starting and/or ending areas were manually provided, use those instead of automatically determining them
			{
				DebugMsg("DetermineFullRoute: Determining spawn or hatch nav areas based off manual input...")

				if (pref_spawnnavarea) spawnnavarea = NavMesh.GetNavAreaByID(pref_spawnnavarea)
				if (pref_hatchnavarea) hatchnavarea = NavMesh.GetNavAreaByID(pref_hatchnavarea)
			}

			if (!spawnnavarea)
			{
				DebugMsg("DetermineFullRoute: spawnnavarea variable not provided, attempting to determine it...")

				if (NetProps.GetPropInt(self, "m_nFlagStatus") == 0)	// depending on the map, bombs with "at home" flags may stay in inaccessible and isolated areas that are far from the map proper
				{
					DebugMsg("DetermineFullRoute: Flag is at home, aborting.", true)

					return false
				}

				local bestarea = false

				if (self.GetOwner() != null) bestarea = self.GetOwner().GetSpawnArea()	// if we're being carried, assume the start area is where the current carrier spawned

				else	// otherwise collect all spawn areas of currently alive bots, and select one that was used the most
				{
					local spawns = {}
					local highestamount = 0

					foreach (player in GetAllPlayers(3))
					{
						if (player.IsOnAnyMission()) continue

						local spawnarea = player.GetSpawnArea()

						if (spawnarea == null) continue

						if (!(spawnarea in spawns)) spawns[spawnarea] <- 0
						spawns[spawnarea]++
					}

					foreach (spawnarea, amount in spawns)
					{
						if (amount > highestamount)
						{
							highestamount = amount
							bestarea = spawnarea
						}
					}
				}

				spawnnavarea = bestarea
			}

			if (!hatchnavarea)
			{
				DebugMsg("DetermineFullRoute: hatchnavarea variable not provided, attempting to determine it...")

				hatchnavarea = FindBestNearestNavMesh(Entities.FindByClassname(null, "func_capturezone").GetCenter())	// any nav mesh that sits as close to where the bomb carrier could start doing its deploying animation
			}
		}

		else DebugMsg("DetermineFullRoute: Redetermining route...") // we're calling this mid-wave, no need to redefine starting and ending points that we already know

		if (!spawnnavarea) DebugMsg("DetermineFullRoute: Failed, couldn't find a NavMesh that's inside the robot spawn", true)
		if (!hatchnavarea) DebugMsg("DetermineFullRoute: Failed, couldn't find a NavMesh that's close to the hatch", true)

		if (!spawnnavarea || !hatchnavarea) return false

		DebugMsg("DetermineFullRoute: Successfully determined spawnnavarea (" + spawnnavarea + ") and hatchnavarea (" + hatchnavarea + ") variables")

		if (blocknav_array.find(spawnnavarea) != null) blocknav_array.remove(blocknav_array.find(spawnnavarea))	// sometimes there might be nav brushes very close to the robot spawn and/or hatch, let's make sure they don't effect the starting and ending areas
		if (blocknav_array.find(hatchnavarea) != null) blocknav_array.remove(blocknav_array.find(hatchnavarea))

		fullroute_navarray = BombHop_BuildPath(spawnnavarea, hatchnavarea)	// build a path that should completely imitate the path a bomb carrier would take

		// some maps tend to have spawn rooms that are gated off from the rest of the map during setup, like bigrock or underworld
		// in that case let's retry and temporarily unblock all meshes that are considered blocked because of these gates

		if (!fullroute_navarray)
		{
			DebugMsg("DetermineFullRoute: Failed to establish path, retrying with unblocked map-placed nav meshes")

			fullroute_navarray = BombHop_BuildPath(spawnnavarea, hatchnavarea, true)
		}

		if (!fullroute_navarray && allowbadrouteonfailure)	// if we really want to, make any possible path, ignoring the bomb carrier's path altogether
		{
			DebugMsg("DetermineFullRoute: Failed to establish path, retrying with no blocked areas.", true)
			fullroute_navarray = BombHop_BuildPath(spawnnavarea, hatchnavarea, true, true)
		}

		if (!fullroute_navarray)	// couldn't make path anyway, keep retrying until something changes
		{
			DebugMsg("DetermineFullRoute: Failed to establish any path, aborting.", true)

			return false
		}

		local new_fullroute_navarray = []	// we ideally don't want the hopping pathing to take spawn rooms into consideration, especially if they're large ones like on decoy

		foreach (nav in fullroute_navarray)	// let's go through all the collected areas and toss out those that have "blu spawnroom" area attribute
		{
			if (GetAreaHeight(nav) > areaheightlimit) continue	// some maps like hoovy dam may place nav areas in mid air, let's not let the bomb stay on such areas (`ignoreelevatedareas` variable has to be set to true)
			if (nav.HasAttributeTF(4)) break					// as soon as we hit an area that's in the spawn room, discard it and all the next ones

			new_fullroute_navarray.append(nav)
		}

		fullroute_navarray = new_fullroute_navarray

		spawnnavarea = fullroute_navarray[fullroute_navarray.len() - 1]	// update the "spawnnavarea" variable that still defines an area in the spawn room, replace it with first one encountered after leaving it
		hatchnavarea = fullroute_navarray[0]

		fullroute_length = DeterminePathLength(fullroute_navarray, [0, 255, 0, 255])

		DebugMsg("DetermineFullRoute ran successfully. fullroute_length = " + fullroute_length + " | fullroute_navarray.len() = " + fullroute_navarray.len(), true)

		if (!redo && NetProps.GetPropInt(self, "m_nFlagStatus") == 2)
		{
			if (hoptimerdisplayclock) self.AcceptInput("ShowTimer", "0.0", null, null)	// display clock if it was hidden
			DetermineReturnTime()	// start the hop timer if the script got called while the bomb was idle
		}

		if (debug && !debug_nodraw)
		{
			DebugDrawText(spawnnavarea.GetCenter(), "SPAWN_NAV", false, 5.0)
			DebugDrawText(hatchnavarea.GetCenter(), "HATCH_NAV", false, 5.0)

			local i = 1

			foreach (nav in fullroute_navarray)
			{
				DebugDrawText(nav.GetCenter(), "" + i, false, 5.0)
				i++
			}
		}
	}

	function DetermineReturnTime(posthop = false)
	{
		if (terminate) { TerminateHopScript(); return }

		if (!InWave()) return										// no point
		if (fullroute_length <= 0) return							// we need a full spawn -> hatch route before we can do anything
		if (NetProps.GetPropInt(self, "m_nFlagStatus") < 2) return	// don't hop if we're not idle
		if (moving)	return											// failsafe

		DebugMsg("DetermineReturnTime has been called")

		if (debug_recoverytest && !routerecovery)
		{
			local recoveryareas = []

			foreach (nav in allareas)
			{
				if (fullroute_navarray.find(nav) != null) continue
				if (nav.HasAttributeTF(2)) continue
				if (nav.HasAttributeTF(4)) continue
				if (nav == hatchnavarea) continue
				if (nav == spawnnavarea) continue

				recoveryareas.append(nav)
			}

			self.SetAbsOrigin(recoveryareas[RandomInt(0, recoveryareas.len() - 1)].GetCenter())
		}

		local calcresult = CalculateDistance()		// we'll need to calculate the distance to tell when and how often the bomb should hop, let's call the function and let it know us what the verdict is

		if (calcresult.atspawn)						// the bomb is sitting nearby the spawn room, so there is nowhere for it to really hop towards
		{
			DebugMsg("DetermineReturnTime: Bomb is sitting in spawn, disabling hopping.", true)

			nohopping = true

			GracePeriodReset()

			NetProps.SetPropFloat(self, "m_flResetTime", Time() + 60000.0)	// this will hide the timer floating above the bomb
			NetProps.SetPropFloat(self, "m_flMaxResetTime", 0.0)

			return -1
		}

		if (!calcresult.success)												// something went wrong, and we don't know why
		{
			DebugMsg("DetermineReturnTime: Distance calculation failed, aborting.", true)

			NetProps.SetPropFloat(self, "m_flResetTime", Time() + hoptime)	// don't hop, try again next time
			NetProps.SetPropFloat(self, "m_flMaxResetTime", hoptime)

			return -1
		}

		// we have determined how far the bomb is from the spawn, let's adjust the hopping timer based on that distance

		hoptime = RemapValClamped(disttospawn, fullroute_length * spawndistance_multiplier_min, fullroute_length * spawndistance_multiplier_max, hoptime_min, hoptime_max)

		if (nohopping_when_hoptime_is_max && hoptime >= hoptime_max && hoptime_min != hoptime_max) 	// the timer can't be any higher than this, meaning the bomb hasn't made any real progress yet
		{
			DebugMsg("DetermineReturnTime: Hopping timer is set to highest possible, disabling hopping.", true)	// let's not beat the dead horse that is the robot team and disable hopping for now

			nohopping = true

			GracePeriodReset()

			TextTimer_Off()

			NetProps.SetPropFloat(self, "m_flResetTime", Time() + 60000.0)
			NetProps.SetPropFloat(self, "m_flMaxResetTime", 0.0)

			return -1
		}

		else nohopping = false	// the bomb did make progress, so let's allow it to hop

		local restoredhoptimepercent = 1.0

		if (graceperiod_enabled) restoredhoptimepercent = GracePeriodApplyTimeDeduction()

		if (posthop && checkforbadhops)				// adjust hop timer based on whether the bomb hopped too little or too far
		{
			DebugMsg("DetermineReturnTime: Last distance travelled was " + hoplength)

			local mult

			if (hoplength <= hoprange) 	mult = RemapValClamped(hoplength, 0, hoprange, 3.0, 1.0)
			else						mult = RemapValClamped(hoplength, hoprange, (hoprange * 2.0), 1.0, 0.5)

			hoptime /= mult

			DebugMsg("DetermineReturnTime: Dividing hop timer by " + mult)
		}

		if (hoptime > (hoptime_max * 2.0)) hoptime = hoptime_max	// failsafe

		if (hoptime < 0.05) { Hop(); return }	// no need to set timer, just hop immediately

		NetProps.SetPropFloat(self, "m_flResetTime", Time() + hoptime)					 	// also refresh the timer icon
		NetProps.SetPropFloat(self, "m_flMaxResetTime", hoptime * restoredhoptimepercent)	// this will make the icon somewhat more accurately represent the grace period

		// 1.5x reset = 1/4, 2x reset = 1/2, 4x reset = 3/4

		DebugMsg("DetermineReturnTime: Successfully set hopping timer to " + hoptime, true)
	}

	function CalculateDistance()				// this function is run whenever the bomb is dropped or when the bomb is about to perform a hop
	{
		DebugMsg("CalculateDistance has been called")

		local resulttable = 							// the function will return this table whenever it's called
		{
			success = false								// have we successfully determined the bomb's path?
			atspawn = false								// have we determined that the bomb is inside or close to a robot spawn room?
		}

		if (hoprange <= 0)
		{
			DebugMsg("CalculateDistance: Bomb is set to hop in place, aborting calculation.", true)
			resulttable.success = true
			return resulttable
		}

		disttospawn = 0

		local hoptarget = false
		local closestroutearea = false
		local recovery_path = {}

		DebugMsg("CalculateDistance: Searching for nearest nav area to bomb's origin...")

		local homenav = FindBestNearestNavMesh(self.GetOrigin())

		if (!homenav)
		{
			DebugMsg("CalculateDistance: Failed to find any nearest nav area to bomb's origin, aborting.", true)
			return resulttable
		}

		DebugMsg("CalculateDistance: Successfully found nearest nav arae to bomb's origin: " + homenav)

		if (homenav.HasAttributeTF(4))
		{
			DebugMsg("CalculateDistance: Bomb is sitting in spawn, aborting.", true)
			resulttable.success = true
			resulttable.atspawn = true
			return resulttable
		}

		local distance = 0
		local fullroute_end = fullroute_navarray[fullroute_navarray.len() - 1]

		DebugMsg("CalculateDistance: Calling CheckIfOnRoute to see if bomb sits on the main route.")

		local fullroute_slot = CheckIfOnRoute(homenav)

		if (fullroute_slot)	// runs if bomb finds itself either directly on the path or pretty close to it
		{
			closestroutearea = fullroute_navarray[fullroute_slot]

			if (closestroutearea == fullroute_end)
			{
				DebugMsg("CalculateDistance: Bomb is next to spawn, aborting.", true)
				resulttable.success = true
				resulttable.atspawn = true
				return resulttable
			}

			fullroute_slot++ // don't actually take the home area into consideration when looking for a hop destiantion

			routerecovery = false

			DebugMsg("CalculateDistance: Found main route close to the bomb, calculating best place to hop onto.")

			hoptarget = fullroute_navarray[fullroute_slot].GetCenter()

			distance += (hoptarget - self.GetOrigin()).Length()

			// ClientPrint(null,3,"initial distance: " + distance)

			if (distance >= hoprange)
			{
				local result = ClampHopDistance(self.GetOrigin(), hoptarget, hoprange)

				if (result) hoptarget = result

				// ClientPrint(null,3,"final distance: " + (hoptarget - self.GetOrigin()).Length())
			}

			else
			{
				for (local i = fullroute_slot; i < fullroute_navarray.len(); i++)	// look through all next areas on the route and determine which one makes the bomb hop the best length
				{
					local area = fullroute_navarray[i]

					if (area == fullroute_end) { hoptarget = area; break }

					local nextarea = fullroute_navarray[i + 1]

					local curdist = (nextarea.GetCenter() - area.GetCenter()).Length()

					distance += curdist	// add distances between next few areas and...

					// DebugDrawText(nextarea.GetCenter(), "" + distance, false, 5.0)

					// ClientPrint(null,3,"new distance: " + distance)

					if (area == fullroute_end || nextarea == fullroute_end) hoptarget = fullroute_end
					// {
						// if (distance >= hoprange) { hoptarget = area; break }
						// else
						// {
							// DebugMsg("CalculateDistance: Bomb is next to spawn, aborting.", true)
							// resulttable.success = true
							// resulttable.atspawn = true
							// return resulttable
						// }
					// }

					if (distance >= hoprange)
					{
						// DebugDrawText(nextarea.GetCenter(), "HOP TARGET (UNFIXED)", false, 5.0)

						local result = ClampHopDistance(area.GetCenter(), nextarea.GetCenter(), curdist - (distance - hoprange))

						if (result) hoptarget = result
						else hoptarget = nextarea.GetCenter()

						// DebugDrawText(hoptarget, "HOP TARGET (FIXED)", false, 5.0)

						// ClientPrint(null,3,"final distance: " + (distance - (curdist - (hoptarget - area.GetCenter()).Length2D())))

						break
					}
				}
			}
		}

		else	// none of the meshes on the route are close to the bomb, meaning it got lost and has to find its way back to the route
		{
			DebugMsg("CalculateDistance: Bomb is not close to the full route, calculating recovery route.")

			routerecovery = true

			local weight = 1.0
			local weight_decrement = (0.4 / fullroute_navarray.len().tofloat())
			local bestdistance = 99999.9
			local hatchdistance = 0
			local prev_area = hatchnavarea

			DebugMsg("CalculateDistance: Weight decrement = " + weight_decrement)

			foreach (area in fullroute_navarray)												// cycle again, look for the best area to rejoin with the route
			{
				weight -= weight_decrement														// manipulate the results a little to encourage the bomb to think more about recovering back to the spawn and not the hatch

				hatchdistance += (area.GetCenter() - prev_area.GetCenter()).Length()

				prev_area = area

				if (recovery_hatchdist <= 1.0 && hatchdistance < (fullroute_length * recovery_hatchdist)) continue	// skip the first areas around the hatch to make the bomb not hop back towards it
				if (recovery_hatchdist > 1.0 && hatchdistance < recovery_hatchdist) continue

				local distance = ((area.GetCenter() - homenav.GetCenter()).Length()) * weight	// determine distance between every area on the route and the area occupied by the bomb (by order from hatch area to spawn area)

				if (distance < bestdistance)
				{
					bestdistance = distance
					hoptarget = area
					closestroutearea = area
				}
			}

			DebugMsg("CalculateDistance: Determined best area to recover to: " + closestroutearea)

			// if (debug && !debug_nodraw)
			// {
				// hoptarget.DebugDrawFilled(0, 0, 255, 255, 5.0, true, 0.0)
				// DebugDrawText(hoptarget.GetCenter(), "-                  RECOVERYCLOSESTAREA", false, 5.0)
			// }

			// the bomb is certainly further from the route than the hop limit allows, meaning we have to build an extra route back to the full route

			local recoveryblock = []

			foreach (nav in GetAllAdjacentAreas(hatchnavarea)) // ensure recovery path doesn't go near hatch
			{
				recoveryblock.append(nav)

				foreach (nav2 in GetAllAdjacentAreas(nav)) recoveryblock.append(nav2)
			}

			foreach (nav in recoveryblock) nav.MarkAsBlocked(3)

			NavMesh.GetNavAreasFromBuildPath(homenav, hoptarget, Vector(), 0.0, 3, false, recovery_path) // otherwise ignore any other nav brush

			foreach (nav in recoveryblock) nav.UnblockArea()

			if (recovery_path.len() <= 0) NavMesh.GetNavAreasFromBuildPath(homenav, hoptarget, Vector(), 0.0, 3, false, recovery_path) // ignore everything and go through hatch if unsuccessful

			DebugMsg("recovery_path.len(): " + recovery_path.len())

			if (recovery_path.len() > 0) // run the same hop distance calculation
			{
				local newarr = []

				for (local i = recovery_path.len() - 1; i >= 0; i--) newarr.append(recovery_path["area" + i])

				recovery_path = newarr

				local recoveryjumpdist = 0

				for (local i = 0; i < recovery_path.len(); i++) // ensure we hop as best as we can
				{
					local cur_recoveryarea = recovery_path[i]
					local next_recoveryarea = recovery_path[i + 1]

					recoveryjumpdist += (next_recoveryarea.GetCenter() - cur_recoveryarea.GetCenter()).Length()

					if (recoveryjumpdist >= hoprange)
					{
						local result = ClampHopDistance(cur_recoveryarea.GetCenter(), next_recoveryarea.GetCenter(), recoveryjumpdist - hoprange)

						if (result) hoptarget = result
						else hoptarget = next_recoveryarea

						break
					}

					if ((i + 1) == recovery_path.len() - 1) { hoptarget = next_recoveryarea; break }
				}
			}
		}

		if (!hoptarget)
		{
			DebugMsg("CalculateDistance: Failed to find a good area to hop onto, aborting.", true)
			return resulttable
		}

		disttospawn = DeterminePathLength(fullroute_navarray, [0, 255, 0, 255], closestroutearea) // calculate the distance from the closest point on the route to the robot spawn
		disttospawn += DeterminePathLength(recovery_path, [255, 255, 0, 255])					 // then add to it the length of the recovery route, if we are on one

		DebugMsg("CalculateDistance: Successfully determined distance to spawn: " + disttospawn)

		// if (debug && !debug_nodraw) DebugDrawText(hoptarget, "-\nBESTCLOSESTAREA", false, 5.0)

		hopend = hoptarget

		if (typeof(hopend) == "instance") hopend = hopend.GetCenter()

		resulttable.success = true
		resulttable.atspawn = (homenav == fullroute_end) ? ((hoprange > 0.0) ? true : false) : false

		DebugMsg("CalculateDistance: Calling EvaluateHopDistance to improve hop distance.")

		// EvaluateHopDistance()	// by default the bomb hops from one nav area's center to another, which is not always efficient given their disproportionate size

		DebugMsg("CalculateDistance: Successfully determined area to hop onto: " + hopend)

		DebugMsg("CalculateDistance has resolved", true)

		return resulttable
	}

	function ClampHopDistance(ar1, ar2, limit)
	{
		// local bestdistance = dist
		local bestplace = false

		local maxz

		local s_orig = ar1
		local e_orig = ar2

		if (s_orig.z >= e_orig.z) 	maxz = s_orig.z
		else 						maxz = e_orig.z

		s_orig.z = maxz
		e_orig.z = maxz

		DebugMsg("EvaluateHopDistance: Dist between start and end is: " + (e_orig - s_orig).Length())
		DebugMsg("EvaluateHopDistance: Dist limit is: " + limit)

		for (local i = 1.0; i <= 9.0; i++)
		{
			DebugMsg("EvaluateHopDistance: CHECK " + i)

			local length = (e_orig - s_orig).Length()
			local point = s_orig + ((e_orig - s_orig) * (i / 10.0)) + Vector(0, 0, 8)

			// DebugDrawBox(point, Vector(-10, -10, -10), Vector(10, 10, 10), 255, 255, 255, 190, 3.0)

			local tracetable =
			{
				start = point
				end = point
				mask = -1
			}

			TraceLineEx(tracetable)

			if ("startsolid" in tracetable)
			{
				DebugMsg("EvaluateHopDistance: Step " + i + " is inside geometry, continuing...")
				continue
			}

			local ground = SnapVectorToGround(point)
			local groundarea = FindBestNearestNavMesh(ground)

			if (!groundarea)
			{
				DebugMsg("EvaluateHopDistance: Step " + i + " has no nav area below it, continuing...")
				continue
			}

			if (CheckIfOnRoute(groundarea) == false)
			{
				DebugMsg("EvaluateHopDistance: Step " + i + "'s nav area is not part of the full route, continuing...")
				continue
			}

			DebugMsg("EvaluateHopDistance: Distance between start and check " + i + " is " + (ground - s_orig).Length())

			bestplace = ground

			if ((ground - s_orig).Length2D() >= limit) break

			// DebugMsg("EvaluateHopDistance: Best distance error is " + bestdistance)
		}

		if (bestplace)
		{
			// DebugMsg("EvaluateHopDistance: Improved hop distance error to " + bestdistance)

			DebugMsg("EvaluateHopDistance: Dist between start and end is now: " + (bestplace - ar1).Length())

			return bestplace
		}

		else DebugMsg("EvaluateHopDistance: Failed to improve hop error.")
	}

	function Hop()
	{
		NetProps.SetPropFloat(self, "m_flResetTime", Time() + 60000.0) // hide the timer icon until we're done hopping
		NetProps.SetPropFloat(self, "m_flMaxResetTime", 0.0)

		local calcresult = CalculateDistance()	// start the calculations to know whether to hop and where

		if (calcresult.atspawn) return -1	// we're in spawn, no need to hop

		if (!calcresult.success)	// failed, try again next time
		{
			NetProps.SetPropFloat(self, "m_flResetTime", Time() + hoptime)

			NetProps.SetPropFloat(self, "m_flMaxResetTime", hoptime)

			return -1
		}

		hopstart = self.GetOrigin()	// the hop begins where the bomb currently is

		if (hoprange <= 0.0) hopend = hopstart

		hoplength = (hopend - hopstart).Length()	// record hop distance for adjusting next hop cooldown
		EmitSoundEx({sound_name = hopsound, channel = 6, entity = self, sound_level = hopsound_level, pitch = (variable_hopsound_pitch) ? (100.0 * (hoprange / hoplength)) : 100.0 })

		hopduration_midjump = hopduration // preserve latest hopduration variable, don't let it get changed during the hop
		hopmovement_detectionrange = (100.0 / hopduration_midjump.tofloat()) * 12.0

		HopUpdateMoveTarget(hopapex, hopstart)

		moving = true

		GracePeriodReset()

		endmovetick = lifetick + hopduration_midjump + 33	// ensure the bomb eventually ends up at its destination if something goes wrong

		HopResponses()

		if (overlay_material)
		{
			overlay_on = true
			overlay_off_tick = lifetick + overlay_duration
		}

		if (!allowpickupduringhop) SetTouchable(false)

		hopapex = hopcurve_func()	// determine where the hop's apex should be

		OnPreHop() // now's a good time to run any extra custom functions from outside scripts

		if (smoothhopcurve)
		{
			hopapex += Vector(0, 0, hopheight)	// bezier curves fall short of the apex so let's compensate
			BombHop_BuildCurve(hopstart, hopend, hopapex, hopduration_midjump)
		}

		TextTimer_Off()

		if (hopduration_midjump == 0.0) HopFinish()
	}

	function EvaluateNavBrushes() 	// building a path that imitates the bomb carrier's path requires us to know and block all undesirable nav areas that we don't want pathing to go through
	{
		if (evaluatingnavbrushes) return	// ensure this runs only once each tick

		DebugMsg("EvaluateNavBrushes has been called.")

		evaluatingnavbrushes = true

		local bombtag = (NetProps.GetPropString(self, "m_iszTags").len() > 0) ? NetProps.GetPropString(self, "m_iszTags") : "bomb_carrier" // if the map has multiple bombs, ensure only the nav brushes related to this bomb are involved

		DebugMsg("EvaluateNavBrushes: Size of blocknav_array before wipe: " + blocknav_array.len())

		blocknav_array.clear()	// reset the list of undesirable areas for recollection

		DebugMsg("EvaluateNavBrushes: Size of blocknav_array after wipe: " + blocknav_array.len())

		DebugMsg("EvaluateNavBrushes: Size of blocknav_array before prefer collection: " + blocknav_array.len())

		if (evaluatedisabledprefers) // if a prefer is supposed to guide the bomb, but is disabled, it probably means the bomb isn't supposed to go through it this wave, making it a useful "pseudo-avoid"
		{
			for (local ent; ent = Entities.FindByClassname(ent, "func_nav_prefer"); ) // scan through all disabled nav_prefers
			{
				if (NetProps.GetPropBool(ent, "m_isDisabled"))
				{
					local tags = split(NetProps.GetPropString(ent, "m_iszTags"), " ")

					if (tags.find("bomb_carrier") != null || tags.find(bombtag) != null)
					{
						foreach (nav in GetAreasObscuredByBrush(ent)) { if (blocknav_array.find(nav) == null) blocknav_array.append(nav) }
					}
				}
			}
		}

		DebugMsg("EvaluateNavBrushes: Size of blocknav_array after prefer collection: " + blocknav_array.len())

		DebugMsg("EvaluateNavBrushes: Bomb tag: " + bombtag)

		for (local ent; ent = Entities.FindByClassname(ent, "func_nav_avoid"); )	// scan through all enabled nav_avoids
		{
			if (NetProps.GetPropBool(ent, "m_isDisabled")) continue

			local tags = split(NetProps.GetPropString(ent, "m_iszTags"), " ")

			if (tags.find("bomb_carrier") != null || tags.find(bombtag) != null)
			{
				foreach (nav in GetAreasObscuredByBrush(ent)) { if (blocknav_array.find(nav) == null) blocknav_array.append(nav) }
			}
		}

		DebugMsg("EvaluateNavBrushes: Size of blocknav_array after avoid collection: " + blocknav_array.len())

		// apply map-specific fixes to the nav mesh

		foreach (nav in alwaysallownav_array) { if (blocknav_array.find(nav) != null) blocknav_array.remove(blocknav_array.find(nav)) }
		foreach (nav in neverallownav_array) { if (blocknav_array.find(nav) == null) blocknav_array.append(nav) }

		DebugMsg("EvaluateNavBrushes: Size of blocknav_array after avoid collection: " + blocknav_array.len())

		if (InWave()) DetermineFullRoute(true)		// if we're calling this in-wave, it's probably because the mesh changed and we need to redefine the route

		EntFireByHandle(self, "RunScriptCode", "evaluatingnavbrushes = false", -1.0, null, null) // make sure this func gets run only once each tick
	}

	function BombHop_Think() // runs every tick
	{
		if (NetProps.GetPropBool(self, "m_bDisabled")) return -1 // bomb is not in use by the mission, no need to use its hopping logic

		if (debug) DebugThink()	// do wave start countdown skip and debug hotkey listeners if we're debugging

		if (!InWave()) return -1 // no need to run this when not in a wave

		lifetick++

		// for the purposes of determining the hop cooldown, we'll need to know the full length of the bomb's path from spawn to hatch
		// if we failed, pause the logic and try again next tick

		if (fullroute_length <= 0 && !DetermineFullRoute()) return -1

		if (IsAtHome()) return -1

		botcarrier = self.GetOwner() // useful for recording who the carrier was when the bomb got dropped

		if (lifetick % 7 == 0) GracePeriodUpdate()

		if (lifetick % overlay_refreshtime == 0) OverlayUpdate()

		UpdateTextTimer()

		if (IsCarried()) return -1

		if (TimeUntilHop() <= 0.05) Hop() // make sure to perform a hop just a few ticks before the actual reset, otherwise the bomb will actually reset back to spawn

		if (moving)	HopMovement() // time to hop

		return -1
	}

	////////////////////////////////////////////////
	////////////////////////////////////////////////
	////////////////////////////////////////////////
	// UTILITY FUNCTIONS
	////////////////////////////////////////////////
	////////////////////////////////////////////////
	////////////////////////////////////////////////

	function DebugMsg(txt, separate = false) { if (debug) ClientPrint(null, 2, "(" + self.GetName() + ") | " + txt + (separate ? "\n---------------------------------------" : "")) }

	function DebugPathTestSetPos(ply)
	{
		if (!debug_pathtest && !debug_recoverytest) return

		local maxclients = MaxClients().tointeger()

		for (local i = 1; i <= maxclients; i++)
		{
			local player = PlayerInstanceFromIndex(i)

			if (player == null) continue
			if (player.GetTeam() != 3) continue
			if (player == ply) continue

			player.SetHealth(0)
			player.SnapEyeAngles(QAngle())
			player.TakeDamage(10000.0, 64, null)
			player.ForceChangeTeam(1, true)
		}

		ply.SetHealth(0)
		ply.SnapEyeAngles(QAngle())
		ply.TakeDamage(10000.0, 64, null)
		ply.ForceChangeTeam(1, true)

		EntFireByHandle(ply, "RunScriptCode", "self.SetHealth(0); self.TakeDamage(10000.0, 64, null)", 0.5, null, null)

		local pop = SpawnEntityFromTable("point_populator_interface", {})

		pop.AcceptInput("PauseBotSpawning", null, null, null)
	}

	function DebugThink()
	{
		if (NetProps.GetPropBoolArray(Entities.FindByClassname(null, "tf_gamerules"), "m_bPlayerReady", 1) && !InWave())
		{
			NetProps.SetPropFloat(Entities.FindByClassname(null, "tf_gamerules"), "m_flRestartRoundTime", Time())
		}

		local maxclients = MaxClients().tointeger()

		for (local i = 1; i <= maxclients; i++)
		{
			local player = PlayerInstanceFromIndex(i)	// allow the bomb to teleport to listen server host with MOUSE3 or wipe debugdraw displays with RELOAD

			if (player == null) continue
			if (player.GetTeam() != 2) continue

			if (NetProps.GetPropInt(player, "m_afButtonLast") & 8192) DebugDrawClear()

			if (!InWave()) continue

			if (NetProps.GetPropInt(player, "m_afButtonLast") & 33554432)
			{
				if (!moving)
				{
					self.SetAbsOrigin(player.GetOrigin())
					DetermineReturnTime()
				}

				else ClientPrint(null, 3, "Can't teleport the bomb while it's hopping.")
			}
		}
	}

	function InWave() { return (!NetProps.GetPropBool(Entities.FindByClassname(null, "tf_objective_resource"), "m_bMannVsMachineBetweenWaves")) }

	function ResetPath() { EntFireByHandle(self, "CallScriptFunction", "SetUp", 0.1, null, null); return true }	// if a bomb has been force-reset after a gate cap, reset most of its variables

	function Clamp(val, minVal, maxVal)
	{
		if (maxVal < minVal)   return maxVal
		else if (val < minVal) return minVal
		else if (val > maxVal) return maxVal
		else 				   return val
	}

	function RemapValClamped(val, A, B, C, D)
	{
		if (A == B) return ((val >= B) ? D : C)

		local cVal = (val - A) / (B - A)

		cVal = Clamp(cVal, 0.0, 1.0)

		return (C + (D - C) * cVal)
	}

	function AddRouteReDeterminationTriggers()
	{
		local scope = self.GetScriptScope()

		function ReDetermineFullRoute()	// some maps may dynamically enable or disable nav brushes (such as when the bomb carrier touches the hatch zone), so we need to recalculate full path when that happens
		{
			for (local ent; ent = Entities.FindByClassname(ent, "item_teamflag"); ) EntFireByHandle(ent, "CallScriptFunction", "EvaluateNavBrushes", 1.0, null, null)

			return true
		}

		InputEnable <- ReDetermineFullRoute
		Inputenable <- ReDetermineFullRoute

		InputDisable <- ReDetermineFullRoute
		Inputdisable <- ReDetermineFullRoute
	}


	// the "GetNavAreasFromBuildPath" function has a quirk that allows us to build a nav path that reliably imitates the path a bomb carrier would take
	// the function's second-to-last argument (IgnoreNavBlockers) allows us to pick any number of nav meshes that we don't want the path to go through
	// by storing all the nav areas that are obscured by func_nav entities in a table and blocking them for one frame, we can have the function pretend to be the bomb carrier and avoid undesirable paths

	function BombHop_BuildPath(start, end, remove_mapplaced_blocked_navs = false, ignore_bombpath = false)
	{
		local table = {}
		local blockednavs = []

		if (remove_mapplaced_blocked_navs)	// this is used in bigrock and underworld when robot spawn is cut off from the nav mesh by gates
		{
			foreach (nav in allareas) { if (nav.IsBlocked(3, true)) blockednavs.append(nav) }

			foreach (nav in blockednavs) nav.UnblockArea()	// temporarily unblock all map-placed blocked meshes and try building a path again
		}

		if (!ignore_bombpath) foreach (nav in blocknav_array) nav.MarkAsBlocked(3)			// block all undesirable areas that we don't want to path through...

		NavMesh.GetNavAreasFromBuildPath(start, end, Vector(), 0.0, 3, false, table)		// ...build a path...

		if (!ignore_bombpath)  foreach (nav in blocknav_array) nav.UnblockArea()			// ...then unblock the undesirables (this has no real effect on bot pathing, since this runs over the course of 1 frame)

		if (remove_mapplaced_blocked_navs) 	{ foreach (nav in blockednavs) nav.MarkAsBlocked(3) }

		if (table.len() > 0)	// convert the returned table to an array for ease of use
		{
			local arr = []

			for (local i = 0; i < table.len() - 1; i++) arr.append(table["area" + i])

			arr.append(start)

			return arr
		}

		else return false
	}

	function BombHop_BuildCurve(start, end, apex, length)	// create a quadratic bezier curve using the start, apex, and end points as parameters
	{
		hopcurve_array.clear()

		local percentage = (1.0 / length.tofloat())

		function Interpolate(from, to, percent)
		{
			local difference = to - from

			return (from + (difference * percent))
		}

		for (local i = 0.0; i < 1.0; i += percentage)
		{
			local a = Interpolate(start, apex, i)
			local b = Interpolate(apex, end, i)
			local c = Interpolate(a, b, i)

			hopcurve_array.append(c)
		}

		hopcurve_array.append(end)

		hopcurve_array.reverse()	// this will make movement code much simpler thanks to the pop() array function
	}

	CanHop <- @() !moving && !nohopping

	function CheckIfOnRoute(area)
	{
		local slot = false

		if (fullroute_navarray.find(area) != null)				// if bomb sits on an area that's a part of the route, use that area as a springboard
		{
			DebugMsg("CheckIfOnRoute: Bomb's area sits on the main route.")
			slot = fullroute_navarray.find(area)
		}

		else														// otherwise check if the bomb's area is adjacent to the route, or the areas adjacent to the bomb's area
		{
			DebugMsg("CheckIfOnRoute: Bomb's area does not sit on the main route, checking for adjacent areas.")
			local checkednavs = []

			foreach (nav in GetAllAdjacentAreas(area))
			{
				local found = false

				if (checkednavs.find(nav) != null) continue

				checkednavs.append(nav)

				if (fullroute_navarray.find(nav) != null) { slot = fullroute_navarray.find(nav); break }

				foreach (nav2 in GetAllAdjacentAreas(nav))
				{
					if (checkednavs.find(nav2) != null) continue

					checkednavs.append(nav2)

					if (fullroute_navarray.find(nav2) != null)
					{
						slot = fullroute_navarray.find(nav2)
						found = true
						break
					}
				}
			}
		}

		return slot
	}

	function DeterminePathLength(input, dc, startarea = false)
	{
		if (input.len() == 0) return 0

		local arr = []

		if (typeof(input) == "table") { for (local i = 0; i < input.len(); i++) arr.append(input["area" + i]) }
		else arr = input

		local dist = 0
		local foundstartarea = false

		for (local i = 0; i < arr.len(); i++)	// if we've determined a start area, skip along the path until we reach it, then start calculating the distance
		{
			if (startarea)
			{
				if (arr[i] == startarea) foundstartarea = true
				if (!foundstartarea) continue
			}

			if (debug && !debug_nodraw) arr[i].DebugDrawFilled(dc[0], dc[1], dc[2], dc[3], 5.0, true, 0.0)

			if (i + 1 > arr.len() - 1) continue

			local curarea1 = arr[i].GetCenter()
			local curarea2 = arr[i + 1].GetCenter()

			dist += (curarea2 - curarea1).Length()
		}

		return dist
	}

	function FindBestNearestNavMesh(vec)
	{
		local homenav = false

		for (local i = 16; i <= 512; i += 16) 									// try to determine the closest nav mesh to the bomb, keep increasing search radius with each unsuccessful try
		{
			local validarea = NavMesh.GetNearestNavArea(vec, i, true, false)	// let's first look for nav meshes that are in the bomb's line of sight

			if (validarea == null) continue

			homenav = validarea
			break
		}

		if (!homenav)																// failed to find any nav mesh, let's try again
		{
			DebugMsg("FindBestNearestNavMesh: Failed to find nearest nav mesh to bomb's origin, retrying with different method...")

			for (local i = 16; i <= 512; i += 16)
			{
				local validarea = NavMesh.GetNearestNavArea(vec, i, false, false)	// this time let's accept meshes that are not in the bomb's line of sight

				if (!validarea) continue

				homenav = validarea
				break
			}
		}

		return homenav
	}


	// some maps (ex. derelict, powerplant) tend to have lots of areas that are bi-directionally linked with other areas that are far above them, even though jumping up to those areas is impossible, these connections should be made one-directional

	function FixPoorNavConnections(check = false)
	{
		local amount = 0

		if (!check && navconnectionsfixed_check.IsTFMarked())
		{
			DebugMsg("FixPoorNavConnections: This func has already run, aborting.", true)
			return
		}

		foreach (nav in allareas)
		{

			foreach (adj_nav in GetAllAdjacentAreas(nav))
			{
				if (!adj_nav.IsConnected(nav, -1)) continue

				local found = false

				for (local i = 0; i <= 3; i++)	// compare vertical distance between each of the areas' corners
				{
					local curnav = nav.GetZ(nav.GetCorner(i))

					for (local j = 0; j <= 3; j++)
					{
						local curadj = adj_nav.GetZ(adj_nav.GetCorner(j))

						local dist = curadj - curnav

						if (dist < 0) dist *= -1.0

						if (dist < 50.0)	// as soon as we find one that's less than 50 HUs, continue to the next pair
						{
							found = true
							break
						}
					}

					if (found) break
				}

				if (!found)	// if the corners are more than 50 HUs apart vertically (roughly jumping height), disconnect
				{
					if (check) amount++
					else
					{
						if (nav.GetCenter().z > adj_nav.GetCenter().z) 	adj_nav.Disconnect(nav)
						else							 				nav.Disconnect(adj_nav)
					}
				}
			}
		}

		amount /= 2	// we're only checking and not actually fixing, meaning every connection gets checked twice from the perspective of two different areas

		if (check) 	ClientPrint(null,3,"Found " + amount + " poor connections between areas." + ((amount > 30) ? " It is highly recommended that the 'FixPoorNavConnections' function is run." : ""))
		else		navconnectionsfixed_check.TFMark()	// this will make vscript permanently remember that this expensive function got run
	}

	function GetAllAdjacentAreas(area)
	{
		local alldir_array = []

		for (local i = 0; i <= 3; i++)
		{
			local table = {}
			area.GetAdjacentAreas(i, table)

			for (local i = 0; i < table.len(); i++) alldir_array.append(table["area" + i])
		}

		return alldir_array
	}

	function GetAllPlayers(team = false, radius = false, alive = true)
	{
		local resultarray = []

		if (radius)
		{
			for (local player; player = Entities.FindByClassnameWithin(player, "player", radius[0], radius[1]); )
			{
				if (team) { if (player.GetTeam() != team) continue }
				if (alive) { if (!player.IsAlive()) continue }

				resultarray.append(player)
			}
		}

		else
		{
			local maxclients = MaxClients().tointeger()

			for (local i = 1; i <= maxclients; i++)
			{
				local player = PlayerInstanceFromIndex(i)

				if (player == null) continue

				if (team) { if (player.GetTeam() != team) continue }
				if (alive) { if (!player.IsAlive()) continue }

				resultarray.append(player)
			}
		}

		return resultarray
	}

	function GetAreaHeight(area)
	{
		if (!ignoreelevatedareas) return 0

		local tracetable =
		{
			start = area.GetCenter() + Vector(0, 0, 24)	// in case some areas are buried in the world
			end = area.GetCenter() - Vector(0, 0, 5000)
			mask = -1
		}

		TraceLineEx(tracetable)

		if ("startsolid" in tracetable) return 0

		return ((tracetable.pos - tracetable.start).Length())
	}

	function GetAreasObscuredByBrush(brush)	// credit goes to ficool2 for the initial code for checking if a point is within a trigger's bounds
	{
		// collect all nav areas that are touching a particular nav brush in any way
		// a nav area is affected by a nav brush entity only when its center is obscured by it, so let's trace and filter out those areas that don't meet this criterion
		// append all matching nav areas to the output array

		// WARNING: this function won't return any areas if the sigmod "sig_etc_entity_limit_manager_convert_server_entity" convar is set to 1! nav_func entities cannot be traced against in any imaginable way while this convar is active!

		local output = []
		local masksearch = 1

		local thisnavtable = {}
		NavMesh.GetNavAreasOverlappingEntityExtent(brush, thisnavtable)

		if (NetProps.GetPropInt(brush, "m_iHammerID") == 0) masksearch = 33554432 // apparently this mask flag can allow traces to collide with custom nav brushes

		brush.RemoveSolidFlags(4)

		for (local i = 0; i < thisnavtable.len(); i++)
		{
			local area = thisnavtable["area" + i]

			local trace =
			{
				start = area.GetCenter()
				end   = area.GetCenter()
				mask  = masksearch
			}

			TraceLineEx(trace)

			if (trace.hit)
			{
				if (trace.enthit == brush) output.append(area)

				else if (considerburiedareas)	// determine where the area is the most elevated, and add that height to its center
				{
					local area_ceil = -9999

					for (local i = 0; i <= 3; i++)
					{
						local height = area.GetZ(area.GetCorner(i))

						if (height > area_ceil) area_ceil = height
					}

					local trace2 =
					{
						start = area.GetCenter() + Vector(0, 0, (area_ceil - area.GetCenter().z))
						end   = area.GetCenter() + Vector(0, 0, (area_ceil - area.GetCenter().z))
						mask  = masksearch
					}

					TraceLineEx(trace2)

					if (trace2.hit && trace2.enthit == brush) output.append(area)
				}
			}
		}

		brush.AddSolidFlags(4)

		return output
	}

	function GracePeriodApplyTimeDeduction()
	{
		restoredhoptime_penalty = 0

		local percent = 1.0 + (restoredhoptime / hoptime)

		hoptime -= restoredhoptime					// deduct the grace period from the determined hop timer

		restoredhoptime_remainder = restoredhoptime	// retain any grace periods that persisted while the bomb was being carried

		return percent
	}

	function GracePeriodRecord()
	{
		// restoredhoptime = TimeSinceLastHop() + restoredhoptime_remainder

		if (restoredhoptime_penaltyspread) 	restoredhoptime_penalty = (restoredhoptime / restoredhoptime_penaltyticks.tofloat()) 	// determine how much the grace period percentage should be deducted every grace period depletion tick
		else								restoredhoptime_penaltytick = lifetick + (restoredhoptime_penaltyticks * 6.66)			// or determine time after pickup at which it should all go away

		TextGraceTimer_On()
	}

	function GracePeriodReset()
	{
		restoredhoptime = 0.0
		restoredhoptime_remainder = 0.0
		restoredhoptime_penalty = 0.0
		restoredhoptime_penaltytick = 0.0

		TextGraceTimer_Off()
	}

	function GracePeriodUpdate()
	{
		if (!graceperiod_enabled) return
		if (!CanHop()) return

		if (IsIdle()) restoredhoptime = TimeSinceLastHop() + restoredhoptime_remainder

		if (restoredhoptime <= 0) return

		if (IsCarried())
		{
			if (restoredhoptime_penaltyspread) 					restoredhoptime -= restoredhoptime_penalty	// keep reducing the grace period until it drops down to 0
			else if (lifetick >= restoredhoptime_penaltytick)	restoredhoptime = 0							// or reduce it all after it's expired if set this way

			if (restoredhoptime <= 0)
			{
				GracePeriodReset()

				OnGraceExpired()

				return
			}
		}
	}

	function HopFinish()
	{
		if (IsIdle()) self.SetAbsOrigin(hopend)	// just in case something goes horribly wrong

		moving = false	// reset all movement-related variables

		SetTouchable(true)	// set the bomb's solidity flags back to default

		DetermineReturnTime()	// update the hop timer now that the bomb's position has changed
		OnPostHop() // run any functions from outside scripts

		TextTimer_On()
	}

	function HopMovement()
	{
		if (smoothhopcurve)
		{
			self.SetAbsOrigin(hopcurve_array.pop())

			if (hopcurve_array.len() <= 0) HopFinish()

			return
		}

		self.SetAbsOrigin(self.GetOrigin() + moveamount)	// move this much every tick

		if ((movetarget - self.GetOrigin()).Length() <= hopmovement_detectionrange)
		{
			if (movetarget == hopend) HopFinish()
			else HopUpdateMoveTarget(hopend, hopapex)
		}

		// if ((hopapex - self.GetOrigin()).Length() <= hopmovement_detectionrange) toapex = false // we have reached the apex
		// if (((hopend - self.GetOrigin()).Length() <= hopmovement_detectionrange && !toapex) || lifetick >= endmovetick) { HopFinish(); return }	// we have reached the hop's end, time to wrap things up

		// local moveamount

		// if (toapex) moveamount = (hopapex - hopstart) * (1.0 / (hopduration_midjump.tofloat() / 2.0))	// divide the amount moved per tick across an amount of ticks equal to hopduration variable so that it looks smooth
		// else		moveamount = (hopend - hopapex) * (1.0 / (hopduration_midjump.tofloat() / 2.0))
	}

	function HopUpdateMoveTarget(pos, prev_pos)
	{
		movetarget = pos
		movetarget_prev = prev_pos

		moveamount = (movetarget - movetarget_prev) * (1.0 / (hopduration_midjump.tofloat() / 2.0))
	}

	function HopResponses()
	{
		if (!hop_responses_enabled) return

		foreach (player in GetAllPlayers(2))
		{
			if (RandomInt(1, hop_response_chance) != 1) continue

			if ((player.GetOrigin() - self.GetOrigin()).Length() < hop_response_radius)
			{
				local class_array = [null, "scout", "sniper", "soldier", "demoman", "medic", "heavy", "pyro", "spy", "engineer"]
				local pick = class_array[player.GetPlayerClass()]
				local special = false

				foreach (cond in hop_response_conditions)
				{
					if (cond[0](player))
					{
						player.PlayScene(format("scenes/Player/%s/low/%i.vcd", pick, cond[1][RandomInt(0, cond[1].len() - 1)]), -1.0)
						special = true
					}
				}

				if (!special && hop_responses[pick].len() > 0) player.PlayScene(format("scenes/Player/%s/low/%i.vcd", pick, hop_responses[pick][RandomInt(0, hop_responses[pick].len() - 1)]), -1.0)
			}
		}
	}

	IsAtHome <- @() NetProps.GetPropInt(self, "m_nFlagStatus") == 0
	IsCarried <- @() NetProps.GetPropInt(self, "m_nFlagStatus") == 1
	IsIdle <- @() NetProps.GetPropInt(self, "m_nFlagStatus") == 2

	function OnPreHop() { foreach ( func in prehop_funcs ) func() }
	function OnPostHop() { foreach ( func in posthop_funcs ) func() }
	function OnGraceExpired() { foreach ( func in graceexpired_funcs ) func() }

	function OverlayUpdate()
	{
		if (!overlay_material) return

		if (lifetick >= overlay_off_tick) overlay_on = false

		foreach (player in GetAllPlayers(2, false, false))
		{
			local curmat = player.GetScriptOverlayMaterial()

			if (curmat.len() > 0)
			{
				local skip = true

				foreach (mat in overlay_material)
				{
					if (mat == curmat)
					{
						skip = false
						break
					}
				}

				if (skip) continue
			}

			if (!overlay_on) player.SetScriptOverlayMaterial(null)
			else
			{
				if (typeof(overlay_material) == "string") player.SetScriptOverlayMaterial(overlay_material)
				if (typeof(overlay_material) == "array")
				{
					local curoverlay = overlay_material.find(player.GetScriptOverlayMaterial())
					if (curoverlay == null) player.SetScriptOverlayMaterial(overlay_material[0])
					else { player.SetScriptOverlayMaterial(((curoverlay + 1) > (overlay_material.len() - 1)) ? overlay_material[0] : overlay_material[curoverlay + 1]) }
				}
			}
		}
	}

	function PostSetParams(arr)
	{
		local reroute = false
		local regrace = false

		foreach (param in arr)
		{
			switch (param[0])
			{
				case "debug":
				{
					if (!param[1]) 	debug = false
					else 			SetUpDebug()

					break
				}

				case "pref_spawnnavarea": { reroute = true; break }
				case "pref_hatchnavarea": { reroute = true; break }

				case "allowpickupduringhop": { if (moving) SetTouchable(param[1]); break }

				case "hopsound": { if (hopsound) PrecacheSound(hopsound); break }

				case "hoptimerdisplayclock":
				{
					self.KeyValueFromFloat("ReturnTime", param[1] ? 599.0 : 600.0)

					if (param[1])
					{
						local old1 = NetProps.GetPropFloat(self, "m_flResetTime")
						local old2 = NetProps.GetPropFloat(self, "m_flMaxResetTime")

						if (NetProps.GetPropInt(self, "m_nFlagStatus") == 2)
						{
							self.AcceptInput("ShowTimer", "0.0", null, null)

							NetProps.SetPropFloat(self, "m_flResetTime", old1)
							NetProps.SetPropFloat(self, "m_flMaxResetTime", old2)
						}
					}

					else
					{
						for (local ent; ent = Entities.FindByClassname(ent, "item_teamflag_return_icon"); )
						{
							if (ent.GetRootMoveParent() == self) ent.Kill()
						}
					}

					break
				}

				case "hoptimerdisplaytext":
				{
					if (!param[1])
					{
						text_timer.Kill()
						text_timer = null
					}

					else
					{
						text_timer = SpawnEntityFromTable("point_worldtext",
						{
							targetname		= self.GetName() + "_bombhop_texttimer"
							textsize       	= 36
							message        	= ""
							color		   	= "255 255 255"
							font           	= 1
							orientation    	= 1
							textspacingx   	= 1
							textspacingy   	= 1
							rendermode     	= 3
						})

						text_timer.AcceptInput("SetParent", "!activator", self, self)
						text_timer.SetLocalOrigin(Vector(0, 0, 70))
					}

					break
				}

				case "hoptimerdisplaygracetimer":
				{
					if (!param[1])
					{
						text_gracetimer.Kill()
						text_gracetimer = null
					}

					else
					{
						text_gracetimer = SpawnEntityFromTable("point_worldtext",
						{
							targetname		= self.GetName() + "_bombhop_textgracetimer"
							textsize       	= 18
							message        	= ""
							color		   	= "255 255 255"
							font           	= 1
							orientation    	= 1
							textspacingx   	= 1
							textspacingy   	= 1
							rendermode     	= 3
						})

						text_gracetimer.AcceptInput("SetParent", "!activator", self, self)
						text_gracetimer.SetLocalOrigin(Vector(0, 0, 50))
					}

					break
				}

				case "graceperiod_enabled": { regrace = true; break }
				case "restoredhoptime_penaltyticks": { regrace = true; break }
				case "restoredhoptime_penaltyspread": { regrace = true; break }

				case "fixpoornavconnections": { FixPoorNavConnections(); break }
			}
		}

		if (reroute) fullroute_length = 0

		if (regrace) GracePeriodReset()
	}

	function SetUpDebug()
	{
		for (local i = 1; i <= Constants.Server.MAX_PLAYERS; i++)
		{
			local player = PlayerInstanceFromIndex(i)

			if (player == null) continue

			if (!player.IsFakeClient())
			{
				player.SetHealth(90000)
				player.SetMoveType(8, 0)
				player.SetCurrency(10000)
			}
		}

		seterrorhandler(function(e)
		{
			local filter = false

			for (local ent; ent = Entities.FindByClassname(ent, "item_teamflag"); )	// seterrorhandler function is not called by the bomb so we have no access to any of its variables here
			{
				if (ent.GetScriptScope() == null) continue
				if (!ent.GetScriptScope().debugger_id && !(!filter)) break

				filter = ent.GetScriptScope().debugger_id

				break
			}

			for (local player; player = Entities.FindByClassname(player, "player");)
			{
				if (NetProps.GetPropString(player, "m_szNetworkIDString") == "[U:1:" + filter + "]" || !filter)
				{
					local Chat = @(m) (printl(m), ClientPrint(player, 2, m))
					ClientPrint(player, 3, format("\x07FF0000AN ERROR HAS OCCURRED [%s].\nCheck console for details", e))

					Chat(format("\n====== TIMESTAMP: %g ======\nAN ERROR HAS OCCURRED [%s]", Time(), e))
					Chat("CALLSTACK")
					local s, l = 2
					while (s = getstackinfos(l++)) Chat(format("*FUNCTION [%s()] %s line [%d]", s.func, s.src, s.line))

					Chat("LOCALS")

					if (s = getstackinfos(2))
					{
						foreach (n, v in s.locals)
						{
							local t = type(v)
							t ==    "null" ? Chat(format("[%s] NULL"  , n))    :
							t == "integer" ? Chat(format("[%s] %d"    , n, v)) :
							t ==   "float" ? Chat(format("[%s] %.14g" , n, v)) :
							t ==  "string" ? Chat(format("[%s] \"%s\"", n, v)) :
											 Chat(format("[%s] %s %s" , n, t, v.tostring()))
						}
					}

					return
				}
			}
		})
	}

	function SnapVectorToGround(pos, offset = false)
	{
		local tracetable =
		{
			start = pos
			end = pos - Vector(0, 0, 5000)
			mask = -1
		}

		TraceLineEx(tracetable)

		if (!offset) return tracetable.pos
		else		 return (tracetable.pos + Vector(0, 0, offset))
	}

	function TextGraceTimer_On()
	{
		if (text_gracetimer) text_gracetimer.EnableDraw()
	}

	function TextGraceTimer_Off()
	{
		if (text_gracetimer) text_gracetimer.DisableDraw()
	}

	function TextTimer_On()
	{
		if (!IsIdle()) return
		if (text_timer) text_timer.EnableDraw()
	}

	function TextTimer_Off()
	{
		if (text_timer) text_timer.DisableDraw()
	}

	TimeUntilHop <- @() NetProps.GetPropFloat(self, "m_flResetTime") - Time()
	TimeSinceLastHop <- @() hoptime - TimeUntilHop()

	function Unload()
	{
		foreach (player in GetAllPlayers(2, false, false)) player.SetScriptOverlayMaterial(null)

		delete BOMBHOP_CALLBACKS
	}

	function UpdateTextTimer()
	{
		if (text_timer && CanHop() && IsIdle()) text_timer.KeyValueFromString("message", format("%.1f", TimeUntilHop()).tostring())

		if (text_gracetimer && restoredhoptime > 0.0) text_gracetimer.KeyValueFromString("message", format("%.1f", restoredhoptime).tostring())
	}

	InputForceReset <- ResetPath 	// this will only be called on mannhattan-styled gate maps that force reset the bombs when a gate is capped
	Inputforcereset <- ResetPath

	InputForceResetSilent <- ResetPath
	Inputforceresetsilent <- ResetPath

	for (local ent; ent = Entities.FindByClassname(ent, "func_nav_*"); )	// recalculate route when any nav brush becomes enabled or disabled...
	{
		if (ent.GetClassname() != "func_nav_prefer" && ent.GetClassname() != "func_nav_avoid") continue

		ent.ValidateScriptScope()

		AddRouteReDeterminationTriggers.call(ent.GetScriptScope())
	}

	for (local ent; ent = Entities.FindByModel(ent, "models/props_mvm/robot_hologram.mdl"); )	// ...or when any bomb path hologram receives those inputs (the called function will always run only once per tick)
	{
		ent.ValidateScriptScope()

		AddRouteReDeterminationTriggers.call(ent.GetScriptScope())
	}

	local id = 0

	for (local ent; ent = Entities.FindByClassname(ent, "item_teamflag"); )
	{
		if (ent == self) continue
		if (ent.GetScriptScope() == null) continue

		if ("debug_id" in ent.GetScriptScope()) id++
	}

	debug_id <- id	// the ID of the bomb that debug commands will need for verifying which bomb they should be run under

	DebugMsg("DebugID: " + debug_id)

	SetUp()

	EntFireByHandle(self, "CallScriptFunction", "NextFrameActions", -1.0, null, null)

	if (nav_interface != null)
	{
		DebugMsg("Map contains a nav_interface entity, setting up route redetermination function")

		nav_interface.ValidateScriptScope()
		local interface_scope = nav_interface.GetScriptScope()

		interface_scope.ReDetermineFullRoute <- function()
		{
			if (NetProps.GetPropBool(Entities.FindByClassname(null, "tf_objective_resource"), "m_bMannVsMachineBetweenWaves")) return true

			for (local ent; ent = Entities.FindByClassname(ent, "item_teamflag"); )
			{
				if (ent.GetScriptScope() == null) continue

				if (!("DetermineFullRoute" in ent.GetScriptScope())) continue

				EntFireByHandle(ent, "RunScriptCode", "DetermineFullRoute(true)", 3.0, null, null)	// it takes a few seconds for recomputation to take place
			}

			return true
		}

		interface_scope.InputRecomputeBlockers <- interface_scope.ReDetermineFullRoute
		interface_scope.Inputrecomputeblockers <- interface_scope.ReDetermineFullRoute
	}

	////////////////////////////////////////////////
	////////////////////////////////////////////////
	////////////////////////////////////////////////
	// CALLBACKS
	////////////////////////////////////////////////
	////////////////////////////////////////////////
	////////////////////////////////////////////////

	BOMBHOP_CALLBACKS <-
	{
		OnGameEvent_teamplay_flag_event = function(params)
		{
			local found = false	// ensure that the callback applies only to this particular bomb

			if ("carrier" in params) { if (EntIndexToHScript(params.carrier) == self.GetOwner()) found = true }	// by the time the bomb is picked up, vscript already knows who its carrier is
			if ("player" in params) { if (EntIndexToHScript(params.player) == self.GetOwner()) found = true }

			if ("carrier" in params) { if (EntIndexToHScript(params.carrier) == botcarrier) found = true }		// by the time the bomb is dropped, we can tell who its carrier was via the saved "botcarrier" variable
			if ("player" in params) { if (EntIndexToHScript(params.player) == botcarrier) found = true }

			if (found)
			{
				if (params.eventtype == 1) // bomb has been picked up
				{
					DebugMsg("I've been picked up, saving grace period.", true)

					TextTimer_Off()

					if (graceperiod_enabled) GracePeriodRecord()

					if (debug_pathtest || debug_recoverytest)
					{
						local maxclients = MaxClients().tointeger()

						for (local i = 1; i <= maxclients; i++)
						{
							local player = PlayerInstanceFromIndex(i)

							if (player == null) continue
							if (player.GetTeam() != 3) continue
							if (player == EntIndexToHScript(params.player)) continue

							player.SetHealth(0)
							player.TakeDamage(10000.0, 64, null)
						}

						EntFireByHandle(EntIndexToHScript(params.player), "RunScriptCode", "self.SetHealth(0); self.TakeDamage(10000.0, 64, null)", 0.5, null, null)

						local pop = SpawnEntityFromTable("point_populator_interface", {})

						pop.AcceptInput("PauseBotSpawning", null, null, null)
					}

					HopFinish()
				}

				if (params.eventtype == 4)	// the bomb has been dropped and changed its position, recalculate hop timer
				{
					DebugMsg("I've been dropped, calling DetermineReturnTime.", true)

					botcarrier = false
					TextTimer_On()

					DetermineReturnTime()
				}
			}
		}

		OnGameEvent_player_say = function(params)
		{
			if (debug)
			{
				if (params.text == "d")
				{
					TerminateHopScript()

					// for (local i = 0; i <= 10; i++)
					// {
					// 	SpawnEntityFromTable("obj_sentrygun",
					// 	{
					// 		origin	= Entities.FindByClassname(null, "func_capturezone").GetCenter() + Vector(RandomFloat(-250, 250), RandomFloat(-250, 250), 0)
					// 		teamnum	= 2
					// 		defaultupgrade = 2
					// 		spawnflags = 10
					// 	})
					// }
				}

				if (params.text.find("!visavoid") != null)	// mark red all the nav meshes that are affected by nav_avoid entities in guiding the bomb carrier
				{
					if (!endswith(params.text, "avoid")) { if (!endswith(params.text, debug_id.tostring())) return } // appending an ID (starting from the number 0) to the command will filter the command to run only under the bomb of that ID

					foreach (nav in blocknav_array) nav.DebugDrawFilled(255, 0, 0, 255, 20.0, true, 0.0)

					DebugMsg("Size of blocknav_array : " + blocknav_array.len())
				}

				if (params.text.find("!vispath") != null)	// this will basically call DetermineFullRoute and visualize the calculated path
				{
					if (!endswith(params.text, "path")) { if (!endswith(params.text, debug_id.tostring())) return }

					local spawnareas = []

					foreach (nav in allareas) { if (nav.HasAttributeTF(4)) spawnareas.append(nav) }

					local test_spawnnavarea
					local test_hatchnavarea

					if (pref_spawnnavarea) 	test_spawnnavarea = NavMesh.GetNavAreaByID(pref_spawnnavarea)
					else					test_spawnnavarea = spawnareas[RandomInt(0, spawnareas.len() - 1)]	// select random nav mesh inside robots' spawn room, can help visualize path flow from different spawn points

					if (pref_hatchnavarea)	test_hatchnavarea = NavMesh.GetNavAreaByID(pref_hatchnavarea)
					else 					test_hatchnavarea = FindBestNearestNavMesh(Entities.FindByClassname(null, "func_capturezone").GetCenter())

					if (test_spawnnavarea == null) DebugMsg("Failed, couldn't find a NavMesh that's close to robot spawn")
					if (test_hatchnavarea == null) DebugMsg("Failed, couldn't find a NavMesh that's close to the hatch")

					if (test_spawnnavarea == null || test_hatchnavarea == null) return

					if (blocknav_array.find(test_spawnnavarea) != null) blocknav_array.remove(blocknav_array.find(test_spawnnavarea))
					if (blocknav_array.find(test_hatchnavarea) != null) blocknav_array.remove(blocknav_array.find(test_hatchnavarea))

					local test_fullroute_navarray = BombHop_BuildPath(test_spawnnavarea, test_hatchnavarea)

					if (!test_fullroute_navarray)																				// failed to create path, maybe the map has pre-placed blocked nav meshes around maps with initially blocked off spawns like bigrock?
					{
						DebugMsg("Failed to establish any path, retrying with unblocked map-placed nav meshes")

						test_fullroute_navarray = BombHop_BuildPath(test_spawnnavarea, test_hatchnavarea, true)
					}

					if (!test_fullroute_navarray)																				// still didn't work? give up
					{
						DebugMsg("Failed to establish any path, aborting")
						return
					}

					local test_new_fullroute_navarray = []

					foreach (nav in test_fullroute_navarray)							// cut blu spawn room meshes out of the equation
					{
						if (GetAreaHeight(nav) >= areaheightlimit) continue							// maps like hoovydam put certain nav areas in complete midair, don't let the bomb sit on those
						if (nav.HasAttributeTF(4)) break
						test_new_fullroute_navarray.append(nav)
					}

					test_fullroute_navarray = test_new_fullroute_navarray

					local first = test_fullroute_navarray[test_fullroute_navarray.len() - 1] 		// let's try building a proper path one more time, now that we've taken spawn room meshes out of the calculation
					local last = test_fullroute_navarray[0]

					DebugMsg("First point: " + first.GetCenter())
					DebugMsg("Last point: " + last.GetCenter())

					local i = 1

					foreach (nav in test_fullroute_navarray)
					{
						nav.DebugDrawFilled(255, 0, 0, 255, 20.0, true, 0.0)
						DebugDrawText(nav.GetCenter(), "" + i, false, 5.0)
						i++
					}

					first.DebugDrawFilled(255, 0, 0, 255, 20.0, true, 0.0)
					last.DebugDrawFilled(255, 0, 0, 255, 20.0, true, 0.0)
				}

				if (params.text == "!pathtest" || params.text == "!recoverytest")
				{
					hoptime_min = 0.5
					hoptime_max = 0.5

					nohopping_when_hoptime_is_max = false

					if (params.text == "!pathtest") debug_pathtest = true
					if (params.text == "!recoverytest") debug_recoverytest = true

					NetProps.SetPropFloat(Entities.FindByClassname(null, "tf_gamerules"), "m_flRestartRoundTime", Time())
				}

				if (params.text == "!heighttest")
				{
					if (debug_id > 0) return		// no need to have this run multiple times per bomb
					if (!ignoreelevatedareas) ClientPrint(null, 3, "ignorelevatedareas is set to false, no areas will be detected")
					foreach (nav in allareas)
					{
						if (GetAreaHeight(nav) >= areaheightlimit)
						{
							nav.DebugDrawFilled(255, 0, 0, 255, 30.0, true, 0.0)
							DebugDrawText(nav.GetCenter(), "" + GetAreaHeight(nav), false, 30.0)
						}
					}
				}

				if (params.text == "!navmeshtest")
				{
					if (debug_id > 0) return		// no need to have this run multiple times per bomb
					FixPoorNavConnections(true)		// this will only run a check and not actually fix the connections
				}
			}
		}

		OnGameEvent_player_spawn = function(params)
		{
			local player = GetPlayerFromUserID(params.userid);

			if (player.IsFakeClient() && (debug_pathtest || debug_recoverytest))
			{
				EntFireByHandle(player, "RunScriptCode", "self.SetOrigin(Entities.FindByClassname(null, `func_capturezone`).GetCenter())", 0.1, null, null)
			}
		}

		OnGameEvent_mvm_wave_complete = function(params) { SetUp() } // winning a wave will not remove the bomb, so we need to manually reset its variables
	}

	foreach (name, callback in BOMBHOP_CALLBACKS) BOMBHOP_CALLBACKS[name] = callback.bindenv(this)

	__CollectGameEventCallbacks(BOMBHOP_CALLBACKS)

	AddThinkToEnt(self, "BombHop_Think")
}

intel_entity.ValidateScriptScope()

BombHop.call(intel_entity.GetScriptScope())