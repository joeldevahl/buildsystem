ImportTarget("targets/unix.lua")

function Target.Execute()
  target.family = "unix"
	target.settings.cc.defines:Add("PLATFORM_LINUX")
end
