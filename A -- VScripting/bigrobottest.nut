printl("fuckass bot test")

::BotTest <-
{
	// Cleanup Functions


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
}