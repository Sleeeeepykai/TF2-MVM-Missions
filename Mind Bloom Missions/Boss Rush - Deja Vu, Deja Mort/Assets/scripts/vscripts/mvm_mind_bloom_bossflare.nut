// Taken straight from Pop Extensions, it conflicts with all think scripts for players
::CONST <- getconsttable()
::ROOT <- getroottable()
::MAX_CLIENTS <- MaxClients().tointeger()

if (!("ConstantNamingConvention" in ROOT))
{
	foreach (a, b in Constants)
	{
		foreach (k,v in b)
		{
			CONST[k] <- v != null ? v : 0;
			ROOT[k] <- v != null ? v : 0;
		}
	}
}

foreach(k, v in ::Entities.getclass())
{
	if (k != "IsValid" && !(k in ROOT))
	{
		ROOT[k] <- ::Entities[k].bindenv(::Entities);
	}
}

foreach(k, v in ::NetProps.getclass())
{
	if (k != "IsValid" && !(k in ROOT))
	{
		ROOT[k] <- ::NetProps[k].bindenv(::NetProps);
	}
}

::BossFlareCosmetics <-
{
	function CleanUp()
	{
		delete ::BossFlareCosmetics;
	}

	function OnGameEvent_recalculate_holidays(params)
	{
		CleanUp();
	}

	function OnGameEvent_mvm_wave_complete(params)
	{
		CleanUp();
	}

	function OnGameEvent_player_spawn(params)
	{
		local player = GetPlayerFromUserID(params.userid);
		if (player == null || !player.IsValid() || !player.IsBotOfType(TF_BOT_TYPE))
		{
			return;
		}
		player.TerminateScriptScope();
		NetProps.SetPropString(player, "m_iszScriptThinkFunction", "");
		AddThinkToEnt(player, null);
		EntFireByHandle(player, "RunScriptCode", "BossFlareCosmetics.TagCheck(self)", -1, null, null);
	}

	function OnGameEvent_player_death(params)
	{
		local player = GetPlayerFromUserID(params.userid);
		if (player == null || !player.IsValid() || !player.IsBotOfType(TF_BOT_TYPE))
		{
			return;
		}
		if (player.HasBotTag("bossflare"))
		{
			local scope = player.GetScriptScope();
			foreach (wearable in scope.DestroyWearables)
			{
				if (wearable != null && wearable.IsValid())
				{
					EntFireByHandle(wearable, "Kill", "", -1, null, null);
				}
			}
		}
	}

	function SetParentLocalOriginDo(child, parent, attachment = null) {
		SetPropEntity(child, "m_hMovePeer", parent.FirstMoveChild())
		SetPropEntity(parent, "m_hMoveChild", child)
		SetPropEntity(child, "m_hMoveParent", parent)

		local origPos = child.GetLocalOrigin()
		child.SetLocalOrigin(origPos + Vector(0, 0, 1))
		child.SetLocalOrigin(origPos)

		local origAngles = child.GetLocalAngles()
		child.SetLocalAngles(origAngles + QAngle(0, 0, 1))
		child.SetLocalAngles(origAngles)

		local origVel = child.GetVelocity()
		child.SetAbsVelocity(origVel + Vector(0, 0, 1))
		child.SetAbsVelocity(origVel)

		EntFireByHandle(child, "SetParent", "!activator", 0, parent, parent)
		if (attachment != null) {
			SetPropEntity(child, "m_iParentAttachment", parent.LookupAttachment(attachment))
			EntFireByHandle(child, "SetParentAttachmentMaintainOffset", attachment, 0, parent, parent)
		}
	}

	function SetParentLocalOrigin(child, parent, attachment = null)
	{
		if (typeof child == "array")
			foreach(i, childIn in child)
				this.SetParentLocalOriginDo(childIn, parent, attachment)
		else
			this.SetParentLocalOriginDo(child, parent, attachment)
	}

	function CreatePlayerWearable(player, model, bonemerge = true, attachment = null)
	{
		local modelIndex = GetModelIndex(model);
		if (modelIndex == -1)
		{
			modelIndex = PrecacheModel(model);
		}

		local wearable = CreateByClassname("tf_wearable");
		SetPropInt(wearable, "m_nModelIndex", modelIndex);
		wearable.SetSkin(player.GetTeam());
		wearable.SetTeam(player.GetTeam());
		wearable.SetSolidFlags(4);
		wearable.SetCollisionGroup(11);
		SetPropBool(wearable, "m_bValidatedAttachedEntity", true);
		SetPropBool(wearable, "m_AttributeManager.m_Item.m_bInitialized", true);
		SetPropInt(wearable, "m_AttributeManager.m_Item.m_iEntityQuality", 0);
		SetPropInt(wearable, "m_AttributeManager.m_Item.m_iEntityLevel", 1);
		SetPropInt(wearable, "m_AttributeManager.m_Item.m_iItemIDLow", 2048);
		SetPropInt(wearable, "m_AttributeManager.m_Item.m_iItemIDHigh", 0);

		wearable.SetOwner(player);
		DispatchSpawn(wearable);
		SetPropInt(wearable, "m_fEffects", bonemerge ? 1 | 128 : 0);
		this.SetParentLocalOrigin(wearable, player, attachment);

		player.ValidateScriptScope();
		local scope = player.GetScriptScope();
		if (!("DestroyWearables" in scope))
		{
			scope.DestroyWearables <- [];
		}
		scope.DestroyWearables.append(wearable);

		return wearable;
	}

	function TagCheck(player)
	{
		if (player.HasBotTag("bossflare"))
		{
			local wearable = CreatePlayerWearable(player, "models/weapons/w_models/w_grenadelauncher.mdl", false, "flag")
			wearable.SetOwner(player)
			wearable.SetModelScale(2.3, 0)
			wearable.SetLocalOrigin(Vector(-15, 0, -6))
			wearable.SetAngles(45, -90, 0)
			local wearable2 = CreatePlayerWearable(player, "models/weapons/w_models/w_grenadelauncher.mdl", false, "flag")
			wearable2.SetOwner(player)
			wearable2.SetLocalOrigin(Vector(12, 0, -0))
			wearable2.SetModelScale(2.3, 0)
			wearable2.SetAngles(45, -45, 45)
		}
	}
}
__CollectGameEventCallbacks(BossFlareCosmetics);
PrecacheModel("models/weapons/w_models/w_grenadelauncher.mdl");