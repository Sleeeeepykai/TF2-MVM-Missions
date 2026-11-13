::MAX_CLIENTS <- MaxClients().tointeger()

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

local FadeState = {
	FadeState_None = 0
	FadeState_FadeIn = 1
	FadeState_FadeOut = 2
}

class MusicState {
	IsNull = false
	MusicPath = "";
	MaxVolume = 1.0;
	CurrentVolume = 0.0;
	Pitch = 100;
	FadeSpeed = 1.0;
	FadeState = 0;
	Length = -1.0;
	StopAfterFade = true;

	constructor(track, fadeSpeed = 1.0, maxVolume = 1.0, pitch = 100, stopAfterFade = true)
	{
		this.MusicPath = track;
		this.FadeSpeed = fadeSpeed;
		this.MaxVolume = maxVolume;
		this.Pitch = pitch;
		this.StopAfterFade = stopAfterFade;
		this.FadeState = 1;
	}

	function FadeIn(delta, instant = false)
	{
		if (this.IsNull)
		{
			return;
		}

		if (!this.IsValid())
		{
			return;
		}

		if (this.CurrentVolume >= this.MaxVolume)
		{
			this.FadeState = 0;
			return;
		}

		this.CurrentVolume += delta / this.FadeSpeed;
		if (instant)
		{
			this.CurrentVolume = this.MaxVolume;
		}
		if (this.CurrentVolume >= this.MaxVolume)
		{
			this.CurrentVolume = this.MaxVolume;
			this.FadeState = 0;
		}
		for (local i = 1, player; i <= MaxClients().tointeger(); i++)
		{
			if ((player = PlayerInstanceFromIndex(i)) == null)
			{
				continue;
			}

			EmitSoundEx({
				sound_name = this.MusicPath
				entity = player
				filter_type = 4
				flags = 1
				volume = this.CurrentVolume
				pitch = this.Pitch
			});
		}
	}

	function FadeOut(delta, instant = false)
	{
		if (this.IsNull)
		{
			return;
		}

		if (!this.IsValid())
		{
			return;
		}

		this.CurrentVolume -= delta / this.FadeSpeed;
		if (instant)
		{
			this.CurrentVolume = 0.0;
		}
		if (this.CurrentVolume <= 0.0)
		{
			this.CurrentVolume = 0.0;
			this.FadeState = 0;
			if (this.StopAfterFade)
			{
				for (local i = 1, player; i <= MaxClients().tointeger(); i++)
				{
					if ((player = PlayerInstanceFromIndex(i)) == null)
					{
						continue;
					}

					EmitSoundEx({
						sound_name = this.MusicPath
						entity = player
						filter_type = 4
						flags = 4
						volume = 0.015
						pitch = this.Pitch
					});
					this.Stop(player);
				}
				return;
			}
		}
		for (local i = 1, player; i <= MaxClients().tointeger(); i++)
		{
			if ((player = PlayerInstanceFromIndex(i)) == null)
			{
				continue;
			}

			EmitSoundEx({
				sound_name = this.MusicPath
				entity = player
				filter_type = 4
				flags = 1
				volume = this.CurrentVolume
				pitch = this.Pitch
			});
		}
	}

	function Stop(client)
	{
		if (this.IsNull)
		{
			return;
		}

		if (!this.IsValid())
		{
			return;
		}

		EmitSoundEx({
			sound_name = this.MusicPath
			entity = client
			filter_type = 4
			flags = 4
			volume = 0.0
			pitch = this.Pitch
		});
		this.FadeState = 0;
	}

	function Reset()
	{
		if (this.IsValid())
		{
			for (local i = 1, player; i <= MaxClients().tointeger(); i++)
			{
				if ((player = PlayerInstanceFromIndex(i)) == null)
				{
					continue;
				}
				EmitSoundEx({
					sound_name = this.MusicPath
					entity = player
					filter_type = 4
					flags = 4
					volume = 0.0
					pitch = this.Pitch
				});
			}
		}
	}

	function IsValid()
	{
		return this.MusicPath != "";
	}
}

if (!("MusicSystemMentMission" in ROOT))
{
	::MusicSystemMentMission <- ""
	local ent = FindByClassname(null, "tf_objective_resource");
	MusicSystemMentMission = GetPropString(ent, "m_iszMvMPopfileName");
}

::MusicSystemMent <-
{
	MasterEntity = null
	function OnGameEvent_recalculate_holidays(params)
	{
		local ent = FindByClassname(null, "tf_objective_resource");
		if (ent)
		{
			if (MusicSystemMentMission != GetPropString(ent, "m_iszMvMPopfileName")) // BAIL
			{
				ResetAll();
				delete ::MusicSystemMentMission;
				delete ::MusicSystemMent;
				return;
			}
		}
	}

	function HookByName(name)
	{
		local entity = Entities.FindByName(null, name);
		if (entity == null)
		{
			return; // Wait, that's illegal
		}

		HookByEntityName(entity.GetClassname(), entity);
	}

	function HookByEntityName(className, baseEntity = null)
	{
		if (baseEntity == null)
		{
			MasterEntity = Entities.FindByClassname(baseEntity, className);
			if (MasterEntity == null)
			{
				return; // Wait, that's illegal
			}
		}
		else
		{
			MasterEntity = baseEntity;
		}

		MasterEntity.ValidateScriptScope();
		local scope = MasterEntity.GetScriptScope();
		if ("QueuedTracks" in scope)
		{
			return;
		}

		scope.CurrentTrack <- null;
		scope.QueuedTracks <- [];

		scope.SetMusicTrack <- function(theme, fadeIn = 1.0, fadeOut = 1.0, maxVolume = 1.0, pitch = 100, stopAfterFade = true)
		{
			for (local i = 0; i < scope.QueuedTracks.len(); i++)
			{
				local track = scope.QueuedTracks[i];
				if (track.MusicPath == theme) // Remove from queue, put it as the current track due to it existing
				{
					track.FadeState = 1;
					track.FadeSpeed = fadeIn;
					track.Pitch = pitch;
					scope.CurrentTrack = track;
					scope.QueuedTracks.remove(i);
					for (local i2 = 0; i2 < scope.QueuedTracks.len(); i2++)
					{
						scope.QueuedTracks[i2].FadeSpeed = fadeOut;
					}
					return;
				}
			}

			if (scope.CurrentTrack != null)
			{
				scope.CurrentTrack.FadeState = 2;
				scope.QueuedTracks.append(scope.CurrentTrack);
			}

			if (theme == "")
			{
				return;
			}

			local track = MusicState(theme, fadeIn, maxVolume, pitch, stopAfterFade);
			track.FadeState = 1;
			scope.CurrentTrack = track;
			for (local i2 = 0; i2 < scope.QueuedTracks.len(); i2++)
			{
				scope.QueuedTracks[i2].FadeSpeed = fadeOut;
			}
		}

		scope.Reset <- function()
		{
			if (scope.CurrentTrack != null)
			{
				scope.CurrentTrack.Reset();
			}
			scope.CurrentTrack = null;

			for (local i = 0; i < scope.QueuedTracks.len(); i++)
			{
				scope.QueuedTracks[i].Reset();
			}

			scope.QueuedTracks.clear();
		}

		scope.Think <- function()
		{
			if (scope.CurrentTrack != null)
			{
				local track = scope.CurrentTrack;
				if (track.FadeState == 1)
				{
					track.FadeIn(FrameTime());
				}
			}

			for (local i = 0; i < scope.QueuedTracks.len(); i++)
			{
				if (scope.QueuedTracks[i].FadeState == 2)
				{
					scope.QueuedTracks[i].FadeOut(FrameTime());
				}
				else
				{
					scope.QueuedTracks.remove(i);
					i--;
				}
			}

			return -1;
		}

		AddThinkToEnt(MasterEntity, "Think");
	}

	function SetMusicTrack(theme, fadeIn = 1.0, fadeOut = 1.0, maxVolume = 1.0, pitch = 100, stopAfterFade = true)
	{
		if (MasterEntity == null)
		{
			return;
		}
		local scope = MasterEntity.GetScriptScope();
		if (scope == null)
		{
			return;
		}
		MasterEntity.GetScriptScope().SetMusicTrack(theme, fadeIn, fadeOut, maxVolume, pitch, stopAfterFade);
	}

	function ResetTracks()
	{
		if (MasterEntity == null)
		{
			return;
		}
		local scope = MasterEntity.GetScriptScope();
		if (scope == null)
		{
			return;
		}
		MasterEntity.GetScriptScope().Reset();
	}

	function ResetAll()
	{
		if (MasterEntity == null)
		{
			return;
		}
		local scope = MasterEntity.GetScriptScope();
		if (scope == null)
		{
			return;
		}

		scope.Reset();
		MasterEntity.TerminateScriptScope();
		SetPropString(MasterEntity, "m_iszScriptThinkFunction", "");
		AddThinkToEnt(MasterEntity, null);
		MasterEntity = null;
	}
}

__CollectGameEventCallbacks(MusicSystemMent);