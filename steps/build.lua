function CollectAllFiles(path, subdirs, exts)
	local src = {}
	for _,e in pairs(exts) do
		for _,p in pairs(subdirs) do
			local s = Collect(PathJoin(path, p .. "/*." .. e))
			if next(s) ~= nil then
				for _,t in pairs(s) do
					table.insert(src, t)
				end
			end
		end
	end
	return src
end

function Step.Init(self)

	function AddProduct(self, ...)
		for prod in TableWalk({...}) do
			if config then
				table.insert(self.products[target][config], prod)
			else
				table.insert(self.target_products[target], prod)
			end
		end
	end

	function DefaultBuildTarget(self)
	end

	function DefaultBuild(self)
		local exts = { "c", "cpp", "cc" }

		if target.platform == "osx" then
			table.insert(exts, "m")  -- Objective C
			table.insert(exts, "mm") -- Objective C++
		end

		local source_dirs = {}
		for _,d in pairs(self.source_dirs) do
			table.insert(source_dirs, d)
			table.insert(source_dirs, PathJoin(d, target.family))
			table.insert(source_dirs, PathJoin(d, target.platform))
		end

		local src = CollectAllFiles(self.path, source_dirs, exts)
		if next(src) ~= nil then
			local obj = Compile(self.settings, src)
			if self.static_library == true then
				local bin = StaticLibrary(self.settings, self.targetname, obj)
				self:AddProduct(bin)
			elseif self.shared_library == true then
				local bin = SharedLibrary(self.settings, self.targetname, obj)
				self:AddProduct(bin)
			elseif self.executable == true then
				local bin = Link(self.settings, self.targetname, obj)
				self:AddProduct(bin)
			end
		end
	end

	DefaultUnit.products           = {}
	DefaultUnit.target_products    = {}
	DefaultUnit.AddProduct         = AddProduct
	DefaultUnit.BuildTarget        = DefaultBuildTarget
	DefaultUnit.DefaultBuildTarget = DefaultBuildTarget
	DefaultUnit.Build              = DefaultBuild
	DefaultUnit.DefaultBuild       = DefaultBuild
end

function Step.PerTarget(self)
	for name,unit in pairs(engine.units) do
		unit.target_products[target] = {}
		unit.products[target] = {}
		unit:BuildTarget()
	end
end

function Step.PerConfig(self)
	for name,unit in pairs(engine.units) do
		unit.products[target][config] = {}
		unit:Build()
	end
end

function Step.PostBuild(self)
	local all = {}
	for _,unit in pairs(engine.units) do
		local per_unit = {}
		for _,config in pairs(engine.configs) do
			local per_config = {}
			for _,target in pairs(engine.targets) do
				local products = unit.products[target][config]
				local target_products = unit.target_products[target]
				for _,p in pairs(products) do
					table.insert(per_config, p)
					table.insert(per_unit, p)
					table.insert(all, p)
				end
				PseudoTarget(unit.name .. "_" .. config.name .. "_" .. target.name, products, target_products)
				PseudoTarget(unit.name .. "_" .. target.name .. "_" .. config.name, products, target_products)
			end
			PseudoTarget(unit.name .. "_" .. config.name, per_config)
		end
		for _,target in pairs(engine.targets) do
			local per_target = {}
			local target_products = unit.target_products[target]
			for _,p in pairs(target_products) do
				table.insert(per_unit, p)
				table.insert(all, p)
			end
			for _,config in pairs(engine.configs) do
				local products = unit.products[target][config]
				for _,p in pairs(products) do
					table.insert(per_target, p)
				end
			end
			PseudoTarget(unit.name .. "_" .. target.name, per_target, target_products)
		end
		PseudoTarget(unit.name, per_unit)
	end

	for _,target in pairs(engine.targets) do
		local per_target = {}
		local first_iteration = true
		for _,config in pairs(engine.configs) do
			local per_config = {}
			for _,unit in pairs(engine.units) do
				local products = unit.products[target][config]
				for _,p in pairs(products) do
					table.insert(per_target, p)
					table.insert(per_config, p)
				end
				if first_iteration then
					local target_products = unit.target_products[target]
					for _,p in pairs(target_products) do
						table.insert(per_target, p)
						table.insert(per_config, p)
					end
				end
			end
			PseudoTarget(target.name .. "_" .. config.name, per_config)
			PseudoTarget(config.name .. "_" .. target.name, per_config)
			first_target = false
		end
		PseudoTarget(target.name, per_target)
	end

	for _,config in pairs(engine.configs) do
		local per_config = {}
		for _,target in pairs(engine.targets) do
			for _,unit in pairs(engine.units) do
				local products = unit.products[target][config]
				local target_products = unit.target_products[target]
				for _,p in pairs(products) do
					table.insert(per_config, p)
				end
				for _,p in pairs(target_products) do
					table.insert(per_config, p)
				end
			end
		end
		PseudoTarget(config.name, per_config)
	end
	DefaultTarget(PseudoTarget("buildall", all))
end
