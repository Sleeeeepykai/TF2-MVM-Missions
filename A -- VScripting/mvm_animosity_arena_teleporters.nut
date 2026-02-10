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

Convars.SetValue("tf_bot_engineer_mvm_hint_min_distance_from_bomb", 99999)

::MaxPlayers <- MaxClients().tointeger()

::MVMAnimosity_ArenaTeleporters <-
{
	function Cleanup()
    {
		Convars.SetValue("tf_bot_engineer_mvm_hint_min_distance_from_bomb", 1300)

		for (local htelehint; htelehint = FindByClassname(htelehint, "bot_hint_teleporter_exit");)
		{
			SetPropString(htelehint, "m_iszScriptThinkFunction", "")
		}

        delete ::MVMAnimosity_ArenaTeleporters
    }
    OnGameEvent_recalculate_holidays = function(_) { if (GetRoundState() == 3) Cleanup() }
	OnGameEvent_mvm_wave_complete = function(_) { Cleanup() }

	function SetDestroyCallback(entity, callback)
    {
        entity.ValidateScriptScope();
        local scope = entity.GetScriptScope();
        scope.setdelegate({}.setdelegate({
                parent   = scope.getdelegate()
                id       = entity.GetScriptId()
                index    = entity.entindex()
                callback = callback
                _get = function(k)
                {
                    return parent[k];
                }
                _delslot = function(k)
                {
                    if (k == id)
                    {
                        entity = EntIndexToHScript(index);
                        local scope = entity.GetScriptScope();
                        scope.self <- entity;
                        callback.pcall(scope);
                    }
                    delete parent[k];
                }
            })
        );
    }

	OnGameEvent_player_builtobject = function(params)
	{
		local player = GetPlayerFromUserID(params.userid)

		local building = EntIndexToHScript(params.index)

		if ( player.GetTeam() != 3 || !player.IsBotOfType(1337))
			return

		if ( params.object != 1 )
			return

		building.ValidateScriptScope()
		local buildingscope = building.GetScriptScope()

		buildingscope.Think <- function() {
			if (NetProps.GetPropInt(self, "m_iState") != 0)
			{
				EntFire("spawnbot_arena_left_teleporter", "Enable", null, 0.0, null)
				EntFire("spawnbot_arena_right_teleporter", "Enable", null, 0.0, null)

				MVMAnimosity_ArenaTeleporters.SetDestroyCallback(self, function() {
					EntFire("spawnbot_arena_left_teleporter", "Disable", null, 0.0, null)
					EntFire("spawnbot_arena_right_teleporter", "Disable", null, 0.0, null)
				})
				NetProps.SetPropString(self, "m_iszScriptThinkFunction", "")
			}
			return 0.1
		}
		AddThinkToEnt(building, "Think")
	}
}

__CollectGameEventCallbacks(MVMAnimosity_ArenaTeleporters)