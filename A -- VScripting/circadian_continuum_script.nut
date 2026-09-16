::CONST <- getconsttable()
::ROOT <- getroottable()

// Classes Folding
foreach( _class in [ "NetProps", "Entities", "EntityOutputs", "NavMesh", "Convars" ] )
{
	foreach( k, v in ROOT[_class].getclass() )
	{
		if ( !( k in ROOT ) && k != "IsValid" )
		{
			ROOT[k] <- ROOT[_class][k].bindenv( ROOT[_class] )
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

			CONST[name] <- value
			ROOT[name] <- value
		}
	}
}

::TimeScript <-
{
	//// CLEANUP FUNCTIONS ////

	function CleanUp()
	{
		delete ::TimeScript
	}

	OnGameEvent_recalculate_holidays = function(_) { if (GetRoundState() == 3) CleanUp() }

	function DayOfTheWeekMissionInit()
	{
		if(!("InitDay" in TimeScript))
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

		local PopInterface = FindByClassname(null, "point_populator_interface")
		PopInterface.AcceptInput("$ResumeWaveSpawn", "Monday", null, null)

		local ObjectiveResource = FindByClassname(null, "tf_objective_resource")

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

		local PopInterface = FindByClassname(null, "point_populator_interface")
		PopInterface.AcceptInput("$ResumeWaveSpawn", "Tuesday", null, null)

		local ObjectiveResource = FindByClassname(null, "tf_objective_resource")

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

		local PopInterface = FindByClassname(null, "point_populator_interface")
		PopInterface.AcceptInput("$ResumeWaveSpawn", "Wednesday", null, null)

		local ObjectiveResource = FindByClassname(null, "tf_objective_resource")

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

		local PopInterface = FindByClassname(null, "point_populator_interface")
		PopInterface.AcceptInput("$ResumeWaveSpawn", "Thursday", null, null)

		local ObjectiveResource = FindByClassname(null, "tf_objective_resource")

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

		local PopInterface = FindByClassname(null, "point_populator_interface")
		PopInterface.AcceptInput("$ResumeWaveSpawn", "Friday", null, null)

		local ObjectiveResource = FindByClassname(null, "tf_objective_resource")

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

		local PopInterface = FindByClassname(null, "point_populator_interface")
		PopInterface.AcceptInput("$ResumeWaveSpawn", "Saturday", null, null)

		local ObjectiveResource = FindByClassname(null, "tf_objective_resource")

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

		local PopInterface = FindByClassname(null, "point_populator_interface")
		PopInterface.AcceptInput("$ResumeWaveSpawn", "Sunday", null, null)

		local ObjectiveResource = FindByClassname(null, "tf_objective_resource")

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