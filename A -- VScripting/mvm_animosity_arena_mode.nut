printl("Animosity Arena Mode Script Enabled")

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

::MVMAnimosity_ArenaMode <-
{
	// Cleanup Functions
	function Cleanup()
    {
		MVMAnimosity_ArenaMode.RemoveRobot()

        delete ::MVMAnimosity_ArenaMode
    }
    OnGameEvent_recalculate_holidays = function(_) { if (GetRoundState() == 3) Cleanup() }
	OnGameEvent_mvm_wave_complete = function(_) { Cleanup() }

	// Search Functions
	OnGameEvent_player_spawn = function(params)
	{
		local player = GetPlayerFromUserID(params.userid)

		if (player.IsBotOfType(1337)) { EntFireByHandle(player, "RunScriptCode", "MVMAnimosity_ArenaMode.BotTagCheck()", -1.0, player, null); return }
	}

	OnScriptHook_OnTakeDamage = function(params)
	{
		local attacker = params.attacker
		local victim = params.const_entity

		if ( !attacker.IsPlayer() || !attacker.IsBotOfType(1337) )
			return

		if ( !victim.IsPlayer() || !victim.IsBotOfType(1337) )
			return

		if ( attacker == victim )
			return

		if ( attacker.HasBotTag("LethalBot") && victim.HasBotTag("FriendlyBot") )
			params.damage = 800
	}

	// Bot Tags
	function BotTagCheck()
	{
		if(activator.HasBotTag("Glow"))
		{
			MVMAnimosity_ArenaMode.BotGlow(activator)
		}
	}

	function ArenaFriendlyBot(target)
	{
		target.SetCustomModelWithClassAnimations("models/bots/demo_boss/bot_demo_boss.mdl")
		target.AddBotAttribute(REMOVE_ON_DEATH)
		target.AddBotAttribute(HOLD_FIRE_UNTIL_FULL_RELOAD)
		target.AddBotAttribute(MINIBOSS)
		target.SetModelScale(2, -1)
		target.AddBotAttribute(USE_BOSS_HEALTH_BAR)
		target.AddWeaponRestriction(PRIMARY_ONLY)
		target.AddBotTag("FriendlyBot")
		target.AddBotTag("bot_giant")

		target.SetMaxHealth(3000)
		target.SetHealth(3000)
		target.AddCustomAttribute("move speed penalty", 0.5, -1)
		target.AddCustomAttribute("damage force reduction", 0.1, -1)
		target.AddCustomAttribute("airblast vulnerability multiplier", 0.1, -1)
		target.AddCustomAttribute("health regen", 200, -1)
		target.AddCustomAttribute("ammo regen", 1.0, -1 )
		target.AddCustomAttribute("health from healers reduced", 0.5, -1)
		target.AddCustomAttribute("health from packs reduced", 0.5, -1)
		target.AddCustomAttribute("override footstep sound set", 4, -1)
		target.AddCustomAttribute("voice pitch scale", 0, -1)

		local targetprimary = target.GetActiveWeapon()

		targetprimary.AddAttribute("fire rate bonus", 0.75, -1)
		targetprimary.AddAttribute("faster reload rate", 0.6, -1)
	}
	function BotGlow(target)
	{
		NetProps.SetPropBool(target, "m_bGlowEnabled", true)
	}

	// Bot Manipulation Functions
	function RemoveRobot()
	{
		for (local i = 1; i <= MaxPlayers; i++)
		{
			local player = PlayerInstanceFromIndex(i)

			if ( player && player.IsAlive() && player.IsBotOfType(1337) && player.HasBotTag("FriendlyBot") )
			{
				player.TakeDamage(999999, 1, null)
				break
			}
		}
	}
}

__CollectGameEventCallbacks(MVMAnimosity_ArenaMode)