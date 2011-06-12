Target = {}
TargetHooks = {}
function ImportTarget(filename)
	local temp_target = Target
	Target = {}
	local patched_filename = filename
	if(engine.path ~= "") then
		patched_filename = engine.path .. "/" .. patched_filename
	end
	Import(patched_filename)
	table.insert(TargetHooks, Target)
	Target = temp_target
end

function AddTarget(name, filename)
	Target = {}
	TargetHooks = {}
	ImportTarget(filename)
	engine.targets[name] = {}
	engine.targets[name].hooks = TargetHooks
	engine.targets[name].name = name
	Target = {}
	TargetHooks = {}
end
