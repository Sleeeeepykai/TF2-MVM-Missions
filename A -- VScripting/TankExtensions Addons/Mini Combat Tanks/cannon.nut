local TINYCOMBATTANK_VALUES_TABLE = {
	TINYCOMBATTANK_CANNON_MODEL                = "models/bots/boss_bot/combat_tank_mk2/mk2_combat_tank_cannon.mdl"
	TINYCOMBATTANK_CANNON_SND_FIRE             = ")mvm/giant_soldier/giant_soldier_rocket_shoot.wav"
	TINYCOMBATTANK_CANNON_SND_FIRE2            = ")weapons/rocket_ll_shoot.wav"
	TINYCOMBATTANK_CANNON_SND_ROCKET_EXPLOSION = ")mvm/giant_soldier/giant_soldier_rocket_explode.wav"
	TINYCOMBATTANK_CANNON_FIRE_STARTUP_DELAY   = 1
	TINYCOMBATTANK_CANNON_FIRE_DELAY           = 3
	TINYCOMBATTANK_CANNON_PARTICLE_TRAIL       = "rockettrail"
	TINYCOMBATTANK_CANNON_PARTICLE_EXPLOSION   = "hightower_explosion"
	TINYCOMBATTANK_CANNON_ROCKET               = "models/weapons/w_models/w_rocket.mdl"
	TINYCOMBATTANK_CANNON_ROCKET_SPEED         = 2000
	TINYCOMBATTANK_CANNON_ROCKET_DAMAGE        = 200
}
foreach(k,v in TINYCOMBATTANK_VALUES_TABLE)
	if(!(k in TankExt.ValueOverrides))
		ROOT[k] <- v

PrecacheModel(TINYCOMBATTANK_CANNON_MODEL)
PrecacheModel(TINYCOMBATTANK_CANNON_ROCKET)
TankExt.PrecacheSound(TINYCOMBATTANK_CANNON_SND_FIRE)
TankExt.PrecacheSound(TINYCOMBATTANK_CANNON_SND_FIRE2)
TankExt.PrecacheSound(TINYCOMBATTANK_CANNON_SND_ROCKET_EXPLOSION)

TankExt.TinyCombatTankWeapons["tinycannon"] <- {
	TurretReplacement = 1
	function SpawnModel()
	{
		local hCannon = CreateByClassnameSafe("funCBaseFlex")
		hCannon.SetModel(TINYCOMBATTANK_CANNON_MODEL)
		hCannon.SetPlaybackRate(1.0)
		hCannon.DispatchSpawn()
		hCannon.SetSequence(hCannon.LookupSequence("idle"))
		return hCannon
	}
	function OnSpawn()
	{
		hTank_scope.vecMountOffset = Vector(39.9593, 0, 19)
		hTank_scope.bAimAtFeet     = true
		local iSkin = hTank.GetSkin()
		if(iSkin == 1 || iSkin == 3)
			self.SetSkin(self.GetSkin() + 4)

		local hWeapon = SpawnEntityFromTableSafe("tf_point_weapon_mimic", {
			damage        = TINYCOMBATTANK_CANNON_ROCKET_DAMAGE
			modelscale    = 1
			speedmax      = TINYCOMBATTANK_CANNON_ROCKET_SPEED
			speedmin      = TINYCOMBATTANK_CANNON_ROCKET_SPEED
			weapontype    = 0
		})
		TankExt.SetParentArray([hWeapon], self)
		local iSeqIdle       = self.LookupSequence("idle")
		local iSeqFire       = self.LookupSequence("cannon_fire")
		local iPosePitch     = self.LookupPoseParameter("aim_pitch")
		local iPoseEye       = self.LookupPoseParameter("eye_yaw")
		local iBarrel        = self.LookupAttachment("gun_muzzle")
		local iEyeYaw        = 0.0
		local flTimeAttack   = 0.0
		local flTimeIdle     = 0.0
		local flFireDuration = self.GetSequenceDuration(iSeqFire)
		function TinyCombatTankWeaponThink()
		{
			if(!(self && self.IsValid())) return
			self.StudioFrameAdvance()
			self.SetPoseParameter(iPosePitch, TankExt.Clamp(hTank_scope.angCurrent.x, -12, 30))
			self.SetPoseParameter(iPoseEye, iEyeYaw = iEyeYaw + 2 % 360)

			local flTime         = Time()
			local bEnemyInRadius = hTank_scope.hTarget ? (hTank_scope.LaserTrace.endpos - hTank_scope.vecTarget).Length() <= TF_ROCKET_RADIUS : false
			local bCanAttack     = flTime >= flTimeAttack
			if(bCanAttack && bEnemyInRadius)
			{
				flTimeAttack = flTime + TINYCOMBATTANK_CANNON_FIRE_DELAY
				flTimeIdle   = flTime + flFireDuration
				self.ResetSequence(iSeqFire)

				local vecBarrel    = self.GetAttachmentOrigin(iBarrel)
				local vecOrigin    = self.GetOrigin()
				local flModelScale = hTank.GetModelScale()
				vecBarrel -= vecOrigin
				vecBarrel *= flModelScale
				vecBarrel += vecOrigin
				hWeapon.SetAbsOrigin(vecBarrel)
				hWeapon.SetAbsAngles(RotateOrientation(hTank.GetAbsAngles(), hTank_scope.angCurrent * -1))
				hWeapon.AcceptInput("FireOnce", null, null, null)

				DispatchParticleEffect("rocketbackblast", vecBarrel, self.GetAttachmentAngles(iBarrel).Left() * -1)
				hTank_scope.AddToSoundQueue({
					sound_name  = TINYCOMBATTANK_CANNON_SND_FIRE
					sound_level = 100
					pitch       = 90
					entity      = hTank
					filter_type = RECIPIENT_FILTER_GLOBAL
				})
				hTank_scope.AddToSoundQueue({
					sound_name  = TINYCOMBATTANK_CANNON_SND_FIRE2
					sound_level = 100
					pitch       = 80
					entity      = hTank
					filter_type = RECIPIENT_FILTER_GLOBAL
				})

				for(local hRocket; hRocket = FindByClassnameWithin(hRocket, "tf_projectile_rocket", hWeapon.GetOrigin(), 64);)
				{
					if(hRocket.GetOwner() != hWeapon || hRocket.GetEFlags() & EFL_NO_MEGAPHYSCANNON_RAGDOLL) continue
					MarkForPurge(hRocket)

					local iTeamNum = hTank.GetTeam()
					hRocket.SetModel(TINYCOMBATTANK_CANNON_ROCKET)
					hRocket.SetSize(Vector(), Vector())
					hRocket.SetSolid(SOLID_BSP)
					hRocket.SetSkin(iTeamNum == TF_TEAM_BLUE ? 1 : 0)
					hRocket.SetTeam(iTeamNum)
					hRocket.SetOwner(hTank)

					hRocket.ValidateScriptScope()
					hRocket.AddEFlags(EFL_NO_MEGAPHYSCANNON_RAGDOLL)
					local vecOrigin     = Vector()
					local vecVelocity   = Vector()
					local bSolid        = false
					local hRocket_scope = hRocket.GetScriptScope()
					hRocket_scope.hTank <- hTank
					local function RocketLogicThink()
					{
						if(!self.IsValid()) return
						vecOrigin   = self.GetOrigin()
						vecVelocity = self.GetAbsVelocity()
						if(!bSolid && (!hTank.IsValid() || !TankExt.IntersectionBoxBox(vecOrigin, self.GetBoundingMins(), self.GetBoundingMaxs(), hTank.GetOrigin(), hTank.GetBoundingMins(), hTank.GetBoundingMaxs())))
							{ bSolid = true; self.SetSolid(SOLID_BBOX) }
						return -1
					}
					hRocket_scope.RocketLogicThink <- RocketLogicThink
					TankExt.AddThinkToEnt(hRocket, "RocketLogicThink")

					TankExt.SetDestroyCallback(hRocket, function()
					{
						local Trace = {
							start = vecOrigin
							end   = vecOrigin + vecVelocity * FrameTime()
							mask  = MASK_SOLID
						}
						TraceLineEx(Trace)
						if(Trace.hit && !(Trace.surface_flags & SURF_SKY))
						{
							EmitSoundEx({
								sound_name  = TINYCOMBATTANK_CANNON_SND_ROCKET_EXPLOSION
								sound_level = 100
								pitch       = 90
								origin      = vecOrigin
								filter_type = RECIPIENT_FILTER_GLOBAL
							})
							DispatchParticleEffect(TINYCOMBATTANK_CANNON_PARTICLE_EXPLOSION, vecOrigin, Trace.plane_normal)
						}
					})

					if(TINYCOMBATTANK_CANNON_PARTICLE_TRAIL != "rockettrail")
					{
						TankExt.DispatchParticleEffectOn(hRocket, null)
						TankExt.DispatchParticleEffectOn(hRocket, TINYCOMBATTANK_CANNON_PARTICLE_TRAIL, "trail")
					}
				}
			}
			else if(flTimeIdle > -1 && flTime >= flTimeIdle)
			{
				flTimeIdle = -1
				self.ResetSequence(iSeqIdle)
			}

			if(!hTank_scope.hTarget)
				flTimeAttack = flTime + TINYCOMBATTANK_CANNON_FIRE_STARTUP_DELAY

			return -1
		}
		TankExt.AddThinkToEnt(self, "TinyCombatTankWeaponThink")
	}
}