function ResolveRestriction(opt)
	local restriction = nil
	local tab = opt[1]
	if tab then
		if tab.branch then
			restriction = {}
			restriction.branch = tab.branch
		end
		-- TODO: parse version and create a branch ID (or similar)
	end
	return restriction
end

function table.contains(table, element)
	for _, value in pairs(table) do
		if value == element then
			return true
		end
	end
	return false
end

function ImprovePatchList(list, sublist)
	for _,dep in pairs(sublist) do
		if not table.contains(list, dep) then
			table.insert(list, 1, dep)
		end
	end
	return list
end

function BuildPatchList(unit, units)
	local list = {}
	for _,import in pairs(unit.using_table) do
		local other_unit = units[import.unit_name]
		local sublist = BuildPatchList(other_unit, units)
		table.insert(sublist, import.unit_name)
		list = ImprovePatchList(list, sublist)
	end
	--print(unit.name)
	--for _,c in pairs(list) do
	--	print("\t" .. c)
	--end
	return list
end

function PatchUnit(unit, patch_list)
	unit:Patch(unit) -- patch self
	for _,inc in pairs(patch_list) do
		local other_unit = engine.units[inc]
		other_unit:Patch(unit)
	end
	for _,import in pairs(unit.usingheaders_table) do
		local other_unit = engine.units[import.unit_name]
		other_unit:PatchHeaders(unit)
	end
end

function Step.Init(self)

	function Using(self, other_unit, ...)
		local tab = {...}
		local import = {}
		import.unit_name = other_unit
		import.restriction = ResolveRestriction(tab)
		table.insert(self.using_table, import)
	end

	function UsingHeaders(self, other_unit, ...)
		local tab = {...}
		local import = {}
		import.unit_name = other_unit
		import.restriction = ResolveRestriction(tab)
		table.insert(self.usingheaders_table, import)
	end

	function DependsOn(self, other_unit, ...)
		local tab = {...}
		local import = {}
		import.unit_name = other_unit
		import.restriction = ResolveRestriction(tab)
		table.insert(self.dependson_table, import)
	end

	function DefaultApplyConfig(self, settings)
		for _,hook in pairs(config.hooks) do
			for _,config_set in pairs(self.config_set) do
				local cs = hook[config_set]
				if cs then
					cs(config, settings)
				end
			end
		end
	end

	function DefaultPatchHeaders(self, other_unit)
		other_unit.settings.cc.includes:Add(PathJoin(self.path, "include"))
	end

	function DefaultPatch(self, other_unit)
		self:ApplyConfig(other_unit)
		self:PatchHeaders(other_unit)

		if self.shared_library or self.static_library then
			other_unit.settings.dll.libs:Add(self.targetname .. other_unit.settings.config_ext)
			other_unit.settings.link.libs:Add(self.targetname .. other_unit.settings.config_ext)
		end
	end

	DefaultUnit.default_config_set  = { "optimizations", "warnings" }
	DefaultUnit.config_set          = {}
	DefaultUnit.restriction         = nil
	DefaultUnit.using_table         = {}
	DefaultUnit.Using               = Using

	DefaultUnit.usingheaders_table  = {}
	DefaultUnit.UsingHeaders        = UsingHeaders

	DefaultUnit.dependson_table     = {}
	DefaultUnit.DependsOn           = DependsOn

	DefaultUnit.ApplyConfig         = DefaultApplyConfig
	DefaultUnit.DefaultApplyConfig  = DefaultApplyConfig
	DefaultUnit.PatchHeaders        = DefaultPatchHeaders
	DefaultUnit.DefaultPatchHeaders = DefaultPatchHeaders
	DefaultUnit.Patch               = DefaultPatch
	DefaultUnit.DefaultPatch        = DefaultPatch
end

function GetOutputPath(path)
	if engine.path ~= "" then
		path = string.gsub(path, engine.path, "")
	end
	return PathJoin(target.outdir, path)
end

function Step.PerTarget(self)
	for name,unit in pairs(engine.units) do
		unit.settings = target.settings:Copy()
		unit.settings.cc.includes:Add(PathJoin(unit.path, "src"))
		unit.settings.cc.includes:Add(PathJoin(GetOutputPath(unit.path), "includes"))
		unit.settings.cc.includes:Add(PathJoin(GetOutputPath(unit.path), "src"))
	end
end

function Step.PerConfig(self)
	for name,unit in pairs(engine.units) do
		unit.settings = config.settings:Copy()
		local patch_list = BuildPatchList(unit, engine.units)
		PatchUnit(unit, patch_list)
		unit.settings.cc.includes:Add(PathJoin(unit.path, "src"))
		unit.settings.cc.includes:Add(PathJoin(GetOutputPath(unit.path), "includes"))
		unit.settings.cc.includes:Add(PathJoin(GetOutputPath(unit.path), "src"))
	end
end
