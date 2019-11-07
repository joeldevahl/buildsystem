local ep = string.gsub(ModuleFilename(), "bam.lua", "")
Import(PathJoin(ep, "build/engine.lua"))

engine.project_name = "vriden"

AddConfig("debug", "configs/debug.lua")
AddConfig("release", "configs/release.lua")

if engine.host.family == "unix" then
	if engine.host.platform == "linux" then
		if engine.host.has32bit.value then
			AddTarget("linux_x86", "targets/linux_x86.lua")
		end
		if engine.host.has64bit.value then
			AddTarget("linux_x86_64", "targets/linux_x86_64.lua")
		end
	elseif engine.host.platform == "macosx" then
		if engine.host.has32bit.value then
			AddTarget("osx_x86", "targets/osx_x86.lua")
		end
		if engine.host.has64bit.value then
			AddTarget("osx_x86_64", "targets/osx_x86_64.lua")
		end
	end
elseif engine.host.family == "windows" then
	AddTarget("win32", "targets/win32.lua")
	AddTarget("winx64", "targets/winx64.lua")
end

AddStep("init", "steps/init.lua")
AddStep("addtools", "steps/addtools.lua")
AddStep("patch", "steps/patch.lua")
AddStep("build", "steps/build.lua")
AddStep("projgen", "steps/projgen.lua")

Init()

AddUnitDir("externals")
AddUnitDir("units")
AddUnitsInDir("projects")

Build()
