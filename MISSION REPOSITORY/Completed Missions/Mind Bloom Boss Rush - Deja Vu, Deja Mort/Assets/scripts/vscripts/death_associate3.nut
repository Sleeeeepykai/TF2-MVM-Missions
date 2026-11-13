::CONST <- getconsttable()
::ROOT <- getroottable()
::MAX_CLIENTS <- MaxClients().tointeger()

::__Util <-
{
SRC_PREFIX = "kill_src_",
    DST_PREFIX = "kill_dst_",

  function OnGameEvent_player_death(params)
    {
        local hPlayer = GetPlayerFromUserID(params.userid)
        if (!hPlayer || !hPlayer.IsValid()) return
        if (!hPlayer.IsBotOfType(1337)) return

        local groups = {}
        local tags = {}
        hPlayer.GetAllBotTags(tags)
        foreach(tag in tags)
        {
            if (tag.find(SRC_PREFIX) == 0)
            {
                local gid = tag.slice(SRC_PREFIX.len())
                if (gid != "") groups[gid] <- true
            }
        }

        local victims = []
        for (local i = 1; i <= MAX_CLIENTS; i++)
        {
            local hEnt = PlayerInstanceFromIndex(i)
            if (!hEnt) continue
            if (!hEnt.IsAlive()) continue
            if (!hEnt.IsBotOfType(1337)) continue
            if (hEnt == hPlayer) continue

            local htags = {}
            hEnt.GetAllBotTags(htags)

            local hit = false
            foreach(g, _ in groups)
            {
                local needle = DST_PREFIX + g
                foreach(ht in htags)
                {
                    if (typeof ht != "string") continue
                    if (ht == needle)
                    {
                        victims.append(hEnt)
                        hit = true
                        break
                    }
                }
                if (hit) break
            }
        }

        foreach(v in victims)
        {
            NetProps.SetPropBool(v, "m_bUseBossHealthBar", false)
            EntFireByHandle(v, "runscriptcode", "local inf=Entities.CreateByClassname(`trigger_hurt`); inf.DispatchSpawn(); inf.SetAbsOrigin(self.GetCenter()); self.TakeDamageEx(inf, inf, null, Vector(), Vector(), 1000000, 0); EntFireByHandle(inf, `Kill`, ``, -1, null, null);", 0.01, hPlayer, v)
        }
    }


function OnGameEvent_recalculate_holidays(_)
{
if (GetRoundState() == Constants.ERoundState.GR_STATE_PREROUND && "__Util" in getroottable())
{
            delete ::__Util
        }
}
}
__CollectGameEventCallbacks(::__Util)