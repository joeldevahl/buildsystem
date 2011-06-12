Config = {}
ConfigHooks = {}
function ImportConfig(filename)
	local temp_config = Config
	Config = {}
	local patched_filename = filename
	if(engine.path ~= "") then
		patched_filename = engine.path .. "/" .. patched_filename
	end
	Import(patched_filename)
	table.insert(ConfigHooks, Config)
	Config = temp_config
end

function AddConfig(name, filename)
	Config = {}
	ConfigHooks = {}
	ImportConfig(filename)
	engine.configs[name] = {}
	engine.configs[name].filename = filename
	engine.configs[name].name = name
	engine.configs[name].hooks = ConfigHooks
	Config = {}
	ConfigHooks = {}
end
