printl("fuckass bot test")

// Constants Folding
::CONST <- getconsttable()
::ROOT <- getroottable()
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

const MAX_WEAPONS = 8
::MaxPlayers <- MaxClients().tointeger()

::BotTest <-
{
	// Cleanup Functions
	function Cleanup()
    {
		for (local i = 1; i <= MaxPlayers; i++)
		{
			local player = PlayerInstanceFromIndex(i)
			NetProps.SetPropString(player, "m_iszScriptThinkFunction", "")
		}
        delete ::BotTest
    }
	OnGameEvent_recalculate_holidays = function(_) { if (GetRoundState() == 3) Cleanup() }
	OnGameEvent_mvm_wave_complete = function(_) { Cleanup() }

	// Search Functions
	OnGameEvent_player_spawn = function(params)
	{
		local player = GetPlayerFromUserID(params.userid)

		if (player.IsBotOfType(1337)) { EntFireByHandle(player, "RunScriptCode", "BotTest.BotTagCheck()", -1.0, player, null); return }

		if (player.GetScriptScope() == null) player.ValidateScriptScope()

		local scope = player.GetScriptScope()
	}
	OnGameEvent_player_death = function(params)
	{
		local player = GetPlayerFromUserID(params.userid)

		NetProps.SetPropString(player, "m_iszScriptThinkFunction", "")
	}

	// Bot Manipulation Functions
	function GivePlayerWeapon(player, classname, item_id)
	{
		local weapon = Entities.CreateByClassname(classname)
		NetProps.SetPropInt(weapon, "m_AttributeManager.m_Item.m_iItemDefinitionIndex", item_id)
		NetProps.SetPropBool(weapon, "m_AttributeManager.m_Item.m_bInitialized", true)
		NetProps.SetPropBool(weapon, "m_bValidatedAttachedEntity", true)
		weapon.SetTeam(player.GetTeam())
		weapon.DispatchSpawn()

		for (local i = 0; i < MAX_WEAPONS; i++)
		{
			local held_weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
			if (held_weapon == null)
				continue
			if (held_weapon.GetSlot() != weapon.GetSlot())
				continue
			held_weapon.Destroy()
			NetProps.SetPropEntityArray(player, "m_hMyWeapons", null, i)
			break
		}

		player.Weapon_Equip(weapon)
		player.Weapon_Switch(weapon)

		return weapon
	}

	function GetItemInSlot(player, slot)
	{
		for ( local child = player.FirstMoveChild(); child; child = child.NextMovePeer() )
			if ( child instanceof CBaseCombatWeapon && child.GetSlot() == slot )
				return child
	}

	// Bot Tag Functions

	function BotTagCheck()
	{
		if(activator.HasBotTag("BurstFlare"))
		{
			BotTest.BurstFlareBot(activator)
		}
	}

	function BurstFlareBot(target)
	{
		local secondary = GetItemInSlot(target, 1)

		PrecacheModel("models/workshop/weapons/c_models/c_detonator/c_detonator.mdl")
		secondary.SetModel("models/workshop/weapons/c_models/c_detonator/c_detonator.mdl")
	}
}

__CollectGameEventCallbacks(BotTest)