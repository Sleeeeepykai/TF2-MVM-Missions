printl("Robot Transformer Initialised")

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
	//// CLEANUP FUNCTIONS ////

    function Cleanup()
    {
        for (local i = 1; i <= MaxPlayers; i++)
		{
			local Player = PlayerInstanceFromIndex(i)

			if(Player && (Player.GetTeam()) == 2)
			{
				SetPropString(Player, "m_iszScriptThinkFunction", "")

				local PlayerClass = Player.GetPlayerClass()
				Player.SetCustomModelWithClassAnimations(PlayerModels[PlayerClass])

				Player.ValidateScriptScope()
				local PlayerScope = Player.GetScriptScope()

				if( ("Wearables" in PlayerScope) )
				{
					foreach(Wearable in PlayerScope.Wearables)
					{
						Wearable.Kill()
					}
				}
				if( ("TPWearables" in PlayerScope) )
				{
					foreach(TPWearable in PlayerScope.TPWearables)
					{
						TPWearable.Kill()
					}
				}
			}
		}

        delete ::RobotTransformer
    }
	OnGameEvent_recalculate_holidays = function(_) { if (GetRoundState() == 3) Cleanup() }

	function OnGameEvent_player_spawn(params)
	{
		local Player = GetPlayerFromUserID(params.userid)

		if(Player && (Player.GetTeam()) == 2)
		{
			SetPropString(Player, "m_iszScriptThinkFunction", "")

			EntFireByHandle(Player, "RunScriptCode", "RobotTransformer.ClearPlayerModel(self)", 1, null, null)

			Player.ValidateScriptScope()
			local PlayerScope = Player.GetScriptScope()

			if( ("Wearables" in PlayerScope) )
			{
				foreach(Wearable in PlayerScope.Wearables)
				{
					Wearable.Kill()
				}
			}
			if( ("TPWearables" in PlayerScope) )
			{
				foreach(TPWearable in PlayerScope.TPWearables)
				{
					TPWearable.Kill()
				}
			}
		}
	}
	function ClearPlayerModel(Player)
	{
		local PlayerClass = Player.GetPlayerClass()
		Player.SetCustomModelWithClassAnimations(PlayerModels[PlayerClass])
	}

	//// TRANSFORMER GLOBAL SETUP FUNCTIONS ////

	function GetPlayerName(Player)
	{
		return GetPropString(Player, "m_szNetname")
	}
	function GivePlayerWeapon(Player, ClassName, ItemID)
	{
		local Weapon = CreateByClassname(ClassName)
		SetPropInt(Weapon, "m_AttributeManager.m_Item.m_iItemDefinitionIndex", ItemID)
		SetPropBool(Weapon, "m_AttributeManager.m_Item.m_bInitialized", true)
		SetPropBool(Weapon, "m_bValidatedAttachedEntity", true)
		Weapon.SetTeam(Player.GetTeam())
		Weapon.DispatchSpawn()

		for (local i = 0; i < MAX_WEAPONS; i++)
		{
			local HeldWeapon = GetPropEntityArray(Player, "m_hMyWeapons", i)
			if (HeldWeapon == null)
				continue
			if (HeldWeapon.GetSlot() != Weapon.GetSlot())
				continue
			HeldWeapon.Destroy()
			SetPropEntityArray(Player, "m_hMyWeapons", null, i)
			break
		}

		Player.Weapon_Equip(Weapon)
		Player.Weapon_Switch(Weapon)

		return Weapon
	}
	function GivePlayerCosmetic(Player, ItemID, ModelPath = null)
	{
		local Weapon = CreateByClassname("tf_weapon_parachute")
		SetPropInt(Weapon, "m_AttributeManager.m_Item.m_iItemDefinitionIndex", 1101)
		SetPropBool(Weapon, "m_AttributeManager.m_Item.m_bInitialized", true)
		Weapon.SetTeam(Player.GetTeam())
		Weapon.DispatchSpawn()
		Player.Weapon_Equip(Weapon)
		local Wearable = GetPropEntity(Weapon, "m_hExtraWearable")
		Weapon.Kill()

		SetPropInt(Wearable, "m_AttributeManager.m_Item.m_iItemDefinitionIndex", ItemID)
		SetPropBool(Wearable, "m_AttributeManager.m_Item.m_bInitialized", true)
		SetPropBool(Wearable, "m_bValidatedAttachedEntity", true)
		Wearable.DispatchSpawn()

		// (optional) Set the model to something new. (Obeys econ's ragdoll physics when ragdolling as well)
		if (ModelPath)
			Wearable.SetModelSimple(ModelPath)

		// (optional) if one wants to delete the item entity, collect them within the player's scope, then send Kill() to the entities within the scope.
		Player.ValidateScriptScope()
		local PlayerScope = Player.GetScriptScope()
		if (!("Wearables" in PlayerScope))
			PlayerScope.Wearables <- []
		PlayerScope.Wearables.append(Wearable)

		return Wearable
	}
	function GetItemInSlot(Player, Slot)
	{
		for ( local Child = Player.FirstMoveChild(); Child; Child = Child.NextMovePeer() )
			if ( Child instanceof CBaseCombatWeapon && Child.GetSlot() == Slot )
				return Child
	}
	function SetWeaponModel(Player, Args)
	{
		local Weapon = "Slot" in Args ? GetItemInSlot( Player, Args.Slot ) : Player.GetActiveWeapon()

		local PlayerScope = Player.GetScriptScope()
		local ModelIndex = PrecacheModel( "Model" in Args ? Args.Model : Args.Type )
		local TPWearable = CreateByClassname( "tf_wearable" )

		SetPropInt( Weapon, "m_nRenderMode", kRenderTransColor )
		SetPropInt( Weapon, "m_clrRender", 0 )

		SetPropInt( TPWearable, "m_nModelIndex", ModelIndex )
		SetPropBool( TPWearable, "m_AttributeManager.m_Item.m_bInitialized", true )
		SetPropBool( TPWearable, "m_bValidatedAttachedEntity", true )
		TPWearable.SetOwner(Player)
		SetPropEntity( TPWearable, "m_hOwner", Player)
		TPWearable.DispatchSpawn()
		SetPropBool( TPWearable, "m_bForcePurgeFixedupStrings", true )
		TPWearable.AcceptInput( "SetParent", "!activator", Player, Player )
		SetPropInt( TPWearable, "m_fEffects", 1|128 )

		if (!("TPWearables" in PlayerScope))
			PlayerScope.TPWearables <- []
		PlayerScope.TPWearables.append(TPWearable)

		return TPWearable
	}

	//// TRANSFORMER MAIN FUNCTIONS ////

	// SCOUT TEMPLATES //
	function MajorLeague(Target)
	{
		// Finding the Player to Transform
		local TransformerTarget
		for (local i = 1; i <= MaxPlayers; i++)
		{
			local Player = PlayerInstanceFromIndex(i)
			if (Player == null)
				continue
			if (GetPlayerName(Player) == Target)
			{
				TransformerTarget = Player;
				break;
			}
		}

		// Executing Transformation
		TransformerTarget.SetPlayerClass(Constants.ETFClass.TF_CLASS_SCOUT)
		SetPropInt(TransformerTarget, "m_Shared.m_iDesiredPlayerClass", Constants.ETFClass.TF_CLASS_SCOUT)

		TransformerTarget.SetCustomModelWithClassAnimations("models/bots/scout_boss/bot_scout_boss.mdl")

		TransformerTarget.SetUseBossHealthBar(true)
		TransformerTarget.SetIsMiniBoss(true)
		TransformerTarget.SetModelScale(1.75, 0)
		TransformerTarget.AddCondEx(56, -1, null)
		TransformerTarget.AddCondEx(66, 0.25, null)
		TransformerTarget.AddCondEx(51, 1, null)

		SetPropString(TransformerTarget, "m_PlayerClass.m_iszClassIcon", "scout_stun_giant")

		// Stripping Cosmetics and Weapons
		for (local Next, Current = TransformerTarget.FirstMoveChild(); Current != null; Current = Next)
		{
			SetPropBool(Current, "m_bForcePurgeFixedupStrings", true)

			Next = Current.NextMovePeer()
			if (Current instanceof CEconEntity)
				Current.Destroy()
		}
		
		GivePlayerWeapon(TransformerTarget, "tf_weapon_bat_wood", 44)
		GivePlayerCosmetic(TransformerTarget, 707, "models/player/items/scout/boombox.mdl")
		GivePlayerCosmetic(TransformerTarget, 486, "models/player/items/scout/summer_shades.mdl")

		// Setting Character Attributes
		TransformerTarget.AddCustomAttribute("max health additive bonus", 2875, 0)
		TransformerTarget.SetHealth(3000)
		TransformerTarget.AddCustomAttribute("ammo regen", 100.0, 0)
		TransformerTarget.AddCustomAttribute("move speed bonus", 8, 0)
		TransformerTarget.AddCustomAttribute("damage force reduction", 0.7, 0)
		TransformerTarget.AddCustomAttribute("airblast vulnerability multiplier", 0.7, 0)
		TransformerTarget.AddCustomAttribute("override footstep sound set", 5, 0)
		TransformerTarget.AddCustomAttribute("voice pitch scale", 0, 0)

		// Setting Item Attributes
		local Melee = GetItemInSlot(TransformerTarget, 2)
		Melee.AddAttribute("effect bar recharge rate increased", 0.001, 0)
	}

	// SOLDIER TEMPLATES //
	function BigrockBurst(Target)
	{
		// Finding the Player to Transform
		local TransformerTarget
		for (local i = 1; i <= MaxPlayers; i++)
		{
			local Player = PlayerInstanceFromIndex(i)
			if (Player == null)
				continue
			if (GetPlayerName(Player) == Target)
			{
				TransformerTarget = Player;
				break;
			}
		}

		// Executing Transformation
		TransformerTarget.SetPlayerClass(Constants.ETFClass.TF_CLASS_SOLDIER)
		SetPropInt(TransformerTarget, "m_Shared.m_iDesiredPlayerClass", Constants.ETFClass.TF_CLASS_SOLDIER)

		TransformerTarget.SetCustomModelWithClassAnimations("models/bots/soldier_boss/bot_soldier_boss.mdl")

		TransformerTarget.SetUseBossHealthBar(true)
		TransformerTarget.SetIsMiniBoss(true)
		TransformerTarget.SetModelScale(1.75, 0)
		TransformerTarget.AddCondEx(56, -1, null)
		TransformerTarget.AddCondEx(66, 0.25, null)
		TransformerTarget.AddCondEx(51, 1, null)

		SetPropString(TransformerTarget, "m_PlayerClass.m_iszClassIcon", "soldier_burstfire_hyper_lite")

		// Stripping Cosmetics and Weapons
		for (local Next, Current = TransformerTarget.FirstMoveChild(); Current != null; Current = Next)
		{
			SetPropBool(Current, "m_bForcePurgeFixedupStrings", true)

			Next = Current.NextMovePeer()
			if (Current instanceof CEconEntity)
				Current.Destroy()
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
		local Primary = GetItemInSlot(TransformerTarget, 0 )

		Primary.SetTeam(4)
		Primary.AddAttribute("damage bonus", 2, 0)
		Primary.AddAttribute("fire rate bonus", 0.2, 0)
		Primary.AddAttribute("faster reload rate", 0.4, 0)
		Primary.AddAttribute("clip size upgrade atomic", 5.0, 0)
	}

	// PYRO TEMPLATES //

	// DEMOMAN TEMPLATES //
	function HammerKnight(Target)
	{
		local TransformerTarget
		for (local i = 1; i <= MaxPlayers; i++)
		{
			local Player = PlayerInstanceFromIndex(i)
			if (Player == null)
				continue
			if (GetPlayerName(Player) == Target)
			{
				TransformerTarget = Player;
				break;
			}
		}

		// Executing Transformation
		TransformerTarget.SetPlayerClass(Constants.ETFClass.TF_CLASS_DEMOMAN)
		SetPropInt(TransformerTarget, "m_Shared.m_iDesiredPlayerClass", Constants.ETFClass.TF_CLASS_DEMOMAN)

		TransformerTarget.SetCustomModelWithClassAnimations("models/bots/demo_boss/bot_demo_boss.mdl")

		TransformerTarget.SetUseBossHealthBar(true)
		TransformerTarget.SetIsMiniBoss(true)
		TransformerTarget.SetModelScale(1.75, 0)
		TransformerTarget.AddCondEx(56, -1, null)
		TransformerTarget.AddCondEx(66, 0.25, null)
		TransformerTarget.AddCondEx(51, 1, null)

		SetPropString(TransformerTarget, "m_PlayerClass.m_iszClassIcon", "mallet_lite")

		// Stripping Cosmetics and Weapons
		for (local Next, Current = TransformerTarget.FirstMoveChild(); Current != null; Current = Next)
		{
			SetPropBool(Current, "m_bForcePurgeFixedupStrings", true)

			Next = Current.NextMovePeer()
			if (Current instanceof CEconEntity)
				Current.Destroy()
		}

		GivePlayerWeapon(TransformerTarget, "tf_weapon_sword", 172)

		// Setting Character Attributes
		TransformerTarget.AddCustomAttribute("max health additive bonus", 3825, 0)
		TransformerTarget.SetHealth(4000)
		TransformerTarget.AddCustomAttribute("move speed penalty", 0.5, 0)
		TransformerTarget.AddCustomAttribute("damage force reduction", 0.4, 0)
		TransformerTarget.AddCustomAttribute("airblast vulnerability multiplier", 0.4, 0)
		TransformerTarget.AddCustomAttribute("override footstep sound set", 4, 0)
		TransformerTarget.AddCustomAttribute("voice pitch scale", 0, 0)

		// Setting Item Attributes
		local Melee = GetItemInSlot(TransformerTarget, 2 )

		Melee.AddAttribute("damage penalty", 0, 0)
		Melee.AddAttribute("fire rate penalty", 1.5, 0)
		Melee.AddAttribute("melee range multiplier", 0.001, 0)

		local MeleeModelInfo = {Slot = 2, Model = "models/weapons/c_models/c_big_mallet/c_big_mallet.mdl"}
		SetWeaponModel(TransformerTarget, MeleeModelInfo)

		// Setting Hammer Functionality
		Melee.ValidateScriptScope()
		local MeleeScope = Melee.GetScriptScope()

		function HammerStrike(Wielder)
		{
			// used in a fire input on attack
			EntFireByHandle(Wielder, "runscriptcode", @"

				local Forward = self.EyeAngles().Forward(); Forward.z = 0; Forward.Norm();
				local HitPos = self.GetOrigin() + (Forward * (128 * self.GetModelScale()));
				local Trace = {
					start = HitPos,
					end = HitPos - Vector(0, 0, 1000),
					mask = 33579137
				}
				TraceLineEx(Trace)
				if (!Trace.hit) return

				HitPos = Trace.pos
				ScreenShake(HitPos, 15, 15, 1, 9999, 0, true)
				DispatchParticleEffect(`hammer_impact_button`, HitPos + Vector(0,0,25), Vector(0, 0, 0))
				local Bomb = Entities.CreateByClassname(`tf_generic_bomb`)

				Bomb.KeyValueFromInt(`damage`, 200)
				Bomb.KeyValueFromInt(`radius`, 300)
				Bomb.KeyValueFromInt(`friendlyfire`, 0)
				Bomb.KeyValueFromString(`classname`, `necro_smasher`)
				Bomb.DispatchSpawn()
				Bomb.SetAbsOrigin(HitPos)
				Bomb.SetTeam(self.GetTeam())
				Bomb.SetOwner(self)
				Bomb.AcceptInput(`Detonate`, null, self, self)

				PrecacheSound(`misc/halloween/strongman_fast_impact_01.wav`)
				PrecacheSound(`ambient/explosions/explode_1.wav`)
				EmitSoundEx({
					sound_name = `misc/halloween/strongman_fast_impact_01.wav`
					origin = HitPos
					channel = 6
					volume      = 1
					sound_level = (40 + (20 * log10(9999 / 36))).tointeger()
					filter_type = 5
				})
				EmitSoundEx({
					sound_name = `ambient/explosions/explode_1.wav`
					origin = HitPos
					channel = 6
					volume      = 1
					sound_level = (40 + (20 * log10(9999 / 36))).tointeger()
					filter_type = 5
				})

				for (local Ent = null; Ent = FindByClassnameWithin(Ent, `player`, HitPos, 300);)
				{
					if (!Ent || !Ent.IsValid()) continue
					if (0 != GetPropInt(Ent, `m_lifeState`) || Ent.GetTeam() == TEAM_SPECTATOR || Ent.GetTeam() == self.GetTeam()) continue

					Ent.SetAbsVelocity(Vector(0, 0, 500))
				}
			", 0.2, Wielder, Wielder)
		}

		MeleeScope.LastFire <- 1e30

		SetPropInt(TransformerTarget, "m_Shared.m_iNextMeleeCrit", -2)
		MeleeScope.Think <- function()
		{
			local Owner = self.GetOwner()

			if (GetPropInt(Owner, "m_Shared.m_iNextMeleeCrit") == 0)
			{
				if (Owner.GetActiveWeapon() == self)
				{
					RobotTransformer.HammerStrike(Owner)

					SetPropInt(TransformerTarget, "m_Shared.m_iNextMeleeCrit", -2)
				}
			}

			return -1;
		}

		AddThinkToEnt(Melee, "Think")
	}

	// HEAVY TRANSFORMS //
	function DeflectorHeavy(Target)
	{
		// Finding the Player to Transform
		local TransformerTarget
		for (local i = 1; i <= MaxPlayers; i++)
		{
			local Player = PlayerInstanceFromIndex(i)
			if (Player == null)
				continue
			if (GetPlayerName(Player) == Target)
			{
				TransformerTarget = Player;
				break;
			}
		}

		// Executing Transformation
		TransformerTarget.SetPlayerClass(Constants.ETFClass.TF_CLASS_HEAVYWEAPONS)
		SetPropInt(TransformerTarget, "m_Shared.m_iDesiredPlayerClass", Constants.ETFClass.TF_CLASS_HEAVYWEAPONS)

		TransformerTarget.SetCustomModelWithClassAnimations("models/bots/heavy_boss/bot_heavy_boss.mdl")

		TransformerTarget.SetUseBossHealthBar(true)
		TransformerTarget.SetIsMiniBoss(true)
		TransformerTarget.SetModelScale(1.75, 0)
		TransformerTarget.AddCondEx(66, 0.25, null)
		TransformerTarget.AddCondEx(51, 1, null)

		SetPropString(TransformerTarget, "m_PlayerClass.m_iszClassIcon", "heavy_deflector")

		// Stripping Cosmetics and Weapons
		for (local Next, Current = TransformerTarget.FirstMoveChild(); Current != null; Current = Next)
		{
			SetPropBool(Current, "m_bForcePurgeFixedupStrings", true)

			Next = Current.NextMovePeer()
			if (Current instanceof CEconEntity)
				Current.Destroy()
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
		local Primary = GetItemInSlot(TransformerTarget, 0 )

		Primary.SetTeam(4)
		Primary.AddAttribute("damage bonus", 1.5, 0)
		Primary.AddAttribute("attack projectiles", 1, 0)
	}

	// ENGINEER TEMPLATES //

	// MEDIC TEMPLATES //

	// SNIPER TEMPLATES //

	// SPY TEMPLATES //
};

__CollectGameEventCallbacks(RobotTransformer)