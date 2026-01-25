printl("Animosity Arena Teleporter Script Enabled")

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

::MVMAnimosity_ArenaTeleporters <-
{
	function Cleanup()
    {
		for (local htelehint; htelehint = FindByClassname(htelehint, "bot_hint_teleporter_exit");)
		{
			SetPropString(htelehint, "m_iszScriptThinkFunction", "")
		}

        delete ::MVMAnimosity_ArenaTeleporters
    }
    OnGameEvent_recalculate_holidays = function(_) { if (GetRoundState() == 3) Cleanup() }
	OnGameEvent_mvm_wave_complete = function(_) { Cleanup() }

	function TeleporterControl()
	{
		for (local htelehint; htelehint = FindByClassname(htelehint, "bot_hint_teleporter_exit");)
		{
			htelehint.ValidateScriptScope()
			local telehintscope = htelehint.GetScriptScope()


			telehintscope.Think <- function() {

				local howner = self.GetOwner()

				if(howner)
				{
					EntFire("spawnbot_arena_teleporter_left", "Enable", null, null, null)
					EntFire("spawnbot_arena_teleporter_right", "Enable", null, null, null)
				}
				else
				{
					EntFire("spawnbot_arena_teleporter_left", "Disable", null, null, null)
					EntFire("spawnbot_arena_teleporter_right", "Disable", null, null, null)
				}

				return -1;
			}

			AddThinkToEnt(htelehint, "Think")
		}
	}
}