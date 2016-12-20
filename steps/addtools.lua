function GetHostBinary(name)
	-- TODO: better selection
	if family == "windows" then
		return "local\\build\\winx64\\" .. str_replace(name, "/", "\\") .."_d.exe"
	elseif platform == "macosx" then
		return "local/build/osx_x86_64/" .. name .. "_d"
	elseif platform == "linux" then
		return "local/build/linux_x86_64/" .. name .. "_d"
	else
		return nope
	end
end

function GetHostSharedLibrary(name)
  -- TODO: better selection
  if family == "windows" then
    return "local\\build\\winx64\\" .. name .."_d.dll"
  elseif platform == "macosx" then
    return "local/build/osx_x86_64/" .. name .. "_d.so"
  elseif platform == "linux" then
    return "local/build/linux_x86_64/" .. name .. "_d.so"
  else
    return nope
  end
end

function Step.Init(self)
	
	function DefaultAddTools(self)
	end

	DefaultUnit.AddTools        = DefaultAddTools
	DefaultUnit.DefaultAddTools = DefaultAddTools
end

function Step.PreBuild(self)
	for name,unit in pairs(engine.units) do
		unit:AddTools()
	end
end
