ImportTarget("targets/unix.lua")

function Target.Execute()
	target.settings.cc.defines:Add("PLATFORM_OSX")
end
