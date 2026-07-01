::CONST <- getconsttable()
::ROOT <- getroottable()

// Classes Folding
foreach( _class in [ "NetProps", "Entities", "EntityOutputs", "NavMesh", "Convars" ] )
{
	foreach( k, v in ROOT[_class].getclass() )
	{
		if ( !( k in ROOT ) && k != "IsValid" )
		{
			ROOT[k] <- ROOT[_class][k].bindenv( ROOT[_class] )
		}
	}
}

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

::OncomingSandstorm <-
{
	//// CLEANUP FUNCTIONS ////

	function CleanUp()
	{
		delete ::OncomingSandstorm
	}

	OnGameEvent_recalculate_holidays = function(_) { if (GetRoundState() == 3) CleanUp() }

	//// MAP FUNCTIONS ////

	function SandstormInit()
	{
		EntFire("nav_avoid_intel_bridges_timer", "Kill")

		SetSkyboxTexture("sky_sandstorm")

		for(local Soundscape; Soundscape = Entities.FindByName(Soundscape, "sndscp_outside");)
		{
			Soundscape.KeyValueFromString("soundscape", "stormfront.outside")
			Soundscape.DispatchSpawn()
		}
	}

	//// DJINN FUNCTIONS ////

	function DjinnInit(Target)
	{
		Target.ValidateScriptScope()
		local DjinnScope = Target.GetScriptScope()

		if (!("DjinnEntities" in DjinnScope))
		{
			DjinnScope.DjinnEntities <- []
		}
		for(local Child = Target.FirstMoveChild(); Child != null; Child = Child.NextMovePeer())
		{
			if (Child.GetClassname() == "bot_generator")
			{
				DjinnScope.DjinnEntities.append(Child)
			}
			else if (Child.GetClassname() == "info_target")
			{
				DjinnScope.DjinnEntities.append(Child)
			}
		}
	}

	function DjinnSummonTrace(Target)
	{
		for(local Child = Target.FirstMoveChild(); Child != null; Child = Child.NextMovePeer())
		{
			if (Child.GetClassname() == "bot_generator")
			{
				local TraceParams = 
				{
					start = Target.GetOrigin()
					end = Child.GetOrigin()
					ignore = Target
				}

				TraceLineEx(TraceParams)

				if(TraceParams.hit)
				{
					Child.ValidateScriptScope()
					Child.GetScriptScope().OriginalPosition <- Child.GetLocalOrigin()

					Child.SetLocalOrigin(Vector())

					EntFireByHandle(Child, "RunScriptCode", "self.SetLocalOrigin(OriginalPosition)", 0.5, null, null)
				}
			}
		}
	}

	function DjinnSummonInit(Target)
	{
		Target.RemoveWeaponRestriction(7)
		Target.ClearAllBotAttributes()
		Target.ClearAllBotTags()
		Target.SetCustomModelWithClassAnimations(null)
		Target.SetDifficulty(3)
		Target.SetMaxVisionRangeOverride(9999)

		SetFakeClientConVarValue(Target, "name", "Resurrected Demoman")
		Target.SetCustomModelWithClassAnimations("models/bots/demo/bot_demo_gibby.mdl")
		SetPropString(Target, "m_iszClassIcon", "demo_crit")

		Target.AddWeaponRestriction(2)
		Target.AddBotAttribute(16)
		Target.AddBotAttribute(32)
		Target.AddBotAttribute(2048)

		Target.AddCustomAttribute("cannot pick up intelligence", 1, 0)
		Target.AddCustomAttribute("max health additive bonus", 125, 0)

		Target.SetHealth(300)
		Target.SetModelScale(1.3, 0.0)
	}

	function SultanSummonInit(Target)
	{
		Target.RemoveWeaponRestriction(7)
		Target.ClearAllBotAttributes()
		Target.ClearAllBotTags()
		Target.SetCustomModelWithClassAnimations(null)
		Target.SetDifficulty(3)
		Target.SetMaxVisionRangeOverride(9999)

		SetFakeClientConVarValue(Target, "name", "Resurrected Rapid Fire Soldier")
		Target.SetCustomModelWithClassAnimations("models/bots/soldier/bot_soldier_gibby.mdl")
		SetPropString(Target, "m_iszClassIcon", "soldier_spammer")

		Target.AddWeaponRestriction(2)
		Target.AddBotAttribute(16)
		Target.AddBotAttribute(32)
		Target.AddBotAttribute(2048)

		Target.AddCustomAttribute("cannot pick up intelligence", 1, 0)
		Target.AddCustomAttribute("max health additive bonus", 400, 0)

		Target.SetHealth(600)
		Target.SetModelScale(1.4, 0.0)
	}
}

__CollectGameEventCallbacks(OncomingSandstorm)