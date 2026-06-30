::DjinnSummonTrace <- function(Target)
{
	local DjinnStartPoint = Entities.FindByName(null, "DjinnTarget")
	local DjinnEndPoint1 = Entities.FindByName(null, "DjinnSummonGeneratorBodyGuard1")
	local DjinnEndPoint2 = Entities.FindByName(null, "DjinnSummonGeneratorBodyGuard2")
	local DjinnEndPoint3 = Entities.FindByName(null, "DjinnSummonGeneratorMobber1")
	local DjinnEndPoint4 = Entities.FindByName(null, "DjinnSummonGeneratorMobber2")

	local TraceParams1 =
	{
		start = DjinnStartPoint.GetOrigin()
		end = DjinnEndPoint1.GetOrigin()
		mask = 16395
	}
	local TraceParams2 =
	{
		start = DjinnStartPoint.GetOrigin()
		end = DjinnEndPoint2.GetOrigin()
		mask = 16395
	}
	local TraceParams3 =
	{
		start = DjinnStartPoint.GetOrigin()
		end = DjinnEndPoint3.GetOrigin()
		mask = 16395
	}
	local TraceParams4 =
	{
		start = DjinnStartPoint.GetOrigin()
		end = DjinnEndPoint4.GetOrigin()
		mask = 16395
	}

	TraceLineEx(TraceParams1)
	if(TraceParams1.hit)
	{
		Target.SetLocalOrigin(DjinnStartPoint.GetOrigin())
		EntFireByHandle(Target, "$GiveItem", "TF_WEAPON_ROCKETLAUNCHER", 0.0, Target, null)
	}

	TraceLineEx(TraceParams2)
	if(TraceParams2.hit)
	{
		Target.SetLocalOrigin(DjinnStartPoint.GetOrigin())
		EntFireByHandle(Target, "$GiveItem", "TF_WEAPON_ROCKETLAUNCHER", 0.0, Target, null)
	}

	TraceLineEx(TraceParams3)
	if(TraceParams3.hit)
	{
		Target.SetLocalOrigin(DjinnStartPoint.GetOrigin())
		EntFireByHandle(Target, "$GiveItem", "TF_WEAPON_ROCKETLAUNCHER", 0.0, Target, null)
	}

	TraceLineEx(TraceParams4)
	if(TraceParams4.hit)
	{
		Target.SetLocalOrigin(DjinnStartPoint.GetOrigin())
		EntFireByHandle(Target, "$GiveItem", "TF_WEAPON_ROCKETLAUNCHER", 0.0, Target, null)
	}
}