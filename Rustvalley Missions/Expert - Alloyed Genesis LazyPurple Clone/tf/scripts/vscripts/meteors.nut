Meteors <- {
    function playSoundFromEntity(hEntity, soundname, huRange = 99999)
	{
		local hEnt = hEntity;
		if (typeof(hEntity) == "string") {
			hEnt = Entities.FindByName(null, hEntity)
		}
		local snd_lvl = (40 + (20 * log10(huRange / 36))).tointeger()
		PrecacheSound(soundname)
		EmitSoundEx({
			sound_name = soundname
			entity = hEnt
			volume      = 1
			sound_level = snd_lvl
			filter_type = RECIPIENT_FILTER_GLOBAL
		})
	}
    enemy_types_to_damage = [
        "player",
        "obj_sentrygun",
        "obj_dispenser",
        "obj_teleporter",
        "base_boss",
        "tank_boss",
        "tf_zombie"
    ],
    meteor_models = [
        { "scale": 1.25, "model": "models/props_moonbase/moon_rock_small001.mdl" },
        { "scale": 1, "model": "models/props_moonbase/moon_rock002_medium.mdl" },
        { "scale": 0.75, "model": "models/props_moonbase/moon_rock_large001.mdl" },
        { "scale": 1, "model": "models/props_moonbase/moon_rock_medium001.mdl" }
    ],
    function CreateMeteor(hTarget, sfx = true)
	{
		local hSkyPosition = hTarget + Vector(RandomInt(-900, 900), RandomInt(-900, 900), 1000)
		local dict_model = Meteors.meteor_models[RandomInt(0, meteor_models.len() - 1)]
		local hMeteor = SpawnEntityFromTable("prop_dynamic",
		{
			DisableBoneFollowers = "1",
			model = dict_model.model,
			StartDisabled = "1",
			rendercolor = "125 0 0",
		})
		hMeteor.SetModelScale(dict_model.scale, 0)
		hMeteor.SetAbsOrigin(hSkyPosition)

		local dir = (hTarget - hSkyPosition)
		dir.Norm()
		hMeteor.SetForwardVector(dir)
		Meteors.playSoundFromEntity(hMeteor, RandomInt(0, 1) == 0 ? "ambient/machines/aircraft_distant_flyby1.wav" : "ambient/machines/aircraft_distant_flyby3.wav")
		hMeteor.ValidateScriptScope()
		local hMeteorScope = hMeteor.GetScriptScope()
		hMeteorScope.hIndicator <- SpawnEntityFromTable("prop_dynamic", {
            model = "models/props_mvm/indicator/indicator_circle.mdl",
            DisableBoneFollowers = "1",
            skin = "1",
            DefaultAnim = "start",
            disableshadows = "1",
            StartDisabled = "0"
        });
		hMeteorScope.hIndicator.SetModelScale(5, 0)
		if (sfx) Meteors.playSoundFromEntity(hMeteorScope.hIndicator, "ptx/other/amored_activate.wav")
		hMeteorScope.hIndicator.SetAbsOrigin(hTarget + Vector(0, 0, 5))
		hMeteorScope.hTrail2 <- SpawnEntityFromTable("info_particle_system", {
			effect_name = "kartimpacttrail"
			start_active = 0
		})
		hMeteorScope.hTrail2.SetAbsOrigin(hSkyPosition + dir * 10)
		hMeteorScope.hTrail2.SetForwardVector(dir)
		hMeteorScope.hTrail2.AcceptInput("SetParent", "!activator", hMeteor, null)
		hMeteorScope.ROCKET_LAUNCH_TIME <- Time() + 3.75
		hMeteorScope.DO_ROCKET_LAUNCH <- true
		hMeteorScope.LerpConst <- hTarget - hSkyPosition
		hMeteorScope.rocketStarted <- false
		hMeteorScope.ROCKET_HIT_TIME <- -1
		hMeteorScope.Think <- function()
		{
			if (Time() >= ROCKET_LAUNCH_TIME && DO_ROCKET_LAUNCH)
			{
				local t = (Time() - ROCKET_LAUNCH_TIME) / 1.25
				if (t >= 1.0)
				{
					hMeteor.SetAbsOrigin(hTarget)
					DO_ROCKET_LAUNCH = false
					hMeteor.AcceptInput("Disable", null, null, null)
					hIndicator.Kill()
					ScreenShake(hTarget, 3, 8, 1, 0, 0, true)
					DispatchParticleEffect("mvm_tank_destroy_bloom", hTarget, Vector(90, 0, 0))
					Meteors.playSoundFromEntity(hMeteor, "ambient/explosions/explode_9.wav")
					ROCKET_HIT_TIME = Time()

					for (local i = 0; i < Meteors.enemy_types_to_damage.len(); i = i + 1)
					{
						for (local entity_to_damage = null; entity_to_damage = Entities.FindByClassnameWithin(entity_to_damage, Meteors.enemy_types_to_damage[i], hTarget, 175);)
						{
							if (!entity_to_damage || !entity_to_damage.IsValid()) continue
							if (0 != NetProps.GetPropInt(entity_to_damage, "m_lifeState")) continue

							entity_to_damage.TakeDamage(300, DMG_BLAST, null)
						}
					}
					return -1
				}
				else
				{
					local easedT = t * t
					local newPos = hSkyPosition + (LerpConst * easedT)
					hMeteor.SetAbsOrigin(newPos)

					local rotationSpeed = 360 * easedT;
           			hMeteor.SetAbsAngles(QAngle(rotationSpeed * 0.5, rotationSpeed, rotationSpeed * 0.2));

					if (!rocketStarted)
					{
						rocketStarted = true
						hMeteor.AcceptInput("Enable", null, null, null)
						hMeteorScope.hTrail2.AcceptInput("Start", null, null, null)
						EntFireByHandle(hMeteor, "runscriptcode", "Meteors.playSoundFromEntity(self, `MeteorFlyby`)", 0.5, null, null)
					}
				}
			}
			if (ROCKET_HIT_TIME >= 0 && Time() >= ROCKET_HIT_TIME + 1.0)
			{
				hTrail2.Kill()
				hMeteor.Kill()
				NetProps.SetPropString(self, "m_iszScriptThinkFunction", "")
			}
			return -1
		}
		AddThinkToEnt(hMeteor, "Think")
	}
	function meteorTimes(total_count, total_time) {
		local time_spots = [];
		for (local i = 0; i < total_count; i++) {
			time_spots.append(RandomFloat(0, total_time));
		}

		return time_spots;
	}
	function MeteorShower(count, total_setup_time = 2)
	{
		local strike_spots = []
		local minareasize = 1500;
		local spots = []
		local total_origin = Vector(0, 0, 0)
		local player_count = 0

		for (local player; player = FindByClassname(player, "player");)
		{
			if (player.GetTeam() != TEAM_SPECTATOR)
			{
				total_origin += player.GetOrigin()
				player_count += 1
			}
		}

		local average_origin_x = null
		local average_origin_y = null
		local average_origin_z = null
		if (player_count > 0)
		{
			average_origin_x = total_origin.x / player_count
			average_origin_y = total_origin.y / player_count
			average_origin_z = total_origin.z / player_count
		}

		local average = Vector(average_origin_x, average_origin_y, average_origin_z)

		local nav_table_average = {}
		NavMesh.GetNavAreasInRadius(average, 2000, nav_table_average)

		foreach(id, nav in nav_table_average)
		{
			if (nav.GetSizeX() * nav.GetSizeY() > minareasize && !nav.HasAttributeTF(TF_NAV_SPAWN_ROOM_RED) && !nav.HasAttributeTF(TF_NAV_SPAWN_ROOM_BLUE) && nav.IsReachableByTeam(2))
			{
				spots.append(nav)
			}
		}

		for (local i = 0; i < count; i++)
		{
			if (spots.len() == 0) break;

			local random_index = RandomInt(0, spots.len() - 1);
			local nav = spots[random_index];
			strike_spots.append(nav.FindRandomSpot())
		}

		local times = meteorTimes(count, total_setup_time)

		for (local i = 0; i < times.len(); i++) {
			local loc = strike_spots[i];
			local time = times[i];
			printl(time)
			local string_to_run = format("Meteors.CreateMeteor(Vector(%d,%d,%d),false)", loc.x, loc.y, loc.z)
			EntFire("bignet", "runscriptcode", string_to_run, time)
		}
	}
}