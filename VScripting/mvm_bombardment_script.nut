printl("Robot Transformer Initialised")

::CONST <- getconsttable()
::ROOT <- getroottable()
::MaxPlayers <- MaxClients().tointeger()

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

::BombardmentScript <-
{
    function OnGameEvent_recalculate_holidays(_)
	{
		if(GetRoundState() != 3)
		{
			return
		}

		delete ::BombardmentScript
	}

    // Needs a Number of Random Players to Target
    function Bombardment(NumberOfPlayers)
    {
        //// CREATING REQUIRED VARIABLES ////

        // Creating a Variable to Compare and/or Override Later
        local PlayerCount = NumberOfPlayers

        // Making a List of Players to Pick From
        local ValidPlayerArray = []

        // Finding our Bombardment Template to Spawn
        local BombardmentTemplate = FindByName(null, "BombardmentPT");

        // If the Bombardment Template does not exist, Cancels the Function
        if(BombardmentTemplate == null)
        {
            return
        }

        //// FINDING OUR VALID PLAYERS ////

        for (local Index = 1; Index <= MaxPlayers; Index++)
        {
            local Player = PlayerInstanceFromIndex(Index)

            // Checks if the Player is Valid and on RED Team
            if(Player && (Player.GetTeam()) == 2)
            {
                local PlayerOrigin = Player.GetOrigin()

                // Checks if the Player is Outdoors
                local SkyTraceParams =
                {
                    start = PlayerOrigin + Vector(0, 0, 64),
                    end = Vector(PlayerOrigin.x, PlayerOrigin.y, 1000),
                    ignore = Player
                }

                TraceLineEx(SkyTraceParams)

                // Adds them to the List if the Player is Outdoors
                if(!SkyTraceParams.hit)
                {
                    ValidPlayerArray.append(Player)
                }
            }
        }

        // If Less than or Equal to 0, Cancels the Function
        if(ValidPlayerArray.len() <= 0)
        {
            return
        }

        //// PICKING RANDOM VALID PLAYERS AND DEPLOYING THE BOMBARDMENT ////

        // If There are Less Valid Players than the Inputted Number of Players, Shrink it to the Total Valid Players
        if(ValidPlayerArray.len() < PlayerCount)
        {
            PlayerCount = ValidPlayerArray.len()
        }

        for (local Index = 0; Index < PlayerCount; Index++)
        {
            // Picks a Random Number between 0 and the Inputted Number of Players
            local RandomInteger = RandomInt(0, ValidPlayerArray.len() - 1)

            // Finds the Player that Matches the Random Number and Saves them as a Variable
            local ChosenPlayer = ValidPlayerArray[RandomInteger]

            // Removes the Chosen Player from the List of Valid Players so they are not Re-Picked
            ValidPlayerArray.remove(RandomInteger)

            local GroundTraceOrigin = ChosenPlayer.GetOrigin()

            // Checks for where the Ground is
            local GroundTraceParams = 
            {
                start = GroundTraceOrigin + Vector(0, 0, 16),
                end = GroundTraceOrigin + Vector(0, 0, -4096),
                ignore = ChosenPlayer
            }

            TraceLineEx(GroundTraceParams)

            // If the Ground is Found, sets the Variable to the Ground
            if(GroundTraceParams.hit)
            {
                GroundTraceOrigin = GroundTraceParams.pos
            }

            // Teleports the Entity Maker to the Ground and Spawns It
            BombardmentTemplate.SetAbsOrigin(GroundTraceOrigin)

            EntFireByHandle(BombardmentTemplate,ForceSpawn,null,0,null,null)
        }
    }
}