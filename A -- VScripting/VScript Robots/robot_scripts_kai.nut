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

::RobotScripts_Kai <-
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

		delete ::RobotScripts_Kai
	}

	OnGameEvent_recalculate_holidays = function(_) { if (GetRoundState() == 3) Cleanup() }

	// Bot Tag Application Functions
	OnGameEvent_player_spawn = function(params)
	{
		local Player = GetPlayerFromUserID(params.userid)

		if (Player.IsBotOfType(1337))
		{
			EntFireByHandle(Player, "RunScriptCode", "RobotScripts_Kai.BotTagCheck()", 0.0, Player, null);
			return
		}
	}
	OnGameEvent_player_death = function(params)
	{
		local Player = GetPlayerFromUserID(params.userid)

		if (Player.IsBotOfType(1337))
		{
			SetPropString(Player, "m_iszScriptThinkFunction", "")
		}
	}

	function BotTagCheck()
	{
		if(activator.HasBotTag("GiantBlitzSoldier"))
		{
			RobotScripts_Kai.GiantBlitzSoldierLogic(activator)
		}
		if(activator.HasBotTag("RifleSniper"))
		{
			activator.SetMission(3, true)
		}
	}

	function GiantBlitzSoldierLogic(Target)
	{
		Target.ValidateScriptScope()
		local TargetScope = Target.GetScriptScope()

		TargetScope.FiringStartTime <- -1
		TargetScope.FirerateStartInterval <- 0.8
		TargetScope.FirerateIncInterval <- 2
		TargetScope.FirerateIncMult <- 0.6
		TargetScope.MaxFirerateMult <- 0.05

		TargetScope.PrevNextFire <- -1
		TargetScope.LastShotTime <- -1

		TargetScope.Think <- function()
		{
			local Weapon = Target.GetActiveWeapon()
			if (!Weapon) return -1

			local NextFire = GetPropFloat(Weapon, "m_flNextPrimaryAttack")
			local GlobalTime = Time()

			if (PrevNextFire < 0)
				PrevNextFire = NextFire

			local ShotFired = (PrevNextFire <= GlobalTime) && (NextFire > GlobalTime)

			if (ShotFired)
			{
				if (FiringStartTime < 0)
					FiringStartTime = GlobalTime

				LastShotTime = GlobalTime

				local FirerateIncCount = floor((GlobalTime - FiringStartTime) / FirerateIncInterval)
				local CurrentFirerate = FirerateStartInterval * pow(FirerateIncMult, FirerateIncCount)

				if (CurrentFirerate < MaxFirerateMult)
					CurrentFirerate = MaxFirerateMult

				local DesiredNext = GlobalTime + CurrentFirerate

				if (NextFire > DesiredNext)
					SetPropFloat(Weapon, "m_flNextPrimaryAttack", DesiredNext)
			}
			else
			{
				local WeaponClip = GetPropInt(Weapon, "m_iClip1")

				if (FiringStartTime >= 0 && LastShotTime >= 0 && GlobalTime - LastShotTime > 1)
					FiringStartTime = -1

				if(WeaponClip == 0 || GetPropBool(weapon, "m_bInReload"))
					FiringStartTime = -1
			}

			return -1
		}

		AddThinkToEnt(Target, "Think")
	}
}

__CollectGameEventCallbacks(RobotScripts_Kai)