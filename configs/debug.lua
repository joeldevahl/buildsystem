ImportConfig("configs/common.lua")

function Config:Execute(self)
	if family == "unix" then
		config.settings.cc.flags:Add("-O0")
		config.settings.cc.flags:Add("-g")
	elseif platform == "windows" then
	end
end
