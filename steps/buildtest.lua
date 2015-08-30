--[[
function Step.Init(self)
	engine.build_tests = false

	function AddTest(self, test)
		if self.tests[config] == nil then
			self.tests[config] = {}
		end
		if self.tests[config][target] == nil then
			self.tests[config][target] = {}
		end
		
		table.insert(self.tests[config][target], test)
	end

	function DefaultGenTestdef(self)
		-- we can only build this automatically for libs
		-- no duplicate main etc.
		if self.executable == false then
			local unittest_unit = engine.units["unittest"]
			local mainsrc = PathJoin(unittest_unit.path, "src/main.cpp")
			local exts = { "c", "cpp", "cc" }

			if target.platform == "osx" then
				table.insert(exts, "m")
			end

			local source_dirs = { "test", PathJoin("test", target.family), PathJoin("test", target.platform) }
			local testfiles = CollectAllFiles(self.path, source_dirs, exts)
			if next(testfiles) ~= nil then
				-- patch local settings
				local fixed_self_path = self.path
				if engine.path ~= "" then
					fixed_self_path = string.gsub(fixed_self_path, engine.path, "")
				end
				local path = PathJoin(target.outdir, PathJoin(fixed_self_path, "generated"))
				local deffile = PathJoin(path, "testdef.h")

				-- command for building def file
				local command = "cat"
				if family == "windows" then
					command = "type"
				end
				for _,v in ipairs(testfiles) do
					command = command .. " " .. v
				end
				if family == "windows" then
				    command = command .. " | findstr \"UNITTEST\""
					command = string.gsub(command, "/", "\\") .. " > " .. deffile
				else
					command = command .. " | grep UNITTEST > " .. deffile
				end
				AddJob(deffile, "gen " .. deffile, command)
				for _,v in ipairs(testfiles) do
					AddDependency(deffile, v) -- have to do this after AddJob
				end

				-- copy main test driver
				CopyToDirectory(path, mainsrc)
				AddDependency(PathJoin(path, "main.cpp"), deffile)
			end
		end
	end

	function DefaultBuildTest(self)
		-- we can only build this automatically for libs
		-- no duplicate main etc.
		if self.executable == false then
			local original_settings = self.settings
			self.settings = original_settings:Copy()

			local unittest_unit = engine.units["unittest"]
			local exts = { "c", "cpp", "cc" }

			if target.platform == "osx" then
				table.insert(exts, "m")
			end

			local source_dirs = { "test", PathJoin("test", target.family), PathJoin("test", target.platform) }
			local testfiles = CollectAllFiles(self.path, source_dirs, exts)
			if next(testfiles) ~= nil then
				-- patch local settings
				local fixed_self_path = self.path
				if engine.path ~= "" then
					fixed_self_path = string.gsub(fixed_self_path, engine.path, "")
				end
				local path = PathJoin(target.outdir, PathJoin(fixed_self_path, "generated"))
				unittest_unit:Patch(self)
				self.settings.cc.includes:Add(path)

				-- build per unit tests
				local testobjs = Compile(self.settings, testfiles)
				local mainobj = Compile(self.settings, PathJoin(path, "main.cpp"))
				local bin = Link(self.settings, "test_" .. self.name, obj, testobjs, mainobj)
				self:AddProduct(bin)
				self:AddTest(bin)
			end
		end
	end

	DefaultUnit.GenTestdef        = DefaultGenTestdef
	DefaultUnit.DefaultGenTestdef = DefaultGenTestdef
	DefaultUnit.BuildTest         = DefaultBuildTest
	DefaultUnit.DefaultBuildTest  = DefaultBuildTest
	DefaultUnit.tests             = {}
	DefaultUnit.AddTest           = AddTest
end

function Step.PerTarget(self)
	if not engine.build_tests then
		return
	end

	for name,unit in pairs(engine.units) do
		unit:GenTestdef()
	end
end

function Step.PerConfig(self)
	if not engine.build_tests then
		return
	end

	for name,unit in pairs(engine.units) do
		unit:BuildTest()
	end
end

function Step.PostBuild(self)

	function TestTarget(names, bins)
		local cmd = ""
		local first = true
		for bin in TableWalk(bins) do
			if not first then
				cmd = cmd .. " && "
			else
				first = false
			end
			cmd = cmd .. bin
		end
		for _,name in ipairs(names) do
			AddJob(name, name, cmd)
		end
		for bin in TableWalk(bins) do
			for _,name in ipairs(names) do
				AddDependency(name, bin)
			end
		end
	end

	local all = {}
	for name,unit in pairs(engine.units) do
		local per_unit = {}
		for _,config in pairs(engine.configs) do
			local per_config = {}
			for _,target in pairs(engine.targets) do
				local ct = unit.tests[config]
				if ct then
					local tests = ct[target]
					for _,p in pairs(tests) do
						table.insert(per_config, p)
						table.insert(per_unit, p)
						table.insert(all, p)
					end
					local names = { "test_" .. unit.name .. "_" .. config.name .. "_" .. target.name,
									"test_" .. unit.name .. "_" .. target.name .. "_" .. config.name }
					TestTarget(names, tests)
				end
			end
			local names = { "test_" .. unit.name .. "_" .. config.name }
			TestTarget(names, per_config)
		end
		for _,target in pairs(engine.targets) do
			local per_target = {}
			for _,config in pairs(engine.configs) do
				local ct = unit.tests[config]
				if ct then
					local tests = ct[target]
					for _,p in pairs(tests) do
						table.insert(per_target, p)
					end
				end
			end
			local names = { "test_" .. unit.name .. "_" .. target.name }
			TestTarget(names, per_target)
		end
		local names = { "test_" .. unit.name }
		TestTarget(names, per_unit)
	end

	for _,target in pairs(engine.targets) do
		local per_target = {}
		for _,config in pairs(engine.configs) do
			for name,unit in pairs(engine.units) do
				local ct = unit.tests[config]
				if ct then
					local tests = ct[target]
					for _,p in pairs(tests) do
						table.insert(per_target, p)
					end
				end
			end
		end
		local names = { "test_" .. target.name }
		TestTarget(names, per_target)
	end

	for _,config in pairs(engine.configs) do
		local per_config = {}
		for _,target in pairs(engine.targets) do
			for name,unit in pairs(engine.units) do
				local ct = unit.tests[config]
				if ct then
					local tests = ct[target]
					for _,p in pairs(tests) do
						table.insert(per_config, p)
					end
				end
			end
		end
		local names = { "test_" .. config.name }
		TestTarget(names, per_config)
	end

	local names = { "testall" }
	TestTarget(names, all)
end
--]]
