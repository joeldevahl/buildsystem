engine = {}
engine.path = string.gsub(ModuleFilename(), "build/engine.lua", "")
engine.targets = {}
engine.configs = {}
engine.steps = {}
engine.units = {}
engine.unitproviders = {}
engine.unresolved_units = {}
engine.sync = false

engine.host = {}
engine.host.family = family
engine.host.platform = platform
engine.host.arch = arch

Import(PathJoin(engine.path, "build/target.lua"))
Import(PathJoin(engine.path, "build/config.lua"))
Import(PathJoin(engine.path, "build/step.lua"))
Import(PathJoin(engine.path, "build/unit.lua"))

function EnsureLoaded(unit, restriction)
	if engine.units[unit] == nil then
		AddUnitByName(unit, restriction)
	else
		if engine.units[unit].restriction ~= restriction then
			error("missmatching restriction for unit " .. unit)
		end
	end
end

function AddUnitDir(path)
	local provider = {}
	provider.class = "dir"
	provider.path = path
	table.insert(engine.unitproviders, provider)
end

function AddUnitGitRoot(url)
	local provider = {}
	provider.class = "gitroot"
	provider.url = url
	table.insert(engine.unitproviders, provider)
end

function AddUnitByName(name, restriction)
	for _,provider in pairs(engine.unitproviders) do
		if provider.class == "dir" then
			local p = PathJoin(provider.path, name)
			if Exist(PathJoin(p, "build.lua")) or Exist(PathJoin(p, name .. ".lua")) then
				AddUnitByPath(name, p)
				return
			end
		elseif provider.class == "gitroot" then
			local p = PathJoin("local/sync", name)
			if Exist(PathJoin(p, "build.lua")) then
				if engine.sync then
					ExecuteSilent("cd " .. p .. " && git pull")
					if restriction then
						ExecuteSilent("cd " .. p .. " && git checkout " .. restriction.branch)
					end
				end
				AddUnitByPath(name, p)
				return
			elseif engine.sync then
				local url = provider.url .. "/" .. name .. ".git"
				local cmd = "cd local/sync" .. " && git clone " .. url
				local res = ExecuteSilent(cmd)
				if res == 0 then
					if restriction then
						ExecuteSilent("cd " .. p .. " && git checkout " .. restriction.branch)
					end
					if Exist(PathJoin(p, "build.lua")) or Exist(PathJoin(p, name .. ".lua")) then
						AddUnitByPath(name, p)
						return
					else
						error("synced unit " .. name .. " contains no build.lua or " .. name .. ".lua")
					end
				end
			end
		end
	end

	error("could not find unit \"" .. name .. "\"")
end

function AddUnitByPath(name, path)
	local old_unit = Unit -- should not be needed any more, but who knows
	local unit = NewUnit(name, path)
	Unit = unit
	if Exist(PathJoin(unit.path, "build.lua")) then
		Import(PathJoin(unit.path, "build.lua"))
	else
		Import(PathJoin(unit.path, name .. ".lua"))
	end
	engine.units[name] = unit
	Unit = old_unit

	-- TODO: clean up the dependencies between build/engine.lua and steps/patch.lua
	for _,import in pairs(unit.using_table) do
		EnsureLoaded(import.unit_name, import.restriction)
	end
	for _,import in pairs(unit.usingheaders_table) do
		EnsureLoaded(import.unit_name, import.restriction)
	end
	for _,import in pairs(unit.dependson_table) do
		EnsureLoaded(import.unit_name, import.restriction)
	end
end

function AddUnitsInDir(path)
	for _,path in pairs(CollectDirs(path .. "/")) do
		if Exist(PathJoin(p, "build.lua")) or Exist(PathJoin(p, name .. ".lua")) then
			AddUnitByPath(PathFilename(path), path)
		end
	end
end

function GetOutputNameWithoutExt(input)
	local full_file = PathFilename(input)
	local name = PathBase(full_file)
	local path = string.gsub(input, full_file, "")
	path = string.gsub(path, target.outdir, "")
	if engine.path ~= "" then
		path = string.gsub(path, engine.path, "")
	end
	-- TODO: strip out start of path for generated files
	return PathJoin(PathJoin(target.outdir, path), name)
end

function IntermediateOutput_Obj(settings, input)
	return GetOutputNameWithoutExt(input) .. settings.config_ext
end

function IntermediateOutput(settings, input)
	return PathJoin(target.outdir, PathBase(PathFilename(input)) .. settings.config_ext)
end

function Init()
	local sync = ScriptArgs["sync"]
	if sync and sync == "true" then
		engine.sync = true
	end

	for _,step in pairs(engine.steps) do
		step:Init()
	end
end

function Build()
	for _,step in pairs(engine.steps) do
		step:PreBuild()
	end

	local settings = NewSettings()
	settings.optimize = 0
	settings.debug = 0
	settings.cc.Output = IntermediateOutput_Obj
	settings.lib.Output = IntermediateOutput
	settings.link.Output = IntermediateOutput
	settings.dll.Output = IntermediateOutput

	for _,t in pairs(engine.targets) do
		target = t
		target.settings = settings:Copy()
		target.outdir = "local/build/" .. target.name
		target.settings.cc.includes:Add(target.outdir)
		target.settings.dll.libpath:Add(target.outdir)
		target.settings.link.libpath:Add(target.outdir)

		config = nil

		for _,hook in pairs(target.hooks) do
			hook:Execute()
		end

		for _,step in pairs(engine.steps) do
			step:PerTarget()
		end

		for _,c in pairs(engine.configs) do
			config = c
			config.settings = target.settings:Copy()

			for _,hook in pairs(config.hooks) do
				hook:Execute()
			end

			for _,step in pairs(engine.steps) do
				step:PerConfig()
			end
		end
	end

	for _,step in pairs(engine.steps) do
		step:PostBuild()
	end
end
