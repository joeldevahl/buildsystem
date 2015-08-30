Step = {}

function AddStep(name, filename)
	Step = {}

	function Step.Init(self)
	end

	function Step.PreBuild(self)
	end

	function Step.PerTarget(self)
	end

	function Step.PerConfig(self)
	end

	function Step.PostBuild(self)
	end

	local patched_filename = filename
	if(engine.path ~= "") then
		patched_filename = engine.path .. "/" .. patched_filename
	end
	Import(patched_filename)
	Step.name = name
	table.insert(engine.steps, Step)
end
