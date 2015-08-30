
function Step.Init(self)

	function Default(self)
		self.static_library = false
		self.shared_library = false
		self.executable = false

		self.settings = {}
		self.source_dirs = {}
	end

	function DefaultInit(self)
		self.static_library = true
		table.insert(self.source_dirs, "src")
	end

	DefaultUnit.Default     = Default
	DefaultUnit.Init        = DefaultInit
	DefaultUnit.DefaultInit = DefaultInit
end

function Step.PerTarget(self)
	for name,unit in pairs(engine.units) do
		unit:Default()
		unit:Init()
	end
end
