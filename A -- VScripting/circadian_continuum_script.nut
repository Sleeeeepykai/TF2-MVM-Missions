::CircadianScript <-
{
	//// CLEANUP FUNCTIONS ////

	ObjectiveResource = Entities.FindByClassname(null, "tf_objective_resource")
	PopInterface = Entities.FindByClassname(null, "point_populator_interface")
	PopfileName = NetProps.GetPropString(ObjectiveResource, "m_iszMvMPopfileName")

	function OnGameEvent_recalculate_holidays(_)
	{
		if(GetRoundState() != 3)
		{
			return
		}

		if(PopfileName != GetPropString(ObjectiveResource, "m_iszMvMPopfileName"))
		{
			delete ::CircadianScript
		}
	}

	//// DEBUG ENTRIES ////

	DeveloperWhitelist = ["[U:1:141959568]"]

	//// DEBUG FUNCTIONS ////

	function OnGameEvent_player_say(params)
	{
		local Player = GetPlayerFromUserID(params.userid)
		if ((!startswith(params.text, "!")))
		{
			return
		}

		SetPropFloat(Player, "m_flPlayerTalkAvailableMessagesTier1", 99)
		SetPropFloat(Player, "m_flPlayerTalkAvailableMessagesTier2", 99)
		SetPropFloat(Player, "m_fLastPlayerTalkTime", 0)

		local splits = split(params.text.slice(1), " ")
		local command = splits.remove(0)

		if (IsDev(Player))
		{
			switch(params.text)
			{
				case "!InitMonday":
				{
					PopInterface.AcceptInput("$PauseWaveSpawn", "Tuesday", null, null)
					PopInterface.AcceptInput("$PauseWaveSpawn", "Wednesday", null, null)
					PopInterface.AcceptInput("$PauseWaveSpawn", "Thursday", null, null)
					PopInterface.AcceptInput("$PauseWaveSpawn", "Friday", null, null)
					PopInterface.AcceptInput("$PauseWaveSpawn", "Saturday", null, null)
					PopInterface.AcceptInput("$PauseWaveSpawn", "Sunday", null, null)
					MondayMissionInit()
					break;
				}
				case "!InitTuesday":
				{
					PopInterface.AcceptInput("$PauseWaveSpawn", "Monday", null, null)
					PopInterface.AcceptInput("$PauseWaveSpawn", "Wednesday", null, null)
					PopInterface.AcceptInput("$PauseWaveSpawn", "Thursday", null, null)
					PopInterface.AcceptInput("$PauseWaveSpawn", "Friday", null, null)
					PopInterface.AcceptInput("$PauseWaveSpawn", "Saturday", null, null)
					PopInterface.AcceptInput("$PauseWaveSpawn", "Sunday", null, null)
					TuesdayMissionInit()
					break;
				}
				case "!InitWednesday":
				{
					PopInterface.AcceptInput("$PauseWaveSpawn", "Monday", null, null)
					PopInterface.AcceptInput("$PauseWaveSpawn", "Tuesday", null, null)
					PopInterface.AcceptInput("$PauseWaveSpawn", "Thursday", null, null)
					PopInterface.AcceptInput("$PauseWaveSpawn", "Friday", null, null)
					PopInterface.AcceptInput("$PauseWaveSpawn", "Saturday", null, null)
					PopInterface.AcceptInput("$PauseWaveSpawn", "Sunday", null, null)
					WednesdayMissionInit()
					break;
				}
				case "!InitThursday":
				{
					PopInterface.AcceptInput("$PauseWaveSpawn", "Monday", null, null)
					PopInterface.AcceptInput("$PauseWaveSpawn", "Tuesday", null, null)
					PopInterface.AcceptInput("$PauseWaveSpawn", "Wednesday", null, null)
					PopInterface.AcceptInput("$PauseWaveSpawn", "Friday", null, null)
					PopInterface.AcceptInput("$PauseWaveSpawn", "Saturday", null, null)
					PopInterface.AcceptInput("$PauseWaveSpawn", "Sunday", null, null)
					ThursdayMissionInit()
					break;
				}
				case "!InitFriday":
				{
					PopInterface.AcceptInput("$PauseWaveSpawn", "Monday", null, null)
					PopInterface.AcceptInput("$PauseWaveSpawn", "Tuesday", null, null)
					PopInterface.AcceptInput("$PauseWaveSpawn", "Wednesday", null, null)
					PopInterface.AcceptInput("$PauseWaveSpawn", "Thursday", null, null)
					PopInterface.AcceptInput("$PauseWaveSpawn", "Saturday", null, null)
					PopInterface.AcceptInput("$PauseWaveSpawn", "Sunday", null, null)
					FridayMissionInit()
					break;
				}
				case "!InitSaturday":
				{
					PopInterface.AcceptInput("$PauseWaveSpawn", "Monday", null, null)
					PopInterface.AcceptInput("$PauseWaveSpawn", "Tuesday", null, null)
					PopInterface.AcceptInput("$PauseWaveSpawn", "Wednesday", null, null)
					PopInterface.AcceptInput("$PauseWaveSpawn", "Thursday", null, null)
					PopInterface.AcceptInput("$PauseWaveSpawn", "Friday", null, null)
					PopInterface.AcceptInput("$PauseWaveSpawn", "Sunday", null, null)
					SaturdayMissionInit()
					break;
				}
				case "!InitSunday":
				{
					PopInterface.AcceptInput("$PauseWaveSpawn", "Monday", null, null)
					PopInterface.AcceptInput("$PauseWaveSpawn", "Tuesday", null, null)
					PopInterface.AcceptInput("$PauseWaveSpawn", "Wednesday", null, null)
					PopInterface.AcceptInput("$PauseWaveSpawn", "Thursday", null, null)
					PopInterface.AcceptInput("$PauseWaveSpawn", "Friday", null, null)
					PopInterface.AcceptInput("$PauseWaveSpawn", "Saturday", null, null)
					SundayMissionInit()
					break;
				}
			}
		}
	}

	function IsDev(Player)
	{
		return DeveloperWhitelist.find(NetProps.GetPropString(Player, "m_szNetworkIDString")) != null
	}

	//// PRIMARY MISSION FUNCTIONS ////

	function CircadianContinuumMissionInit()
	{
		if(!("InitDay" in CircadianScript))
		{
			local TimeTable = {}
			LocalTime(TimeTable)
			InitDay <- TimeTable.dayofweek
		}
		
		switch(InitDay)
		{
			case 0:
			{
				SundayMissionInit()
				break;
			}
			case 1:
			{
				MondayMissionInit()
				break;
			}
			case 2:
			{
				TuesdayMissionInit()
				break;
			}
			case 3:
			{
				WednesdayMissionInit()
				break;
			}
			case 4:
			{
				ThursdayMissionInit()
				break;
			}
			case 5:
			{
				FridayMissionInit()
				break;
			}
			case 6:
			{
				SaturdayMissionInit()
				break;
			}
		}
	}

	function MondayMissionInit()
	{
		IncludeScript("alternatewaves")

		PopInterface.AcceptInput("$ResumeWaveSpawn", "Monday", null, null)

		switch(GetPropInt(ObjectiveResource, "m_nMannVsMachineWaveCount"))
		{
			case 1:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}	
			case 2:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}
			case 3:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}
			case 4:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}
			case 5:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}
			case 6:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}
			case 7:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}
		}
	}

	function TuesdayMissionInit()
	{
		IncludeScript("alternatewaves")

		PopInterface.AcceptInput("$ResumeWaveSpawn", "Tuesday", null, null)

		switch(GetPropInt(ObjectiveResource, "m_nMannVsMachineWaveCount"))
		{
			case 1:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}	
			case 2:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}
			case 3:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}
			case 4:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}
			case 5:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}
			case 6:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}
			case 7:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}
		}
	}

	function WednesdayMissionInit()
	{
		IncludeScript("alternatewaves")

		PopInterface.AcceptInput("$ResumeWaveSpawn", "Wednesday", null, null)

		switch(GetPropInt(ObjectiveResource, "m_nMannVsMachineWaveCount"))
		{
			case 1:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}	
			case 2:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}
			case 3:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}
			case 4:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}
			case 5:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}
			case 6:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}
			case 7:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}
		}
	}

	function ThursdayMissionInit()
	{
		IncludeScript("alternatewaves")

		PopInterface.AcceptInput("$ResumeWaveSpawn", "Thursday", null, null)

		switch(GetPropInt(ObjectiveResource, "m_nMannVsMachineWaveCount"))
		{
			case 1:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}	
			case 2:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}
			case 3:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}
			case 4:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}
			case 5:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}
			case 6:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}
			case 7:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}
		}
	}

	function FridayMissionInit()
	{
		IncludeScript("alternatewaves")

		PopInterface.AcceptInput("$ResumeWaveSpawn", "Friday", null, null)

		switch(GetPropInt(ObjectiveResource, "m_nMannVsMachineWaveCount"))
		{
			case 1:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}	
			case 2:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}
			case 3:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}
			case 4:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}
			case 5:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}
			case 6:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}
			case 7:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}
		}
	}

	function SaturdayMissionInit()
	{
		IncludeScript("alternatewaves")

		PopInterface.AcceptInput("$ResumeWaveSpawn", "Saturday", null, null)

		switch(GetPropInt(ObjectiveResource, "m_nMannVsMachineWaveCount"))
		{
			case 1:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}	
			case 2:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}
			case 3:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}
			case 4:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}
			case 5:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}
			case 6:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}
			case 7:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}
		}
	}

	function SundayMissionInit()
	{
		IncludeScript("alternatewaves")

		PopInterface.AcceptInput("$ResumeWaveSpawn", "Sunday", null, null)

		switch(GetPropInt(ObjectiveResource, "m_nMannVsMachineWaveCount"))
		{
			case 1:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}	
			case 2:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}
			case 3:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}
			case 4:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}
			case 5:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}
			case 6:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}
			case 7:
			{
				AlternateWaves.ClearWaveIcons()

				break;
			}
		}
	}
}

// Classes Folding
foreach( _class in [ "NetProps", "Entities", "EntityOutputs", "NavMesh", "Convars" ] )
{
	foreach( k, v in ROOT[_class].getclass() )
	{
		if ( !( k in CircadianScript ) && k != "IsValid" )
		{
			CircadianScript[k] <- ROOT[_class][k].bindenv( ROOT[_class] )
		}
	}
}
// Constants Folding
if (!("ConstantNamingConvention" in ROOT)) // make sure folding is only done once
{
	foreach (enum_table in Constants)
	{
		foreach (name, value in enum_table)
		{
			if (value == null)
				value = 0

			CircadianScript[name] <- value
		}
	}
}

__CollectGameEventCallbacks(CircadianScript)