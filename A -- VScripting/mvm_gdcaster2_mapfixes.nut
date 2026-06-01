
EntFire("resupply_1", "AddOutput", "targetname ResupplySpawn1", 0.0, null)
EntFire("resupply_2", "AddOutput", "targetname ResupplySpawn1", 0.0, null)

for(local UpgradeEntity; UpgradeEntity = Entities.FindByClassname(UpgradeEntity, "func_upgradestation");)
{
	if(NetProps.GetPropInt(UpgradeEntity, "m_iHammerID") == 555405)
	{
		EntFireByHandle(UpgradeEntity, "AddOutput", "targetname UpgradeSpawn1", 0.0, null, null)
	}
	if(NetProps.GetPropInt(UpgradeEntity, "m_iHammerID") == 571799)
	{
		EntFireByHandle(UpgradeEntity, "AddOutput", "targetname UpgradeSpawn2", 0.0, null, null)
	}
}
for(local DoorEntity; DoorEntity = Entities.FindByClassname(DoorEntity, "func_door");)
{
	if(NetProps.GetPropInt(DoorEntity, "m_iHammerID") == 555408)
	{
		EntFireByHandle(DoorEntity, "AddOutput", "targetname UpgradeSpawnDoor1", 0.0, null, null)
	}
	if(NetProps.GetPropInt(DoorEntity, "m_iHammerID") == 571802)
	{
		EntFireByHandle(DoorEntity, "AddOutput", "targetname UpgradeSpawnDoor2", 0.0, null, null)
	}
}