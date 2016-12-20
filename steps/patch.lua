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

function UnitDependencyNameList( unit )
  local res = {}
  for _, dep in ipairs( unit.using_table ) do
    table.insert( res, dep.unit_name )
  end
  return res
end

function FullDependencyMap( unit_name, units )
  local result = {}
  local unit = units[unit_name]
  result[unit_name] = UnitDependencyNameList( unit )
  for _, sub in pairs( unit.using_table ) do
    if not table.contains( result, sub ) then
      local sub_deps = FullDependencyMap( sub.unit_name, units )
      for k, v in pairs( sub_deps ) do
        if not table.contains( result, k ) then
          result[k] = v;
        end
      end
    end
  end
  return result
end

function FindEmptyDeps( dep_map )
  for k, v in pairs( dep_map ) do
    if #v == 0 then
      return k
    end
  end
  return nil
end

function TableIsEmpty( t )
  for i, _ in pairs( t ) do
    return false
  end
  return true
end

function ListRemove( lst, item )
  for i, v in ipairs( lst ) do
    if v == item then
      table.remove( lst, i )
      return
    end
  end
end

function SolveDeps( dep_map )
  local list = {}
  while TableIsEmpty( dep_map ) == false do
    local run = true
    while run do
      local rem = FindEmptyDeps( dep_map )
      if rem == nil then
        run = false
      else
        table.insert( list, rem )
        dep_map[rem] = nil
        for i, v in pairs( dep_map ) do
          if table.contains( v, rem ) then
            ListRemove( v, rem )
          end
        end
      end
    end
  end
  return list
end

function BuildPatchList(unit, units)
  local full_dep = FullDependencyMap(unit.name, units)
  local solved = SolveDeps( full_dep )
  local list = {}
  for _, v in ipairs( solved ) do
    table.insert( list, 1, v )
  end
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

	function DefaultApplyConfig(self, other_unit)
		for _,config_set in pairs(self.config_set) do
			local already_applied = table.contains(other_unit.applied_config_set, config_set)
			if not already_applied then
				for _,hook in pairs(config.hooks) do
					local cs = hook[config_set]
					if cs then
						cs(hook, other_unit.settings)
					end
				end
				table.insert(other_unit.applied_config_set, config_set)
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

	DefaultUnit.applied_config_set  = {}
	DefaultUnit.default_config_set  = { "optimizations", "warnings" } -- TODO: figure out how tom make this imutable
	DefaultUnit.config_set          = DefaultUnit.default_config_set
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
	  unit.applied_config_set = {}
	end
	for name,unit in pairs(engine.units) do
		unit.settings = config.settings:Copy()
		local patch_list = BuildPatchList(unit, engine.units)
		PatchUnit(unit, patch_list)
		unit.settings.cc.includes:Add(PathJoin(unit.path, "src"))
		unit.settings.cc.includes:Add(PathJoin(GetOutputPath(unit.path), "includes"))
		unit.settings.cc.includes:Add(PathJoin(GetOutputPath(unit.path), "src"))
	end
end
