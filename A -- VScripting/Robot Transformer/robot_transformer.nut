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

::RobotTransformer <-
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

			foreach(wearable in player_scope.wearables)
			{
				wearable.Kill()
			}

			for ( local player; player = Entities.FindByClassname( player, "player" ); ) {
				NetProps.SetPropString(player, "m_iszScriptThinkFunction", "")
			}

			local playerclass = player.GetPlayerClass()
			player.SetCustomModelWithClassAnimations(PlayerModels[playerclass])
		}

        delete ::RobotTransformer
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

		player.ValidateScriptScope()
		local scope = player.GetScriptScope()

		if (!player || !player.IsValid() || player.IsBotOfType(1337))
			return

		EntFireByHandle(player, "RunScriptCode", "RobotTransformer.ClearPlayerModel(self)", 1, null, null)

		if("wearables" in scope && scope.wearables.len()>0)
		{
			foreach(wearable in scope.wearables)
			{
				wearable.Kill()
			}

			delete scope.wearables
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
	function SetWeaponModel(bot, args)
	{
		local wep = "slot" in args ? GetItemInSlot( bot, args.slot ) : bot.GetActiveWeapon()

		local scope = bot.GetScriptScope()
		local modelindex = PrecacheModel( "model" in args ? args.model : args.type )
		local tp_wearable = Entities.CreateByClassname( "tf_wearable" )

		NetProps.SetPropInt( wep, "m_nRenderMode", kRenderTransColor )
		NetProps.SetPropInt( wep, "m_clrRender", 0 )

		NetProps.SetPropInt( tp_wearable, "m_nModelIndex", modelindex )
		NetProps.SetPropBool( tp_wearable, "m_AttributeManager.m_Item.m_bInitialized", true )
		NetProps.SetPropBool( tp_wearable, "m_bValidatedAttachedEntity", true )
		tp_wearable.SetOwner(bot)
		NetProps.SetPropEntity( tp_wearable, "m_hOwner", bot)
		tp_wearable.DispatchSpawn()
		NetProps.SetPropBool( tp_wearable, "m_bForcePurgeFixedupStrings", true )
		tp_wearable.AcceptInput( "SetParent", "!activator", bot, bot )
		NetProps.SetPropInt( tp_wearable, "m_fEffects", 1|128 )
	}

	//// TRANSFORMER MAIN FUNCTIONS ////

	// SCOUT TRANSFORMS //

	// SOLDIER TRANSFORMS //
	function BigrockBurst(target)
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
		TransformerTarget.AddCustomAttribute("move speed penalty", 0.5, 0)
		TransformerTarget.AddCustomAttribute("damage force reduction", 0.4, 0)
		TransformerTarget.AddCustomAttribute("airblast vulnerability multiplier", 0.4, 0)
		TransformerTarget.AddCustomAttribute("override footstep sound set", 4, 0)
		TransformerTarget.AddCustomAttribute("voice pitch scale", 0, 0)

		// Setting Item Attributes
		local primary = GetItemInSlot(TransformerTarget, 0 )

		primary.SetTeam(4)
		primary.AddAttribute("damage bonus", 2, 0)
		primary.AddAttribute("fire rate bonus", 0.2, 0)
		primary.AddAttribute("faster reload rate", 0.4, 0)
		primary.AddAttribute("clip size upgrade atomic", 5.0, 0)
	}

	// PYRO TRANSFORMS //

	// DEMOMAN TRANSFORMS //
	function Hammerknight(target)
	{
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
		TransformerTarget.AddCondEx(56, -1, null)
		TransformerTarget.AddCondEx(66, 0.25, null)
		TransformerTarget.AddCondEx(51, 1, null)

		NetProps.SetPropString(TransformerTarget, "m_PlayerClass.m_iszClassIcon", "demoknight_giant")

		// Stripping Cosmetics and Weapons
		for (local next, current = TransformerTarget.FirstMoveChild(); current != null; current = next)
		{
			NetProps.SetPropBool(current, "m_bForcePurgeFixedupStrings", true)

			next = current.NextMovePeer()
			if (current instanceof CEconEntity)
				current.Destroy()
		}

		GivePlayerWeapon(TransformerTarget, "tf_wearable", 405)
		GivePlayerWeapon(TransformerTarget, "tf_wearable_demoshield", 131)
		GivePlayerWeapon(TransformerTarget, "tf_weapon_katana", 357)

		// Setting Character Attributes
		TransformerTarget.AddCustomAttribute("max health additive bonus", 3800, 0)
		TransformerTarget.SetHealth(4000)
		TransformerTarget.AddCustomAttribute("move speed penalty", 0.5, 0)
		TransformerTarget.AddCustomAttribute("damage force reduction", 0.4, 0)
		TransformerTarget.AddCustomAttribute("airblast vulnerability multiplier", 0.4, 0)
		TransformerTarget.AddCustomAttribute("override footstep sound set", 4, 0)
		TransformerTarget.AddCustomAttribute("voice pitch scale", 0, 0)

		// Setting Item Attributes
		local secondary = GetItemInSlot(TransformerTarget, 1 )

		secondary.AddAttribute("mult charge turn control", 5, 0)

		local melee = GetItemInSlot(TransformerTarget, 2 )

		melee.AddAttribute("fire rate penalty", 1.2, 0)
		melee.AddAttribute("restore health on kill", 10, 0)
		melee.AddAttribute("decapitate type", 0, 0)
		melee.AddAttribute("crit kill will gib", 1, 0)

		local meleemodelinfo = {slot = 2, model = "models/weapons/c_models/c_big_mallet/c_big_mallet.mdl"}
		SetWeaponModel(TransformerTarget, meleemodelinfo)

		// Setting Hammer Functionality
		melee.ValidateScriptScope()
		local meleescope = melee.GetScriptScope()

		function HammerStrike(wielder)
		{
			// used in a fire input on attack
			EntFireByHandle(wielder, "runscriptcode", @"

				local forward = self.EyeAngles().Forward(); forward.z = 0; forward.Norm();
				local vHitPos = self.GetOrigin() + (forward * (128 * self.GetModelScale()));
				local Trace = {
					start = vHitPos,
					end = vHitPos - Vector(0, 0, 1000),
					mask = 33579137
				}
				TraceLineEx(Trace)
				if (!Trace.hit) return

				vHitPos = Trace.pos
				ScreenShake(vHitPos, 15, 15, 1, 9999, 0, true)
				DispatchParticleEffect(`hammer_impact_button`, vHitPos + Vector(0,0,25), Vector(0, 0, 0))
				local hBomb = Entities.CreateByClassname(`tf_generic_bomb`)

				hBomb.KeyValueFromInt(`damage`, 100)
				hBomb.KeyValueFromInt(`radius`, 300)
				hBomb.KeyValueFromInt(`friendlyfire`, 0)
				hBomb.KeyValueFromString(`classname`, `necro_smasher`)
				hBomb.DispatchSpawn()
				hBomb.SetAbsOrigin(vHitPos)
				hBomb.SetTeam(self.GetTeam())
				hBomb.SetOwner(self)
				hBomb.AcceptInput(`Detonate`, null, self, self)

				PrecacheSound(`sound/misc/halloween/strongman_fast_impact_01.wav`)
				EmitSoundEx({
					sound_name = `sound/misc/halloween/strongman_fast_impact_01.wav`
					origin = vHitPos
					volume      = 1
					sound_level = (40 + (20 * log10(9999 / 36))).tointeger()
					filter_type = 5
				})

				for (local hEnt = null; hEnt = Entities.FindByClassnameWithin(hEnt, `player`, vHitPos, 300);)
				{
					if (!hEnt || !hEnt.IsValid()) continue
					if (0 != NetProps.GetPropInt(hEnt, `m_lifeState`) || hEnt.GetTeam() == TEAM_SPECTATOR || hEnt.GetTeam() == self.GetTeam()) continue

					hEnt.SetAbsVelocity(Vector(0, 0, 500))
				}
			", 0.4, wielder, wielder)
		}

		meleescope.Think <- function() {

			local nextswing = NetProps.GetPropFloat(melee, "m_flNextPrimaryAttack")

			if (swingpressed && nextswing < Time())
			{
				RobotTransformer.Hammerknight.HammerStrike(self)
			}
			else
			{
				return
			}
			return -1
		}

		AddThinkToEnt(melee, "Think")
	}

	// HEAVY TRANSFORMS //
	function DeflectorHeavy(target)
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

		TransformerTarget.SetCustomModelWithClassAnimations("models/bots/heavy_boss/bot_heavy_boss.mdl")

		TransformerTarget.SetUseBossHealthBar(true)
		TransformerTarget.SetIsMiniBoss(true)
		TransformerTarget.SetModelScale(1.75, 0)
		TransformerTarget.AddCondEx(66, 0.25, null)
		TransformerTarget.AddCondEx(51, 1, null)

		NetProps.SetPropString(TransformerTarget, "m_PlayerClass.m_iszClassIcon", "heavy_deflector")

		// Stripping Cosmetics and Weapons
		for (local next, current = TransformerTarget.FirstMoveChild(); current != null; current = next)
		{
			NetProps.SetPropBool(current, "m_bForcePurgeFixedupStrings", true)

			next = current.NextMovePeer()
			if (current instanceof CEconEntity)
				current.Destroy()
		}

		GivePlayerWeapon(TransformerTarget, "tf_weapon_minigun", 850)
		GivePlayerCosmetic(TransformerTarget, 840, "models/player/items/mvm_loot/heavy/robo_ushanka.mdl")

		// Setting Character Attributes
		TransformerTarget.AddCustomAttribute("max health additive bonus", 4700, 0)
		TransformerTarget.SetHealth(5000)
		TransformerTarget.AddCustomAttribute("ammo regen", 100.0, 0)
		TransformerTarget.AddCustomAttribute("move speed penalty", 0.5, 0)
		TransformerTarget.AddCustomAttribute("damage force reduction", 0.3, 0)
		TransformerTarget.AddCustomAttribute("airblast vulnerability multiplier", 0.3, 0)
		TransformerTarget.AddCustomAttribute("override footstep sound set", 2, 0)
		TransformerTarget.AddCustomAttribute("voice pitch scale", 0, 0)

		// Setting Item Attributes
		local primary = GetItemInSlot(TransformerTarget, 0 )

		primary.SetTeam(4)
		primary.AddAttribute("damage bonus", 1.5, 0)
		primary.AddAttribute("attack projectiles", 1, 0)
	}

	// ENGINEER TRANSFORMS //

	// MEDIC TRANSFORMS //

	// SNIPER TRANSFORMS //

	// SPY TRANSFORMS //
};

__CollectGameEventCallbacks(RobotTransformer)