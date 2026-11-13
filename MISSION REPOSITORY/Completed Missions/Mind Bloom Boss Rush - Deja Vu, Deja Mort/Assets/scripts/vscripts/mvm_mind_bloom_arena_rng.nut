::MindBloomRNG <-
{
	GlobalIndex = 0
	AllowedBosses = []

	function CleanUp()
	{
		delete ::MindBloomRNG;
	}

	function OnGameEvent_recalculate_holidays(params)
	{
		CleanUp();
	}

	function OnGameEvent_mvm_wave_complete(params)
	{
		CleanUp();
	}

	function AddRNGArena(arena, boss)
	{
		local table = {
			init = arena,
			squad = boss
		}
		AllowedBosses.append(table);
	}

	function InitRNGArena()
	{
		GlobalIndex = RandomInt(0, AllowedBosses.len() - 1);
		EntFire(AllowedBosses[GlobalIndex].init, "Trigger", null, 6.25); // When the map updates, remove the delay
	}

	function StartRNGArena()
	{
		local populator = Entities.FindByClassname(null, "point_populator_interface");
		populator.AcceptInput("$ResumeWavespawn", AllowedBosses[GlobalIndex].squad, null, null);
	}
}
__CollectGameEventCallbacks(MindBloomRNG);