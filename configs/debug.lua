ImportConfig("configs/common.lua")

function Config.optimizations(self, settings)
	if family == "unix" then
		settings.cc.flags:Add("-O0")
		settings.cc.flags:Add("-g")
		settings.cc.flags:Add("-fstrict-aliasing")
	elseif family == "windows" then
		settings.cc.flags:Add("/sdl") -- SDL checks
		settings.cc.flags:Add("/Od") -- No optimization
		settings.cc.flags:Add("/Oy-") -- Keep frame pointers
		settings.cc.flags:Add("/RTC1") -- Runtime checks
		settings.cc.flags:Add("/GS") -- Secutiry checks
	end
end

function Config.warnings(self, settings)
	if family == "unix" then
		settings.cc.flags:Add("-Wall")
		settings.cc.flags:Add("-Werror")
	elseif family == "windows" then
		settings.cc.flags:Add("/WX") -- warnings as errors
		settings.cc.flags:Add("/W4") -- Level 4 warning reports
	end
end

function Config.Execute(self)
	config.settings.config_name = "debug"
	config.settings.config_ext = "_d"

	if family == "unix" then
	  config.settings.cc.flags:Add("-g")
	elseif family == "windows" then
		config.settings.cc.defines:Add("_DEBUG")
		config.settings.cc.flags:Add("/MDd") -- Multithreded debug dll runtime
		config.settings.cc.flags:Add("/Z7") -- C7 compatible debug info
		config.settings.dll.flags:Add("/DEBUG")
		config.settings.dll.flags:Add("/MANIFEST")
		config.settings.dll.flags:Add("/DYNAMICBASE")
		config.settings.dll.flags:Add("/NXCOMPAT")
		config.settings.link.flags:Add("/DEBUG")
		config.settings.link.flags:Add("/MANIFEST")
		config.settings.link.flags:Add("/DYNAMICBASE")
		config.settings.link.flags:Add("/NXCOMPAT")
	end
end
