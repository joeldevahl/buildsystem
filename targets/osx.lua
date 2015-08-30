ImportTarget("targets/unix.lua")

function Target.Execute()
	target.platform = "osx"
	target.family = "darwin"
	target.settings.cc.defines:Add("FAMILY_DARWIN")
	target.settings.cc.defines:Add("PLATFORM_OSX")
end
