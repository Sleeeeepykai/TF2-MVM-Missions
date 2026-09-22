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
	// CLEANUP FUNCTIONS //

	function Cleanup()
	{
		printl("Void Cleanup")

		NovemberMasterScript.SetAmbienceNormal()

		if("NovemberMasterScript" in getroottable())
		{
			delete ::NovemberMasterScript
		}
	}

	OnGameEvent_recalculate_holidays = function(_) { if (GetRoundState() == 3) Cleanup() }

	// MAIN FUNCTIONS //

	function SetAmbienceNormal()
	{
		SetSkyboxTexture("sky_november_01")
		EntFire("env_sun", "AddOutput", "rendercolor 251 226 200 400")
		EntFire("env_soundscape*", "Enable")

		if(FindByName(null, "VoidSkybox"))
		{
			EntFire("VoidSkybox", "Kill")
		}

		local FogController = FindByClassname(null, "env_fog_controller")

		FogController.AcceptInput("SetColor", "181 114 99", null, null)
		FogController.AcceptInput("SetStartDist", "100", null, null)
		FogController.AcceptInput("SetEndDist", "8000", null, null)
	}

	function SetAmbienceVoid()
	{
		SetSkyboxTexture("sky_void_01")
		EntFire("env_sun", "AddOutput", "rendercolor 234 200 251 400")
		EntFire("env_soundscape*", "Disable")

		local FogController = FindByClassname(null, "env_fog_controller")

		FogController.AcceptInput("SetColor", "0 0 0", null, null)
		FogController.AcceptInput("SetStartDist", "100", null, null)
		FogController.AcceptInput("SetEndDist", "4000", null, null)

		for (local i = 1; i <= MaxPlayers; i++)
		{
			local Player = PlayerInstanceFromIndex(i)
			if (Player == null)
				continue

			SetPropInt(Player, "m_Local.m_audio.soundscapeIndex", 153)
		}

		printl("Void Enable Success")
	}
}