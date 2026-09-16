printl("Void Script Enabled")

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

::NovemberMasterScript <-
{
	// Cleanup Functions
	function Cleanup()
	{
		printl("Void Cleanup")

		SetSkyboxTexture("sky_november_01")
		EntFire("env_sun", "AddOutput", "rendercolor 251 226 200 400")
		EntFire("env_soundscape*", "Enable")
		EntFire("env_soundscape_proxy*", "Enable")

		for (local i = 1; i <= MaxPlayers; i++)
		{
			local Player = PlayerInstanceFromIndex(i)
			if (Player == null)
				continue

			SetPropString(Player, "m_iszScriptThinkFunction", "")
			SetPropInt(Player, "m_Local.m_skybox3d.fog.colorPrimary", RGBAToColor32(181, 114, 99, 255))
			SetPropInt(Player, "m_Local.m_fog.colorPrimary", RGBAToColor32(181, 114, 99, 255))
		}

		delete ::NovemberMasterScript
	}

	OnGameEvent_recalculate_holidays = function(_) { if (GetRoundState() == 3) Cleanup() }

	// HELPER FUNCTIONS //

	function RGBAToColor32(r, g, b, a)
	{
		return ((r) | (g << 8) | (b << 16) | (a << 24))
	}

	function GetSoundscapeIndex(/* str */ soundscape_name) /* -> int */
	{
		local player = FindByClassname(null, "player")
		if (!player)
			throw "Attempted GetSoundscapeIndex() with no player entity."

		local player_soundscape_index = GetPropInt(player, "m_Local.m_audio.soundscapeIndex")

		// Create a soundscape entity that has the soundscape name that we're interested in.
		local env_soundscape = CreateByClassname("env_soundscape_triggerable")
		SetPropBool(env_soundscape, "m_bForcePurgeFixedupStrings", true)
		env_soundscape.KeyValueFromString("soundscape", soundscape_name)
		env_soundscape.DispatchSpawn()

		// Create a corresponding trigger for this entity.
		local trigger = CreateByClassname("trigger_soundscape")
		SetPropBool(trigger, "m_bForcePurgeFixedupStrings", true)
		SetPropEntity(trigger, "m_hSoundscape", env_soundscape)

		// StartTouch on the player to update their soundscape.
		trigger.AcceptInput("StartTouch", "", null, player)
		env_soundscape.Destroy()
		trigger.Destroy()

		// Read the new soundscape index off the player.
		local soundscape_index = GetPropInt(player, "m_Local.m_audio.soundscapeIndex")
		// Restore the player's original soundscape index.
		SetPropInt(player, "m_Local.m_audio.soundscapeIndex", player_soundscape_index)

		return soundscape_index
	}

	// MAIN FUNCTIONS //

	function SetAmbienceNormal()
	{
		SetSkyboxTexture("sky_november_01")
		EntFire("env_sun", "AddOutput", "rendercolor 251 226 200 400")
		EntFire("env_soundscape*", "Enable")
		EntFire("env_soundscape_proxy*", "Enable")

		for (local i = 1; i <= MaxPlayers; i++)
		{
			local Player = PlayerInstanceFromIndex(i)
			if (Player == null)
				continue

			SetPropInt(Player, "m_Local.m_skybox3d.fog.colorPrimary", RGBAToColor32(181, 114, 99, 255))
			SetPropInt(Player, "m_Local.m_fog.colorPrimary", RGBAToColor32(181, 114, 99, 255))
		}
	}

	function SetAmbienceVoid()
	{
		Precache
		SetSkyboxTexture("sky_void_01")
		EntFire("env_sun", "AddOutput", "rendercolor 234 200 251 400")
		EntFire("env_soundscape*", "Disable")
		EntFire("env_soundscape_proxy*", "Disable")

		for (local i = 1; i <= MaxPlayers; i++)
		{
			local Player = PlayerInstanceFromIndex(i)
			if (Player == null)
				continue

			SetPropInt(Player, "m_Local.m_skybox3d.fog.colorPrimary", RGBAToColor32(143, 99, 181, 255))
            SetPropInt(Player, "m_Local.m_fog.colorPrimary", RGBAToColor32(143, 99, 181, 255))
			SetPropInt(Player, "m_Local.m_audio.soundscapeIndex", GetSoundscapeIndex("Soundscape.Void"))
		}

		printl("Void Enable Success")
	}
}