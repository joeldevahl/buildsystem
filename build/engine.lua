engine = {}
engine.path = ""
if ModuleFilename() then
	engine.path = string.gsub(ModuleFilename(), "build/engine.lua", "")
end
engine.targets = {}
engine.configs = {}
engine.units = {}

Import(PathJoin(engine.path, "build/host.lua"))
engine.host = NewHost()
engine.host:Add(OptTestCompileC("has32bit", "int main(){return 0;}", "-m32"))
engine.host:Add(OptTestCompileC("has64bit", "int main(){return 0;}", "-m64"))
engine.host:Finalize("host.lua")
engine.host.family = family
engine.host.platform = platform

Import(PathJoin(engine.path, "build/unit.lua"))
Import(PathJoin(engine.path, "build/config.lua"))
Import(PathJoin(engine.path, "build/target.lua"))

function AddUnit(name, path)
	local unit = NewUnit(path)
	Unit = unit
	Import(PathJoin(unit.path, "build.lua"))
	Unit = nil
	engine.units[name] = unit
end

function AddUnitsInDir(path)
	for _,path in pairs(CollectDirs(path .. "/")) do
		if Exist(PathJoin(path, "build.lua")) then
			AddUnit(PathFilename(path), path)
		end
	end
end

function IntermediateOutput_Obj(settings, input)
	local full_file = PathFilename(input)
	local name = PathBase(full_file)
	local path = string.gsub(input, full_file, "")
	if engine.path ~= "" then
		path = string.gsub(path, engine.path, "")
	end
	return PathJoin(PathJoin(config.outdir, path), name .. settings.config_ext)
end

function IntermediateOutput(settings, input)
	return PathJoin(config.outdir, PathBase(PathFilename(input)) .. settings.config_ext)
end

function Init()
	AddUnitsInDir(PathJoin(engine.path, "units"))
	AddUnitsInDir(PathJoin(engine.path, "externals"))
end

function table.contains(table, element)
	for _, value in pairs(table) do
		if value == element then
			return true
		end
	end
	return false
end

function BuildPatchList(unit, units)
	local list = {}
	for _,inc in pairs(unit.using_table) do
		local other_unit = units[inc]
		local sublist = BuildPatchList(other_unit, units)
		table.insert(sublist, inc)
		for _,dep in pairs(sublist) do
			if not table.contains(list, dep) then
				table.insert(list, dep)
			end
		end
	end
	return list
end

function Build()
	local target_names = {}
	if ScriptArgs["target"] then
		table.insert(target_names, ScriptArgs["target"])
	else
		for _,t in pairs(engine.targets) do
			table.insert(target_names, t.name)
		end
	end

	local config_names = {}
	if ScriptArgs["config"] then
		table.insert(config_names, ScriptArgs["config"])
	else
		for _,c in pairs(engine.configs) do
			table.insert(config_names, c.name)
		end
	end

	local settings = NewSettings()
	settings.optimize = 0
	settings.debug = 0
	settings.cc.Output = IntermediateOutput_Obj
	settings.lib.Output = IntermediateOutput
	settings.link.Output = IntermediateOutput
	settings.dll.Output = IntermediateOutput

	for _,t in pairs(target_names) do
		target = engine.targets[t]
		target.settings = settings
		for _,hook in pairs(target.hooks) do
			hook:Execute()
		end

		for _,c in pairs(config_names) do
			config = engine.configs[c]
			config.outdir = "local/" .. config.name .. "/" .. target.name
			config.settings = target.settings:Copy()
			config.settings.link.libpath:Add(config.outdir)

			for _,hook in pairs(config.hooks) do
				hook:Execute()
			end

			for name,unit in pairs(engine.units) do
				unit:Default()
				unit:Init()
			end

			for name,unit in pairs(engine.units) do
				unit.settings = config.settings:Copy()
				local patch_list = BuildPatchList(unit, engine.units)
				--print("Unit " .. name)
				--print("\tuses")
				--for _,u in pairs(unit.using_table) do
				--	print("\t\t" .. u)
				--end
				--print("\twill link")
				--for _,u in pairs(patch_list) do
				--	print("\t\t" .. u)
				--end
				for _,inc in pairs(patch_list) do
					local other_unit = engine.units[inc]
					other_unit:Patch(unit.settings)
				end
				unit:Patch(unit.settings)
				for _,inc in pairs(unit.usingheaders_table) do
					local other_unit = engine.units[inc]
					other_unit:PatchHeaders(unit.settings)
				end
			end

			for name,unit in pairs(engine.units) do
				unit:Build()
			end
		end
	end

end
