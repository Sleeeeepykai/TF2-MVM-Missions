if (!("SetInputHook" in getroottable()))
{
	local _PostInputScope = null
	local _PostInputFunc = null

	::SetInputHook <- function(entity, input, pre_func, post_func)
	{
		entity.ValidateScriptScope()
		local scope = entity.GetScriptScope()
		if (post_func)
		{
			local wrapper_func = function()
			{
				_PostInputScope = scope
				_PostInputFunc = post_func
				if (pre_func && !pre_func.call(scope))
				{
					_PostInputScope = null
					_PostInputFunc = null
					return false
				}
				return true
			}
			scope["Input" + input] <- wrapper_func
			scope["Input" + input.tolower()] <- wrapper_func
		}
		else if (pre_func)
		{
			scope["Input" + input] <- pre_func
			scope["Input" + input.tolower()] <- pre_func
		}
	}

	getroottable().setdelegate(
	{
		_delslot = function(k)
		{
			if (_PostInputScope && k == "activator" && "activator" in this)
			{
				_PostInputFunc.call(_PostInputScope)
				_PostInputFunc = null
			}
			rawdelete(k)
		}
	})
}

if (!("CameraFixerEvents" in getroottable()))
{
	::CameraFixerEvents <-
	{
		function OnGameEvent_teamplay_round_start(_)
		{
			local dummy = SpawnEntityFromTable("point_viewcontrol",
			{
				vscripts = "point_viewcontrol_fix"
			})

			dummy.GetScriptScope().ForceDisableAll()
			dummy.Destroy()
		}
	}
	__CollectGameEventCallbacks(CameraFixerEvents)
}

const LIFE_ALIVE = 0

function Precache()
{
	NetProps.SetPropBool(self, "m_bForcePurgeFixedupStrings", true)

	local take_damage = null
	local life_state = null
	SetInputHook(self, "Enable",
		function()
		{
			take_damage = NetProps.GetPropInt(activator, "m_takedamage")
			NetProps.SetPropEntity(self, "m_hPlayer", null)
			activator.SetForceLocalDraw(true)
			return true
		},
		function()
		{
			NetProps.SetPropInt(activator, "m_takedamage", take_damage)
			if (activator.GetActiveWeapon())
				activator.GetActiveWeapon().EnableDraw()
		}
	)
	SetInputHook(self, "Disable",
		function()
		{
			take_damage = NetProps.GetPropInt(activator, "m_takedamage")
			life_state = NetProps.GetPropInt(activator, "m_lifeState")
			NetProps.SetPropInt(activator, "m_lifeState", LIFE_ALIVE)
			NetProps.SetPropEntity(self, "m_hPlayer", activator)

			activator.SetForceLocalDraw(false)
			return true
		},
		function()
		{
			NetProps.SetPropInt(activator, "m_lifeState", life_state)
			NetProps.SetPropInt(activator, "m_takedamage", take_damage)
		}
	)
}

function EnableAll()
{
	for (local i = MaxClients().tointeger(); i > 0; i--)
	{
		local player = PlayerInstanceFromIndex(i)
		if (!player || player.IsFakeClient())
			continue

		self.AcceptInput("Enable", "", player, null)
	}
}

function DisableAll()
{
	for (local i = MaxClients().tointeger(); i > 0; i--)
	{
		local player = PlayerInstanceFromIndex(i)
		if (!player || player.IsFakeClient())
			continue

		if (NetProps.GetPropEntity(player, "m_hViewEntity") == self)
		{
			NetProps.SetPropEntity(self, "m_hPlayer", player)
			self.AcceptInput("Disable", "", player, null)
		}
	}
}

function ForceDisableAll()
{
	for (local i = MaxClients().tointeger(); i > 0; i--)
	{
		local player = PlayerInstanceFromIndex(i)
		if (!player || player.IsFakeClient())
			continue

		NetProps.SetPropEntity(self, "m_hPlayer", player)
		self.AcceptInput("Disable", "", player, null)
	}
}
