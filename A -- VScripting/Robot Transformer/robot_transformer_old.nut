printl("Robot Transformer Initialised.")

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

::PlayerModels <-
[
    "models/player/scout.mdl",
    "models/player/scout.mdl",
    "models/player/sniper.mdl",
    "models/player/soldier.mdl",
    "models/player/demo.mdl",
    "models/player/medic.mdl",
    "models/player/heavy.mdl",
    "models/player/pyro.mdl",
    "models/player/spy.mdl",
    "models/player/engineer.mdl",
]

::RobotTransformerSpace <-
{
	mvm_stats = Entities.FindByClassname(null, "tf_mann_vs_machine_stats")

	//// CLEANUP FUNCTIONS ////

    function Cleanup()
    {
        for ( local i = MaxClients().tointeger(); i > 0; i-- )
		{
			local player = PlayerInstanceFromIndex( i );
			if ( !player )
				continue;

			AddThinkToEnt( player, null )
			EmitSoundEx({entity = player, flags = 4, filter_type = RECIPIENT_FILTER_GLOBAL | 512})

			for ( local child = player.FirstMoveChild(); child; child = child.NextMovePeer() )
  				if ( !(child instanceof CBaseCombatWeapon) && child instanceof CEconEntity )
    				EntFireByHandle( child, "Kill", null, -1, null, null )

			local playerclass = player.GetPlayerClass()
			player.SetCustomModelWithClassAnimations(PlayerModels[playerclass])
		}

        delete ::RobotTransformerSpace
    }
    function OnGameEvent_stats_resetround(_)
    {
        if (GetRoundState() != GR_STATE_PREROUND)
            return
        if (NetProps.GetPropInt(mvm_stats, "m_iCurrentWaveIdx") != 0)
            return
        Cleanup()
    }

	function OnGameEvent_player_spawn(params)
	{
		local player = GetPlayerFromUserID(params.userid)

		if (!player || !player.IsValid() || player.IsBotOfType(1337))
			return

		EntFireByHandle(player, "RunScriptCode", "RobotTransformerSpace.ClearPlayerModel(self)", 1, null, null)
	}
	function OnGameEvent_player_death(params)
	{
		local player = GetPlayerFromUserID(params.userid)

		if (!player || !player.IsValid() || player.IsBotOfType(1337))
			return

		AddThinkToEnt(player, null)

		EmitSoundEx({entity = player, flags = 4, filter_type = RECIPIENT_FILTER_GLOBAL | 512})

		for ( local child = player.FirstMoveChild(); child; child = child.NextMovePeer() )
  			if ( !(child instanceof CBaseCombatWeapon) && child instanceof CEconEntity )
    			EntFireByHandle( child, "Kill", null, -1, null, null )
	}

	function RemoveAllTransforms()
	{
		for ( local i = MaxClients().tointeger(); i > 0; i-- )
		{
			local player = PlayerInstanceFromIndex( i );
			if ( !player )
				continue;

			AddThinkToEnt(player, null);

			EmitSoundEx({entity = player, flags = 4, filter_type = RECIPIENT_FILTER_GLOBAL | 512})

			for ( local child = player.FirstMoveChild(); child; child = child.NextMovePeer() )
  				if ( !(child instanceof CBaseCombatWeapon) && child instanceof CEconEntity )
    				EntFireByHandle( child, "Kill", null, -1, null, null )

			local playerclass = player.GetPlayerClass()
			player.SetCustomModelWithClassAnimations(PlayerModels[playerclass])
		}
	}
	function ClearPlayerModel(player)
	{
		local playerclass = player.GetPlayerClass()
		player.SetCustomModelWithClassAnimations(PlayerModels[playerclass])
	}

	//// TRANSFORMER GLOBAL SETUP FUNCTIONS ////

	function GetPlayerName(player)
	{
		return NetProps.GetPropString(player, "m_szNetname")
	}
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
	function GivePlayerCosmetic(player, item_id, model_path = null)
	{
		local weapon = Entities.CreateByClassname("tf_weapon_parachute")
		NetProps.SetPropInt(weapon, "m_AttributeManager.m_Item.m_iItemDefinitionIndex", 1101)
		NetProps.SetPropBool(weapon, "m_AttributeManager.m_Item.m_bInitialized", true)
		weapon.SetTeam(player.GetTeam())
		weapon.DispatchSpawn()
		player.Weapon_Equip(weapon)
		local wearable = NetProps.GetPropEntity(weapon, "m_hExtraWearable")
		weapon.Kill()

		NetProps.SetPropInt(wearable, "m_AttributeManager.m_Item.m_iItemDefinitionIndex", item_id)
		NetProps.SetPropBool(wearable, "m_AttributeManager.m_Item.m_bInitialized", true)
		NetProps.SetPropBool(wearable, "m_bValidatedAttachedEntity", true)
		wearable.DispatchSpawn()

		// (optional) Set the model to something new. (Obeys econ's ragdoll physics when ragdolling as well)
		if (model_path)
			wearable.SetModelSimple(model_path)

		// (optional) if one wants to delete the item entity, collect them within the player's scope, then send Kill() to the entities within the scope.
		player.ValidateScriptScope()
		local player_scope = player.GetScriptScope()
		if (!("wearables" in player_scope))
			player_scope.wearables <- []
		player_scope.wearables.append(wearable)

		return wearable
	}
	function GetItemInSlot(player, slot)
	{
		for ( local child = player.FirstMoveChild(); child; child = child.NextMovePeer() )
			if ( child instanceof CBaseCombatWeapon && child.GetSlot() == slot )
				return child
	}

	//// TRANSFORMER MAIN FUNCTIONS ////

	// SCOUT TRANSFORMS //

	// SOLDIER TRANSFORMS //
	function GigaBurst(target)
	{
		// Finding the Player to Transform
		local TransformerTarget
		for (local i = 1; i <= MaxPlayers; i++)
		{
			local player = PlayerInstanceFromIndex(i)
			if (player == null)
				continue
			if (GetPlayerName(player) == target)
			{
				TransformerTarget = player;
				break;
			}
		}


		// Executing Transformation
		TransformerTarget.SetPlayerClass(Constants.ETFClass.TF_CLASS_SOLDIER)
		NetProps.SetPropInt(TransformerTarget, "m_Shared.m_iDesiredPlayerClass", Constants.ETFClass.TF_CLASS_SOLDIER)

		TransformerTarget.SetCustomModelWithClassAnimations("models/bots/soldier_boss/bot_soldier_boss.mdl")

		TransformerTarget.SetUseBossHealthBar(true)
		TransformerTarget.SetIsMiniBoss(true)
		TransformerTarget.SetModelScale(1.75, 0)
		TransformerTarget.SetForcedTauntCam(1)
		TransformerTarget.AddCondEx(56, -1, null)
		TransformerTarget.AddCondEx(66, 0.25, null)
		TransformerTarget.AddCondEx(51, 1, null)

		NetProps.SetPropString(TransformerTarget, "m_PlayerClass.m_iszClassIcon", "soldier_burstfire")

		// Stripping Cosmetics and Weapons
		for (local next, current = TransformerTarget.FirstMoveChild(); current != null; current = next)
		{
			NetProps.SetPropBool(current, "m_bForcePurgeFixedupStrings", true)

			next = current.NextMovePeer()
			if (current instanceof CEconEntity)
				current.Destroy()
		}

		// Giving New Cosmetics and Weapons
		GivePlayerWeapon(TransformerTarget, "tf_weapon_rocketlauncher", 205)
		GivePlayerCosmetic(TransformerTarget, 99, "models/player/items/soldier/soldier_viking.mdl")

		// Setting Character Attributes
		TransformerTarget.AddCustomAttribute("max health additive bonus", 4000, 0)
		TransformerTarget.SetHealth(4200)
		TransformerTarget.AddCustomAttribute("ammo regen", 100.0, 0)
		TransformerTarget.AddCustomAttribute("move speed bonus", 0.5, 0)
		TransformerTarget.AddCustomAttribute("damage force reduction", 0.4, 0)
		TransformerTarget.AddCustomAttribute("airblast vulnerability multiplier", 0.4, 0)
		TransformerTarget.AddCustomAttribute("override footstep sound set", 4, 0)
		TransformerTarget.AddCustomAttribute("voice pitch scale", 0, 0)

		// Setting Item Attributes
		local primary = GetItemInSlot(TransformerTarget, 0 )

		primary.AddAttribute("damage bonus", 2, 0)
		primary.AddAttribute("fire rate bonus", 0.2, 0)
		primary.AddAttribute("faster reload rate", 0.4, 0)
		primary.AddAttribute("clip size upgrade atomic", 5.0, 0)
	}

	// PYRO TRANSFORMS //

	// DEMOMAN TRANSFORMS //

	// HEAVY TRANSFORMS //

	// ENGINEER TRANSFORMS //

	// MEDIC TRANSFORMS //

	// SNIPER TRANSFORMS //

	// SPY TRANSFORMS //
};

RobotTransformerSpace.RemoveAllTransforms()

__CollectGameEventCallbacks(RobotTransformerSpace)