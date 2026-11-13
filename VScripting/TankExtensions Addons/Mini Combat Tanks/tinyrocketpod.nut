local TINYCOMBATTANK_VALUES_TABLE = {
	TINYCOMBATTANK_ROCKETPOD_SND_FIRE              = "Weapon_RPG.Single"
	TINYCOMBATTANK_ROCKETPOD_ROCKET_SPEED          = 900
	TINYCOMBATTANK_ROCKETPOD_ROCKET_DAMAGE         = 30
	TINYCOMBATTANK_ROCKETPOD_ROCKET                = "models/weapons/w_models/w_rocket.mdl"
	TINYCOMBATTANK_ROCKETPOD_ROCKET_HOMING         = "models/weapons/w_models/w_rocket.mdl"
	TINYCOMBATTANK_ROCKETPOD_RELOAD_DELAY          = 0.3
	TINYCOMBATTANK_ROCKETPOD_PARTICLE_TRAIL        = "rockettrail"
	TINYCOMBATTANK_ROCKETPOD_PARTICLE_TRAIL_HOMING = "eyeboss_projectile"
	TINYCOMBATTANK_ROCKETPOD_MODEL                 = "models/bots/boss_bot/combat_tank_mk2/mk2_rocket_pod.mdl"
	TINYCOMBATTANK_ROCKETPOD_HOMING_POWER          = 0.05
	TINYCOMBATTANK_ROCKETPOD_HOMING_SPEED_MULT     = 0.75
	TINYCOMBATTANK_ROCKETPOD_HOMING_DURATION       = 1.5
	TINYCOMBATTANK_ROCKETPOD_FIRE_DELAY            = 0.2
	TINYCOMBATTANK_ROCKETPOD_CONE_RADIUS           = 90
}
foreach(k,v in TINYCOMBATTANK_VALUES_TABLE)
	if(!(k in TankExt.ValueOverrides))
		ROOT[k] <- v

PrecacheModel(TINYCOMBATTANK_ROCKETPOD_MODEL)
PrecacheModel(TINYCOMBATTANK_ROCKETPOD_ROCKET)
PrecacheModel(TINYCOMBATTANK_ROCKETPOD_ROCKET_HOMING)
TankExt.PrecacheSound(TINYCOMBATTANK_ROCKETPOD_SND_FIRE)

TankExt.TinyCombatTankWeapons["tinyrocketpod"] <- {
	Model = TINYCOMBATTANK_ROCKETPOD_MODEL
	function OnSpawn()
	{
		local hWeapon = SpawnEntityFromTableSafe("tf_point_weapon_mimic", {
			damage        = TINYCOMBATTANK_ROCKETPOD_ROCKET_DAMAGE
			modeloverride = TINYCOMBATTANK_ROCKETPOD_ROCKET
			modelscale    = 0.5
			speedmax      = TINYCOMBATTANK_ROCKETPOD_ROCKET_SPEED
			speedmin      = TINYCOMBATTANK_ROCKETPOD_ROCKET_SPEED
			weapontype    = 0
		})
		TankExt.SetParentArray([hWeapon], self)
		local flTimeNext = 0.0
		local iSlots     = [1, 2, 3, 4, 5, 6, 7, 8, 9]
		local bReloading = false
		local bClosed    = true
		bHoming <- false

		local function FixMisalignedAttachmentOrigin(vecAttachment, vecOrigin, flModelScale = null)
		{
			if(!flModelScale)
				flModelScale = hTank.GetModelScale()

			if(flModelScale == 0.5)
				return vecAttachment

			vecAttachment -= vecOrigin
			vecAttachment *= flModelScale
			vecAttachment += vecOrigin

			return vecAttachment
		}

		function TinyCombatTankWeaponThink()
		{
			if(!(self && self.IsValid())) return
			local flTime       = Time()
			local bEnemyInCone = hTank_scope.flAngleDot >= cos(TINYCOMBATTANK_ROCKETPOD_CONE_RADIUS * DEG2RAD)
			local bNext        = flTime >= flTimeNext
			if(bNext && bEnemyInCone && !bReloading && iSlots.len() > 0)
			{
				if(bClosed)
				{
					bClosed = false
					self.AcceptInput("SetAnimation", "open", null, null)
					flTimeNext = flTime + 0.33
					return
				}

				flTimeNext = flTime + TINYCOMBATTANK_ROCKETPOD_FIRE_DELAY
				local iRNG    = RandomInt(0, iSlots.len() - 1)
				local iBarrel = iSlots[iRNG]
				iSlots.remove(iRNG)

				local vecOrigin    = self.GetOrigin()
				local flModelScale = hTank.GetModelScale()
				// SetPropInt(hWeapon, "m_iParentAttachment", iBarrel) // this is slower
				hWeapon.SetAbsOrigin(FixMisalignedAttachmentOrigin(self.GetAttachmentOrigin(iBarrel), vecOrigin, flModelScale))
				hWeapon.SetAbsAngles(TankExt.VectorAngles(hTank_scope.LaserTrace.endpos - FixMisalignedAttachmentOrigin(self.GetAttachmentOrigin(5), vecOrigin, flModelScale)))
				hWeapon.AcceptInput("FireOnce", null, null, null)

				local vecBackBlast = FixMisalignedAttachmentOrigin(self.GetAttachmentOrigin(iBarrel + 9), vecOrigin, flModelScale)
				DispatchParticleEffect("rocketbackblast", vecBackBlast, self.GetAttachmentAngles(iBarrel + 9).Forward())
				hTank_scope.AddToSoundQueue({
					sound_name  = TINYCOMBATTANK_ROCKETPOD_SND_FIRE
					sound_level = 90
					entity      = hTank
					filter_type = RECIPIENT_FILTER_GLOBAL
				})

				for(local hRocket; hRocket = FindByClassnameWithin(hRocket, "tf_projectile_rocket", hWeapon.GetOrigin(), 64);)
				{
					if(hRocket.GetOwner() != hWeapon || hRocket.GetEFlags() & EFL_NO_MEGAPHYSCANNON_RAGDOLL) continue
					MarkForPurge(hRocket)

					local iTeamNum = hTank.GetTeam()
					hRocket.SetSize(Vector(), Vector())
					hRocket.SetSolid(SOLID_BSP)
					hRocket.SetSequence(1)
					hRocket.SetSkin(iTeamNum == TF_TEAM_BLUE ? 1 : 0)
					hRocket.SetTeam(iTeamNum)
					hRocket.SetOwner(hTank)

					hRocket.ValidateScriptScope()
					hRocket.AddEFlags(EFL_NO_MEGAPHYSCANNON_RAGDOLL)
					local bSolid = false
					local hRocket_scope = hRocket.GetScriptScope()
					hRocket_scope.hTank <- hTank
					local function RocketLogicThink()
					{
						if(!self.IsValid()) return
						local vecOrigin = self.GetOrigin()
						if(!bSolid && (!hTank.IsValid() || !TankExt.IntersectionBoxBox(vecOrigin, self.GetBoundingMins(), self.GetBoundingMaxs(), hTank.GetOrigin(), hTank.GetBoundingMins(), hTank.GetBoundingMaxs())))
							{ bSolid = true; self.SetSolid(SOLID_BBOX) }
						if("HomingThink" in this) HomingThink()
						return -1
					}
					hRocket_scope.RocketLogicThink <- RocketLogicThink
					if(bHoming)
					{
						hRocket.SetModel(TINYCOMBATTANK_ROCKETPOD_ROCKET_HOMING)
						hRocket.SetSize(Vector(), Vector())
						hRocket_scope.HomingParams <- {
							Target      = hTank_scope.hTarget
							TurnPower   = TINYCOMBATTANK_ROCKETPOD_HOMING_POWER
							RocketSpeed = TINYCOMBATTANK_ROCKETPOD_HOMING_SPEED_MULT
							AimTime     = TINYCOMBATTANK_ROCKETPOD_HOMING_DURATION
						}
						IncludeScript("tankextensions/misc/homingrocket", hRocket_scope)
					}
					TankExt.AddThinkToEnt(hRocket, "RocketLogicThink")

					local sTrail = bHoming ? TINYCOMBATTANK_ROCKETPOD_PARTICLE_TRAIL_HOMING : TINYCOMBATTANK_ROCKETPOD_PARTICLE_TRAIL
					if(sTrail != "rockettrail")
					{
						hRocket.AcceptInput("DispatchEffect", "ParticleEffectStop", null, null)
						local hTrail = CreateByClassnameSafe("trigger_particle")
						hTrail.KeyValueFromString("particle_name", sTrail)
						hTrail.KeyValueFromString("attachment_name", "trail")
						hTrail.KeyValueFromInt("attachment_type", 4)
						hTrail.KeyValueFromInt("spawnflags", 64)
						DispatchSpawn(hTrail)
						hTrail.AcceptInput("StartTouch", null, hRocket, hRocket)
						hTrail.Kill()
					}
				}
			}

			if(bNext && bReloading)
			{
				flTimeNext = flTime + TINYCOMBATTANK_ROCKETPOD_RELOAD_DELAY
				for(local i = 1; i <= 9; i++)
					if(iSlots.find(i) == null)
					{
						iSlots.append(i)
						break
					}
				if(iSlots.len() >= 9) bReloading = false
			}

			if(bNext && !bEnemyInCone || iSlots.len() == 0)
			{
				if(!bClosed)
				{
					bClosed = true
					self.AcceptInput("SetAnimation", "close", null, null)
					flTimeNext = flTime + 0.66
				}
				if(iSlots.len() < 9)
					bReloading = true
			}
			return -1
		}
		TankExt.AddThinkToEnt(self, "TinyCombatTankWeaponThink")
	}
}

TankExt.TinyCombatTankWeapons["rocketpod_homing"] <- {
	Model = TINYCOMBATTANK_ROCKETPOD_MODEL
	function OnSpawn()
	{
		TankExt.TinyCombatTankWeapons["rocketpod"].OnSpawn.call(this)
		bHoming = true
	}
}