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

SetValue("tf_bot_engineer_mvm_hint_min_distance_from_bomb", 0)
SetValue("tf_bot_engineer_mvm_sentry_hint_bomb_forward_range", 99999)
SetValue("tf_bot_engineer_mvm_sentry_hint_bomb_backward_range", 99999)

::MaxPlayers <- MaxClients().tointeger()

::MVMAnimosity_ArenaTeleporters <-
{
	function Cleanup()
    {
		SetValue("tf_bot_engineer_mvm_hint_min_distance_from_bomb", 1300)
		SetValue("tf_bot_engineer_mvm_sentry_hint_bomb_forward_range", 0)
		SetValue("tf_bot_engineer_mvm_sentry_hint_bomb_backward_range", 3000)

		for (local TeleHint; TeleHint = FindByClassname(TeleHint, "bot_hint_teleporter_exit");)
		{
			SetPropString(TeleHint, "m_iszScriptThinkFunction", "")
		}

        delete ::MVMAnimosity_ArenaTeleporters
    }
    OnGameEvent_recalculate_holidays = function(_) { if (GetRoundState() == 3) Cleanup() }
	OnGameEvent_mvm_wave_complete = function(_) { Cleanup() }

	function SetDestroyCallback(Entity, Callback)
    {
        Entity.ValidateScriptScope();
        local EntityScope = Entity.GetScriptScope();
        EntityScope.setdelegate({}.setdelegate({
                parent   = EntityScope.getdelegate()
                id       = Entity.GetScriptId()
                index    = Entity.entindex()
                Callback = Callback
                _get = function(k)
                {
                    return parent[k];
                }
                _delslot = function(k)
                {
                    if (k == id)
                    {
                        Entity = EntIndexToHScript(index);
                        local EntityScope = Entity.GetScriptScope();
                        EntityScope.self <- Entity;
                        Callback.pcall(Scope);
                    }
                    delete parent[k];
                }
            })
        );
    }

	OnGameEvent_player_builtobject = function(params)
	{
		local Player = GetPlayerFromUserID(params.userid)

		local Building = EntIndexToHScript(params.index)

		if ( Player.GetTeam() != 3 || !Player.IsBotOfType(1337))
			return

		if ( params.object != 1 )
			return

		Building.ValidateScriptScope()
		local BuildingScope = Building.GetScriptScope()

		BuildingScope.Think <- function() {
			if (GetPropInt(self, "m_iState") != 0)
			{
				EntFire("spawnbot_arena_left_teleporter", "Enable", null, 0.0, null)
				EntFire("spawnbot_arena_right_teleporter", "Enable", null, 0.0, null)

				MVMAnimosity_ArenaTeleporters.SetDestroyCallback(self, function() {
					EntFire("spawnbot_arena_left_teleporter", "Disable", null, 0.0, null)
					EntFire("spawnbot_arena_right_teleporter", "Disable", null, 0.0, null)
				})
				SetPropString(self, "m_iszScriptThinkFunction", "")
			}
			return 0.1
		}
		AddThinkToEnt(Building, "Think")
	}
}

__CollectGameEventCallbacks(MVMAnimosity_ArenaTeleporters)