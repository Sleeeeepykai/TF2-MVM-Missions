::CONST <- getconsttable()
::ROOT <- getroottable()
::MAX_CLIENTS <- MaxClients().tointeger()

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

::ReforgerMechanic <- {}

function ReforgerMechanic::CleanUp()
{
	if ("ReforgerMechanic") in getroottable())
	{
		delete ::ReforgerMechanic
	}
}

ReforgerMechanic::OnGameEvent_recalculate_holidays = function(_) { if (GetRoundState() == 3) CleanUp() }

function ReforgerMechanic::OnGameEvent_player_spawn(params)
{
	local Bot = GetPlayerFromUserID(params.userid)
	if(!Bot.IsBotOfType(1337))
	{
		return
	}

	EntFireByHandle(Bot, "RunScriptCode", "ReforgerMechanic.BotTagCheck(self)", 0.015, null, null)
}

function ReforgerMechanic::BotTagCheck(Bot)
{
	if (Bot.HasBotTag("TetherMaster"))
	{
		Bot.ValidateScriptScope()
		Bot.GetScriptScope().TetherMasterInstance <- ReforgerMechanic.TetherMaster(Bot)
	}
}

class ReforgerMechanic.TetherMaster
{
	TetherMasterBot = null

	constructor(Bot)
	{
		TetherMasterBot = Bot
	}

	local ReforgerDetector = SpawnEntityFromTable("trigger_multiple", 
	{
		targetname = "ReforgerDetector"

		filtername = "ReforgerGiantFilter"
		spawnflags = 1
		startdisabled = 1

		"OnStartTouch#1" : "ReforgerTetherAttachRelay,Trigger,,0,-1"
		"OnStartTouch#2" : "!activator,$ChangeAttributes,GDemoReforged,0,-1"
	})

	local ReforgerGiantFilter = SpawnEntityFromTable("filter_tf_bot_has_tag", 
	{
		targetname = "ReforgerGiantFilter"
		tags = "ReforgerGiant"
		require_all_tags = 1
	})

	local ReforgerTetherAttachRelay = SpawnEntityFromTable("logic_relay", {
		targetname = "ReforgerTetherAttachRelay"
		spawnflags = 2

		"OnTrigger#1" : "ReforgerDetector,Disable,,0,-1"
		"OnTrigger#2" : "!parent,$AddPlayerAttribute,always allow taunt|1,0,-1
		"OnTrigger#3" : "!parent,$Taunt,,0.02,-1"
		"OnTrigger#4" : "ReforgerTetherSpawner,ForceSpawnAtEntityOrigin,!parent,3.33,-1"
		"OnTrigger#5" : "tf_gamerules,PlayVO,misc/halloween/spell_spawn_boss.wav,3.33,-1"
		"OnTrigger#6" : "tf_gamerules,PlayVO,items/powerup_pickup_supernova.wav,3.33,-1"
		"OnTrigger#7" : "playerRunScriptCodeScreenShake(self.GetOrigin(), 5, 5, 2, 50000, 0, true)3.33-1"
		"OnTrigger#8" : "ReforgerTetherBuilding,SetBuilder,,3.4,-1"
		"OnTrigger#9" : "DemomanReforgedVoiceline,PickRandom,7.33,-1"
		"OnTrigger#10" : "!activatorRunScriptCodeSendGlobalGameEvent(`show_annotation`, { text = `This giant has been Reforged!`, lifetime = 5.0, follow_entindex = self.entindex(), play_sound = `misc/null.wav` })7.33,-1"
	})

	local ReforgerTetherBreakRelay = SpawnEntityFromTable("logic_relay", 
	{
		targetname = "ReforgerTetherBreakRelay"
		spawnflags = 2
		
 	})
}

__CollectGameEventCallbacks(::ReforgerMechanic)