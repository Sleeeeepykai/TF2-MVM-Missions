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

	OnGameEvent_recalculate_holidays = function(_) { if (GetRoundState() == 3) Cleanup() }

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
					start = Target
					end = Child
					ignore = Target
				}

				TraceLineEx(TraceParams)

				if(TraceParams.hit)
				{
					local OriginalPosition = Child.GetLocalOrigin()

					Child.SetLocalOrigin(Target)

					EntFireByHandle(Child, "CallScriptFunction", SetLocalOrigin(OriginalPosition), 0.5, Target, null)
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

		SetFakeClientConVarValue(Target, "name", "Resurrected Soldier")
		Target.SetCustomModelWithClassAnimations("models/bots/soldier/bot_soldier_gibby.mdl")
		SetPropString(Target, "m_iszClassIcon", "soldier_crit")

		Target.AddWeaponRestriction(2)
		Target.AddBotAttribute(16)
		Target.AddBotAttribute(32)
		Target.AddBotAttribute(2048)

		Target.AddCustomAttribute("cannot pick up intelligence", 1, 0)
		Target.AddCustomAttribute("max health additive bonus", 125, 0)

		Target.SetHealth(300)
		Target.SetModelScale(1.3, 0.0)
	}
}

__CollectGameEventCallbacks(OncomingSandstorm)