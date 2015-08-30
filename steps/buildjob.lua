function JobBundle(unit, name, subdir)
	local exts = { "c", "cpp", "cc" }

	if target.platform == "osx" then
		table.insert(exts, "m")
	end

	local jobs = CollectAllFiles(unit.path, { subdir }, exts)
	if next(jobs) ~= nil then
		local fixed_unit_path = unit.path
		if engine.path ~= "" then
			fixed_unit_path = string.gsub(fixed_unit_path, engine.path, "")
		end

		-- TODO: this should be a separate utility
		local path = PathJoin(target.outdir, PathJoin(fixed_unit_path, "generated"))
		local tablesrc = PathJoin(path, "jobdef_" .. name .. unit.settings.config_ext .. ".cpp")
		local script = PathJoin(engine.path, "steps/jobh.lua")
		cmd ="bam -e " .. script
		cmd = cmd .. " -- "
		cmd = cmd .. " -o " .. tablesrc
		for _,job in pairs(jobs) do
			cmd = cmd .. " " .. job
		end
		AddJob(tablesrc, "gen " .. tablesrc, cmd)
		AddDependency(tablesrc, script)
		for _,job in pairs(jobs) do
			AddDependency(tablesrc, job)
		end

		local jobobjs = Compile(unit.settings, jobs)
		local tableobj = Compile(unit.settings, tablesrc)
		local bundle = SharedLibrary(unit.settings, name, tableobj, jobobjs)
		return bundle
	end
end

function Step.Init(self)
	
	function DefaultBuildJobs(self)
		local bundle = JobBundle(self, self.name, "src/jobs")
		if bundle then
			self:AddProduct(bundle)
		end
		if engine.build_tests then
			local testbundle = JobBundle(self, "test" .. self.name, "test/jobs")
			if testbundle then
				self:AddProduct(testbundle)
			end
		end
	end

	DefaultUnit.BuildJobs        = DefaultBuildJobs
	DefaultUnit.DefaultBuildJobs = DefaultBuildJobs
end

function Step.PerConfig(self)
	for name,unit in pairs(engine.units) do
		unit:BuildJobs()
	end
end
