ImportConfig("configs/common.lua")

function Config:optimizations(self, settings)
	if family == "unix" then
		config.settings.cc.flags:Add("-O3")
		config.settings.cc.flags:Add("-fstrict-aliasing")
	elseif platform == "windows" then
		config.settings.cc.flags:Add("/Ox") -- Max optimization
	end
end

function Config:warnings(self, settings)
	if family == "unix" then
		config.settings.cc.flags:Add("-Wall")
		config.settings.cc.flags:Add("-Werror")
	elseif family == "windows" then
		config.settings.cc.flags:Add("/WX") -- warnings as errors
		config.settings.cc.flags:Add("/W4") -- Level 4 warning reports
	end
end

function Config:Execute(self)
	config.settings.config_name = "release"
	config.settings.config_ext = "_r"
	
	config.settings.cc.defines:Add('LOG_ENABLE')
	config.settings.cc.defines:Add('DBG_TOOLS_ASSERT_ENABLE')
	
	if family == "windows" then
		config.settings.cc.flags:Add("/MDd") -- Multithreded debug dll runtime
		config.settings.cc.flags:Add("/Zi") -- Debug database
		config.settings.link.flags:Add("/DEBUG")
		config.settings.link.flags:Add("/MANIFEST")
		config.settings.link.flags:Add("/DYNAMICBASE")
		config.settings.link.flags:Add("/NXCOMPAT")
	end
end
