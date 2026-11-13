::CONST <- getconsttable()
::ROOT <- getroottable()
::MAX_CLIENTS <- MaxClients().tointeger()

if (!("ConstantNamingConvention" in ROOT))
{
	foreach (a, b in Constants)
	{
		foreach (k,v in b)
		{
			CONST[k] <- v != null ? v : 0;
			ROOT[k] <- v != null ? v : 0;
		}
	}
}

foreach(k, v in ::Entities.getclass())
{
	if (k != "IsValid" && !(k in ROOT))
	{
		ROOT[k] <- ::Entities[k].bindenv(::Entities);
	}
}

foreach(k, v in ::NetProps.getclass())
{
	if (k != "IsValid" && !(k in ROOT))
	{
		ROOT[k] <- ::NetProps[k].bindenv(::NetProps);
	}
}

local STATE_CONSTANTS = {
	STATE_MINIGUN = 0
	STATE_GAUNTLETS = 1
	STATE_SHOTGUN = 2
	STATE_FLEE = 3
}

local ATTACK_CONSTANTS = {
	ATTACK_SLAM = 0
	ATTACK_SLASH = 1
	ATTACK_QUAKE = 2
	ATTACK_LASER = 3
	ATTACK_UPPERCUT = 4
}

foreach (k, v in STATE_CONSTANTS)
{
	if (!(k in ROOT))
	{
		CONST[k] <- v
		ROOT[k] <- v
	}
}

foreach (k, v in ATTACK_CONSTANTS)
{
	if (!(k in ROOT))
	{
		CONST[k] <- v
		ROOT[k] <- v
	}
}

if(!("RedWorldMissionName" in ROOT))
{
	::RedWorldMissionName <- ""
	local ent = Entities.FindByClassname(null, "tf_objective_resource");
	RedWorldMissionName = GetPropString(ent, "m_iszMvMPopfileName");
}

::RedWorld <-
{
	BossIntroSound1 = ["vo/mvm/mght/heavy_mvm_m_domination04.mp3", "vo/mvm/mght/heavy_mvm_m_domination06.mp3"]
	BossIntroSound2 = ["vo/mvm/mght/heavy_mvm_m_domination13.mp3", "vo/mvm/mght/heavy_mvm_m_laughhappy01.mp3"]
	BossIntroDelay1 = [2.2, 3.3]
	BossPositions = [Vector(105.0, 967.0, 0.0), Vector(155.0, 4525.0, 64.0), Vector(-3000.0, 4500.0, 0.0), Vector(727.0, 2798.0, 0.0), Vector(-1213.0, 2875.0, 128.0), Vector(-2175.0, 6280.0, 0.0), Vector(-2930.0, 7547.0, 0.0)]
	BossAngles = [QAngle(0.0, 90.0, 0.0), QAngle(0.0, 180.0, 0.0), QAngle(0.0, 0.0, 0.0), QAngle(0.0, 180.0, 0.0), QAngle(0.0, 0.0, 0.0), QAngle(0.0, -90.0, 0.0), QAngle(0.0, -90.0, 0.0)]
	ChosenBossPosition = Vector(0.0, 0.0, 0.0)
	ChosenBossAngles = Vector(0.0, 0.0, 0.0)
	BossFleeRange = [3500.0, 5000.0]
	BossChangePhaseSounds = ["vo/mvm/mght/heavy_mvm_m_revenge11.mp3", "vo/mvm/mght/heavy_mvm_m_revenge08.mp3", "vo/mvm/mght/heavy_mvm_m_revenge10.mp3", "vo/mvm/mght/heavy_mvm_m_revenge01.mp3", "vo/mvm/mght/taunts/heavy_mvm_m_taunts15.mp3"]
	BossMinigunStartSounds = ["vo/mvm/mght/heavy_mvm_m_meleedare01.mp3", "vo/mvm/mght/heavy_mvm_m_meleedare02.mp3", "vo/mvm/mght/heavy_mvm_m_meleedare03.mp3", "vo/mvm/mght/heavy_mvm_m_meleedare04.mp3", "vo/mvm/mght/heavy_mvm_m_meleedare09.mp3", "vo/mvm/mght/heavy_mvm_m_meleedare10.mp3"]
	BossMinigunFireSounds = ["vo/mvm/mght/taunts/heavy_mvm_m_taunts07.mp3", "vo/mvm/mght/taunts/heavy_mvm_m_taunts10.mp3", "vo/mvm/mght/taunts/heavy_mvm_m_taunts11.mp3"]
	BossCloakOnSound = ")weapons/medi_shield_deploy.wav"
	BossCloakOffSound = ")weapons/medi_shield_retract.wav"
	BossHealthThreshold = 15000
	LockedRespawnTime = false
	WaveInProgress = false
	InstancedUpgradeStations = []
	InMeltdown = true

	AllRedDeathCheck = false
	WinEntity = null
	DoGiantSpawnSound = false

	function SpawnUpgradeTable(position, angles, indicatorPos, indicatorAng, start = true)
	{
		if (start)
		{
			CleanAllUpgradeStations();
		}
		local entities = [];
		local ent = SpawnEntityFromTable("prop_dynamic", {
			model = "models/weapons/w_models/w_wrench.mdl",
			origin = Vector(15.0, 39.0, 59.0),
			angles = QAngle(0.0, 306.0, 90.0),
			disablebonefollowers = 1,
			disableshadows = 1
		});
		entities.append(ent);
		InstancedUpgradeStations.append(ent);

		ent = SpawnEntityFromTable("prop_dynamic", {
			model = "models/props_spytech/binder001.mdl",
			origin = Vector(-8.0, 35.0, 59.0),
			angles = QAngle(0.0, 180.0, 90.0),
			skin = 1,
			disableshadows = 1
		});
		entities.append(ent);
		InstancedUpgradeStations.append(ent);

		ent = SpawnEntityFromTable("prop_dynamic", {
			model = "models/props_spytech/binder001.mdl",
			origin = Vector(-8.0, 35.0, 63.0),
			angles = QAngle(0.0, 213.5, 90.0),
			disableshadows = 1
		});
		entities.append(ent);
		InstancedUpgradeStations.append(ent);

		ent = SpawnEntityFromTable("prop_dynamic", {
			model = "models/weapons/w_models/w_toolbox.mdl",
			origin = Vector(-13.0, 5.0, 56.0),
			angles = QAngle(0.0, 0.0, 0.0),
			disableshadows = 1
		});
		entities.append(ent);
		InstancedUpgradeStations.append(ent);

		ent = SpawnEntityFromTable("prop_dynamic", {
			model = "models/effects/saxxy_flash/saxxy_flash.mdl",
			origin = Vector(-7.0, -26.0, 55.0),
			angles = QAngle(0.0, 0.0, 0.0),
			disableshadows = 1
		});
		entities.append(ent);
		InstancedUpgradeStations.append(ent);

		ent = SpawnEntityFromTable("prop_dynamic", {
			model = "models/weapons/c_models/c_sledgehammer/c_sledgehammer.mdl",
			origin = Vector(-11.0, -36.0, 59.0),
			angles = QAngle(0.0, 123.5, 90.0),
			disableshadows = 1
		});
		entities.append(ent);
		InstancedUpgradeStations.append(ent);

		ent = SpawnEntityFromTable("prop_dynamic", {
			model = "models/player/items/all_class/hwn_spellbook_diary.mdl",
			origin = Vector(0.0, -41.0, 56.0),
			angles = QAngle(-90.0, 0.0, 0.0),
			disableshadows = 1
		});
		entities.append(ent);
		InstancedUpgradeStations.append(ent);

		local stationEnt = SpawnEntityFromTable("func_upgradestation", {
			targetname = "temp_upgrade_station_redworld",
			origin = Vector(0.0, 0.0, 19.0),
			mins = Vector(-64.0, -64.0, -64.0),
			maxs = Vector(64.0, 64.0, 32.0),
			startdisabled = 0
		});
		stationEnt.SetSize(Vector(-64.0, -64.0, -64.0), Vector(64.0, 64.0, 64.0));
		stationEnt.AddSolidFlags(FSOLID_TRIGGER | FSOLID_USE_TRIGGER_BOUNDS | FSOLID_NOT_SOLID);

		local entityParent = SpawnEntityFromTable("prop_dynamic", {
			model = "models/props_spytech/work_table001.mdl",
			origin = Vector(0.0, 0.0, 19.0),
			angles = QAngle(0.0, 0.0, 0.0),
			solid = 6
		});

		for (local i = 0; i < entities.len(); i++)
		{
			ent = entities[i];
			ent.AcceptInput("SetParent", "!activator", entityParent, null);
		}
		entityParent.Teleport(true, position + Vector(0.0, 0.0, 19.0), true, angles, false, Vector(0.0, 0.0, 0.0));
		stationEnt.Teleport(true, position + Vector(0.0, 0.0, 32.0), true, angles, false, Vector(0.0, 0.0, 0.0));
		InstancedUpgradeStations.append(entityParent);

		ent = CreateByClassname("prop_dynamic");
		ent.KeyValueFromString("model", "models/props_mvm/mvm_upgrade_sign.mdl");
		ent.AcceptInput("SetDefaultAnimation", "idle", null, null);
		ent.SetAbsOrigin(indicatorPos);
		ent.SetAbsAngles(indicatorAng);
		DispatchSpawn(ent);
		InstancedUpgradeStations.append(ent);
	}

	function CleanAllUpgradeStations()
	{
		for (local i = 0; i < InstancedUpgradeStations.len(); i++)
		{
			if (InstancedUpgradeStations[i] == null || !InstancedUpgradeStations[i].IsValid())
			{
				continue;
			}

			InstancedUpgradeStations[i].Kill();
		}

		local station = null;
		while ((station = Entities.FindByClassname(station, "func_upgradestation")) != null)
		{
			if (station.GetName() == "temp_upgrade_station_redworld")
			{
				station.Kill();
			}
		}
		InstancedUpgradeStations.clear();
	}

	function OnScriptHook_OnTakeDamage(params)
	{
		local inflictor = params.inflictor;
		local victim = params.const_entity;
		if (victim == null || inflictor == null || !victim.IsPlayer() || victim.GetTeam() != 3)
		{
			return;
		}

		if (inflictor.GetName() == "tonka_bombs")
		{
			params.damage *= 0;
		}

		if (victim.HasBotTag("soviet_tonka_weapons"))
		{
			params.damage *= victim.GetScriptScope().CurrentVulnerability;
		}
	}

	function OnGameEvent_recalculate_holidays(params)
	{
		local gamerules = FindByClassname(null, "tf_gamerules");
		gamerules.ValidateScriptScope();
		local scope = gamerules.GetScriptScope();
		scope.Think <- function()
		{
			if (!RedWorld.WaveInProgress)
			{
				return -1;
			}

			gamerules.AcceptInput("SetRedTeamRespawnWaveTime", "15.0", null, null);
			return -1;
		}
		if (WinEntity != null && WinEntity.IsValid())
		{
			WinEntity.Kill();
			WinEntity = null;
		}
		local ent = Entities.FindByClassname(null, "tf_objective_resource");
		if (ent)
		{
			if (RedWorldMissionName != GetPropString(ent, "m_iszMvMPopfileName") || !InMeltdown) // BAIL
			{
				if (scope != null)
				{
					gamerules.TerminateScriptScope();
					SetPropString(gamerules, "m_iszScriptThinkFunction", "");
					AddThinkToEnt(gamerules, null);
				}
				CleanAllUpgradeStations();
				RemoveSpeedBoostToAll();
				delete ::RedWorldMissionName;
				delete ::RedWorld;
				return;
			}
		}
		ApplySpeedBoostToAll();
	}

	function ApplySpeedBoostToAll()
	{
		if (!InMeltdown)
		{
			return;
		}
		for (local i = 1; i <= MAX_CLIENTS; i++)
		{
			local temp = PlayerInstanceFromIndex(i);
			if (temp == null || temp.GetTeam() != 2)
			{
				continue;
			}

			temp.AddCond(TF_COND_SPEED_BOOST);
		}
	}

	function RemoveSpeedBoostToAll()
	{
		if (!InMeltdown)
		{
			return;
		}
		for (local i = 1; i <= MAX_CLIENTS; i++)
		{
			local temp = PlayerInstanceFromIndex(i);
			if (temp == null || temp.GetTeam() != 2)
			{
				continue;
			}

			temp.RemoveCond(TF_COND_SPEED_BOOST);
		}
	}

	function OnGameEvent_mvm_wave_complete(params)
	{
		WaveInProgress = false;
		ApplySpeedBoostToAll();
	}

	function OnGameEvent_mvm_wave_failed(params)
	{
		WaveInProgress = false;
		ApplySpeedBoostToAll();
	}

	function OnGameEvent_mvm_begin_wave(params)
	{
		WaveInProgress = true;
		RemoveSpeedBoostToAll();
	}

	function OnGameEvent_mvm_reset_stats(params)
	{
		WaveInProgress = true;
	}

	function OnGameEvent_player_spawn(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		if (params.team != 3 && InMeltdown)
		{
			if (AllRedDeathCheck)
			{
				player.AddCondEx(TF_COND_SPEED_BOOST, 10.0, null);
			}
			else if (!WaveInProgress)
			{
				player.AddCond(TF_COND_SPEED_BOOST);
			}

			return;
		}
		SetPropInt(player, "m_nRenderMode", 0);
		SetPropInt(player, "m_clrRender", 0xFFFFFF);
		player.TerminateScriptScope();
		SetPropString(player, "m_iszScriptThinkFunction", "");
		AddThinkToEnt(player, null);
		EntFireByHandle(player, "RunScriptCode", "RedWorld.TagCheck(self)", -1, null, null)
	}

	function ClassCheck(player)
	{
		if (!InMeltdown)
		{
			return;
		}
		if (player.GetPlayerClass() != 6)
		{
			local timer = CreateByClassname("logic_relay");
			timer.ValidateScriptScope();
			local scope = timer.GetScriptScope();
			scope.SwapClass <- function()
			{
				player.SetPlayerClass(6);
				SetPropInt(player, "m_Shared.m_iDesiredPlayerClass", 6);
				player.Regenerate(true);
				self.Destroy();
			}

			timer.ConnectOutput("OnTrigger", "SwapClass");
			EntFireByHandle(timer, "Trigger", "", 0.0, null, null);
		}
	}

	function OnGameEvent_player_death(params)
	{
		local player = GetPlayerFromUserID(params.userid);
		if (player && player.IsBotOfType(TF_BOT_TYPE))
		{
			local tags = {};
			player.GetAllBotTags(tags);
			foreach (tag in tags)
			{
				if (tag.find("soviet_tonka_weapons") != null)
				{
					StopSupportBots();
					local position = player.GetOrigin();
					local rotation = player.GetAbsAngles();
					rotation.z = 0.0;
					local boss = SpawnEntityFromTable("prop_dynamic", {
						origin = position,
						angles = rotation,
						modelscale = 1.9,
						skin = 1,
						model = "models/mentrillum/bots/soviet_tonka_weapons_02.mdl",
						HoldAnimation = true
					});
					local hat1 = SpawnEntityFromTable("prop_dynamic", {
						origin = position,
						angles = rotation,
						modelscale = 1,
						skin = 1,
						model = "models/player/items/heavy/heavy_ushanka.mdl"
					});
					local hat2 = SpawnEntityFromTable("prop_dynamic", {
						origin = position,
						angles = rotation,
						modelscale = 0.8,
						skin = 1,
						model = "models/player/items/heavy/cop_glasses.mdl"
					});
					local hat3 = SpawnEntityFromTable("prop_dynamic", {
						origin = position,
						angles = rotation,
						modelscale = 1,
						skin = 1,
						model = "models/workshop/player/items/heavy/sum23_heavy_metal/sum23_heavy_metal.mdl"
					});
					local scope = player.GetScriptScope();
					if (scope.State == STATE_GAUNTLETS)
					{
						local gloves = SpawnEntityFromTable("prop_dynamic", {
						origin = position,
						angles = rotation,
						modelscale = 1,
						skin = 1,
						model = "models/weapons/c_models/c_fists_of_steel/c_fists_of_steel.mdl"
						rendercolor = "0 55 117"
						});
						gloves.AcceptInput("SetParent", "!activator", boss, null);
						SetPropInt(gloves, "m_fEffects", 129);
						gloves.AcceptInput("SetParentAttachmentMaintainOffset", "head", boss, null);
					}
					hat1.AcceptInput("SetParent", "!activator", boss, null);
					hat2.AcceptInput("SetParent", "!activator", boss, null);
					hat3.AcceptInput("SetParent", "!activator", boss, null);
					SetPropInt(hat1, "m_fEffects", 129);
					SetPropInt(hat2, "m_fEffects", 129);
					SetPropInt(hat3, "m_fEffects", 129);
					hat1.AcceptInput("SetParentAttachmentMaintainOffset", "head", boss, null);
					hat2.AcceptInput("SetParentAttachmentMaintainOffset", "head", boss, null);
					hat3.AcceptInput("SetParentAttachmentMaintainOffset", "head", boss, null);
					BossDeathPost(boss);
					KillAllBots(player);
				}
			}
		}

		if (!AllRedDeathCheck)
		{
			return;
		}

		if (player.GetTeam() != 2)
		{
			return;
		}

		local dead = true;
		for (local i = 1; i <= MAX_CLIENTS; i++)
		{
			local temp = PlayerInstanceFromIndex(i);
			if (temp == null || temp.GetTeam() != 2 || temp == player)
			{
				continue;
			}

			if (temp.IsAlive())
			{
				dead = false;
				break;
			}
		}

		if (dead)
		{
			if (WinEntity == null || !WinEntity.IsValid())
			{
				WinEntity = SpawnEntityFromTable("game_round_win",
				{
					targetname = "all_blue_win",
					TeamNum = 3,
					force_map_reset = 1
				});
			}
			EntFire("all_blue_win", "RoundWin");
		}
	}

	function BossDeathPost(boss)
	{
		SetPropBool(boss, "m_bSequenceLoops", false);
		boss.AcceptInput("SetAnimation", "death", null, null);
		boss.AcceptInput("Enable", null, null, null);
		boss.ValidateScriptScope();
		local scope = boss.GetScriptScope();

		scope.ShakeTime <- Time() + 3.35667;
		scope.Think <- function()
		{
			local time = Time();
			if (scope.ShakeTime > -1.0 && scope.ShakeTime <= time)
			{
				for (local i = 1; i <= MAX_CLIENTS; i++)
				{
					local temp = PlayerInstanceFromIndex(i);
					if (temp == null)
					{
						continue;
					}

					ScreenShake(boss.GetOrigin(), 9.0, 9.0, 2.0, 2500.0, 0, true);
				}
				scope.ShakeTime = -1.0;
			}
		}
		AddThinkToEnt(boss, "Think");
	}

	function KillAllBots(exclude = null)
	{
		for (local i = 1; i <= MAX_CLIENTS; i++)
		{
			local otherPlayer = PlayerInstanceFromIndex(i);
			if (otherPlayer == null || otherPlayer.GetTeam() != 3 || !otherPlayer.IsAlive())
			{
				continue;
			}

			if (exclude != null && otherPlayer == exclude)
			{
				continue;
			}

			otherPlayer.SetHealth(0);
			otherPlayer.TakeDamageCustom(otherPlayer, otherPlayer, null, Vector(0, 0, 0), otherPlayer.GetCenter(), otherPlayer.GetHealth().tofloat() + 10.0, 0, 6);
		}
	}

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

	function SupportShotgun()
	{
		local player = self;
		if (player == null)
		{
			return;
		}
		local shotgun = null;
		local doSwap = false;

		for (local i = 0; i < 8; i++)
		{
			local weapon = GetPropEntityArray(player, "m_hMyWeapons", i);
			if (weapon == null)
			{
				continue;
			}

			if (weapon.GetSlot() == 0)
			{
				if (player.GetActiveWeapon() == weapon)
				{
					doSwap = true;
				}
				weapon.Destroy();
				SetPropEntityArray(player, "m_hMyWeapons", null, i);
				weapon = null;
				continue;
			}

			if (weapon.GetSlot() == 1)
			{
				shotgun = weapon;
				if (doSwap)
				{
					player.Weapon_Switch(shotgun);
				}
				break;
			}
		}

		if (shotgun == null)
		{
			return;
		}

		local gameText = SpawnEntityFromTable("game_text", {
			channel = 0
			color = "0 255 0"
			holdtime = 1
			x = 0.8
			y = 0.8
			message = "Resupply\n██████████ READY"
		})

		shotgun.ValidateScriptScope();
		local scope = shotgun.GetScriptScope();
		if ("Cleanup" in scope)
		{
			scope.Cleanup();
		}
		local maxTime = 15.0;

		scope.ButtonsLast <- 0;
		scope.Ready       <- true;
		scope.ResupplyTime <- 0.0;

		scope.Think <- function()
		{
			local buttons = GetPropInt(player, "m_nButtons");
			local buttonsChanged = ButtonsLast ^ buttons;
			local buttonsPressed = buttonsChanged & buttons;
			local buttonsReleased = buttonsChanged & (~buttons);
			ButtonsLast = buttons;

			local weapon = player.GetActiveWeapon();
			local time = Time();
			if (weapon == self && (buttonsPressed & Constants.FButtons.IN_ATTACK3) != 0 && ResupplyTime <= time)
			{
				if (ResupplyTime <= time)
				{
					trace <-
					{
						start = player.EyePosition(),
						end = player.EyePosition() + (player.EyeAngles().Forward() * 200.0),
						hullmin = Vector(-16.0, -16.0, -16.0),
						hullmax = Vector(16.0, 16.0, 16.0),
						mask = 33636363,
						ignore = player
					}

					TraceHull(trace);
					if (trace.hit && trace.enthit.GetClassname() == "player" && trace.enthit.GetTeam() == player.GetTeam())
					{
						EmitSoundOnClient("BaseCombatCharacter.AmmoPickup", player);
						EmitSoundOnClient("BaseCombatCharacter.AmmoPickup", trace.enthit);
						local hit = trace.enthit;
						ResupplyTime = time + maxTime;
						for (local i = 0; i < 8; i++)
						{
							local targetWeapon = GetPropEntityArray(hit, "m_hMyWeapons", i);
							if (targetWeapon == null || weapon.GetSlot() >= 2)
							{
								continue;
							}

							if (targetWeapon.GetAttribute("panic_attack", 0.0) > 0.0)
							{
								continue;
							}

							targetWeapon.SetClip1(targetWeapon.GetDefaultClip1());
						}
						local pack = CreateByClassname("item_ammopack_full");
						pack.SetOrigin(hit.GetOrigin());
						SetPropInt(pack, "m_nRenderMode", 10);
						pack.DisableDraw();
						DispatchSpawn(pack);
						EntFireByHandle(pack, "Kill", "", 0.05, null, null);
					}
					else
					{
						EmitSoundEx({
							sound_name = "player/suit_denydevice.wav"
							entity = player
							filter_type = 4
						});
					}
				}
				else
				{

				}
			}

			local message = "Resupply\n";
			if (ResupplyTime <= time)
			{
				gameText.KeyValueFromString("color", "0 255 0");
				message += "██████████ READY";
			}
			else
			{
				gameText.KeyValueFromString("color", "255 0 0");
				local maxBars = 10;
				local bars = ceil((maxBars * ((ResupplyTime - time) / maxTime)).tofloat());

				if (bars > maxBars)
				{
					bars = maxBars;
				}

				for (local i = 0; i < maxBars; i++)
				{
					if (i < bars)
					{
						message += "░";
					}
					else
					{
						message += "█";
					}
				}

				message += format(" %i", ceil(ResupplyTime - time));
			}

			SetPropString(gameText, "m_iszMessage", message);
			gameText.AcceptInput("Display", null, player, null);
			return 0;
		}
		scope.Cleanup <- function()
		{
			if (gameText != null && gameText.IsValid())
			{
				gameText.Kill();
			}
		}
		RedWorld.SetDestroyCallback(shotgun, scope.Cleanup);
		AddThinkToEnt(shotgun, "Think");
	}

	function StartQuakeExplosions(player)
	{
		local locator = SpawnEntityFromTable("prop_dynamic_override", {
			origin = player.GetOrigin(),
			angles = player.GetAbsAngles(),
			solid = 0,
			startdisabled = 1,
			skin = 1,
			rendermode = "1",
			rendercolor = "0 0 0",
			renderamt = "0",
			solid = "0",
			model = "models/blackout.mdl"
		});
		locator.SetMoveType(MOVETYPE_NOCLIP, MOVECOLLIDE_DEFAULT);
		locator.SetSolid(FSOLID_NOT_SOLID);
		locator.ValidateScriptScope();
		local scope = locator.GetScriptScope();
		scope.NextTeleportTime <- 0.0;
		scope.Duration <- 0.0;
		//scope.NextTeleportTime = 0.3 + time;
		scope.Duration = 3.5 + Time();
		scope.Think <- function()
		{
			local time = Time();
			if (scope.NextTeleportTime <= time)
			{
				EmitSoundEx({
					sound_name = ")mentrillum/mvm/sfx/attack_groundpound.wav",
					entity = locator,
					filter_type = RECIPIENT_FILTER_GLOBAL,
					sound_level = 90,
				});
				local nextTime = 0.3;
				local nextFwd = 125.0;
				local nextDmg = 80.0;
				if (player.GetScriptScope().Phase == 1)
				{
					nextTime = 0.2;
					nextFwd = 100.0;
					nextDmg = 75.0;
				}
				else if (player.GetScriptScope().Phase >= 2)
				{
					nextTime = 0.15;
					nextFwd = 90.0;
					nextDmg = 70.0;
				}
				RedWorld.Explode(locator.GetOrigin(), nextDmg, 256.0, "ExplosionCore_MidAir", player);
				local fwd = locator.GetAbsAngles().Forward() * nextFwd;
				local newPos = fwd + locator.GetOrigin();
				locator.Teleport(true, newPos, false, locator.GetAbsAngles(), false, locator.GetAbsVelocity());

				scope.NextTeleportTime = nextTime + time;
			}
			if (scope.Duration <= time)
			{
				locator.TerminateScriptScope();
				SetPropString(locator, "m_iszScriptThinkFunction", "");
				AddThinkToEnt(locator, null);
				locator.Kill();
			}
			return;
		}
		AddThinkToEnt(locator, "Think");
	}

	function DeleteAllNavs()
	{
		local nav = null;
		while ((nav = Entities.FindByClassname(nav, "func_nav_avoid")) != null)
		{
			nav.Kill();
		}

		nav = null;
		while ((nav = Entities.FindByClassname(nav, "func_nav_prefer")) != null)
		{
			nav.Kill();
		}
	}

	function KillAllDispensers()
	{
		local dispenser = null;
		while ((dispenser = Entities.FindByClassname(dispenser, "obj_dispenser")) != null)
		{
			dispenser.Kill();
		}
	}

	function SpawnAllDispensers()
	{
		SpawnEntityFromTable("obj_dispenser", {
			teamnum = 2,
			solidtoplayers = 0,
			defaultupgrade = 2,
			origin = Vector(330.0, 560.0, 64.0),
			angles = QAngle(0.0, -90.0, 0.0)
		});

		SpawnEntityFromTable("obj_dispenser", {
			teamnum = 2,
			solidtoplayers = 0,
			defaultupgrade = 2,
			origin = Vector(-360.0, 560.0, 64.0),
			angles = QAngle(0.0, -90.0, 0.0)
		});

		SpawnEntityFromTable("obj_dispenser", {
			teamnum = 2,
			solidtoplayers = 0,
			defaultupgrade = 2,
			origin = Vector(300.0, 990.0, 0.0),
			angles = QAngle(0.0, -90.0, 0.0)
		});

		SpawnEntityFromTable("obj_dispenser", {
			teamnum = 2,
			solidtoplayers = 0,
			defaultupgrade = 2,
			origin = Vector(260.0, 2060.0, 0.0),
			angles = QAngle(0.0, 90.0, 0.0)
		});

		SpawnEntityFromTable("obj_dispenser", {
			teamnum = 2,
			solidtoplayers = 0,
			defaultupgrade = 2,
			origin = Vector(-760.0, 5096.0, 67.0),
			angles = QAngle(0.0, -90.0, 0.0)
		});

		SpawnEntityFromTable("obj_dispenser", {
			teamnum = 2,
			solidtoplayers = 0,
			defaultupgrade = 2,
			origin = Vector(-2430.0, 5600.0, 0.0),
			angles = QAngle(0.0, -90.0, 0.0)
		});

		SpawnEntityFromTable("obj_dispenser", {
			teamnum = 2,
			solidtoplayers = 0,
			defaultupgrade = 2,
			origin = Vector(-1920.0, 5600.0, 0.0),
			angles = QAngle(0.0, -90.0, 0.0)
		});

		SpawnEntityFromTable("obj_dispenser", {
			teamnum = 2,
			solidtoplayers = 0,
			defaultupgrade = 2,
			origin = Vector(-2130.0, 6500.0, 0.0),
			angles = QAngle(0.0, -45.0, 0.0)
		});

		SpawnEntityFromTable("obj_dispenser", {
			teamnum = 2,
			solidtoplayers = 0,
			defaultupgrade = 2,
			origin = Vector(-2870.0, 5890.0, 0.0),
			angles = QAngle(0.0, -90.0, 0.0)
		});

		SpawnEntityFromTable("obj_dispenser", {
			teamnum = 2,
			solidtoplayers = 0,
			defaultupgrade = 2,
			origin = Vector(-1430.0, 4230.0, -12.0),
			angles = QAngle(0.0, -90.0, 0.0)
		});
	}

	function TagCheck(player)
	{
		local tags = {};
		player.GetAllBotTags(tags);
		foreach (tag in tags)
		{
			if (tag.find("soviet_tonka_weapons") != null)
			{
				player.Teleport(true, ChosenBossPosition + Vector(0.0, 0.0, 15.0), true, ChosenBossAngles, true, player.GetAbsVelocity());
				player.RemoveCondEx(TF_COND_INVULNERABLE, true);
				player.RemoveCondEx(TF_COND_INVULNERABLE_HIDE_UNLESS_DAMAGED, true);
				player.RemoveCondEx(TF_COND_INVULNERABLE_CARD_EFFECT, true);
				player.RemoveCondEx(TF_COND_INVULNERABLE_USER_BUFF, true);
				player.RemoveCondEx(TF_COND_PHASE, true);
				EntFire("pop_interface", "ChangeBotAttributes", "Melee_Action");
				player.ValidateScriptScope();
				local scope = player.GetScriptScope();

				scope.State <- STATE_GAUNTLETS;
				scope.AttackCooldown <- 0.0;
				scope.IsQuakeAttackQueued <- false;
				scope.QuakeAttackCooldown <- 0.0;

				scope.IsLaserAttackQueued <- false;
				scope.LaserAttackCooldown <- 0.0;
				scope.LaserDuration <- 0.0;
				scope.LaserEntities <- [];
				scope.LaserTargetEntity <- null;
				scope.LaserTick <- 0.0;

				scope.AttackTime <- 0.0;
				scope.AttackHitTime <- 0.0;
				scope.IsAttacking <- false;
				scope.AttackType <- 0;
				scope.AlwaysLookAtTarget <- null;
				scope.Phase <- 0;
				scope.SwitchingPhase <- false;
				scope.SwitchTime <- RandomFloat(20.0, 40.0) + Time();
				//scope.SwitchTime <- 8.0 + Time();

				scope.OldMinigunState <- 0;
				scope.MinigunState <- 0;
				scope.MinigunFocus <- null;
				scope.QuoteChance <- 0;

				scope.FleePosition <- Vector(0.0, 0.0, 0.0);
				scope.ReachedFleePosition <- false;
				scope.FleeTime <- 0.0;
				scope.FleeAbortTime <- 0.0;
				scope.StateBeforeFlee <- 0;

				scope.NextPathUpdate <- 0.0;
				scope.PathArray <- [];
				scope.PathIndex <- 0;
				scope.PathLength <- 0;

				scope.CurrentAnimation <- null;
				scope.MiscAnimations <- [];
				scope.OriginalGauntletColor <- 0;

				scope.CurrentVulnerability <- 1.0;

				scope.IsCloaked <- false;
				scope.CloakTime <- 12.0;
				scope.CloakDecloakTime <- 12.0;
				scope.CloakRange <- 1250.0;
				scope.CloakDecloakRange <- 300.0;
				scope.CloakCooldown <- scope.CloakTime + Time();

				scope.Think <- function()
				{
					RedWorld.TonkaThink(player);
					return -1;
				}

				scope.PlayAnimation <- function(animName, rate = 1.0, cycle = 0.0)
				{
					local player = self;
					scope.ResetAnimation();
					SetPropInt(self, "m_nRenderMode", 10);
					for (local wearable; wearable = Entities.FindByClassname(wearable, "tf_wearable*");)
					{
						if (wearable == null || wearable.GetOwner() != self)
						{
							continue;
						}

						SetPropInt(wearable, "m_nRenderMode", 10);
					}

					for (local weapon; weapon = Entities.FindByClassname(weapon, "tf_weapon*");)
					{
						if (weapon == null || weapon.GetOwner() != self)
						{
							continue;
						}

						SetPropInt(weapon, "m_nRenderMode", 1);
						if (weapon.GetSlot() == 2)
						{
							scope.OriginalGauntletColor = GetPropInt(weapon, "m_clrRender");
						}
						SetPropInt(weapon, "m_clrRender", 0);
					}
					local position = self.GetOrigin();
					local rotation = self.GetAbsAngles();
					local animation = SpawnEntityFromTable("prop_dynamic", {
						targetname = "tonka_animation",
						origin = position,
						angles = rotation,
						modelscale = 1.9,
						skin = 1,
						model = "models/mentrillum/bots/soviet_tonka_weapons_02.mdl",
						defaultanim = "stand_melee"
					});
					local hat1 = SpawnEntityFromTable("prop_dynamic", {
						origin = position,
						angles = rotation,
						modelscale = 1,
						skin = 1,
						model = "models/player/items/heavy/heavy_ushanka.mdl"
					});
					local hat2 = SpawnEntityFromTable("prop_dynamic", {
						origin = position,
						angles = rotation,
						modelscale = 0.8,
						skin = 1,
						model = "models/player/items/heavy/cop_glasses.mdl"
					});
					local hat3 = SpawnEntityFromTable("prop_dynamic", {
						origin = position,
						angles = rotation,
						modelscale = 1,
						skin = 1,
						model = "models/workshop/player/items/heavy/sum23_heavy_metal/sum23_heavy_metal.mdl"
					});
					if (scope.State == STATE_GAUNTLETS)
					{
						local gloves = SpawnEntityFromTable("prop_dynamic", {
						origin = position,
						angles = rotation,
						modelscale = 1,
						skin = 1,
						model = "models/weapons/c_models/c_fists_of_steel/c_fists_of_steel.mdl"
						rendercolor = "0 55 117"
						});
						gloves.AcceptInput("SetParent", "!activator", animation, null);
						SetPropInt(gloves, "m_fEffects", 129);
						gloves.AcceptInput("SetParentAttachmentMaintainOffset", "head", animation, null);
						scope.MiscAnimations.append(hat2);
					}
					hat1.AcceptInput("SetParent", "!activator", animation, null);
					hat2.AcceptInput("SetParent", "!activator", animation, null);
					hat3.AcceptInput("SetParent", "!activator", animation, null);
					SetPropInt(hat1, "m_fEffects", 129);
					SetPropInt(hat2, "m_fEffects", 129);
					SetPropInt(hat3, "m_fEffects", 129);
					hat1.AcceptInput("SetParentAttachmentMaintainOffset", "head", animation, null);
					hat2.AcceptInput("SetParentAttachmentMaintainOffset", "head", animation, null);
					hat3.AcceptInput("SetParentAttachmentMaintainOffset", "head", animation, null);
					animation.ValidateScriptScope();
					local animScope = animation.GetScriptScope();
					animScope.Think <- function()
					{
						if (!animation.IsValid())
						{
							return -1;
						}

						animation.SetOrigin(player.GetOrigin());
						local angles = player.GetAbsAngles();
						angles.x = 0.0;
						angles.z = 0.0;
						animation.SetAbsAngles(angles);
						return -1;
					}

					AddThinkToEnt(animation, "Think");

					animation.AcceptInput("SetAnimation", animName, null, null);
					EntFireByHandle(animation, "SetCycle", (cycle + 0.02).tostring(), 0.02, null, null);
					SetPropFloat(animation, "m_flCycle", cycle);
					SetPropFloat(animation, "m_flPlaybackRate", rate);
					scope.CurrentAnimation = animation;
					local glow = SpawnEntityFromTable("tf_glow" {
						glowcolor = "125 168 196 255",
						target = "bignet"
					});
					SetPropEntity(glow, "m_hTarget", animation);
					SetPropEntity(glow, "m_hMovePeer", animation.FirstMoveChild());
					SetPropEntity(animation, "m_hMoveChild", glow);
					SetPropEntity(glow, "m_hMoveParent", animation);
					RedWorld.SetAlwaysTransmit(animation);
					scope.MiscAnimations.append(hat1);
					scope.MiscAnimations.append(hat2);
					scope.MiscAnimations.append(hat3);
					scope.MiscAnimations.append(glow);
				}

				scope.ResetAnimation <- function()
				{
					SetPropInt(self, "m_nRenderMode", 0);
					for (local wearable; wearable = Entities.FindByClassname(wearable, "tf_wearable*");)
					{
						if (wearable == null || wearable.GetOwner() != self)
						{
							continue;
						}

						SetPropInt(wearable, "m_nRenderMode", 0);
					}

					for (local weapon; weapon = Entities.FindByClassname(weapon, "tf_weapon*");)
					{
						if (weapon == null || weapon.GetOwner() != self)
						{
							continue;
						}

						SetPropInt(weapon, "m_nRenderMode", 0);
						SetPropInt(weapon, "m_clrRender", weapon.GetSlot() != 2 ? 0xFFFFFF : scope.OriginalGauntletColor);
					}
					if (scope.CurrentAnimation != null && scope.CurrentAnimation.IsValid())
					{
						scope.CurrentAnimation.Destroy();
						scope.CurrentAnimation = null;
					}
					if (scope.MiscAnimations.len() > 0)
					{
						for (local i = 0; i < scope.MiscAnimations.len(); i++)
						{
							if (scope.MiscAnimations[i] == null || !scope.MiscAnimations[i].IsValid())
							{
								continue;
							}
							scope.MiscAnimations[i].Destroy();
						}
					}
					scope.MiscAnimations.clear();
				}

				scope.LaserThink <- function()
				{
					if (scope.AlwaysLookAtTarget == null)
					{
						return;
					}

					local time = Time();

					if (scope.LaserTick > time)
					{
						return;
					}
					local trace =
					{
						start = player.EyePosition(),
						end = scope.AlwaysLookAtTarget.GetCenter(),
						mask = 33636363,
						ignore = player
					}

					TraceLineEx(trace);
					local endPoint = trace.endpos;
					if (scope.LaserTargetEntity != null)
					{
						scope.LaserTargetEntity.Kill();
						scope.LaserTargetEntity = null;
					}
					scope.LaserTargetEntity = SpawnEntityFromTable("info_target", {
						origin = endPoint
					});
					for (local i = 0; i < scope.LaserEntities.len(); i++)
					{
						scope.LaserEntities[i].Kill();
					}
					scope.LaserEntities.clear();
					for (local i = 0; i < 2; i++)
					{
						local attachment = format("eye_boss_%i", i + 1);
						local pos = player.GetAttachmentOrigin(player.LookupAttachment(attachment));
						local laser = SpawnEntityFromTable("env_beam", {
							origin = pos,
							lightningstart = "bignet",
							lightningend = "bignet",
							boltwidth = 20,
							life = 0,
							NoiseAmplitude = 4.0,
							texture = "sprites/laser.vmt",
							rendercolor = "255 0 0",
							framerate = 60,
							spawnflags = 1
						});
						SetPropEntityArray(laser, "m_hAttachEntity", laser, 0);
						SetPropEntityArray(laser, "m_hAttachEntity", scope.LaserTargetEntity, 1);
						scope.LaserEntities.push(laser);
						laser.SetAbsOrigin(pos);
						laser.AcceptInput("TurnOn", null, null, null);
					}

					if (trace.hit)
					{
						local hit = trace.enthit;
						if (hit == null || !hit.IsValid() || hit.GetTeam() != 2)
						{
							return;
						}

						hit.TakeDamageEx(player, player, null, Vector(), endPoint, 15.0, DMG_SHOCK | DMG_ALWAYSGIB | DMG_SLOWBURN);
					}
					scope.LaserTick = time + 0.1;
				}

				scope.StartCloak <- function()
				{
					if (scope.IsCloaked || scope.IsAttacking)
					{
						return;
					}

					EmitSoundEx({sound_name = RedWorld.BossCloakOnSound,
					entity = self,
					sound_level = 100,
					filter_type = RECIPIENT_FILTER_GLOBAL});
					EmitSoundEx({sound_name = RedWorld.BossCloakOnSound,
					entity = self,
					sound_level = 100,
					filter_type = RECIPIENT_FILTER_GLOBAL});
					self.AddCond(TF_COND_STEALTHED_USER_BUFF);
					DispatchParticleEffect("drg_cow_explosioncore_charged_blue", self.GetOrigin() + Vector(0.0, 0.0, 45.0), Vector(0.0, 0.0, 0.0));
					scope.IsCloaked = true;
					scope.CloakCooldown = Time() + scope.CloakTime;
					self.AddCustomAttribute("no_attack", 1, 0.0);
				}

				scope.StopCloak <- function()
				{
					if (!scope.IsCloaked)
					{
						return;
					}

					EmitSoundEx({sound_name = RedWorld.BossCloakOffSound,
					entity = self,
					sound_level = 100,
					filter_type = RECIPIENT_FILTER_GLOBAL});
					EmitSoundEx({sound_name = RedWorld.BossCloakOffSound,
					entity = self,
					sound_level = 100,
					filter_type = RECIPIENT_FILTER_GLOBAL});
					DispatchParticleEffect("drg_cow_explosioncore_charged_blue", self.GetOrigin() + Vector(0.0, 0.0, 45.0), Vector(0.0, 0.0, 0.0));
					self.RemoveCond(TF_COND_STEALTHED_USER_BUFF);
					scope.IsCloaked = false;
					scope.CloakCooldown = Time() + scope.CloakDecloakTime;
					self.RemoveCustomAttribute("no_attack");
				}

				scope.ToggleCloak <- function()
				{
					if (scope.IsCloaked)
					{
						scope.StopCloak();
					}
					else
					{
						scope.StartCloak();
					}
				}

				scope.ProcessCloak <- function()
				{
					if (scope.IsCloaked && self.InCond(TF_COND_BURNING))
					{
						scope.StopCloak();
					}
					local range = scope.IsCloaked ? scope.CloakDecloakRange : scope.CloakRange;
					for (local otherPlayer; otherPlayer = FindByClassnameWithin(otherPlayer, "player", player.GetCenter(), range);)
					{
						if (otherPlayer == null || !otherPlayer.IsValid() || !otherPlayer.IsAlive() || IsPlayerABot(otherPlayer) || otherPlayer.GetTeam() != 2)
						{
							continue;
						}
						local playerRange = (otherPlayer.GetOrigin() - player.GetOrigin()).LengthSqr();

						if (scope.IsCloaked && playerRange <= pow(scope.CloakDecloakRange, 2.0))
						{
							scope.ToggleCloak();
							return;
						}

						if (!scope.IsCloaked && (playerRange <= pow(scope.CloakDecloakRange + 50.0, 2.0) || playerRange > pow(scope.CloakRange, 2.0)))
						{
							return;
						}
					}

					if (scope.CloakCooldown <= Time())
					{
						scope.ToggleCloak();
					}
				}
				AddThinkToEnt(player, "Think");
			}
		}
	}

	function SetAlwaysTransmit(ent)
	{
		local target = SpawnEntityFromTable("info_target", {targetname = "target_alwaystransmit"})
		target.AddEFlags(EFL_IN_SKYBOX | EFL_FORCE_CHECK_TRANSMIT)
		target.AcceptInput("SetParent", "!activator", ent, null)
		target.SetLocalOrigin(Vector())
		return target;
	}

	function TonkaThink(player)
	{
		local scope = player.GetScriptScope();
		local time = Time();
		if (player.GetTeam() != 3  || !player.IsAlive())
		{
			player.TerminateScriptScope();
			SetPropString(player, "m_iszScriptThinkFunction", "");
			AddThinkToEnt(player, null);
			scope.ResetAnimation();
			return 0;
		}

		if (scope.IsCloaked && !player.InCond(TF_COND_STEALTHED_USER_BUFF))
		{
			player.AddCond(TF_COND_STEALTHED_USER_BUFF);
		}

		if (scope.AlwaysLookAtTarget != null)
		{
			local newDirection = LerpQAngles(player.GetAbsAngles(), VectorToQAngle(scope.AlwaysLookAtTarget.GetOrigin() - player.GetOrigin()), 0.85);
			newDirection.x = 0.0;
			newDirection.z = 0.0;
			local vel = player.GetAbsAngles().Forward() * 1.0;
			player.Teleport(false, Vector(), true, newDirection, true, vel);
			player.SetAbsAngles(newDirection);
			player.SetLocalAngles(newDirection);
			player.SetPoseParameter(player.LookupPoseParameter("body_yaw"), 0.0);
			SetPropVector(player, "m_vecBaseVelocity", vel);
		}

		if (!scope.SwitchingPhase && player.GetHealth() <= RedWorld.BossHealthThreshold && scope.Phase < 3)
		{
			RedWorld.ChangePhase(player, scope.Phase + 1);
		}

		switch (scope.Phase)
		{
			case 0:
			{
				break;
			}

			case 1:
			{
				break;
			}

			case 2:
			{
				break;
			}
		}

		switch (scope.State)
		{
			case STATE_MINIGUN:
			{
				local minigun = null;
				for (local i = 0; i <= 8; i++)
				{
					local weapon = GetPropEntityArray(player, "m_hMyWeapons", i)
					if (weapon != null && weapon.GetSlot() == 0)
					{
						minigun = weapon;
						break;
					}
				}
				scope.MinigunState = GetPropInt(minigun, "m_iWeaponState");

				if (scope.QuoteChance == 1 && scope.MinigunState == 1)
				{
					scope.QuoteChance = 0;
					local sound = RedWorld.BossMinigunStartSounds[RandomInt(0, BossMinigunStartSounds.len() - 1)];
					EmitSoundEx({sound_name = sound,
					entity = player,
					sound_level = 100,
					filter_type = RECIPIENT_FILTER_GLOBAL});
					EmitSoundEx({sound_name = sound,
					entity = player,
					sound_level = 100,
					filter_type = RECIPIENT_FILTER_GLOBAL});
					EmitSoundEx({sound_name = sound,
					entity = player,
					sound_level = 100,
					filter_type = RECIPIENT_FILTER_GLOBAL});
				}
				if (scope.QuoteChance == 2 && scope.MinigunState == 2)
				{
					scope.QuoteChance = 0;
					local sound = RedWorld.BossMinigunFireSounds[RandomInt(0, BossMinigunFireSounds.len() - 1)];
					EmitSoundEx({sound_name = sound,
					entity = player,
					sound_level = 100,
					filter_type = RECIPIENT_FILTER_GLOBAL});
					EmitSoundEx({sound_name = sound,
					entity = player,
					sound_level = 100,
					filter_type = RECIPIENT_FILTER_GLOBAL});
					EmitSoundEx({sound_name = sound,
					entity = player,
					sound_level = 100,
					filter_type = RECIPIENT_FILTER_GLOBAL});
				}
				if (scope.MinigunState == 3 || scope.MinigunState == 4 || (scope.MinigunState == 0 && (scope.OldMinigunState == 3 || scope.OldMinigunState == 4)))
				{
					player.AddBotAttribute(8);
					player.AddCustomAttribute("no_attack", 1, 0.0);
					scope.SwitchTime = 1.0 + Time();
				}
				scope.OldMinigunState = scope.MinigunState;
				break;
			}

			case STATE_GAUNTLETS:
			{
				if (scope.IsCloaked && scope.IsAttacking)
				{
					scope.StopCloak();
				}

				if (scope.Phase >= 1 && !scope.SwitchingPhase)
				{
					scope.ProcessCloak();
				}

				if (!scope.IsAttacking && scope.AttackCooldown <= time)
				{
					if (!scope.IsQuakeAttackQueued && !scope.IsLaserAttackQueued)
					{
						if (scope.QuakeAttackCooldown <= time)
						{
							if (RandomInt(0, 5) == 0)
							{
								scope.IsQuakeAttackQueued = true;
							}
							else
							{
								scope.QuakeAttackCooldown = time + 2.0;
							}
						}

						if (scope.LaserAttackCooldown <= time && !scope.IsQuakeAttackQueued)
						{
							if (RandomInt(0, 5) == 0 && scope.Phase >= 1)
							{
								scope.IsLaserAttackQueued = true;
							}
							else
							{
								scope.LaserAttackCooldown = time + 2.0;
							}
						}
					}

					if (scope.IsQuakeAttackQueued)
					{
						for (local otherPlayer; otherPlayer = FindByClassnameWithin(otherPlayer, "player", player.GetCenter(), 450.0);)
						{
							if (otherPlayer == null || !otherPlayer.IsValid() || !otherPlayer.IsAlive() || IsPlayerABot(otherPlayer) || otherPlayer.GetTeam() != 2)
							{
								continue;
							}

							scope.IsAttacking = true;
							scope.AttackHitTime = (0.32 * 1.15) + time;
							scope.AttackTime = (1.4 * 1.15) + time;
							player.AddCond(TF_COND_FREEZE_INPUT);
							scope.PlayAnimation("attack3", 0.85);
							scope.AttackType = ATTACK_QUAKE;
							scope.IsQuakeAttackQueued = false;
							scope.AlwaysLookAtTarget = otherPlayer;
						}
					}

					if (scope.IsLaserAttackQueued)
					{
						for (local otherPlayer; otherPlayer = FindByClassnameWithin(otherPlayer, "player", player.GetCenter(), 450.0);)
						{
							if (otherPlayer == null || !otherPlayer.IsValid() || !otherPlayer.IsAlive() || IsPlayerABot(otherPlayer) || otherPlayer.GetTeam() != 2)
							{
								continue;
							}

							scope.IsAttacking = true;
							scope.AttackHitTime = 0.4 + time;
							scope.AttackTime = 2.1 + time;
							player.AddCond(TF_COND_FREEZE_INPUT);
							scope.PlayAnimation("taunt_unleashed_rage_heavy", 1.0);
							scope.AttackType = ATTACK_LASER;
							scope.IsLaserAttackQueued = false;
							scope.AlwaysLookAtTarget = otherPlayer;
							EmitSoundEx({sound_name = ")mentrillum/mvm/sfx/attack_chestbeam.wav",
							entity = player,
							sound_level = 90,
							filter_type = RECIPIENT_FILTER_GLOBAL});
						}
					}

					local bestDistance = 140.0;
					for (local otherPlayer; otherPlayer = FindByClassnameWithin(otherPlayer, "player", player.GetCenter(), bestDistance);)
					{
						if (otherPlayer == null || !otherPlayer.IsValid() || !otherPlayer.IsAlive() || IsPlayerABot(otherPlayer) || otherPlayer.GetTeam() != 2)
						{
							continue;
						}

						scope.IsAttacking = true;
						local validAttacks = [ATTACK_SLAM, ATTACK_SLASH];
						if (scope.Phase >= 1)
						{
							validAttacks.append(ATTACK_UPPERCUT);
						}
						scope.AttackType = validAttacks[RandomInt(0, validAttacks.len() - 1)];
						switch (scope.AttackType)
						{
							case ATTACK_SLAM:
							{
								scope.AttackHitTime = (0.46 * 1.2) + time;
								scope.AttackTime = (0.93 * 1.2) + time;
								player.AddCond(TF_COND_FREEZE_INPUT);
								scope.PlayAnimation("attack1", 1.0);
								break;
							}

							case ATTACK_SLASH:
							{
								scope.AttackHitTime = (0.4 * 1.2) + time;
								scope.AttackTime = (0.71 * 1.2) + time;
								player.AddCond(TF_COND_FREEZE_INPUT);
								scope.PlayAnimation("attack2", 0.8);
								break;
							}

							case ATTACK_UPPERCUT:
							{
								scope.AttackHitTime = (0.3 * 1.25) + time;
								scope.AttackTime = (1.1 * 1.25) + time;
								player.AddCond(TF_COND_FREEZE_INPUT);
								scope.PlayAnimation("taunt_bare_knuckle_beatdown_outro", 0.75);
								break;
							}
						}
						scope.AlwaysLookAtTarget = otherPlayer;
					}
				}

				if (scope.IsAttacking && scope.AttackTime > -1.0)
				{
					if (scope.AttackHitTime > -1.0 && scope.AttackHitTime <= time)
					{
						switch (scope.AttackType)
						{
							case ATTACK_SLAM:
							{
								for (local hitTarget; hitTarget = FindByClassnameWithin(hitTarget, "player", player.GetOrigin(), 350.0);)
								{
									if (hitTarget == null || !hitTarget.IsValid() || !hitTarget.IsAlive() || IsPlayerABot(hitTarget) || hitTarget.GetTeam() != 2)
									{
										continue;
									}

									local direction = hitTarget.GetOrigin() - player.GetCenter();
									direction.Norm();
									direction.Scale(20.0);
									hitTarget.TakeDamageEx(player, player, null, direction, player.GetCenter(), 75.0, DMG_CLUB);
									EmitSoundEx({sound_name = ")mentrillum/mvm/sfx/tank_punch_01.mp3",
									entity = hitTarget,
									sound_level = 85,
									filter_type = RECIPIENT_FILTER_GLOBAL,
									pitch = RandomInt(88, 105)});
								}
								local particle = SpawnEntityFromTable("info_particle_system",
								{
									effect_name = "hammer_impact_button",
									start_active = 1,
									origin = player.GetOrigin(),
									angles = player.GetAbsAngles()
								});
								EntFireByHandle(particle, "Kill", null, 0.1, null, null);
								for (local temp; temp = FindByClassnameWithin(temp, "player", player.GetOrigin(), 750.0);)
								{
									if (temp == null || !temp.IsValid() || !temp.IsAlive() || IsPlayerABot(temp) || temp.GetTeam() != 2)
									{
										continue;
									}

									trace <-
									{
										start = player.GetCenter(),
										end = player.GetCenter(),
										mask = 33636363,
										ignore = player
									}

									TraceLineEx(trace);
									if (!trace.hit || trace.enthit == temp)
									{
										if (temp.GetOrigin().z > player.GetOrigin().z + 80.0)
										{
											continue;
										}

										local velocity = VectorToQAngle(temp.GetOrigin() - player.GetOrigin());
										velocity.x += 30.0;
										local fwd = velocity.Forward();
										fwd.Norm();
										local scale = 900.0 - (temp.GetOrigin() - player.GetOrigin()).Length();
										fwd.x *= scale;
										fwd.y *= scale;
										fwd.z += scale / 2.0;
										SetPropVector(temp, "m_vecBaseVelocity", fwd);
									}
								}
								break;
							}

							case ATTACK_SLASH:
							{
								for (local hitTarget; hitTarget = FindByClassnameWithin(hitTarget, "player", player.GetOrigin(), 200.0);)
								{
									if (hitTarget == null || !hitTarget.IsValid() || !hitTarget.IsAlive() || IsPlayerABot(hitTarget) || hitTarget.GetTeam() != 2)
									{
										continue;
									}

									local direction = hitTarget.GetOrigin() - player.GetCenter();
									direction.Norm();
									direction.Scale(20.0);
									hitTarget.TakeDamageEx(player, player, null, direction, player.GetCenter(), 90.0, DMG_CLUB);
									EmitSoundEx({sound_name = ")mentrillum/mvm/sfx/tank_punch_01.mp3",
									entity = hitTarget,
									sound_level = 85,
									filter_type = RECIPIENT_FILTER_GLOBAL,
									pitch = RandomInt(88, 105)});
								}
								break;
							}

							case ATTACK_UPPERCUT:
							{
								for (local hitTarget; hitTarget = FindByClassnameWithin(hitTarget, "player", player.GetOrigin(), 200.0);)
								{
									if (hitTarget == null || !hitTarget.IsValid() || !hitTarget.IsAlive() || IsPlayerABot(hitTarget) || hitTarget.GetTeam() != 2)
									{
										continue;
									}

									local direction = hitTarget.GetOrigin() - player.GetCenter();
									local directionAng = VectorToQAngle(direction);
									if (fabs(player.GetAbsAngles().y - directionAng.y) > 100.0)
									{
										continue;
									}

									direction.Norm();
									direction.Scale(20.0);
									hitTarget.TakeDamageEx(player, player, null, direction, player.GetCenter(), 110.0, DMG_CLUB | DMG_RADIATION);
									EmitSoundEx({sound_name = ")mentrillum/mvm/sfx/tank_punch_01.mp3",
									entity = hitTarget,
									sound_level = 85,
									filter_type = RECIPIENT_FILTER_GLOBAL,
									pitch = RandomInt(88, 105)});

									local velocity = VectorToQAngle(hitTarget.GetOrigin() - player.GetOrigin());
									velocity.x += 30.0;
									local fwd = velocity.Forward();
									fwd.Norm();
									local scale = 600.0 - (hitTarget.GetOrigin() - player.GetOrigin()).Length();
									fwd.x *= scale / 4.5;
									fwd.y *= scale / 4.5;
									fwd.z += scale;
									SetPropVector(hitTarget, "m_vecBaseVelocity", fwd);
								}
								break;
							}

							case ATTACK_QUAKE:
							{
								scope.QuakeAttackCooldown = time + 4.0;
								RedWorld.StartQuakeExplosions(player);
								break;
							}

							case ATTACK_LASER:
							{
								scope.LaserDuration = 1.1 + time;
								break;
							}
						}

						scope.AttackHitTime = -1.0;
					}

					if (scope.AttackTime <= time)
					{
						scope.AttackTime = -1.0;
						scope.AttackCooldown = RandomFloat(2.0, 4.5) + time;
						scope.IsAttacking = false;
						scope.ResetAnimation();
						player.RemoveCond(TF_COND_FREEZE_INPUT);
						scope.AlwaysLookAtTarget = null;
						scope.LaserDuration = -1.0;
					}
				}

				if (scope.IsAttacking)
				{
					if (scope.LaserDuration > -1.0 && scope.LaserDuration > time)
					{
						scope.LaserThink();
					}
					else
					{
						if (scope.LaserEntities.len() > 0)
						{
							for (local i = 0; i < scope.LaserEntities.len(); i++)
							{
								scope.LaserEntities[i].Kill();
							}
							scope.LaserEntities.clear();
						}
						if (scope.LaserTargetEntity != null)
						{
							scope.LaserTargetEntity.Kill();
							scope.LaserTargetEntity = null;
						}
					}
				}
				break;
			}

			case STATE_SHOTGUN:
			{
				break;
			}

			case STATE_FLEE:
			{
				if (scope.IsCloaked && player.InCond(TF_COND_BURNING))
				{
					scope.StopCloak();
				}
				if (((player.GetOrigin() - scope.FleePosition).LengthSqr() <= 175.0 * 175.0 || scope.FleeTime <= time) && !scope.ReachedFleePosition)
				{
					scope.StopCloak();
					EntFire("pop_interface", "ChangeBotAttributes", "Sandvich_Action");
					scope.ReachedFleePosition = true;
					EntFireByHandle(player, "$RemovePlayerAttribute", "no_attack", 0.05, null, null);
					EntFireByHandle(player, "$RemovePlayerAttribute", "increased jump height", 0.05, null, null);
				}
				else
				{
					if (scope.NextPathUpdate <= time)
					{
						UpdatePath(player, scope.FleePosition);
					}
					ComputeToPath(player);
					if (player.GetLocomotionInterface().IsStuck())
					{
						scope.FleeTime = 0.0;
					}
				}
				if (scope.ReachedFleePosition)
				{
					if (!player.InCond(TF_COND_TAUNTING))
					{
						scope.FleeAbortTime = 3.65 + time;
					}
					if (scope.ReachedFleePosition && scope.FleeAbortTime <= time)
					{
						player.RemoveCond(87);
						scope.State = 10;
						scope.SwitchTime = 0.0;
						scope.SwitchingPhase = false;
						player.RemoveBotAttribute(IGNORE_ENEMIES);
						player.RemoveBotAttribute(SUPPRESS_FIRE);
						player.ClearBehaviorFlag(16);
						player.AcceptInput("$BotCommand", "switch_action Mobber", null, null);
						EntFireByHandle(player, "$BotCommand", "switch_action Mobber", 0.1, null, null);
						scope.CurrentVulnerability += 0.25;
						//EntFire("pop_interface", "ChangeBotAttributes", "Melee_Action");
						//EntFire("pop_interface", "ChangeBotAttributes", "Melee_Action", 0.1);
					}
				}

				return;
			}
		}

		if (scope.SwitchTime <= time && scope.State != STATE_FLEE && !scope.SwitchingPhase)
		{
			if (scope.IsAttacking)
			{
				scope.SwitchTime += 2.0;
				return;
			}
			player.RemoveBotAttribute(8);
			EntFireByHandle(player, "$RemovePlayerAttribute", "no_attack", 0.1, null, null);
			local validStates = [STATE_MINIGUN, STATE_SHOTGUN, STATE_GAUNTLETS];
			if (validStates.find(scope.State) != null)
			{
				validStates.remove(validStates.find(scope.State));
			}

			if (scope.IsCloaked)
			{
				scope.StopCloak();
			}

			scope.State = validStates[RandomInt(0, validStates.len() - 1)];
			switch (scope.State)
			{
				case STATE_MINIGUN:
				{
					scope.QuoteChance = RandomInt(0, 2);
					// It's over 9000!
					scope.SwitchTime = 9001.0 + Time();
					EntFire("pop_interface", "ChangeBotAttributes", "Minigun_Action");
					break;
				}

				case STATE_SHOTGUN:
				{
					scope.SwitchTime = RandomFloat(10.0, 20.0) + Time();
					switch (RandomInt(0, 1))
					{
						case 0:
						{
							EntFire("pop_interface", "ChangeBotAttributes", "Shotgun_Action_Dragonsbreath");
							break;
						}

						case 1:
						{
							EntFire("pop_interface", "ChangeBotAttributes", "Shotgun_Action_ResupplyShotgun");
							break;
						}
					}

					break;
				}

				case STATE_GAUNTLETS:
				{
					EntFire("pop_interface", "ChangeBotAttributes", "Melee_Action");
					scope.AttackCooldown = RandomFloat(2.0, 4.5) + time;
					scope.SwitchTime = RandomFloat(20.0, 40.0) + Time();
					break;
				}
			}
		}
	}

	function UpdatePath(player, pos)
	{
		local scope = player.GetScriptScope();
		local startArea = NavMesh.GetNearestNavArea(player.GetOrigin(), 500.0, false, true);
		local endArea = NavMesh.GetNearestNavArea(pos, 500.0, false, true);
		local result = {};
		NavMesh.GetNavAreasFromBuildPath(startArea, endArea, pos, 0, 3, false, result);

		local path = [pos];
		scope.PathLength = result.len();
		for (local i = 1; i < scope.PathLength; i++)
		{
			local resultPos = result["area"+i].GetCenter();
			path.push(resultPos);
		}
		path.reverse();
		scope.PathLength = path.len();

		scope.PathIndex = 0;
		scope.PathArray = path;
		scope.NextPathUpdate = Time() + 0.3;
	}

	function ComputeToPath(player)
	{
		local scope = player.GetScriptScope();
		local loco = player.GetLocomotionInterface();
		local pathPos = scope.PathArray[0];
		local dist = (player.GetOrigin() - pathPos).LengthSqr();
		loco.FaceTowards(pathPos);
		loco.Approach(pathPos, 1.0);
		if (!loco.IsClimbingOrJumping())
		{
			local adjustedPos = player.GetOrigin();
			adjustedPos.z += loco.GetStepHeight() - 5.0;
			local tempPathPos = pathPos;
			local tempPlayerPos = player.GetOrigin();
			tempPathPos.z = tempPlayerPos.z;
			local direction = VectorToQAngle(tempPathPos - tempPlayerPos).Forward();
			local endPos = tempPlayerPos + (direction * 125.0);
			endPos.z += loco.GetStepHeight() - 5.0;

			local trace =
			{
				start = adjustedPos,
				end = endPos,
				mask = 33636363,
				ignore = player
			}

			TraceLineEx(trace);
			if (trace.hit)
			{
				loco.Jump();
			}
		}
	}

	function Explode(pos, damage, radius, particle, attacker)
	{
		local bomb = SpawnEntityFromTable("tf_generic_bomb", {
			targetname = "tonka_bombs",
			origin = pos,
			damage = damage,
			radius = radius,
			health = 1,
			friendlyfire = 1,
			explode_particle = particle,
			sound = "vo/null.mp3"
		});
		for (local i = 1; i <= MAX_CLIENTS; i++)
		{
			local temp = PlayerInstanceFromIndex(i);
			if (temp == null)
			{
				continue;
			}

			ScreenShake(pos, 3.0, 3.0, 0.0, radius * 5.0, 1, true);
			ScreenShake(pos, 6.0, 6.0, 0.5, radius * 5.0, 0, true);
		}
		bomb.TakeDamage(9001.0, DMG_BLAST, attacker);
	}

	function VectorToQAngle(Vector)
	{
		local yaw, pitch
		if (Vector.y == 0.0 && Vector.x == 0.0)
		{
			yaw = 0.0
			if (Vector.z > 0.0)
			{
				pitch = 270.0
			}
			else
			{
				pitch = 90.0
			}
		}
		else
		{
			yaw = (::atan2(Vector.y, Vector.x) * 57.2958)
			while (yaw > 180.0)
			{
				yaw -= 360.0;
			}
			while (yaw < -180.0)
			{
				yaw += 360.0;
			}
			pitch = (::atan2(-Vector.z, Vector.Length2D()) * 57.2958)
			while (pitch > 180.0)
			{
				pitch -= 360.0;
			}
			while (pitch < -180.0)
			{
				pitch += 360.0;
			}
		}
		return ::QAngle(pitch, yaw, 0.0)
	}

	function LerpVectors(a, b, t)
	{
		if (t < 0.0)
		{
			t = 0.0;
		}
		if (t > 1.0)
		{
			t = 1.0;
		}

		local c = Vector();
		c.x = a.x + (b.x - a.x) * t;
		c.y = a.y + (b.y - a.y) * t;
		c.z = a.z + (b.z - a.z) * t;

		return c;
	}

	function LerpQAngles(a, b, t)
	{
		if (t < 0.0)
		{
			t = 0.0;
		}
		if (t > 1.0)
		{
			t = 1.0;
		}

		local c = QAngle();
		c.x = a.x + (b.x - a.x) * t;
		c.y = a.y + (b.y - a.y) * t;
		c.z = a.z + (b.z - a.z) * t;

		return c;
	}

	function SwitchBossState(player, state)
	{
		local scope = player.GetScriptScope();
		if (!("State" in scope))
		{
			return;
		}

		if (scope.State == state)
		{
			return;
		}

		scope.State = state;
		scope.AttackCooldown = 4.0;
	}

	function ShuffleBossSpawn()
	{
		local arr = []
		for (local i = 0; i < BossPositions.len(); i++)
		{
			arr.append(i);
		}
		while (arr.len() > 0)
		{
			local index = arr.find(RandomInt(0, arr.len() - 1));
			if (index == null)
			{
				break;
			}
			local val = arr[index];
			local area = NavMesh.GetNearestNavArea(BossPositions[val], 2000.0, false, false);
			local skip = false;
			for (local i2 = 1; i2 <= MAX_CLIENTS; i2++)
			{
				local player = PlayerInstanceFromIndex(i2);
				if (player == null || player.GetTeam() != 2)
				{
					continue;
				}

				local area2 = NavMesh.GetNearestNavArea(player.GetOrigin(), 10000.0, false, false);
				if (area2 == null)
				{
					continue;
				}

				if (NavMesh.NavAreaTravelDistance(area, area2, 10000.0) <= 2000.0)
				{
					skip = true;
					break;
				}
			}
			if (skip)
			{
				arr.remove(index);
				continue;
			}
			ChosenBossPosition = BossPositions[val];
			ChosenBossAngles = BossAngles[val];
			DoBossIntro(BossPositions[val], BossAngles[val]);
			ShuffleUpgradeTable(val);
			return;
		}
		// Last resort
		ChosenBossPosition = BossPositions[BossPositions.len() - 1];
		ChosenBossAngles = BossAngles[BossAngles.len() - 1];
		DoBossIntro(BossPositions[BossPositions.len() - 1], BossAngles[BossAngles.len() - 1]);
		ShuffleUpgradeTable(BossPositions.len() - 1);
	}

	function ShuffleUpgradeTable(index)
	{
		local spawnPos = Vector(0.0, 0.0, 0.0);
		local spawnAng = QAngle(0.0, 0.0, 0.0);
		local spawnPosIndicator = Vector(0.0, 0.0, 0.0);
		local spawnAngIndicator = QAngle(0.0, 0.0, 0.0);

		switch (index)
		{
			case 0: // Spawn
			{
				spawnPos = Vector(415.0, 640.0, -18.0);
				spawnAng = QAngle(0.0, 90.0, 0.0);
				spawnPosIndicator = Vector(415.0, 610.0, 200.0);
				spawnAngIndicator = QAngle(0.0, 90.0, 0.0);
				break;
			}

			case 1: // Far right outdoor
			{
				spawnPos = Vector(745.0, 5525.0, 23.0);
				spawnAng = QAngle(0.0, -90.0, 0.0);
				spawnPosIndicator = Vector(770.0, 5656.0, 220.0);
				spawnAngIndicator = QAngle(0.0, -90.0, 0.0);
				break;
			}

			case 2: // Far left outdoor
			{
				spawnPos = Vector(-2805.0, 5025.0, -18.0);
				spawnAng = QAngle(0.0, -90.0, 0.0);
				spawnPosIndicator = Vector(-2805.0, 5056.0, 190.0);
				spawnAngIndicator = QAngle(0.0, -90.0, 0.0);
				break;
			}

			case 3: // Garage
			{
				spawnPos = Vector(865.0, 2795.0, -18.0);
				spawnAng = QAngle(0.0, 180.0, 0.0);
				spawnPosIndicator = Vector(912.0, 2795.0, 200.0);
				spawnAngIndicator = QAngle(0.0, 180.0, 0.0);
				break;
			}

			case 4: // Left back indoor
			{
				spawnPos = Vector(-1545.0, 2720.0, 110.0);
				spawnAng = QAngle(0.0, 90.0, 0.0);
				spawnPosIndicator = Vector(-1545.0, 2690.0, 300.0);
				spawnAngIndicator = QAngle(0.0, 90.0, 0.0);
				break;
			}

			case 5: // Outside BLU gate
			{
				spawnPos = Vector(-1715.0, 5020.0, -18.0);
				spawnAng = QAngle(0.0, -90.0, 0.0);
				spawnPosIndicator = Vector(-1715.0, 5072.0, 230.0);
				spawnAngIndicator = QAngle(0.0, -90.0, 0.0);
				break;
			}

			case 6: // In BLU spawn
			{
				spawnPos = Vector(-2580.0, 5020.0, -82.0);
				spawnAng = QAngle(0.0, -90.0, 0.0);
				spawnPosIndicator = Vector(-2580.0, 5072.0, 137.0);
				spawnAngIndicator = QAngle(0.0, -90.0, 0.0);
				break;
			}
		}
		SpawnUpgradeTable(spawnPos, spawnAng, spawnPosIndicator, spawnAngIndicator, false);
	}

	function DoBossIntro(position, rotation)
	{
		local boss = SpawnEntityFromTable("prop_dynamic", {
			origin = position,
			angles = rotation,
			modelscale = 1.9,
			startdisabled = 1,
			skin = 1,
			model = "models/mentrillum/bots/soviet_tonka_weapons_02.mdl",
			"OnAnimationDone" : "!self,Kill,,-1,-1"
		});
		local hat1 = SpawnEntityFromTable("prop_dynamic", {
			origin = position,
			angles = rotation,
			modelscale = 1,
			skin = 1,
			model = "models/player/items/heavy/heavy_ushanka.mdl"
		});
		local hat2 = SpawnEntityFromTable("prop_dynamic", {
			origin = position,
			angles = rotation,
			modelscale = 0.8,
			skin = 1,
			model = "models/player/items/heavy/cop_glasses.mdl"
		});
		local hat3 = SpawnEntityFromTable("prop_dynamic", {
			origin = position,
			angles = rotation,
			modelscale = 1,
			skin = 1,
			model = "models/workshop/player/items/heavy/sum23_heavy_metal/sum23_heavy_metal.mdl"
		});
		hat1.AcceptInput("SetParent", "!activator", boss, null);
		hat2.AcceptInput("SetParent", "!activator", boss, null);
		hat3.AcceptInput("SetParent", "!activator", boss, null);
		SetPropInt(hat1, "m_fEffects", 129);
		SetPropInt(hat2, "m_fEffects", 129);
		SetPropInt(hat3, "m_fEffects", 129);
		hat1.AcceptInput("SetParentAttachmentMaintainOffset", "head", boss, null);
		hat2.AcceptInput("SetParentAttachmentMaintainOffset", "head", boss, null);
		hat3.AcceptInput("SetParentAttachmentMaintainOffset", "head", boss, null);
		local camera = SpawnEntityFromTable("point_viewcontrol", { targetname = "boss_camera" });
		DoBossIntroPost(boss, camera);
	}

	function DoBossIntroPost(boss, camera)
	{
		camera.AcceptInput("SetParent", "!activator", boss, null);
		camera.AcceptInput("SetParentAttachment", "camera", null, null);
		local gameText = SpawnEntityFromTable("game_text", {
			channel = 3,
			color = "255 50 50",
			holdtime = 7.8,
			x = -1.0,
			y = 0.65,
			effect = 2,
			fxtime = 0.9,
			fadein = 0.01,
			fadeout = 0.01,
			spawnflags = 1,
			message = "Soviet Tonka Weapons"
		});
		local rng = RandomInt(0, 3);
		local msg = "";
		switch (rng)
		{
			case 0:
			{
				msg = "He may be tanky, but he'll heal a few times if he gets too low."
				break;
			}

			case 1:
			{
				msg = "If he spots you with his minigun, take cover to force him to switch weapons."
				break;
			}

			case 2:
			{
				msg = "All support bots drop money, kill them for either buybacks or upgrades."
				break;
			}

			case 3:
			{
				msg = "Watch out for his various attacks, he punches, creates explosions in the ground,\nand has an eye laser. Yes, an eye laser."
				break;
			}
		}
		local gameTextEx = SpawnEntityFromTable("game_text", {
			channel = 5,
			color = "255 50 50",
			holdtime = 6.8,
			x = -1.0,
			y = 0.75,
			effect = 2,
			fxtime = 0.9,
			fadein = 0.0,
			fadeout = 0.0,
			spawnflags = 1,
			message = msg
		});
		RedWorld.SetDestroyCallback(camera, function()
		{
			self.AcceptInput("$DisableAll", null, null, null);
			ScreenFade(null, 255, 255, 255, 255, 1.0, 0.05, 1);
			gameText.Kill();

			for (local i = 1; i <= MAX_CLIENTS; i++)
			{
				local player = PlayerInstanceFromIndex(i);
				if (player == null || player.IsFakeClient() || player.GetTeam() != 2)
				{
					continue;
				}

				player.RemoveCond(TF_COND_TAUNTING);
				player.RemoveCond(TF_COND_FREEZE_INPUT);
				player.SetHudHideFlags(0);
				SetPropInt(player, "m_iFOV", 0);
			}
		})

		DoBossIntroPost2(boss, camera, gameText, gameTextEx);
	}

	function DoBossIntroPost2(boss, camera, gameText, gameTextEx)
	{
		boss.AcceptInput("SetAnimation", "intro", null, null);
		boss.AcceptInput("Enable", null, null, null);
		camera.AcceptInput("$EnableAll", null, null, null);

		for (local i = 1; i <= MAX_CLIENTS; i++)
		{
			local player = PlayerInstanceFromIndex(i);
			if (player == null || player.IsFakeClient() || player.GetTeam() != 2)
			{
				continue;
			}

			player.RemoveCond(TF_COND_TAUNTING);
			player.AddCond(TF_COND_FREEZE_INPUT);
			player.SetHudHideFlags(0xffffffff & ~(HIDEHUD_CHAT | HIDEHUD_ALL));
		}

		camera.ValidateScriptScope();
		local scope = camera.GetScriptScope();

		scope.NextVoiceTime <- -1.0;
		scope.VoiceIndex <- 0;
		scope.RandomIndex <- 0;
		scope.TextTime <- 0.0;
		scope.TextTimeEx <- 0.0;
		scope.Duration <- 0.0;

		scope.NextVoiceTime = Time() + 2.0;
		scope.TextTime = Time() + 1.0;
		scope.TextTimeEx = Time() + 2.0;
		scope.Duration = Time() + boss.GetSequenceDuration(boss.LookupSequence("intro"));
		scope.RandomIndex = RandomInt(0, BossIntroSound1.len() - 1);
		camera.GetScriptScope().Think <- function()
		{
			local time = Time();
			if (scope.TextTime > -1.0 && scope.TextTime < time)
			{
				for (local i = 1; i <= MAX_CLIENTS; i++)
				{
					local player = PlayerInstanceFromIndex(i);
					if (player == null)
					{
						continue;
					}
					if (RedWorld.InMeltdown)
					{
						EmitSoundEx({sound_name = "#mentrillum/mvm/music/red_alert_3_hell_march_3.wav"
							entity = player
							filter_type = 4
							volume = 1.0});
					}
				}
				gameText.AcceptInput("Display", null, -1, null);
				scope.TextTime = -1.0;
			}
			if (scope.TextTimeEx > -1.0 && scope.TextTimeEx < time)
			{
				gameTextEx.AcceptInput("Display", null, -1, null);
				scope.TextTimeEx = -1.0;
			}
			for (local i = 1; i <= MAX_CLIENTS; i++)
			{
				local player = PlayerInstanceFromIndex(i);
				if (player == null)
				{
					continue;
				}
				player.SetForcedTauntCam(0);
				SetPropInt(player, "m_iFOV", 75);
			}
			if (scope.NextVoiceTime > -1.0 && scope.NextVoiceTime < time && scope.VoiceIndex < 2)
			{
				scope.NextVoiceTime = RedWorld.BossIntroDelay1[scope.RandomIndex] + time;
				local sound = RedWorld.BossIntroSound1[scope.RandomIndex];
				if (scope.VoiceIndex == 1)
				{
					sound = RedWorld.BossIntroSound2[scope.RandomIndex];
				}
				scope.VoiceIndex++;
				for (local i = 1, player; i <= MAX_CLIENTS; i++)
				{
					if ((player = PlayerInstanceFromIndex(i)) != null)
					{
						EmitSoundEx({sound_name = sound
						entity = player
						filter_type = 4});
						EmitSoundEx({sound_name = sound
						entity = player
						filter_type = 4
						volume = 0.5});
					}
				}
			}

			if (scope.Duration > -1.0 && scope.Duration < time)
			{
				boss.Kill();
				scope.Duration = -1.0;
			}

			return 0;
		}
		ScreenFade(null, 0, 0, 0, 255, 1.0, 0.05, 1);
		AddThinkToEnt(camera, "Think");
	}

	function ChangePhase(bot, phase)
	{
		local scope = bot.GetScriptScope();
		scope.SwitchingPhase = true;
		local sound = RedWorld.BossChangePhaseSounds[RandomInt(0, BossChangePhaseSounds.len() - 1)];
		EmitSoundEx({sound_name = sound,
		entity = bot,
		sound_level = 100,
		filter_type = RECIPIENT_FILTER_GLOBAL});
		EmitSoundEx({sound_name = sound,
		entity = bot,
		sound_level = 100,
		filter_type = RECIPIENT_FILTER_GLOBAL});
		EmitSoundEx({sound_name = sound,
		entity = bot,
		sound_level = 100,
		filter_type = RECIPIENT_FILTER_GLOBAL});
		StopSupportBots();
		local populator = FindByClassname(null, "point_populator_interface");
		populator.AcceptInput("$ResumeWavespawn", format("phase%d_bots", phase), null, null);
		scope.Phase = phase;
		EntFireByHandle(bot, "$AddPlayerAttribute", "no_attack|1", 0.1, null, null);
		scope.AttackTime = -1.0;
		scope.AttackCooldown = 4.0 + Time();
		scope.IsAttacking = false;
		scope.ResetAnimation();
		bot.AddCond(TF_COND_FREEZE_INPUT);
		scope.AlwaysLookAtTarget = null;
		scope.LaserDuration = -1.0;
		if (scope.LaserTargetEntity != null)
		{
			scope.LaserTargetEntity.Kill();
			scope.LaserTargetEntity = null;
		}
		for (local i = 0; i < scope.LaserEntities.len(); i++)
		{
			if (scope.LaserEntities[i] == null || !scope.LaserEntities[i].IsValid())
			{
				continue;
			}
			scope.LaserEntities[i].Kill();
		}
		scope.LaserEntities.clear();
		if (!scope.IsCloaked)
		{
			scope.PlayAnimation("taunt_rps_rock_lose", 1.0, 0.489);
			EntFireByHandle(bot, "RunScriptCode", "RedWorld.StartFlee(self)", 2.0, null, null);
		}
		else
		{
			EntFireByHandle(bot, "RunScriptCode", "RedWorld.StartFlee(self)", 0.0, null, null);
		}
	}

	function StartFlee(bot)
	{
		if (bot.GetTeam() != 3  || !bot.IsAlive())
		{
			return;
		}
		local scope = bot.GetScriptScope();
		scope.ResetAnimation();
		scope.StateBeforeFlee = scope.State;
		scope.SwitchTime += 2.0;
		scope.FleeTime = Time() + RandomFloat(10.0, 16.0);
		scope.State = STATE_FLEE;
		scope.StartCloak();
		EntFire("pop_interface", "ChangeBotAttributes", "Melee_Action");
		scope.ReachedFleePosition = false;
		local tableAreas = {};
		local areas = [];
		local range = RandomFloat(RedWorld.BossFleeRange[0], RedWorld.BossFleeRange[1]);
		NavMesh.GetNavAreasInRadius(bot.GetOrigin(), range, tableAreas);
		foreach (nav in tableAreas)
		{
			if (nav.HasAttributeTF(TF_NAV_SPAWN_ROOM_RED))
			{
				continue;
			}
			areas.append(nav);
		}
		local area = areas[RandomInt(0, areas.len() - 1)];
		scope.FleePosition = area.GetCenter();
		scope.FleePosition.z += 1.0;
		bot.AddBotAttribute(IGNORE_ENEMIES);
		bot.AddBotAttribute(SUPPRESS_FIRE);
		bot.RemoveCond(TF_COND_FREEZE_INPUT);
		bot.SetBehaviorFlag(16);
		EntFireByHandle(bot, "$BotCommand", "switch_action Idle", 0.1, null, null);
		EntFireByHandle(bot, "$AddPlayerAttribute", "increased jump height|1.6", 0.1, null, null);
		EntFireByHandle(bot, "$AddPlayerAttribute", "no_attack|1", 0.1, null, null);
	}

	function StopSupportBots()
	{
		local populator = FindByClassname(null, "point_populator_interface");
		for (local i = 0; i < 4; i++)
		{
			populator.AcceptInput("$PauseWavespawn", format("phase%d_bots", i), null, null);
		}
	}

	function RandomizeTeleport(player, name)
	{
		local arr = [];
		local teleporter = null;
		while ((teleporter = Entities.FindByName(teleporter, name)) != null)
		{
			arr.append(teleporter);
		}
		teleporter = arr[RandomInt(0, arr.len() - 1)];
		player.Teleport(true, teleporter.GetOrigin(), true, teleporter.GetAbsAngles(), false, player.GetAbsVelocity());
	}
}

__CollectGameEventCallbacks(RedWorld);
RedWorld.InMeltdown = GetMapName().find("meltdown") != null;
PrecacheSound("player/suit_denydevice.wav");
PrecacheSound("#mentrillum/mvm/music/red_alert_3_hell_march_3.wav");
PrecacheModel("models/blackout.mdl");
PrecacheSound(RedWorld.BossCloakOnSound);
PrecacheSound(RedWorld.BossCloakOffSound);
PrecacheModel("models/weapons/w_models/w_wrench.mdl");
PrecacheModel("models/props_spytech/binder001.mdl");
PrecacheModel("models/weapons/w_models/w_toolbox.mdl");
PrecacheModel("models/effects/saxxy_flash/saxxy_flash.mdl");
PrecacheModel("models/weapons/c_models/c_sledgehammer/c_sledgehammer.mdl");
PrecacheModel("models/player/items/all_class/hwn_spellbook_diary.mdl");
PrecacheModel("models/props_spytech/work_table001.mdl");
PrecacheModel("models/player/items/heavy/heavy_ushanka.mdl");
PrecacheModel("models/player/items/heavy/cop_glasses.mdl");
PrecacheModel("models/workshop/player/items/heavy/sum23_heavy_metal/sum23_heavy_metal.mdl");
PrecacheModel("models/weapons/c_models/c_fists_of_steel/c_fists_of_steel.mdl");
PrecacheModel("models/props_mvm/mvm_upgrade_sign.mdl");
for (local i = 0; i < RedWorld.BossIntroSound1.len(); i++)
{
	PrecacheSound(RedWorld.BossIntroSound1[i]);
	PrecacheSound(RedWorld.BossIntroSound2[i]);
}
for (local i = 0; i < RedWorld.BossChangePhaseSounds.len(); i++)
{
	PrecacheSound(RedWorld.BossChangePhaseSounds[i]);
}
for (local i = 0; i < RedWorld.BossMinigunStartSounds.len(); i++)
{
	PrecacheSound(RedWorld.BossMinigunStartSounds[i]);
}
for (local i = 0; i < RedWorld.BossMinigunFireSounds.len(); i++)
{
	PrecacheSound(RedWorld.BossMinigunFireSounds[i]);
}
RedWorld.ApplySpeedBoostToAll();

for (local i = 1, player; i <= MaxClients().tointeger(); i++)
{
	if ((player = PlayerInstanceFromIndex(i)) != null)
	{
		RedWorld.ClassCheck(player);
	}
}