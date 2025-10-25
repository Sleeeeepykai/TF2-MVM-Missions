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
	function CollectEventsInScope(events)
	{
		local events_id = UniqueString()
		getroottable()[events_id] <- events

		foreach (name, callback in events)
			events[name] = callback.bindenv(this)

		local cleanup_user_func, cleanup_event = "OnGameEvent_scorestats_accumulated_update"
		if (cleanup_event in events)
			cleanup_user_func = events[cleanup_event]

		events[cleanup_event] <- function(params)
		{
			if (cleanup_user_func)
				cleanup_user_func(params)

			delete getroottable()[events_id]
		}
		__CollectGameEventCallbacks(events)
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

	// Think Table Functions
	function MultipleThinks()
	{
		local time = Time()
		foreach (name, func in ThinkTable)
		{
			if (ThinkDelays[name] > time)
				continue

			local delay = func()
			if (delay == null || delay < 0.0)
				delay = 0.0

			ThinkDelays[name] = time + delay
		}

		return -1
	}
	function AddThinkTable(entity)
	{
		entity.ValidateScriptScope()
		local scope = entity.GetScriptScope()

		scope.ThinkTable <- {}
		scope.ThinkDelays <- {}
		scope.MultipleThinks <- MultipleThinks
		AddThinkToEnt(entity, "MultipleThinks")

		return scope
	}
	function AddThink(entity, name, func)
	{
		local scope = entity.GetScriptScope()
		scope.ThinkTable[name] <- func//.bindenv(scope) seemingly has no impact
		scope.ThinkDelays[name] <- 0.0
	}

	//// TRANSFORMER CLASS SPECIFIC SETUP FUNCTIONS ////

	function GiantSoldierFootstepThink()
	{
		PrecacheScriptSound("MVM.GiantSoldierStep")

		local buttons = NetProps.GetPropInt(self, "m_nButtons")
		if (!(self.GetFlags() & Constants.FPlayer.FL_ONGROUND))
			return -1.0
		if (!(buttons & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT)))
			return -1.0
		EmitSoundEx({sound_name = "MVM.GiantSoldierStep", channel = 4, entity = self})
			return 0.5
	}

	function GiantPyroFootstepThink()
	{
		PrecacheScriptSound("MVM.GiantPyroStep")

		local buttons = NetProps.GetPropInt(self, "m_nButtons")
		if (!(self.GetFlags() & Constants.FPlayer.FL_ONGROUND))
			return -1.0
		if (!(buttons & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT)))
			return -1.0
		EmitSoundEx({sound_name = "MVM.GiantPyroStep", channel = 4, entity = self})
			return 0.5
	}

	function GiantDemoFootstepThink()
	{
		PrecacheScriptSound("MVM.GiantDemomanStep")

		local buttons = NetProps.GetPropInt(self, "m_nButtons")
		if (!(self.GetFlags() & Constants.FPlayer.FL_ONGROUND))
			return -1.0
		if (!(buttons & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT)))
			return -1.0
		EmitSoundEx({sound_name = "MVM.GiantDemomanStep", channel = 4, entity = self})
			return 0.5
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

		AddThinkTable(TransformerTarget)
		AddThink(TransformerTarget, "FootstepThink", GiantSoldierFootstepThink)

		PrecacheScriptSound("MVM.GiantSoldierLoop")
		EmitSoundEx({sound_name = "MVM.GiantSoldierLoop", channel = 6, volume = 0.5, entity = TransformerTarget})

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
		TransformerTarget.AddCustomAttribute("voice pitch scale", 0, 0)

		// Setting Item Attributes
		local primary = GetItemInSlot(TransformerTarget, 0 )

		primary.AddAttribute("damage bonus", 2, 0)
		primary.AddAttribute("fire rate bonus", 0.2, 0)
		primary.AddAttribute("faster reload rate", 0.4, 0)
		primary.AddAttribute("clip size upgrade atomic", 5.0, 0)
	}
	function RocketShotgun(target)
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
		TransformerTarget.AddCondEx(66, 0.25, null)
		TransformerTarget.AddCondEx(51, 1, null)

		NetProps.SetPropString(TransformerTarget, "m_PlayerClass.m_iszClassIcon", "soldier_blackbox")

		// Stripping Cosmetics and Weapons
		for (local next, current = TransformerTarget.FirstMoveChild(); current != null; current = next)
		{
			NetProps.SetPropBool(current, "m_bForcePurgeFixedupStrings", true)

			next = current.NextMovePeer()
			if (current instanceof CEconEntity)
				current.Destroy()
		}

		// Giving New Cosmetics, Weapons and Footsteps
		GivePlayerWeapon(TransformerTarget, "tf_weapon_rocketlauncher", 228)

		AddThinkTable(TransformerTarget)
		AddThink(TransformerTarget, "FootstepThink", GiantSoldierFootstepThink)

		PrecacheScriptSound("MVM.GiantSoldierLoop")
		EmitSoundEx({sound_name = "MVM.GiantSoldierLoop", channel = 6, volume = 0.5, entity = TransformerTarget})

		// Setting Character Attributes
		TransformerTarget.AddCustomAttribute("max health additive bonus", 3800, 0)
		TransformerTarget.SetHealth(4000)
		TransformerTarget.AddCustomAttribute("ammo regen", 100.0, 0)
		TransformerTarget.AddCustomAttribute("move speed bonus", 0.5, 0)
		TransformerTarget.AddCustomAttribute("damage force reduction", 0.4, 0)
		TransformerTarget.AddCustomAttribute("airblast vulnerability multiplier", 0.4, 0)
		TransformerTarget.AddCustomAttribute("voice pitch scale", 0, 0)

		// Setting Item Attributes
		local primary = GetItemInSlot(TransformerTarget, 0 )

		primary.AddAttribute("fire rate bonus", 0.75, 0)
		primary.AddAttribute("faster reload rate", 0.4, 0)
		primary.AddAttribute("clip size penalty", 0.5, 0)
		primary.AddAttribute("projectile spread angle penalty", 5.0, 0)
		primary.AddAttribute("mult projectile count", 10.0, 0)
		primary.AddAttribute("ignores other projectiles", 1.0, 0)
	}

	// PYRO TRANSFORMS //
	function ComboPyro(target)
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
		TransformerTarget.SetPlayerClass(Constants.ETFClass.TF_CLASS_PYRO)
		NetProps.SetPropInt(TransformerTarget, "m_Shared.m_iDesiredPlayerClass", Constants.ETFClass.TF_CLASS_PYRO)

		TransformerTarget.SetCustomModelWithClassAnimations("models/bots/pyro_boss/bot_pyro_boss.mdl")
		TransformerTarget.SetUseBossHealthBar(true)
		TransformerTarget.SetIsMiniBoss(true)
		TransformerTarget.SetModelScale(1.75, 0)
		TransformerTarget.SetForcedTauntCam(1)
		TransformerTarget.AddCondEx(66, 0.25, null)
		TransformerTarget.AddCondEx(51, 1, null)

		// Stripping Cosmetics and Weapons
		for (local next, current = TransformerTarget.FirstMoveChild(); current != null; current = next)
		{
			NetProps.SetPropBool(current, "m_bForcePurgeFixedupStrings", true)

			next = current.NextMovePeer()
			if (current instanceof CEconEntity)
				current.Destroy()
		}

		GivePlayerWeapon(TransformerTarget, "tf_weapon_flamethrower", 21)
		GivePlayerWeapon(TransformerTarget, "tf_weapon_flaregun", 39)
		GivePlayerWeapon(TransformerTarget, "tf_weapon_fireaxe", 38)

		AddThinkTable(TransformerTarget)
		AddThink(TransformerTarget, "FootstepThink", GiantPyroFootstepThink)
		PrecacheScriptSound("MVM.GiantPyroLoop")
		EmitSoundEx({sound_name = "MVM.GiantPyroLoop", channel = 6, volume = 0.5, entity = TransformerTarget})

		// Setting Character Attributes
		TransformerTarget.AddCustomAttribute("max health additive bonus", 2825, 0)
		TransformerTarget.SetHealth(3000)
		TransformerTarget.AddCustomAttribute("ammo regen", 100.0, 0)
		TransformerTarget.AddCustomAttribute("move speed bonus", 0.5, 0)
		TransformerTarget.AddCustomAttribute("damage force reduction", 0.6, 0)
		TransformerTarget.AddCustomAttribute("airblast vulnerability multiplier", 0.6, 0)
		TransformerTarget.AddCustomAttribute("voice pitch scale", 0, 0)

		// Setting Item Attributes
		local primary = GetItemInSlot(TransformerTarget, 0 )
		local secondary = GetItemInSlot(TransformerTarget, 1 )
		local melee = GetItemInSlot(TransformerTarget, 2 )

		primary.AddAttribute("damage bonus", 2, 0)
		primary.AddAttribute("airblast pushback scale", 5, 0)
		primary.AddAttribute("weapon burn time increased", 2, 0)
		primary.AddAttribute("weapon burn dmg increased", 2, 0)
		primary.AddAttribute("is australium item", 1, 0)
		primary.AddAttribute("item style override", 1, 0)

		secondary.AddAttribute("damage bonus", 2, 0)
		secondary.AddAttribute("projectile speed increased", 2, 0)
		secondary.AddAttribute("faster reload rate", 0.5, 0)

		melee.AddAttribute("damage bonus", 2, 0)
		melee.AddAttribute("is australium item", 1, 0)
		melee.AddAttribute("item style override", 1, 0)
	}

	// DEMOMAN TRANSFORMS //
	function NuclearCaber(target)
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
		TransformerTarget.SetPlayerClass(Constants.ETFClass.TF_CLASS_DEMOMAN)
		NetProps.SetPropInt(TransformerTarget, "m_Shared.m_iDesiredPlayerClass", Constants.ETFClass.TF_CLASS_DEMOMAN)

		TransformerTarget.SetCustomModelWithClassAnimations("models/bots/demo_boss/bot_demo_boss.mdl")
		TransformerTarget.SetUseBossHealthBar(true)
		TransformerTarget.SetIsMiniBoss(true)
		TransformerTarget.SetModelScale(1.75, 0)
		TransformerTarget.SetForcedTauntCam(1)
		TransformerTarget.AddCondEx(56, -1, null)
		TransformerTarget.AddCondEx(66, 0.25, null)
		TransformerTarget.AddCondEx(51, 1, null)

		// Stripping Cosmetics and Weapons
		for (local next, current = TransformerTarget.FirstMoveChild(); current != null; current = next)
		{
			NetProps.SetPropBool(current, "m_bForcePurgeFixedupStrings", true)

			next = current.NextMovePeer()
			if (current instanceof CEconEntity)
				current.Destroy()
		}

		// Giving New Cosmetics, Weapons and Footsteps
		GivePlayerWeapon(TransformerTarget, "tf_wearable", 405)
		GivePlayerWeapon(TransformerTarget, "tf_wearable_demoshield", 131)
		GivePlayerWeapon(TransformerTarget, "tf_weapon_stickbomb", 307)
		GivePlayerCosmetic(TransformerTarget, 403, "models/player/items/demo/demo_sultan_hat.mdl")

		AddThinkTable(TransformerTarget)
		AddThink(TransformerTarget, "FootstepThink", GiantDemoFootstepThink)

		PrecacheScriptSound("MVM.GiantDemomanLoop")
		EmitSoundEx({sound_name = "MVM.GiantDemomanLoop", channel = 6, volume = 0.5, entity = TransformerTarget})

		// Setting Character Attributes
		TransformerTarget.AddCustomAttribute("max health additive bonus", 3800, 0)
		TransformerTarget.SetHealth(4000)
		TransformerTarget.AddCustomAttribute("move speed bonus", 0.5, 0)
		TransformerTarget.AddCustomAttribute("damage force reduction", 0.5, 0)
		TransformerTarget.AddCustomAttribute("airblast vulnerability multiplier", 0.5, 0)
		TransformerTarget.AddCustomAttribute("voice pitch scale", 0, 0)

		// Setting Item Attributes
		local melee = GetItemInSlot(TransformerTarget, 0 )

		melee.AddAttribute("damage bonus", 50, 0)
		melee.AddAttribute("blast radius increased", 30.0, 0)
		melee.AddAttribute("use large smoke explosion", 1.0, 0)
		melee.AddAttribute("blast dmg to self increased", 100.0, 0)
	}

	// HEAVY TRANSFORMS //
	function MittensMan(target)
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
		TransformerTarget.SetPlayerClass(Constants.ETFClass.TF_CLASS_HEAVYWEAPONS)
		NetProps.SetPropInt(TransformerTarget, "m_Shared.m_iDesiredPlayerClass", Constants.ETFClass.TF_CLASS_HEAVYWEAPONS)

		TransformerTarget.SetCustomModelWithClassAnimations("models/bots/heavy/bot_heavy.mdl")
		TransformerTarget.AddCondEx(56, -1, null)
		TransformerTarget.AddCondEx(66, 0.25, null)
		TransformerTarget.AddCondEx(51, 1, null)

		// Stripping Cosmetics and Weapons
		for (local next, current = TransformerTarget.FirstMoveChild(); current != null; current = next)
		{
			NetProps.SetPropBool(current, "m_bForcePurgeFixedupStrings", true)

			next = current.NextMovePeer()
			if (current instanceof CEconEntity)
				current.Destroy()
		}

		// Giving New Cosmetics, Weapons, Footsteps and Voicelines
		GivePlayerWeapon(TransformerTarget, "tf_weapon_fists", 656)
		GivePlayerCosmetic(TransformerTarget, 634, "models/player/items/all_class/trn_wiz_hat_heavy.mdl")
		GivePlayerCosmetic(TransformerTarget, 647, "models/workshop/player/items/all_class/xms_beard/xms_beard_heavy.mdl")

		// Setting Character Attributes
		TransformerTarget.AddCustomAttribute("dmg from ranged reduced", 0.01, 0)
		TransformerTarget.AddCustomAttribute("dmg from melee increased", 0.01, 0)
		TransformerTarget.AddCustomAttribute("damage force reduction", 0.01, 0)
		TransformerTarget.AddCustomAttribute("airblast vulnerability multiplier", 0.01, 0)
		TransformerTarget.AddCustomAttribute("gesture speed increase", 2, 0)

		// Setting Item Attributes
		local melee = GetItemInSlot(TransformerTarget, 0)

		melee.AddAttribute("melee attack rate bonus", 1.5, 0)
	}

	// ENGINEER TRANSFORMS //

	// MEDIC TRANSFORMS //

	// SNIPER TRANSFORMS //

	// SPY TRANSFORMS //
	function LondonSpy(target)
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
		TransformerTarget.SetPlayerClass(Constants.ETFClass.TF_CLASS_SPY)
		NetProps.SetPropInt(TransformerTarget, "m_Shared.m_iDesiredPlayerClass", Constants.ETFClass.TF_CLASS_SPY)

		TransformerTarget.SetCustomModelWithClassAnimations("models/bots/spy/bot_spy.mdl")

		TransformerTarget.AddCondEx(66, 0.25, null)
		TransformerTarget.AddCondEx(51, 1, null)

		// Stripping Cosmetics and Weapons
		for (local next, current = TransformerTarget.FirstMoveChild(); current != null; current = next)
		{
			NetProps.SetPropBool(current, "m_bForcePurgeFixedupStrings", true)

			next = current.NextMovePeer()
			if (current instanceof CEconEntity)
				current.Destroy()
		}

		// Giving New Cosmetics, Weapons, Footsteps and Voicelines
		GivePlayerWeapon(TransformerTarget, "tf_weapon_knife", 461)
		GivePlayerCosmetic(TransformerTarget, 31447, "models/workshop/player/items/spy/sum24_sneaky_blinder/sum24_sneaky_blinder.mdl")
		GivePlayerCosmetic(TransformerTarget, 30602, "models/workshop/player/items/spy/dec2014_the_puffy_provocateur/dec2014_the_puffy_provocateur.mdl")

		// Setting Character Attributes
		TransformerTarget.AddCustomAttribute("move speed bonus", 2.0, 0)

		// Setting Item Attributes
		local melee = GetItemInSlot(TransformerTarget, 0)

		melee.AddAttribute("damage bonus", 0.01, 0)
		melee.AddAttribute("fire rate bonus", 0.001, 0)
	}
};

RobotTransformerSpace.RemoveAllTransforms()

RobotTransformerSpace.CollectEventsInScope
({
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

	function OnGameEvent_player_spawn(params)
	{
		local player = GetPlayerFromUserID(params.userid)

		if (!player || !player.IsValid() || player.IsBotOfType(1337))
			return

		EntFireByHandle(player, "RunScriptCode", "RobotTransformerSpace.ClearPlayerModel(self)", 1, null, null)
	}
})

__CollectGameEventCallbacks(RobotTransformerSpace)