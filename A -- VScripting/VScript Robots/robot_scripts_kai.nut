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

::RobotScripts_Kai <-
{
	// Cleanup Functions
	function Cleanup()
	{
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
	}

	function GiantBlitzSoldierLogic(Target)
	{
		Target.ValidateScriptScope()
		TargetScope = Target.GetScriptScope()

		TargetScope.FiringStartTime <- -1
		TargetScope.FirerateStartInterval <- 0.8
		TargetScope.FirerateIncInterval <- 2
		TargetScope.FirerateIncMult <- 0.1
		TargetScope.MaxFirerateMult <- 0.1

		TargetScope.Think <- function()
		{
			local Weapon = Target.GetActiveWeapon()
			local NextFire = GetPropFloat(Weapon, "m_flNextPrimaryAttack")

			local GlobalTime = Time()

			if (NextFire <= GlobalTime)
			{
				if (FiringStartTime < 0)
					FiringStartTime = GlobalTime

				local FirerateIncCount = floor((GlobalTime - FiringStartTime) / FirerateIncInterval)

				local CurrentFirerate = FirerateStartInterval * pow(FirerateIncMult, FirerateIncCount)

				if (CurrentFirerate < MaxFirerateMult)
					CurrentFireRate = MaxFirerateMult

				SetPropFloat(Weapon, "m_flNextPrimaryAttack", GlobalTime + CurrentFireRate)
			}
			else
			{
				if (FiringStartTime >= 0 && NextFire - GlobalTime > 1)
					FiringStartTime = -1
			}

			return 0.05
		}
		AddThinkToEnt(Target, "Think")
	}
}

__CollectGameEventCallbacks(RobotScripts_Kai)