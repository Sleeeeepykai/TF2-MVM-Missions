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
			SetPropInt(Player, "m_Local.m_audio.soundscapeIndex", 153)
		}

		printl("Void Enable Success")
	}
}