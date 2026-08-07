::CONST <- getconsttable()
::ROOT <- getroottable()
::MAX_CLIENTS <- MaxClients().tointeger()

if (!("ConstantNamingConvention" in ROOT))
	foreach (a,b in Constants)
		foreach (k,v in b)
		{
			CONST[k] <- v != null ? v : 0
			ROOT[k] <- v != null ? v : 0
		}

foreach(k, v in ::NetProps.getclass())
	if (k != "IsValid" && !(k in ROOT))
		ROOT[k] <- ::NetProps[k].bindenv(::NetProps)

// Note: the folding was done with this being a large file in mind (in the future)
::TERMINATION <- {
    HANDLE_GREY_TRAIN_BOT = null

	// Events & Hooks
	function OnScriptHook_OnTakeDamage(tParams)
	{
		local hVictim = tParams.const_entity

		if (hVictim && hVictim.GetClassname() == "prop_dynamic" && hVictim.GetName() == "grey_mann_escape_train")
		{
			if (!TERMINATION.HANDLE_GREY_TRAIN_BOT)
			{
				for (local i = 1; i <= MAX_CLIENTS; i++)
				{
					local hPlayer = PlayerInstanceFromIndex(i);
					if (hPlayer && hPlayer.IsAlive() && hPlayer.IsBotOfType(1337) && hPlayer.HasBotTag("bot_grey_train_hook"))
					{
						TERMINATION.HANDLE_GREY_TRAIN_BOT = hPlayer
						break
					}
				}
			}
			if (!TERMINATION.HANDLE_GREY_TRAIN_BOT) return
			local iHealth = TERMINATION.HANDLE_GREY_TRAIN_BOT.GetHealth()  - tParams.damage
			if (iHealth >= TERMINATION.HANDLE_GREY_TRAIN_BOT.GetMaxHealth() / 10) TERMINATION.HANDLE_GREY_TRAIN_BOT.SetHealth(iHealth)
		}
	}
    function OnGameEvent_recalculate_holidays(_)
	{
		if (GetRoundState() == Constants.ERoundState.GR_STATE_PREROUND && "TERMINATION" in getroottable())
			delete ::TERMINATION
	}
	function OnGameEvent_mvm_wave_complete(_)
	{
		if ("TERMINATION" in getroottable())
			delete ::TERMINATION
	}
}

__CollectGameEventCallbacks(::TERMINATION)