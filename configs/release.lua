ImportConfig("configs/common.lua")

function Config:Execute(self)
	if family == "unix" then
		config.settings.cc.flags:Add("-O3")
	elseif platform == "windows" then
	end
end
